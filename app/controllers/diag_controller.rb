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
    ).map { |(size, s)| { size: size, preview: safe_string.call(s, limit: 200) } }

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
end