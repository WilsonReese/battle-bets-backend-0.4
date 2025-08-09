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
    # Get resident set size in MB
    rss_mb = (`ps -o rss= -p #{Process.pid}`.to_i / 1024.0).round(1)

    # Always include lightweight GC stats
    data = {
      rss_mb: rss_mb,
      gc: GC.stat.slice(:heap_live_slots, :heap_free_slots, :old_objects, :total_allocated_objects, :malloc_increase_bytes)
    }

    # Only include expensive object scans if explicitly requested
    if params[:full] == "true"
      data[:objs] = {
        T_STRING: ObjectSpace.each_object(String).count,
        T_ARRAY:  ObjectSpace.each_object(Array).count,
        T_HASH:   ObjectSpace.each_object(Hash).count
      }

      data[:largest_strings] = ObjectSpace.each_object(String)
        .sort_by(&:bytesize)
        .last(5)
        .map { |s| { size: s.bytesize, preview: s[0, 200] } }

      data[:largest_arrays] = ObjectSpace.each_object(Array)
        .sort_by(&:size)
        .last(5)
        .map { |a| { length: a.size, sample: a.first(5) } }

      data[:largest_hashes] = ObjectSpace.each_object(Hash)
        .sort_by(&:size)
        .last(5)
        .map { |h| { length: h.size, keys_sample: h.keys.first(5) } }
    end

    render json: data
  end
end