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
    render json: {
      rss_mb: GetProcessMem.new.mb.round(1),
      gc: stats,
      objs: counts
    }
  end
end