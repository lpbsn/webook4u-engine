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

      slots.reject { |slot| blocked_slot_starts.include?(slot) }
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

    def blocked_slot_starts
      client.bookings
            .blocking_slot
            .where(booking_start_time: day_range)
            .pluck(:booking_start_time)
            .to_set
    end

    def day_range
      date.in_time_zone.all_day
    end
  end
end
