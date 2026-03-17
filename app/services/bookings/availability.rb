# frozen_string_literal: true

module Bookings
  class Availability
    def self.slot_blocked?(client:, booking_start_time:, exclude_booking_id: nil)
      scope = client.bookings.blocking_slot.for_slot(booking_start_time)
      scope = scope.where.not(id: exclude_booking_id) if exclude_booking_id.present?
      scope.exists?
    end

    def self.valid_generated_slot?(client:, service:, booking_start_time:)
      AvailableSlots.new(
        client: client,
        service: service,
        date: booking_start_time.to_date
      ).call.include?(booking_start_time)
    end
  end
end
