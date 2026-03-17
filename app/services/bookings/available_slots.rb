# frozen_string_literal: true

module Bookings
  # Génère les créneaux disponibles pour une prestation à une date donnée.
  # Prend en compte : horaires, durée, créneaux réservés, min notice, jours non ouvrés.
  class AvailableSlots
    def initialize(client:, service:, date:)
      @client = client
      @service = service
      @date = date.to_date
    end

    def call
      return [] unless BookingRules.bookable_day?(date)

      slots.reject { |slot| slot_overlaps_blocking_booking?(slot) }
    end

    private

    attr_reader :client, :service, :date

    def slots
      start_of_day = date.in_time_zone.change(hour: BookingRules.day_start_hour, min: 0)
      end_of_day = date.in_time_zone.change(hour: BookingRules.day_end_hour, min: 0)

      result = []
      current_slot = start_of_day

      while current_slot + service.duration_minutes.minutes <= end_of_day
        result << current_slot
        current_slot += BookingRules.slot_duration
      end

      result.reject { |slot| slot < BookingRules.minimum_bookable_time }
    end

    def blocking_intervals_for_day
      @blocking_intervals_for_day ||= begin
        day_start = date.in_time_zone.change(hour: BookingRules.day_start_hour, min: 0)
        day_end   = date.in_time_zone.change(hour: BookingRules.day_end_hour,  min: 0)

        BlockingBookings.intervals_for_range(
          client: client,
          range_start: day_start,
          range_end: day_end
        )
      end
    end

    def slot_overlaps_blocking_booking?(slot_start)
      slot_end = slot_start + service.duration_minutes.minutes

      blocking_intervals_for_day.any? do |(booking_start, booking_end)|
        Availability.overlap?(booking_start, booking_end, slot_start, slot_end)
      end
    end

    def day_range
      date.in_time_zone.all_day
    end
  end
end
