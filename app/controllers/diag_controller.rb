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

def fiber_pinpoint
  require "objspace"

  target = find_big_json_string
  return render json: { error: "no big JSON string" } unless target

  results = []

  ObjectSpace.each_object(Fiber) do |fib|
    hit = scan_fiber_for_owner(fib, target, max_depth: 8, max_nodes: 200_000)
    next unless hit
    results << hit
    break if results.size >= 3
  end

  render json: {
    target: { size: target.bytesize, head: safe_head(target) },
    hits: results.presence || "none"
  }
end

def pin_env
  require "objspace"

  target = find_big_json_string
  return render json: { error: "no big JSON string" } unless target

  hits = []
  ObjectSpace.each_object(Hash) do |h|
    # Heuristic: real Rack envs have these keys
    begin
      keys = h.keys
      next unless keys.any? { |k| k.to_s == "rack.version" } &&
                  keys.any? { |k| k.to_s == "REQUEST_METHOD" }
    rescue
      next
    end
    path = find_path_inside(h, target, max_depth: 7, seen: {})
    if path
      hits << {
        env_object_id: h.object_id,
        path: path,                       # chain of {kind, key/index/ivar, class}
        head: safe_head(target),
        size: target.bytesize
      }
      break if hits.size >= 2
    end
  end

  render json: hits.empty? ? { result: "not found" } : { result: "found", hits: hits }
end

def pin_response_holders
  require "objspace"

  target = find_big_json_string
  return render json: { error: "no big JSON string" } unless target

  hits = []

  # 1) ActionDispatch::Response
  ObjectSpace.each_object(Object) do |obj|
    next unless obj.class.name == "ActionDispatch::Response"
    begin
      body = obj.instance_variable_get(:@body) rescue nil
      if body.equal?(target)
        hits << { holder: "ActionDispatch::Response", via: "@body == target" }
        break
      elsif body.is_a?(Array) && body.include?(target)
        hits << { holder: "ActionDispatch::Response", via: "@body includes target" }
        break
      end
    rescue
    end
  end

  # 2) Rack::BodyProxy (common wrapper that holds @body)
  ObjectSpace.each_object(Object) do |obj|
    next unless obj.class.name == "Rack::BodyProxy"
    begin
      inner = obj.instance_variable_get(:@body) rescue nil
      if inner.equal?(target)
        hits << { holder: "Rack::BodyProxy", via: "@body == target" }
        break
      elsif inner.is_a?(Array) && inner.include?(target)
        hits << { holder: "Rack::BodyProxy", via: "@body includes target" }
        break
      end
    rescue
    end
  end

  # 3) Arrays used as response bodies directly (Rack allows [String])
  if hits.empty?
    ObjectSpace.each_object(Array) do |arr|
      begin
        if arr.include?(target)
          hits << { holder: "Array", via: "array includes target", sample_size: arr.size }
          break
        end
      rescue
      end
    end
  end

  render json: hits.empty? ? { result: "not found" } : { result: "found", hits: hits }
end

def array_path
  require "objspace"

  target = find_big_json_string
  return render json: { error: "no big JSON string" } unless target

  result = { target: { size: target.bytesize, head: safe_head(target) }, checks: {} }

  # 1) Find the array that includes the string (if any)
  arr_holder = nil
  ObjectSpace.each_object(Array) do |arr|
    begin
      if arr.include?(target)
        arr_holder = arr
        break
      end
    rescue
    end
  end
  if arr_holder
    result[:array_holder] = { class: arr_holder.class.name, length: arr_holder.length }
  else
    result[:checks][:array] = "not found"
  end

  # 2) Rack::BodyProxy -> @body
  bodyproxy_hit = nil
  ObjectSpace.each_object(Object) do |obj|
    next unless obj.class.name == "Rack::BodyProxy"
    begin
      inner = obj.instance_variable_get(:@body) rescue nil
      if inner.equal?(target) || (inner.is_a?(Array) && inner.include?(target))
        bodyproxy_hit = { holder: "Rack::BodyProxy", via: inner.equal?(target) ? "@body==target" : "@body includes target" }
        break
      end
    rescue
    end
  end
  result[:bodyproxy] = bodyproxy_hit || { status: "not found" }

  # 3) ActionDispatch::Response -> @body
  ad_hit = nil
  ObjectSpace.each_object(Object) do |obj|
    next unless obj.class.name == "ActionDispatch::Response"
    begin
      body = obj.instance_variable_get(:@body) rescue nil
      if body.equal?(target) || (body.is_a?(Array) && body.include?(target))
        ad_hit = { holder: "ActionDispatch::Response", via: body.equal?(target) ? "@body==target" : "@body includes target" }
        break
      end
    rescue
    end
  end
  result[:action_dispatch_response] = ad_hit || { status: "not found" }

  # 4) Rack env Hashes: look for rack.response_body safely
  env_hit = nil
  ObjectSpace.each_object(Hash) do |h|
    keys = (h.keys rescue nil)
    next unless keys
    begin
      next unless keys.any? { |k| k.to_s == "rack.response_body" }
      val = nil
      # Avoid encoding issues: find the actual key object that stringifies to "rack.response_body"
      found_key = keys.find { |k| (k.to_s rescue nil) == "rack.response_body" }
      val = h[found_key] rescue nil
      if val && (val.equal?(target) || (val.is_a?(Array) && val.include?(target)))
        env_hit = { holder: "Rack env", via: "rack.response_body", val_class: val.class.name }
        break
      end
    rescue
    end
  end
  result[:rack_env] = env_hit || { status: "not found" }

  # 5) If we found any holder, try BFS to reconstruct a short path to it
  holder_obj = arr_holder || (bodyproxy_hit && "Rack::BodyProxy") || (ad_hit && "ActionDispatch::Response")
  if arr_holder
    path = bfs_path_to_target(Thread.main, arr_holder, max_nodes: 150_000, max_depth: 10) rescue nil
    result[:path_classes] = path&.map { |o| o.class.name }
  end

  # Final
  if result.values.any? { |v| v.is_a?(Hash) && v[:holder] }
    render json: result
  else
    render json: result.merge(error: "no holder found for current target; try triggering the big endpoint and calling this immediately"), status: :not_found
  end
end

require "net/http"
require "uri"

def probe_after
  # 1) Hit your big endpoint from inside the dyno
  uri = URI.parse("#{request.base_url}/api/v1/api_sports/games?league=2&season=2025")
  Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
    req = Net::HTTP::Get.new(uri.request_uri)
    # include auth header if your app needs it; otherwise omit
    http.request(req) # we don’t store the body; let it be GC’able
  end

  # 2) Wait a moment to let the request finish and middleware unwind
  sleep (params[:delay].presence || 2).to_i

  # 3) Run the same holder scans you used in array_path
  target = find_big_json_string
  result = { after_delay_sec: (params[:delay].presence || 2).to_i }

  unless target
    return render json: result.merge(note: "no big JSON string found after delay")
  end

  res = { target: { size: target.bytesize, head: safe_head(target) }, checks: {} }

  # Array holder?
  arr_holder = nil
  ObjectSpace.each_object(Array) do |arr|
    begin
      if arr.include?(target)
        arr_holder = arr
        break
      end
    rescue
    end
  end
  res[:array_holder] = arr_holder ? { class: arr_holder.class.name, length: arr_holder.length } : { status: "not found" }

  # BodyProxy?
  bp_hit = nil
  ObjectSpace.each_object(Object) do |o|
    next unless o.class.name == "Rack::BodyProxy"
    begin
      inner = o.instance_variable_get(:@body) rescue nil
      if inner.equal?(target) || (inner.is_a?(Array) && inner.include?(target))
        bp_hit = { holder: "Rack::BodyProxy" }
        break
      end
    rescue
    end
  end
  res[:bodyproxy] = bp_hit || { status: "not found" }

  # ActionDispatch::Response?
  ad_hit = nil
  ObjectSpace.each_object(Object) do |o|
    next unless o.class.name == "ActionDispatch::Response"
    begin
      body = o.instance_variable_get(:@body) rescue nil
      if body.equal?(target) || (body.is_a?(Array) && body.include?(target))
        ad_hit = { holder: "ActionDispatch::Response" }
        break
      end
    rescue
    end
  end
  res[:action_dispatch_response] = ad_hit || { status: "not found" }

  # Rack env (safe key scan)
  env_hit = nil
  ObjectSpace.each_object(Hash) do |h|
    keys = (h.keys rescue nil)
    next unless keys
    begin
      next unless keys.any? { |k| k.to_s == "rack.response_body" }
      key_obj = keys.find { |k| (k.to_s rescue nil) == "rack.response_body" }
      val = h[key_obj] rescue nil
      if val && (val.equal?(target) || (val.is_a?(Array) && val.include?(target)))
        env_hit = { holder: "Rack env via rack.response_body", val_class: val.class.name }
        break
      end
    rescue
    end
  end
  res[:rack_env] = env_hit || { status: "not found" }

  render json: res
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

# bounded BFS from `root` to `needle`, returning the path (array of objects) if found
def bfs_path_to_target(root, needle, max_nodes:, max_depth:)
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

  # 3) if Array, note if the string is included
  if owner_obj.is_a?(Array)
    info[:array_length] = owner_obj.length rescue nil
    begin
      info[:array_contains_target] = owner_obj.include?(target)
    rescue
    end
  end

  # 4) common reader methods that might return the big string
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

def scan_fiber_for_owner(fiber, target, max_depth:, max_nodes:)
  # BFS from the fiber; at each node, try to find an exact owner field/key/method == target
  seen   = {}
  queue  = []
  parent = {}  # child_id -> parent_id
  nodes  = {}  # id -> object

  fid = fiber.__id__
  seen[fid]  = true
  nodes[fid] = fiber
  queue << [fiber, 0]

  visits = 0

  while (pair = queue.shift)
    node, depth = pair

    # Check whether THIS node owns the target directly (ivar/hash key/method)
    owner_hint = precise_owner_hit(node, target)
    if owner_hint
      path = reconstruct_path(nodes, parent, node.__id__)
      return {
        fiber: fiber.object_id,
        owner_class: node.class.name,
        owner_hint: owner_hint,
        path_classes: path.map { |o| o.class.name }
      }
    end

    next if depth >= max_depth

    # Traverse
    reachable(node).each do |child|
      cid = child.__id__
      next if seen[cid]
      seen[cid] = true
      parent[cid] = node.__id__
      nodes[cid]  = child
      queue << [child, depth + 1]
    end

    visits += 1
    break if visits > max_nodes
  end

  nil
end

def precise_owner_hit(obj, target)
  # 1) direct ivars
  begin
    obj.instance_variables.each do |ivar|
      v = obj.instance_variable_get(ivar)
      return { via: "ivar", ivar: ivar.to_s } if v.equal?(target)
      # nested: array contains target
      if v.is_a?(Array) && v.include?(target)
        return { via: "ivar_array_includes", ivar: ivar.to_s }
      end
      # nested: Rack::BodyProxy or similar wrapping an array
      if v && v.respond_to?(:instance_variable_get)
        inner = v.instance_variable_get(:@body) rescue nil
        if inner.equal?(target)
          return { via: "ivar_wrapper_body_eq", ivar: ivar.to_s, wrapper: v.class.name }
        elsif inner.is_a?(Array) && inner.include?(target)
          return { via: "ivar_wrapper_array_includes", ivar: ivar.to_s, wrapper: v.class.name }
        end
      end
    end
  rescue
  end

  # 2) Hash keys/values (Rack env)
  if obj.is_a?(Hash)
    begin
      obj.each do |k, v|
        # direct key/value equality
        return({ via: "hash_key", key: key_preview(k) }) if k.equal?(target)
        return({ via: "hash_val", key: key_preview(k) }) if v.equal?(target)

        # value is array containing target (e.g. response body array)
        if v.is_a?(Array) && v.include?(target)
          return({ via: "hash_val_array_includes", key: key_preview(k) })
        end

        # value is a wrapper that has @body or similar
        if v && v.respond_to?(:instance_variable_get)
          inner = v.instance_variable_get(:@body) rescue nil
          if inner.equal?(target)
            return({ via: "hash_val_wrapper_body_eq", key: key_preview(k), wrapper: v.class.name })
          elsif inner.is_a?(Array) && inner.include?(target)
            return({ via: "hash_val_wrapper_array_includes", key: key_preview(k), wrapper: v.class.name })
          end
        end

        # special: ActionDispatch::Response has @body (array)
        if v && v.class.name == "ActionDispatch::Response"
          body = v.instance_variable_get(:@body) rescue nil
          if body.equal?(target)
            return({ via: "hash_val_response_body_eq", key: key_preview(k) })
          elsif body.is_a?(Array) && body.include?(target)
            return({ via: "hash_val_response_body_array", key: key_preview(k) })
          end
        end
      end

      # env preview for context
      if obj.respond_to?(:keys)
        sample = obj.keys.take(15).map { |k| key_preview(k) }
        if sample.any? { |s| s =~ /\A(rack|action_dispatch|puma|response|body)/i }
          return({ via: "hash_scan", sample_keys: sample })
        end
      end
    rescue
    end
  end

  # 3) Arrays
  if obj.is_a?(Array)
    begin
      return({ via: "array_includes" }) if obj.include?(target)
    rescue
    end
  end

  # 4) Common readers
  %i[body string to_str to_s].each do |m|
    next unless obj.respond_to?(m)
    begin
      val = obj.public_send(m)
      return({ via: "method", method: m.to_s }) if val.equal?(target)
      return({ via: "method_array_includes", method: m.to_s }) if val.is_a?(Array) && val.include?(target)
    rescue
    end
  end

  nil
end

# Deep scan *inside one container*, returning a labeled path to target.
# Path records look like: { kind: "hash_key", key: "rack.response_body", class: "Hash" }
def find_path_inside(obj, target, max_depth:, seen:)
  return nil if max_depth < 0
  oid = obj.__id__
  return nil if seen[oid]
  seen[oid] = true

  # Direct hit
  return [] if obj.equal?(target)

  # Hash: scan keys/values and drill down
  if obj.is_a?(Hash)
    obj.each do |k, v|
      return [{ kind: "hash_key", key: key_preview(k), class: obj.class.name }] if k.equal?(target)
      return [{ kind: "hash_val", key: key_preview(k), class: obj.class.name }] if v.equal?(target)

      # Dive into value
      sub = find_path_inside(v, target, max_depth: max_depth - 1, seen: seen)
      if sub
        return [{ kind: "hash_val", key: key_preview(k), class: obj.class.name }] + sub
      end
    end
  end

  # Array: scan elements
  if obj.is_a?(Array)
    obj.each_with_index do |v, i|
      return [{ kind: "array_elem", index: i, class: obj.class.name }] if v.equal?(target)

      sub = find_path_inside(v, target, max_depth: max_depth - 1, seen: seen)
      if sub
        return [{ kind: "array_elem", index: i, class: obj.class.name }] + sub
      end
    end
  end

  # Common wrappers: look through ivars (e.g., Rack::BodyProxy@body, ActionDispatch::Response@body)
  begin
    obj.instance_variables.each do |ivar|
      val = obj.instance_variable_get(ivar)
      next if val.nil?
      return [{ kind: "ivar", ivar: ivar.to_s, class: obj.class.name }] if val.equal?(target)

      sub = find_path_inside(val, target, max_depth: max_depth - 1, seen: seen)
      if sub
        return [{ kind: "ivar", ivar: ivar.to_s, class: obj.class.name }] + sub
      end
    end
  rescue
  end

  # Reader methods that often expose bodies
  %i[body string to_str to_s].each do |m|
    next unless obj.respond_to?(m)
    begin
      val = obj.public_send(m)
      if val.equal?(target)
        return [{ kind: "method", method: m.to_s, class: obj.class.name }]
      end
      sub = find_path_inside(val, target, max_depth: max_depth - 1, seen: seen)
      if sub
        return [{ kind: "method", method: m.to_s, class: obj.class.name }] + sub
      end
    rescue
    end
  end

  nil
end
  

end