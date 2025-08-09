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
      head = s.byteslice(0,2)
      next unless head == "[{" || head == "{\""
      target = s if target.nil? || s.bytesize > target.bytesize
    end
    return render json: { error: "no big JSON string" } unless target

    encode = ->(s) {
      s.encode("UTF-8", invalid: :replace, undef: :replace, replace: "?").byteslice(0,160)
    rescue
      "<preview unavailable>"
    }

    # shallow-ish graph search from an object
    graph_has = ->(root, needle, cap=20_000) do
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
        rescue
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
        begin
          v = t[k]
        rescue
          v = nil
        end
        next if v.nil?

        direct = v.equal?(target)
        indirect = !direct && graph_has.call(v, target, 20_000)
        next unless direct || indirect

        entry = { key: k.to_s, val_class: (v.class.name rescue nil) }

        if v.is_a?(Hash)
          entry[:val_size] = v.size
          # try to find a subkey path (one level) that points at target
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
end