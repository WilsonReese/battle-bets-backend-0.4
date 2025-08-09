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

    # Sample largest retained strings (over 100 bytes) to avoid noise
    string_samples = []
    begin
      ObjectSpace.each_object(String) do |s|
        next if s.bytesize < 100
        string_samples << { size: s.bytesize, preview: s[0..100] }
      end
      string_samples = string_samples.sort_by { |h| -h[:size] }.first(5)
    rescue => e
      string_samples = ["Error scanning strings: #{e.message}"]
    end

    # Sample largest retained arrays
    array_samples = []
    begin
      ObjectSpace.each_object(Array) do |a|
        array_samples << { length: a.length, sample: a[0..2] }
      end
      array_samples = array_samples.sort_by { |h| -h[:length] }.first(5)
    rescue => e
      array_samples = ["Error scanning arrays: #{e.message}"]
    end

    # Sample largest retained hashes
    hash_samples = []
    begin
      ObjectSpace.each_object(Hash) do |h|
        hash_samples << { length: h.length, keys: h.keys.first(3) }
      end
      hash_samples = hash_samples.sort_by { |h| -h[:length] }.first(5)
    rescue => e
      hash_samples = ["Error scanning hashes: #{e.message}"]
    end

    render json: {
      rss_mb: GetProcessMem.new.mb.round(1),
      gc: stats,
      objs: counts,
      largest_strings: string_samples,
      largest_arrays: array_samples,
      largest_hashes: hash_samples
    }
  end
end