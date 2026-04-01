# frozen_string_literal: true

require "test_helper"

class Bookings::SlotDecisionTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

  setup do
    @client = Client.create!(name: "Salon Slot Decision", slug: "salon-slot-decision")
    create_weekday_opening_hours_for(@client)
    @enseigne = @client.enseignes.create!(name: "Enseigne A", full_address: "1 rue A")
    @other_enseigne = @client.enseignes.create!(name: "Enseigne B", full_address: "2 rue B")
    @service = @client.services.create!(name: "Coupe", duration_minutes: 30, price_cents: 2500)
  end

  test "returns invalid slot when booking_start_time is nil" do
    result = build_decision(booking_start_time: nil).call

    assert_not result.bookable?
    assert_equal Bookings::Errors::INVALID_SLOT, result.error_code
    assert_equal Bookings::Errors.message_for(Bookings::Errors::INVALID_SLOT), result.error_message
    assert_nil result.booking_end_time
  end

  test "returns slot not bookable when slot is outside generated grid and not blocked" do
    travel_to Time.zone.local(2026, 3, 15, 8, 0, 0) do
      result = build_decision(
        booking_start_time: Time.zone.local(2026, 3, 16, 8, 0, 0)
      ).call

      assert_not result.bookable?
      assert_equal Bookings::Errors::SLOT_NOT_BOOKABLE, result.error_code
    end
  end

  test "returns slot unavailable when overlapping confirmed booking exists" do
    travel_to Time.zone.local(2026, 3, 15, 8, 0, 0) do
      @client.bookings.create!(
        enseigne: @enseigne,
        service: @service,
        booking_start_time: Time.zone.local(2026, 3, 16, 10, 0, 0),
        booking_end_time: Time.zone.local(2026, 3, 16, 10, 30, 0),
        booking_status: :confirmed,
        customer_first_name: "Ada",
        customer_last_name: "Lovelace",
        customer_email: "ada@example.com"
      )

      result = build_decision(
        booking_start_time: Time.zone.local(2026, 3, 16, 10, 15, 0)
      ).call

      assert_not result.bookable?
      assert_equal Bookings::Errors::SLOT_UNAVAILABLE, result.error_code
    end
  end

  test "returns slot unavailable when overlapping active pending booking exists" do
    travel_to Time.zone.local(2026, 3, 15, 8, 0, 0) do
      @client.bookings.create!(
        enseigne: @enseigne,
        service: @service,
        booking_start_time: Time.zone.local(2026, 3, 16, 10, 0, 0),
        booking_end_time: Time.zone.local(2026, 3, 16, 10, 30, 0),
        booking_status: :pending,
        booking_expires_at: BookingRules.pending_expires_at
      )

      result = build_decision(
        booking_start_time: Time.zone.local(2026, 3, 16, 10, 0, 0)
      ).call

      assert_not result.bookable?
      assert_equal Bookings::Errors::SLOT_UNAVAILABLE, result.error_code
    end
  end

  test "returns bookable when no blocking booking exists" do
    travel_to Time.zone.local(2026, 3, 15, 8, 0, 0) do
      slot = Time.zone.local(2026, 3, 16, 11, 0, 0)
      result = build_decision(booking_start_time: slot).call

      assert result.bookable?
      assert_nil result.error_code
      assert_equal slot + 30.minutes, result.booking_end_time
      assert_equal @enseigne.id, result.resource.identifier
    end
  end

  test "returns bookable when slot starts at end of another booking" do
    travel_to Time.zone.local(2026, 3, 15, 8, 0, 0) do
      first_start = Time.zone.local(2026, 3, 16, 10, 0, 0)
      first_end = first_start + 30.minutes

      @client.bookings.create!(
        enseigne: @enseigne,
        service: @service,
        booking_start_time: first_start,
        booking_end_time: first_end,
        booking_status: :confirmed,
        customer_first_name: "Ada",
        customer_last_name: "Lovelace",
        customer_email: "ada@example.com"
      )

      result = build_decision(booking_start_time: first_end).call

      assert result.bookable?
    end
  end

  test "returns bookable when blocking booking belongs to another enseigne" do
    travel_to Time.zone.local(2026, 3, 15, 8, 0, 0) do
      slot = Time.zone.local(2026, 3, 16, 12, 0, 0)

      @client.bookings.create!(
        enseigne: @other_enseigne,
        service: @service,
        booking_start_time: slot,
        booking_end_time: slot + 30.minutes,
        booking_status: :confirmed,
        customer_first_name: "Ada",
        customer_last_name: "Lovelace",
        customer_email: "ada@example.com"
      )

      result = build_decision(booking_start_time: slot).call

      assert result.bookable?
    end
  end

  test "returns bookable with exclude_booking_id for the booking itself" do
    travel_to Time.zone.local(2026, 3, 15, 8, 0, 0) do
      slot = Time.zone.local(2026, 3, 16, 13, 0, 0)
      booking = @client.bookings.create!(
        enseigne: @enseigne,
        service: @service,
        booking_start_time: slot,
        booking_end_time: slot + 30.minutes,
        booking_status: :pending,
        booking_expires_at: BookingRules.pending_expires_at
      )

      result = build_decision(
        booking_start_time: slot,
        exclude_booking_id: booking.id
      ).without_generated_slot_requirement.call

      assert result.bookable?
    end
  end

  test "can skip generated slot requirement for confirm flows" do
    result = build_decision(
      booking_start_time: Time.zone.local(2026, 3, 16, 10, 15, 0)
    ).without_generated_slot_requirement.call

    assert result.bookable?
    assert_nil result.error_code
  end

  private

  def build_decision(booking_start_time:, exclude_booking_id: nil)
    Bookings::SlotDecision.new(
      client: @client,
      enseigne: @enseigne,
      service: @service,
      booking_start_time: booking_start_time,
      exclude_booking_id: exclude_booking_id
    )
  end
end
