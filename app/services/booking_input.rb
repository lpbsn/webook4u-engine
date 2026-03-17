module BookingInput
  MAX_FUTURE_DAYS = 30

  def self.safe_date(date_param, today: Date.current, max_future_days: MAX_FUTURE_DAYS)
    return nil if date_param.blank?

    parsed_date = Date.iso8601(date_param)
    return nil if parsed_date < today
    return nil if parsed_date > today + max_future_days.days

    parsed_date
  rescue ArgumentError
    nil
  end

  def self.safe_time(time_param, now: Time.zone.now, max_future_days: MAX_FUTURE_DAYS)
    return nil if time_param.blank?

    parsed_time = Time.zone.parse(time_param)
    return nil if parsed_time.nil?
    return nil if parsed_time < now
    return nil if parsed_time > now + max_future_days.days

    parsed_time
  rescue ArgumentError, TypeError
    nil
  end
end

