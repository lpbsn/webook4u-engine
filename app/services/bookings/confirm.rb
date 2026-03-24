# frozen_string_literal: true

module Bookings
  class Confirm
    Result = Struct.new(:success?, :booking, :error_code, :error_message, keyword_init: true)

    def initialize(booking:, booking_params:)
      @booking = booking
      @booking_params = booking_params
    end

    def call
      return failure(Errors::NOT_PENDING) unless booking.pending?
      return failure(Errors::SESSION_EXPIRED) if booking.expired?

      SlotLock.with_lock(enseigne_id: booking.enseigne_id, booking_start_time: booking.booking_start_time) do
        if Availability.slot_blocked?(
          client: booking.client,
          enseigne: booking.enseigne,
          service: booking.service,
          booking_start_time: booking.booking_start_time,
          exclude_booking_id: booking.id
        )
          return failure(Errors::SLOT_UNAVAILABLE)
        end

        booking.update!(
          confirmation_token: SecureRandom.uuid,
          customer_first_name: booking_params[:customer_first_name],
          customer_last_name: booking_params[:customer_last_name],
          customer_email: booking_params[:customer_email],
          booking_status: :confirmed
        )
      end

      success(booking)
    rescue ActiveRecord::RecordInvalid
      failure(Errors::FORM_INVALID)
    rescue ActiveRecord::RecordNotUnique
      failure(Errors::SLOT_TAKEN_DURING_CONFIRM)
    end

    private

    attr_reader :booking, :booking_params

    def success(booking)
      Result.new(success?: true, booking: booking, error_code: nil, error_message: nil)
    end

    def failure(code)
      Result.new(
        success?: false,
        booking: booking,
        error_code: code,
        error_message: Errors.message_for(code)
      )
    end
  end
end
