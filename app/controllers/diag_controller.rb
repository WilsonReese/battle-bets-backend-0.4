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

    # Find largest JSON-looking string (>500KB)
    target = nil
    ObjectSpace.each_object(String) do |s|
      next if s.bytesize < 500_000
      head = s.byteslice(0,2)
      next unless head == "[{" || head == "{\""
      target = s if target.nil? || s.bytesize > target.bytesize
    end
    return render json: { error: "no big JSON string" } unless target

    # Helper to see if an object *directly* references the string
    refs_target = ->(obj) do
      ObjectSpace.reachable_objects_from(obj).any? { |child| child.equal?(target) } rescue false
    end

    suspects = {}

    # 1) ActionDispatch::Response (Rails response objects)
    begin
      responses = []
      ObjectSpace.each_object(ActionDispatch::Response) do |r|
        if refs_target.call(r)
          responses << { obj: r.object_id, status: r.status rescue nil, body_class: (r.body.class.name rescue nil) }
        end
      end
      suspects[:action_dispatch_response] = responses unless responses.empty?
    rescue; end

    # 2) Rack::BodyProxy (wrapped response bodies)
    begin
      proxies = []
      ObjectSpace.each_object(Rack::BodyProxy) do |bp|
        proxies << { obj: bp.object_id } if refs_target.call(bp)
      end
      suspects[:rack_body_proxy] = proxies unless proxies.empty?
    rescue; end

    # 3) StringIO / Tempfile buffers
    begin
      ios = []
      ObjectSpace.each_object(StringIO) { |io| ios << { obj: io.object_id } if refs_target.call(io) }
      suspects[:stringio] = ios unless ios.empty?
    rescue; end
    begin
      temps = []
      ObjectSpace.each_object(Tempfile) { |tf| temps << { obj: tf.object_id } if refs_target.call(tf) }
      suspects[:tempfile] = temps unless temps.empty?
    rescue; end

    # 4) Thread locals (Puma threads persist)
    begin
      hits = []
      Thread.list.each do |t|
        # quick check whether any TL directly references target
        tl_keys = (t.keys rescue [])
        tl_keys.each do |k|
          v = (t[k] rescue nil)
          if v.equal?(target) || refs_target.call(v)
            hits << { thread: t.object_id, key: k.to_s, val_class: v.class.name rescue nil }
          end
        end
      end
      suspects[:thread_locals] = hits unless hits.empty?
    rescue; end

    render json: {
      target: { size: target.bytesize, head: (target[0,100].encode("UTF-8", invalid: :replace, undef: :replace, replace: "?") rescue "<>") },
      suspects: (suspects.empty? ? "none" : suspects),
    }
  end
end