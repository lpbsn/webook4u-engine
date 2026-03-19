# Single source of truth for booking-related business rules.
# Used by: Bookings::AvailableSlots, Bookings::Input, Bookings::CreatePending, Booking model.
# Do not put domain logic here—only constants and simple predicates.

module BookingRules
  SLOT_DURATION_MINUTES = 30
  DAY_START_HOUR = 9
  DAY_END_HOUR = 18
  MIN_NOTICE_MINUTES = 30
  MAX_FUTURE_DAYS = 30
  PENDING_EXPIRATION_MINUTES = 5

  BUSINESS_TIMEZONE = "Europe/Paris"

  class << self
    def business_today
      Time.now.in_time_zone(BUSINESS_TIMEZONE).to_date
    end

    def slot_duration
      SLOT_DURATION_MINUTES.minutes
    end

    def day_start_hour
      DAY_START_HOUR
    end

    def day_end_hour
      DAY_END_HOUR
    end

    def bookable_day?(date)
      d = date.respond_to?(:to_date) ? date.to_date : date
      d.monday? || d.tuesday? || d.wednesday? || d.thursday? || d.friday?
    end

    def min_notice_minutes
      MIN_NOTICE_MINUTES
    end

    def minimum_bookable_time(now: Time.zone.now)
      now + min_notice_minutes.minutes
    end

    def max_future_days
      MAX_FUTURE_DAYS
    end

    def pending_expiration_minutes
      PENDING_EXPIRATION_MINUTES
    end

    def pending_expires_at(from: Time.zone.now)
      from + pending_expiration_minutes.minutes
    end

    # Predicate: is this booking past its expiration time? (single source for temporal validity rule)
    def booking_expired?(booking, now: Time.zone.now)
      return true if booking.booking_expires_at.blank?
      booking.booking_expires_at <= now
    end
  end
end
