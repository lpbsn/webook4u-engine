require "test_helper"

class BookingTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

  setup do
    @client = Client.create!(
      name: "Le Salon Des gâté",
      slug: "salon-des-gate"
    )

    @service = @client.services.create!(
      name: "Coupe homme",
      duration_minutes: 30,
      price_cents: 2500
    )
  end

  # =========================================================
  # VALIDATIONS GÉNÉRALES
  # =========================================================

  test "is valid with minimal pending attributes" do
    booking = Booking.new(
      client: @client,
      service: @service,
      booking_start_time: Time.zone.local(2026, 3, 16, 10, 0, 0),
      booking_end_time: Time.zone.local(2026, 3, 16, 10, 30, 0),
      booking_status: :pending,
      booking_expires_at: Time.zone.local(2026, 3, 15, 10, 5, 0)
    )

    assert booking.valid?
  end

  test "requires booking_start_time" do
    booking = Booking.new(
      client: @client,
      service: @service,
      booking_end_time: Time.zone.local(2026, 3, 16, 10, 30, 0),
      booking_status: :pending,
      booking_expires_at: Time.zone.local(2026, 3, 15, 10, 5, 0)
    )

    assert_not booking.valid?
    assert_includes booking.errors[:booking_start_time], "can't be blank"
  end

  test "requires booking_end_time" do
    booking = Booking.new(
      client: @client,
      service: @service,
      booking_start_time: Time.zone.local(2026, 3, 16, 10, 0, 0),
      booking_status: :pending,
      booking_expires_at: Time.zone.local(2026, 3, 15, 10, 5, 0)
    )

    assert_not booking.valid?
    assert_includes booking.errors[:booking_end_time], "can't be blank"
  end

  test "requires booking_status" do
    booking = Booking.new(
      client: @client,
      service: @service,
      booking_start_time: Time.zone.local(2026, 3, 16, 10, 0, 0),
      booking_end_time: Time.zone.local(2026, 3, 16, 10, 30, 0)
    )

    assert_not booking.valid?
    assert_includes booking.errors[:booking_status], "can't be blank"
  end

  # =========================================================
  # VALIDATIONS CONDITIONNELLES : PENDING
  # =========================================================

  test "pending booking requires booking_expires_at" do
    booking = Booking.new(
      client: @client,
      service: @service,
      booking_start_time: Time.zone.local(2026, 3, 16, 10, 0, 0),
      booking_end_time: Time.zone.local(2026, 3, 16, 10, 30, 0),
      booking_status: :pending
    )

    assert_not booking.valid?
    assert_includes booking.errors[:booking_expires_at], "can't be blank"
  end

  # =========================================================
  # VALIDATIONS CONDITIONNELLES : CONFIRMED
  # =========================================================

  test "confirmed booking requires customer first name" do
    booking = Booking.new(
      client: @client,
      service: @service,
      booking_start_time: Time.zone.local(2026, 3, 16, 11, 0, 0),
      booking_end_time: Time.zone.local(2026, 3, 16, 11, 30, 0),
      booking_status: :confirmed,
      customer_last_name: "Boisson",
      customer_email: "leo@example.com"
    )

    assert_not booking.valid?
    assert_includes booking.errors[:customer_first_name], "can't be blank"
  end

  test "confirmed booking requires customer last name" do
    booking = Booking.new(
      client: @client,
      service: @service,
      booking_start_time: Time.zone.local(2026, 3, 16, 11, 0, 0),
      booking_end_time: Time.zone.local(2026, 3, 16, 11, 30, 0),
      booking_status: :confirmed,
      customer_first_name: "Léonard",
      customer_email: "leo@example.com"
    )

    assert_not booking.valid?
    assert_includes booking.errors[:customer_last_name], "can't be blank"
  end

  test "confirmed booking requires customer email" do
    booking = Booking.new(
      client: @client,
      service: @service,
      booking_start_time: Time.zone.local(2026, 3, 16, 11, 0, 0),
      booking_end_time: Time.zone.local(2026, 3, 16, 11, 30, 0),
      booking_status: :confirmed,
      customer_first_name: "Léonard",
      customer_last_name: "Boisson"
    )

    assert_not booking.valid?
    assert_includes booking.errors[:customer_email], "can't be blank"
  end

  test "confirmed booking requires valid email format" do
    booking = Booking.new(
      client: @client,
      service: @service,
      booking_start_time: Time.zone.local(2026, 3, 16, 11, 0, 0),
      booking_end_time: Time.zone.local(2026, 3, 16, 11, 30, 0),
      booking_status: :confirmed,
      customer_first_name: "Léonard",
      customer_last_name: "Boisson",
      customer_email: "not-an-email"
    )

    assert_not booking.valid?
    assert_not_empty booking.errors[:customer_email]
  end

  test "confirmed booking is valid with complete customer information" do
    booking = Booking.new(
      client: @client,
      service: @service,
      booking_start_time: Time.zone.local(2026, 3, 16, 11, 0, 0),
      booking_end_time: Time.zone.local(2026, 3, 16, 11, 30, 0),
      booking_status: :confirmed,
      customer_first_name: "Léonard",
      customer_last_name: "Boisson",
      customer_email: "leo@example.com"
    )

    assert booking.valid?
  end

  # =========================================================
  # VALIDATIONS MÉTIER
  # =========================================================

  test "booking_end_time must be after booking_start_time" do
    booking = Booking.new(
      client: @client,
      service: @service,
      booking_start_time: Time.zone.local(2026, 3, 16, 12, 0, 0),
      booking_end_time: Time.zone.local(2026, 3, 16, 12, 0, 0),
      booking_status: :pending,
      booking_expires_at: Time.zone.local(2026, 3, 15, 10, 5, 0)
    )

    assert_not booking.valid?
    assert_includes booking.errors[:booking_end_time], "must be after booking_start_time"
  end

  test "service must belong to the same client" do
    other_client = Client.create!(
      name: "Maigris Mon Gros",
      slug: "maigris-mon-gros"
    )

    other_service = other_client.services.create!(
      name: "Séance individuelle",
      duration_minutes: 30,
      price_cents: 4000
    )

    booking = Booking.new(
      client: @client,
      service: other_service,
      booking_start_time: Time.zone.local(2026, 3, 16, 12, 0, 0),
      booking_end_time: Time.zone.local(2026, 3, 16, 12, 30, 0),
      booking_status: :pending,
      booking_expires_at: Time.zone.local(2026, 3, 15, 10, 5, 0)
    )

    assert_not booking.valid?
    assert_includes booking.errors[:service], "must belong to the same client"
  end

  # =========================================================
  # MÉTHODES MÉTIER
  # =========================================================

  test "expired? returns true when booking_expires_at is in the past" do
    travel_to Time.zone.local(2026, 3, 15, 10, 0, 0) do
      booking = Booking.new(
        client: @client,
        service: @service,
        booking_start_time: Time.zone.local(2026, 3, 16, 10, 0, 0),
        booking_end_time: Time.zone.local(2026, 3, 16, 10, 30, 0),
        booking_status: :pending,
        booking_expires_at: 1.minute.ago
      )

      assert booking.expired?
    end
  end

  test "expired? returns false when booking_expires_at is in the future" do
    travel_to Time.zone.local(2026, 3, 15, 10, 0, 0) do
      booking = Booking.new(
        client: @client,
        service: @service,
        booking_start_time: Time.zone.local(2026, 3, 16, 10, 0, 0),
        booking_end_time: Time.zone.local(2026, 3, 16, 10, 30, 0),
        booking_status: :pending,
        booking_expires_at: 5.minutes.from_now
      )

      assert_not booking.expired?
    end
  end

  test "confirmable? returns true for non expired pending booking" do
    travel_to Time.zone.local(2026, 3, 15, 10, 0, 0) do
      booking = Booking.new(
        client: @client,
        service: @service,
        booking_start_time: Time.zone.local(2026, 3, 16, 10, 0, 0),
        booking_end_time: Time.zone.local(2026, 3, 16, 10, 30, 0),
        booking_status: :pending,
        booking_expires_at: 5.minutes.from_now
      )

      assert booking.confirmable?
    end
  end

  test "confirmable? returns false for expired pending booking" do
    travel_to Time.zone.local(2026, 3, 15, 10, 0, 0) do
      booking = Booking.new(
        client: @client,
        service: @service,
        booking_start_time: Time.zone.local(2026, 3, 16, 10, 0, 0),
        booking_end_time: Time.zone.local(2026, 3, 16, 10, 30, 0),
        booking_status: :pending,
        booking_expires_at: 1.minute.ago
      )

      assert_not booking.confirmable?
    end
  end

  test "confirmable? returns false for confirmed booking" do
    booking = Booking.new(
      client: @client,
      service: @service,
      booking_start_time: Time.zone.local(2026, 3, 16, 10, 0, 0),
      booking_end_time: Time.zone.local(2026, 3, 16, 10, 30, 0),
      booking_status: :confirmed,
      customer_first_name: "Léonard",
      customer_last_name: "Boisson",
      customer_email: "leo@example.com"
    )

    assert_not booking.confirmable?
  end

  test "customer_full_name returns concatenated first and last name" do
    booking = Booking.new(
      customer_first_name: "Léonard",
      customer_last_name: "Boisson"
    )

    assert_equal "Léonard Boisson", booking.customer_full_name
  end

  # =========================================================
  # SCOPES
  # =========================================================

  test "active_pending returns only non expired pending bookings" do
    travel_to Time.zone.local(2026, 3, 15, 10, 0, 0) do
      active_pending = @client.bookings.create!(
        service: @service,
        booking_start_time: Time.zone.local(2026, 3, 16, 9, 0, 0),
        booking_end_time: Time.zone.local(2026, 3, 16, 9, 30, 0),
        booking_status: :pending,
        booking_expires_at: 5.minutes.from_now
      )

      expired_pending = @client.bookings.create!(
        service: @service,
        booking_start_time: Time.zone.local(2026, 3, 16, 9, 30, 0),
        booking_end_time: Time.zone.local(2026, 3, 16, 10, 0, 0),
        booking_status: :pending,
        booking_expires_at: 1.minute.ago
      )

      confirmed = @client.bookings.create!(
        service: @service,
        booking_start_time: Time.zone.local(2026, 3, 16, 10, 0, 0),
        booking_end_time: Time.zone.local(2026, 3, 16, 10, 30, 0),
        booking_status: :confirmed,
        customer_first_name: "Léonard",
        customer_last_name: "Boisson",
        customer_email: "leo@example.com"
      )

      results = Booking.active_pending

      assert_includes results, active_pending
      assert_not_includes results, expired_pending
      assert_not_includes results, confirmed
    end
  end

  test "blocking_slot returns confirmed and active pending bookings only" do
    travel_to Time.zone.local(2026, 3, 15, 10, 0, 0) do
      active_pending = @client.bookings.create!(
        service: @service,
        booking_start_time: Time.zone.local(2026, 3, 16, 11, 0, 0),
        booking_end_time: Time.zone.local(2026, 3, 16, 11, 30, 0),
        booking_status: :pending,
        booking_expires_at: 5.minutes.from_now
      )

      expired_pending = @client.bookings.create!(
        service: @service,
        booking_start_time: Time.zone.local(2026, 3, 16, 11, 30, 0),
        booking_end_time: Time.zone.local(2026, 3, 16, 12, 0, 0),
        booking_status: :pending,
        booking_expires_at: 1.minute.ago
      )

      confirmed = @client.bookings.create!(
        service: @service,
        booking_start_time: Time.zone.local(2026, 3, 16, 12, 0, 0),
        booking_end_time: Time.zone.local(2026, 3, 16, 12, 30, 0),
        booking_status: :confirmed,
        customer_first_name: "Léonard",
        customer_last_name: "Boisson",
        customer_email: "leo@example.com"
      )

      results = Booking.blocking_slot

      assert_includes results, active_pending
      assert_includes results, confirmed
      assert_not_includes results, expired_pending
    end
  end

  test "slot_blocked? returns true when slot is blocked by confirmed booking" do
    slot = Time.zone.local(2026, 3, 16, 14, 0, 0)

    @client.bookings.create!(
      service: @service,
      booking_start_time: slot,
      booking_end_time: slot + 30.minutes,
      booking_status: :confirmed,
      customer_first_name: "Léonard",
      customer_last_name: "Boisson",
      customer_email: "leo@example.com"
    )

    assert Booking.slot_blocked?(client: @client, booking_start_time: slot)
  end

  test "slot_blocked? returns false when no blocking booking exists" do
    slot = Time.zone.local(2026, 3, 16, 15, 0, 0)

    assert_not Booking.slot_blocked?(client: @client, booking_start_time: slot)
  end
end
