class DiagController < ApplicationController
  # lock this down however you prefer
  def compact
    require "get_process_mem"
    before = GetProcessMem.new.mb
    GC.start
    GC.compact  # Ruby 3.2 supports this
    after  = GetProcessMem.new.mb
    render json: { rss_mb_before: before.round(1), rss_mb_after: after.round(1), delta: (after - before).round(1) }
  end

  def mem
    # Lightweight RSS (MB) using ps (works on Heroku)
    rss_mb = (`ps -o rss= -p #{Process.pid}`.to_i / 1024.0).round(1)

    data = {
      rss_mb: rss_mb,
      gc: GC.stat.slice(:heap_live_slots, :heap_free_slots, :old_objects, :total_allocated_objects, :malloc_increase_bytes)
    }

    return render json: data unless params[:full].to_s == "true"

    # --- helpers ---
    safe_string = ->(obj, limit: 200) do
      s = obj.is_a?(String) ? obj : obj.to_s
      s = s.encode("UTF-8", invalid: :replace, undef: :replace, replace: "?")
      s.byteslice(0, limit)
    rescue
      "<uninspectable>"
    end

    # Keep only top N by a metric without storing everything
    top_n = ->(enum, n:, metric:) do
      buf = [] # array of [metric_value, object]
      enum.each do |obj|
        val = metric.call(obj) rescue next
        next if val.nil?
        if buf.length < n
          buf << [val, obj]
          buf.sort_by! { |x| x[0] } # asc
        elsif val > buf[0][0]
          buf[0] = [val, obj]
          buf.sort_by! { |x| x[0] }
        end
      end
      buf.sort_by { |x| -x[0] } # desc
    end

    # Counts only (cheap)
    data[:objs] = {
      T_STRING: ObjectSpace.each_object(String).count,
      T_ARRAY:  ObjectSpace.each_object(Array).count,
      T_HASH:   ObjectSpace.each_object(Hash).count
    }

    # Top strings by bytesize, skipping obvious binary blobs
    top_strings = top_n.call(
      ObjectSpace.each_object(String).lazy.reject { |s| s.encoding == Encoding::ASCII_8BIT },
      n: 5,
      metric: ->(s) { s.bytesize }
    ).map do |(size, s)|
      info = {}
      if ObjectSpace.respond_to?(:allocation_sourcefile)
        info[:file]       = ObjectSpace.allocation_sourcefile(s)
        info[:line]       = ObjectSpace.allocation_sourceline(s)
        info[:method]     = ObjectSpace.allocation_method_id(s).to_s rescue nil
        info[:class_path] = ObjectSpace.allocation_class_path(s).to_s rescue nil
      end
      { size: size, preview: safe_string.call(s, limit: 200) }.merge(info)
    end

    # Top arrays by length (only show element classes so we never dump huge contents)
    top_arrays = top_n.call(
      ObjectSpace.each_object(Array),
      n: 5,
      metric: ->(a) { a.length rescue 0 }
    ).map do |(len, a)|
      sample = (a[0, 5] || []).map { |e| e.class.name rescue "?" }
      { length: len, sample_types: sample }
    end

    # Top hashes by length (only show key classes)
    top_hashes = top_n.call(
      ObjectSpace.each_object(Hash),
      n: 5,
      metric: ->(h) { h.length rescue 0 }
    ).map do |(len, h)|
      sample = (h.keys[0, 5] || []).map { |k| k.class.name rescue "?" }
      { length: len, key_types: sample }
    end

    data[:largest_strings] = top_strings
    data[:largest_arrays]  = top_arrays
    data[:largest_hashes]  = top_hashes

    render json: data
  end

  def owner
    require "objspace"

    # 1) pick the biggest JSON-like string (>500KB)
    target = nil
    ObjectSpace.each_object(String) do |s|
      next if s.bytesize < 500_000
      head = s.byteslice(0, 2)
      next unless head == "[{" || head == "{\""
      target = s if target.nil? || s.bytesize > target.bytesize
    end
    return render json: { error: "no big JSON string found" } unless target

    info = {
      size: target.bytesize,
      preview: (target.encode("UTF-8", invalid: :replace, undef: :replace, replace: "?").byteslice(0, 180) rescue "<preview>"),
    }

    # 2) Try to find a container that directly holds it (Array/Hash)
    owner = nil

    # scan a bounded number of arrays
    scanned = 0
    ObjectSpace.each_object(Array) do |a|
      scanned += 1
      break if scanned > 50_000
      begin
        if a.include?(target)
          owner = { kind: "Array", class: a.class.name, sample_types: a.first(5).map { |e| e.class.name } }
          break
        end
      rescue
      end
    end

    if owner.nil?
      scanned = 0
      ObjectSpace.each_object(Hash) do |h|
        scanned += 1
        break if scanned > 50_000
        begin
          if h.value?(target)
            owner = { kind: "Hash", class: h.class.name, key_types: h.keys.first(5).map { |k| k.class.name } }
            break
          end
        rescue
        end
      end
    end

    # 3) Check some likely roots too

    likely = {}

    # Rails.logger buffer/formatter
    begin
      lg = Rails.logger
      likely[:logger_class] = lg.class.name
      likely[:logger_formatter] = lg.formatter.class.name if lg.respond_to?(:formatter)
    rescue; end

    # Threads and thread locals (Puma threads persist)
    begin
      thread_hits = []
      Thread.list.each do |t|
        next unless t.key?(:last_response) || t.keys.any?
        # check any thread locals that equal target
        t.keys.each do |k|
          v = t[k] rescue nil
          if v.equal?(target)
            thread_hits << { thread: t.object_id, key: k.to_s }
          end
        end
      end
      likely[:thread_hits] = thread_hits if thread_hits.any?
    rescue; end

    # Rails.cache quick class check (ensure not MemoryStore)
    begin
      likely[:cache_store_class] = Rails.cache.class.name
    rescue; end

    render json: { target: info, container_owner: owner || "not found", likely: likely }
  end

  def holders
    require "objspace"

    # 1) locate the largest JSON-looking string (>500KB)
    target = nil
    ObjectSpace.each_object(String) do |s|
      next if s.bytesize < 500_000
      head = s.byteslice(0, 2)
      next unless head == "[{" || head == "{\""
      target = s if target.nil? || s.bytesize > target.bytesize
    end
    return render json: { error: "no big JSON string" } unless target

    encode = lambda do |s|
      begin
        s.encode("UTF-8", invalid: :replace, undef: :replace, replace: "?").byteslice(0, 180)
      rescue
        "<preview unavailable>"
      end
    end

    # helpers
    safe_reachable = lambda { |obj|
      begin
        ObjectSpace.reachable_objects_from(obj)
      rescue
        []
      end
    }

    graph_has = lambda { |root, needle, max_nodes|
      seen = {}
      queue = [root]
      visited = 0
      while (node = queue.shift)
        return true if node.equal?(needle)
        id = node.__id__
        next if seen[id]
        seen[id] = true
        visited += 1
        break if visited > max_nodes
        safe_reachable.call(node).each { |child| queue << child }
      end
      false
    }

    # 2) assemble likely roots to probe
    roots = []
    begin
      roots << Rails
      roots << Rails.application if defined?(Rails) && Rails.respond_to?(:application)
      roots << Rails.application.middleware if Rails.application.respond_to?(:middleware)
    rescue; end

    begin
      lg = Rails.logger
      roots << lg if lg
      roots << lg.formatter if lg && lg.respond_to?(:formatter) && lg.formatter
      if lg && lg.instance_variables.include?(:@loggers)
        arr = lg.instance_variable_get(:@loggers) rescue []
        arr.each { |l2| roots << l2 }
      end
    rescue; end

    begin
      roots << Thread.main
      Thread.list.each { |t| roots << t }
    rescue; end

    # Common rack/rails classes if loaded
    roots << ActionDispatch::Response if defined?(ActionDispatch::Response)
    roots << Rack::BodyProxy          if defined?(Rack::BodyProxy)

    # 3) scan roots with a bigger cap (still bounded)
    hits = []
    roots.uniq.each do |root|
      begin
        klass = root.is_a?(Module) ? root.name : root.class.name
        refs  = graph_has.call(root, target, 50_000) # widened from 10–20k
        hits << { root_class: klass, refs: refs }
      rescue
        # ignore
      end
    end

    # 4) also try deeper on specific object instances (responses/body proxies)
    adr_hits = []
    if defined?(ActionDispatch::Response)
      begin
        ObjectSpace.each_object(ActionDispatch::Response) do |r|
          if graph_has.call(r, target, 25_000)
            status     = (r.status rescue nil)
            body_class = begin
              b = r.body
              b.class.name
            rescue
              nil
            end
            adr_hits << { obj: r.object_id, status: status, body_class: body_class }
          end
          break if adr_hits.size >= 5
        end
      rescue; end
    end

    bp_hits = []
    if defined?(Rack::BodyProxy)
      begin
        ObjectSpace.each_object(Rack::BodyProxy) do |bp|
          if graph_has.call(bp, target, 25_000)
            bp_hits << { obj: bp.object_id }
          end
          break if bp_hits.size >= 5
        end
      rescue; end
    end

    render json: {
      target: { size: target.bytesize, head: encode.call(target) },
      root_hits: hits,
      action_dispatch_response: (adr_hits.empty? ? nil : adr_hits),
      rack_body_proxy:          (bp_hits.empty?  ? nil : bp_hits)
    }
  end

  def thread_refs
    require "objspace"

    # Find the biggest JSON-like string (>500KB)
    target = nil
    ObjectSpace.each_object(String) do |s|
      next if s.bytesize < 500_000
      head = s.byteslice(0, 2)
      next unless head == "[{" || head == "{\""
      target = s if target.nil? || s.bytesize > target.bytesize
    end
    return render json: { error: "no big JSON string" } unless target

    encode = ->(str) {
      begin
        str.encode("UTF-8", invalid: :replace, undef: :replace, replace: "?").byteslice(0, 160)
      rescue StandardError
        "<preview unavailable>"
      end
    }

    graph_has = ->(root, needle, cap = 20_000) do
      seen = {}
      q = [root]
      visited = 0
      while (node = q.shift)
        return true if node.equal?(needle)
        id = node.__id__
        next if seen[id]
        seen[id] = true
        visited += 1
        break if visited > cap
        begin
          ObjectSpace.reachable_objects_from(node).each { |child| q << child }
        rescue StandardError
        end
      end
      false
    end

    hits = []
    Thread.list.each do |t|
      keys = (t.keys rescue [])
      next if keys.empty?
      key_hits = []
      keys.each do |k|
        v = (t[k] rescue nil)
        next if v.nil?
        direct   = v.equal?(target)
        indirect = !direct && graph_has.call(v, target, 20_000)
        next unless direct || indirect

        entry = { key: k.to_s, val_class: (v.class.name rescue nil) }
        if v.is_a?(Hash)
          entry[:val_size] = v.size
          v.each do |kk, vv|
            if vv.equal?(target)
              entry[:sub_hit] = { subkey: kk.to_s, sub_val_class: (vv.class.name rescue nil) }
              break
            end
          end
        elsif v.is_a?(Array)
          entry[:val_size] = v.length
        end
        key_hits << entry
      end
      hits << { thread: t.object_id, keys: key_hits } unless key_hits.empty?
    end

    render json: {
      target: { size: target.bytesize, head: encode.call(target) },
      thread_hits: hits
    }
  end

  def thread_path
    require "objspace"

    target = find_big_json_string
    return render json: { error: "no big JSON string" } unless target

    Thread.list.each do |t|
      path, parent = bfs_path_with_parent(t, target, max_nodes: 60_000, max_depth: 10)
      next unless path

      last  = path.last         # should be target or near
      prev  = path[-2]          # the object that references the target
      owner = inspect_owner_edge(prev, target)

      return render json: {
        target: { size: target.bytesize, head: safe_head(target) },
        thread: t.object_id,
        path_classes: path.map { |o| o.class.name },
        owner_hint: owner
      }
    end

    render json: { target: { size: target.bytesize, head: safe_head(target) }, note: "no path found; try right after a few API hits" }
  end

  def fiber_owner
    require "objspace"

    target = find_big_json_string
    return render json: { error: "no big JSON string" } unless target

    # Scan all Fibers for a nearby Hash or object that references the target
    hits = []
    ObjectSpace.each_object(Fiber) do |fib|
      path = bfs_path_to_target(fib, target, max_nodes: 60_000, max_depth: 10)
      next unless path
      parent = path[-2] # object that directly references target
      hint   = inspect_owner_edge(parent, target)
      hits << {
        fiber: fib.object_id,
        path_classes: path.map { |o| o.class.name },
        owner_hint: hint
      }
      break if hits.size >= 3
    end

    render json: {
      target: { size: target.bytesize, head: safe_head(target) },
      hits: hits
    }
  end

  private

  def safe_head(str)
    str.encode("UTF-8", invalid: :replace, undef: :replace, replace: "?").byteslice(0, 160)
  rescue
    "<preview unavailable>"
  end

  def find_big_json_string
    biggest = nil
    ObjectSpace.each_object(String) do |s|
      next if s.bytesize < 500_000
      head = s.byteslice(0, 2)
      next unless head == "[{" || head == "{\""
      biggest = s if biggest.nil? || s.bytesize > biggest.bytesize
    end
    biggest
  end

  def reachable(obj)
    ObjectSpace.reachable_objects_from(obj)
  rescue
    []
  end

  # bounded BFS from `root` to `needle`, returning the path (objects) if found
  def bfs_path_to_target(root, needle, max_nodes:, max_depth:)
    seen   = {}
    queue  = []
    parent = {}
    nodes  = {}

    rid = root.__id__
    seen[rid]  = true
    nodes[rid] = root
    queue << [root, 0]

    visits = 0
    while (pair = queue.shift)
      node, depth = pair
      return reconstruct_path(nodes, parent, node.__id__) if node.equal?(needle)
      next if depth >= max_depth

      reachable(node).each do |child|
        cid = child.__id__
        next if seen[cid]
        seen[cid] = true
        parent[cid] = node.__id__
        nodes[cid]  = child
        return reconstruct_path(nodes, parent, cid) if child.equal?(needle)
        queue << [child, depth + 1]
      end

      visits += 1
      break if visits > max_nodes
    end

    nil
  end

  def reconstruct_path(nodes, parent, leaf_id)
    path = []
    cur  = leaf_id
    while cur
      path << nodes[cur]
      cur = parent[cur]
    end
    path.reverse
  end

  # Tell us exactly how `owner_obj` points to the target (ivar? hash key? method?)
  def inspect_owner_edge(owner_obj, target)
    return { note: "no owner (target was root?)" } if owner_obj.nil?

    info = { owner_class: owner_obj.class.name }

    # 1) instance variables
    begin
      iv_hits = []
      owner_obj.instance_variables.each do |ivar|
        v = owner_obj.instance_variable_get(ivar)
        iv_hits << ivar.to_s if v.equal?(target)
      end
      info[:ivars_pointing_to_target] = iv_hits unless iv_hits.empty?
    rescue
    end

    # 2) if Hash, check keys/values; show size and a few keys
    if owner_obj.is_a?(Hash)
      info[:hash_size] = owner_obj.size rescue nil
      begin
        key_hits = []
        val_hits = []
        sample_keys = []
        owner_obj.each do |k, v|
          key_hits << key_preview(k) if k.equal?(target)
          val_hits << key_preview(k) if v.equal?(target)
          sample_keys << key_preview(k)
          break if sample_keys.size >= 10
        end
        info[:hash_keys_equal_target]   = key_hits unless key_hits.empty?
        info[:hash_values_equal_target] = val_hits unless val_hits.empty?
        info[:hash_keys_sample]         = sample_keys unless sample_keys.empty?
      rescue
      end
    end

    # 3) if Array, say so
    if owner_obj.is_a?(Array)
      info[:array_length] = owner_obj.length rescue nil
      begin
        info[:array_contains_target] = owner_obj.include?(target)
      rescue
      end
    end

    # 4) common reader methods
    %i[body string to_str to_s].each do |m|
      next unless owner_obj.respond_to?(m)
      begin
        val = owner_obj.public_send(m)
        if val.equal?(target)
          info[:method_pointing_to_target] = m.to_s
          break
        end
      rescue
      end
    end

    info
  end

  def key_preview(k)
    case k
    when String then k
    when Symbol then k.to_s
    else k.inspect
    end
  end

  def safe_head(str)
    str.encode("UTF-8", invalid: :replace, undef: :replace, replace: "?").byteslice(0, 160)
  rescue
    "<preview unavailable>"
  end

  # find the largest JSON-looking String (>500KB)
  def find_big_json_string
    biggest = nil
    ObjectSpace.each_object(String) do |s|
      next if s.bytesize < 500_000
      head = s.byteslice(0, 2)
      next unless head == "[{" || head == "{\""
      biggest = s if biggest.nil? || s.bytesize > biggest.bytesize
    end
    biggest
  end

  def reachable(obj)
    ObjectSpace.reachable_objects_from(obj)
  rescue
    []
  end

  def kind_of_obj(o)
    case o
    when Hash  then "Hash"
    when Array then "Array"
    else o.class.name
    end
  end

  # Breadth-first search from `root` to `needle`, bounded, returning the path (objects)
  def bfs_path_to_target(root, needle, max_nodes:, max_depth:)
    seen = {}
    queue = []
    parent = {}  # child.__id__ -> parent.__id__
    objects = {} # id -> object (to reconstruct path)

    root_id = root.__id__
    seen[root_id] = true
    objects[root_id] = root
    queue << [root, 0]

    visits = 0

    while (pair = queue.shift)
      node, depth = pair
      return reconstruct_path(objects, parent, node, needle) if node.equal?(needle)
      next if depth >= max_depth

      children = reachable(node)
      children.each do |child|
        id = child.__id__
        next if seen[id]
        seen[id] = true
        parent[id] = node.__id__
        objects[id] = child
        return reconstruct_path(objects, parent, child, needle) if child.equal?(needle)
        queue << [child, depth + 1]
      end

      visits += 1
      break if visits > max_nodes
    end

    nil
  end

  # def reconstruct_path(nodes, parent, leaf_id)
  #   path = []
  #   cur  = leaf_id
  #   while cur
  #     path << nodes[cur]
  #     cur = parent[cur]
  #   end
  #   path.reverse
  # end

  def bfs_path_with_parent(root, needle, max_nodes:, max_depth:)
    seen   = {}
    queue  = []
    parent = {}  # child_id -> parent_id
    nodes  = {}  # id -> object

    rid = root.__id__
    seen[rid]  = true
    nodes[rid] = root
    queue << [root, 0]

    visits = 0

    while (pair = queue.shift)
      node, depth = pair
      return [reconstruct_path(nodes, parent, node.__id__), parent] if node.equal?(needle)
      next if depth >= max_depth

      children = reachable(node)
      children.each do |child|
        cid = child.__id__
        next if seen[cid]
        seen[cid] = true
        parent[cid] = node.__id__
        nodes[cid]  = child
        return [reconstruct_path(nodes, parent, cid), parent] if child.equal?(needle)
        queue << [child, depth + 1]
      end

      visits += 1
      break if visits > max_nodes
    end

    nil
  end

  def inspect_owner_edge(owner_obj, target)
    return { note: "no owner (target was root?)" } if owner_obj.nil?

    info = { owner_class: owner_obj.class.name }

    # 1) Check instance variables that directly point at target
    begin
      iv_hits = []
      owner_obj.instance_variables.each do |ivar|
        v = owner_obj.instance_variable_get(ivar)
        if v.equal?(target)
          iv_hits << ivar.to_s
        end
      end
      info[:ivars_pointing_to_target] = iv_hits unless iv_hits.empty?
    rescue
    end

    # 2) If Hash, check keys/values
    if owner_obj.is_a?(Hash)
      begin
        key_hits = []
        val_hits = []
        owner_obj.each do |k, v|
          key_hits << (k.is_a?(String) ? k : k.inspect) if k.equal?(target)
          val_hits << (k.is_a?(String) ? k : k.inspect) if v.equal?(target)
        end
        info[:hash_keys_equal_target]   = key_hits unless key_hits.empty?
        info[:hash_values_equal_target] = val_hits unless val_hits.empty?
      rescue
      end
    end

    # 3) If Array, check if it contains target
    if owner_obj.is_a?(Array)
      begin
        if owner_obj.include?(target)
          info[:array_contains_target] = true
        end
      rescue
      end
    end

    # 4) Common reader methods that might return the big string
    %i[body string to_str].each do |m|
      next unless owner_obj.respond_to?(m)
      begin
        val = owner_obj.public_send(m)
        if val.equal?(target)
          info[:method_pointing_to_target] = m.to_s
        end
      rescue
      end
    end

    info
  end
  

end