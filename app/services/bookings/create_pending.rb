# frozen_string_literal: true

module Bookings
  class CreatePending
    Result = Struct.new(:success?, :booking, :error_code, :error_message, keyword_init: true)

    def initialize(client:, service:, booking_start_time:)
      @client = client
      @service = service
      @booking_start_time = booking_start_time
    end

    def call
      return failure(Errors::INVALID_SLOT) if booking_start_time.nil?

      booking_end_time = booking_start_time + service.duration_minutes.minutes
      booking = nil

      SlotLock.with_lock(client_id: client.id, booking_start_time: booking_start_time) do
        if Availability.slot_blocked?(client: client, service: service, booking_start_time: booking_start_time)
          return failure(Errors::SLOT_UNAVAILABLE)
        end

        unless Availability.valid_generated_slot?(client: client, service: service, booking_start_time: booking_start_time)
          return failure(Errors::SLOT_NOT_BOOKABLE)
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
      failure(Errors::PENDING_CREATION_FAILED)
    end

    private

    attr_reader :client, :service, :booking_start_time

    def success(booking)
      Result.new(success?: true, booking: booking, error_code: nil, error_message: nil)
    end

    def failure(code)
      Result.new(
        success?: false,
        booking: nil,
        error_code: code,
        error_message: Errors.message_for(code)
      )
    end
  end
end
