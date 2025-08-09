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
    require "get_process_mem"

    stats  = GC.stat.slice(:heap_live_slots, :heap_free_slots, :old_objects, :total_allocated_objects, :malloc_increase_bytes)
    counts = ObjectSpace.count_objects.slice(:T_STRING, :T_ARRAY, :T_HASH) rescue {}

    largest_strings = []
    largest_arrays  = []
    largest_hashes  = []

    # Helper to safely preview objects
    safe_preview = ->(obj) {
      str = obj.inspect rescue obj.to_s rescue "<uninspectable>"
      str[0..200] # limit preview size
    }

    # Strings
    ObjectSpace.each_object(String) do |s|
      next if s.encoding == Encoding::BINARY # skip binary blobs
      largest_strings << { size: s.bytesize, preview: safe_preview.call(s) }
    end
    largest_strings.sort_by! { |h| -h[:size] }
    largest_strings = largest_strings.first(5)

    # Arrays
    ObjectSpace.each_object(Array) do |a|
      begin
        largest_arrays << { length: a.length, sample: safe_preview.call(a[0..4]) }
      rescue
        next
      end
    end
    largest_arrays.sort_by! { |h| -h[:length] }
    largest_arrays = largest_arrays.first(5)

    # Hashes
    ObjectSpace.each_object(Hash) do |h|
      begin
        largest_hashes << { length: h.length, keys_sample: safe_preview.call(h.keys[0..4]) }
      rescue
        next
      end
    end
    largest_hashes.sort_by! { |h| -h[:length] }
    largest_hashes = largest_hashes.first(5)

    render json: {
      rss_mb: GetProcessMem.new.mb.round(1),
      gc: stats,
      objs: counts,
      largest_strings: largest_strings,
      largest_arrays: largest_arrays,
      largest_hashes: largest_hashes
    }
  end
end