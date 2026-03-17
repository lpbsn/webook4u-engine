# frozen_string_literal: true

module Bookings
  class Availability
    def self.slot_blocked?(client:, service:, booking_start_time:, exclude_booking_id: nil)
      new_start = booking_start_time
      new_end   = booking_start_time + service.duration_minutes.minutes

      BlockingBookings.overlapping(
        client: client,
        start_time: new_start,
        end_time: new_end,
        exclude_booking_id: exclude_booking_id
      ).exists?
    end

    def self.valid_generated_slot?(client:, service:, booking_start_time:)
      AvailableSlots.new(
        client: client,
        service: service,
        date: booking_start_time.to_date
      ).call.include?(booking_start_time)
    end

    def self.overlap?(start_a, end_a, start_b, end_b)
      start_a < end_b && end_a > start_b
    end
  end
end
