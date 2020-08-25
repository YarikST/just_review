module Cancelable
  extend ActiveSupport::Concern

  def cancelled? *uuids
    $redis.exists(cancelable_uuid(uuids))
  end

  def cancel! *uuids
    $redis.setex(cancelable_uuid(uuids), timeout_cancelled, 1)
  end

  def timeout_cancelled
    #86400   - 24h
    #172800  - 48h

    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end

  private

  def cancelable_uuid uuids
    "cancelled:#{name}:#{uuids.join('-')}"
  end
end
