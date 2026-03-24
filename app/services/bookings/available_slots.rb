# frozen_string_literal: true

module Bookings
  # Génère les créneaux disponibles pour une prestation à une date donnée.
  # Prend en compte : horaires, durée, créneaux réservés, min notice, jours non ouvrés.
  class AvailableSlots
    def initialize(client:, service:, date:, enseigne: nil)
      @client = client
      @service = service
      @date = date.to_date
      @enseigne = enseigne
    end

    def call
      return [] if opening_intervals.empty?

      slots.reject { |slot| slot_overlaps_blocking_booking?(slot) }
    end

    private

    attr_reader :client, :service, :date, :enseigne

    def slots
      result = []

      opening_intervals.each do |(start_of_day, end_of_day)|
        current_slot = start_of_day

        while current_slot + service.duration_minutes.minutes <= end_of_day
          result << current_slot
          current_slot += BookingRules.slot_duration
        end
      end

      result.reject { |slot| slot < BookingRules.minimum_bookable_time }
    end

    def blocking_intervals_for_day
      @blocking_intervals_for_day ||= begin
        BlockingBookings.intervals_for_range(
          client: client,
          enseigne: enseigne,
          range_start: opening_intervals.first.first,
          range_end: opening_intervals.last.last
        )
      end
    end

    def opening_intervals
      @opening_intervals ||= ScheduleResolver.new(
        client: client,
        enseigne: enseigne,
        date: date
      ).call
    end

    def slot_overlaps_blocking_booking?(slot_start)
      slot_end = slot_start + service.duration_minutes.minutes

      blocking_intervals_for_day.any? do |(booking_start, booking_end)|
        Availability.overlap?(booking_start, booking_end, slot_start, slot_end)
      end
    end
  end
end
