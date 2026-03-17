# frozen_string_literal: true

module Bookings
  class CreatePending
    Result = Struct.new(:success?, :booking, :error_message, keyword_init: true)

    def initialize(client:, service:, booking_start_time:)
      @client = client
      @service = service
      @booking_start_time = booking_start_time
    end

    def call
      return failure("Le créneau sélectionné est invalide.") if booking_start_time.nil?

      booking_end_time = booking_start_time + service.duration_minutes.minutes
      booking = nil

      SlotLock.with_lock(
        client_id: client.id,
        booking_start_time: booking_start_time
      ) do
        if Availability.slot_blocked?(client: client, booking_start_time: booking_start_time)
          return failure("Le créneau sélectionné n'est plus disponible.")
        end

        unless Availability.valid_generated_slot?(
          client: client,
          service: service,
          booking_start_time: booking_start_time
        )
          return failure("Le créneau sélectionné n'est pas réservable.")
        end

        booking = Booking.create!(
          client: client,
          service: service,
          booking_start_time: booking_start_time,
          booking_end_time: booking_end_time,
          booking_status: :pending,
          booking_expires_at: BookingRules.pending_expires_at
        )
      end

      success(booking)
    rescue ActiveRecord::RecordInvalid
      failure("Impossible de créer la réservation temporaire.")
    end

    private

    attr_reader :client, :service, :booking_start_time

    def success(booking)
      Result.new(success?: true, booking: booking, error_message: nil)
    end

    def failure(message)
      Result.new(success?: false, booking: nil, error_message: message)
    end
  end
end
