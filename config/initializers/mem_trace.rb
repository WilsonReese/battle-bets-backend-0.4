if ENV["MEM_TRACE"] == "1"
  require "objspace"
  ObjectSpace.trace_object_allocations_start
  Rails.logger.info "MEM_TRACE enabled"
end