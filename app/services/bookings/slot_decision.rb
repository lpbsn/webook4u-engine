# frozen_string_literal: true

module Bookings
  class SlotDecision
    # Single point of truth for "is this slot reservable?"
    #
    # The slot is evaluated against a reservable Resource abstraction rather
    # than directly against the public booking context. Today this resource is
    # still the whole enseigne; the next target is an explicit staff resource.
    Result = Struct.new(
      :bookable?,
      :error_code,
      :error_message,
      :booking_start_time,
      :booking_end_time,
      :resource,
      keyword_init: true
    )

    def initialize(client:, service:, booking_start_time:, enseigne:, exclude_booking_id: nil, resource: nil)
      @client = client
      @enseigne = enseigne
      @service = service
      @booking_start_time = booking_start_time
      @exclude_booking_id = exclude_booking_id
      @resource = resource
      @require_generated_slot = true
    end

    def call
      return failure(Errors::INVALID_SLOT) if booking_start_time.nil?
      return failure(Errors::SLOT_UNAVAILABLE) if blocked_slot?
      return failure(Errors::SLOT_NOT_BOOKABLE) if require_generated_slot? && !generated_slot?

      success
    end

    def without_generated_slot_requirement
      @require_generated_slot = false
      self
    end

    private

    attr_reader :client, :enseigne, :service, :booking_start_time, :exclude_booking_id

    def booking_end_time
      @booking_end_time ||= booking_start_time + service.duration_minutes.minutes
    end

    def resource
      # Current trivial resolution:
      # public enseigne selection -> one implicit staff/resource for that enseigne.
      # Once multiple staffs exist, this resolution will become an explicit
      # domain step without changing SlotDecision's public contract.
      @resource ||= Resource.for_enseigne(client: client, enseigne: enseigne)
    end

    def require_generated_slot?
      @require_generated_slot
    end

    def generated_slot?
      AvailableSlots.new(
        client: client,
        enseigne: enseigne,
        service: service,
        date: booking_start_time.to_date
      ).call.include?(booking_start_time)
    end

    def blocked_slot?
      BlockingBookings.overlapping(
        client: client,
        resource: resource,
        start_time: booking_start_time,
        end_time: booking_end_time,
        exclude_booking_id: exclude_booking_id
      ).exists?
    end

    def success
      Result.new(
        bookable?: true,
        error_code: nil,
        error_message: nil,
        booking_start_time: booking_start_time,
        booking_end_time: booking_end_time,
        resource: resource
      )
    end

    def failure(code)
      Result.new(
        bookable?: false,
        error_code: code,
        error_message: Errors.message_for(code),
        booking_start_time: booking_start_time,
        booking_end_time: booking_start_time.present? ? booking_end_time : nil,
        resource: resource
      )
    end
  end
end
