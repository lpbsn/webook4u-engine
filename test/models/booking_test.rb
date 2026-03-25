require "test_helper"

class BookingTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

  setup do
    @client = Client.create!(
      name: "Le Salon Des gâté",
      slug: "salon-des-gate"
    )

    @enseigne = @client.enseignes.create!(
      name: "Enseigne principale",
      full_address: "1 rue de Paris"
    )
    @other_enseigne = @client.enseignes.create!(
      name: "Enseigne secondaire",
      full_address: "2 rue de Paris"
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
      enseigne: @enseigne,
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
      enseigne: @enseigne,
      service: @service,
      booking_end_time: Time.zone.local(2026, 3, 16, 10, 30, 0),
      booking_status: :pending,
      booking_expires_at: Time.zone.local(2026, 3, 15, 10, 5, 0)
    )

    assert_not booking.valid?
    assert booking.errors[:booking_start_time].any?
  end

  test "requires booking_end_time" do
    booking = Booking.new(
      client: @client,
      enseigne: @enseigne,
      service: @service,
      booking_start_time: Time.zone.local(2026, 3, 16, 10, 0, 0),
      booking_status: :pending,
      booking_expires_at: Time.zone.local(2026, 3, 15, 10, 5, 0)
    )

    assert_not booking.valid?
    assert booking.errors[:booking_end_time].any?
  end

  test "requires booking_status" do
    booking = Booking.new(
      client: @client,
      enseigne: @enseigne,
      service: @service,
      booking_start_time: Time.zone.local(2026, 3, 16, 10, 0, 0),
      booking_end_time: Time.zone.local(2026, 3, 16, 10, 30, 0)
    )

    assert_not booking.valid?
    assert booking.errors[:booking_status].any?
  end

  # =========================================================
  # VALIDATIONS CONDITIONNELLES : PENDING
  # =========================================================

  test "pending booking requires booking_expires_at" do
    booking = Booking.new(
      client: @client,
      enseigne: @enseigne,
      service: @service,
      booking_start_time: Time.zone.local(2026, 3, 16, 10, 0, 0),
      booking_end_time: Time.zone.local(2026, 3, 16, 10, 30, 0),
      booking_status: :pending
    )

    assert_not booking.valid?
    assert booking.errors[:booking_expires_at].any?
  end

  # =========================================================
  # VALIDATIONS CONDITIONNELLES : CONFIRMED
  # =========================================================

  test "confirmed booking requires customer first name" do
    booking = Booking.new(
      client: @client,
      enseigne: @enseigne,
      service: @service,
      booking_start_time: Time.zone.local(2026, 3, 16, 11, 0, 0),
      booking_end_time: Time.zone.local(2026, 3, 16, 11, 30, 0),
      booking_status: :confirmed,
      customer_last_name: "Boisson",
      customer_email: "leo@example.com"
    )

    assert_not booking.valid?
    assert booking.errors[:customer_first_name].any?
  end

  test "confirmed booking requires customer last name" do
    booking = Booking.new(
      client: @client,
      enseigne: @enseigne,
      service: @service,
      booking_start_time: Time.zone.local(2026, 3, 16, 11, 0, 0),
      booking_end_time: Time.zone.local(2026, 3, 16, 11, 30, 0),
      booking_status: :confirmed,
      customer_first_name: "Léonard",
      customer_email: "leo@example.com"
    )

    assert_not booking.valid?
    assert booking.errors[:customer_last_name].any?
  end

  test "confirmed booking requires customer email" do
    booking = Booking.new(
      client: @client,
      enseigne: @enseigne,
      service: @service,
      booking_start_time: Time.zone.local(2026, 3, 16, 11, 0, 0),
      booking_end_time: Time.zone.local(2026, 3, 16, 11, 30, 0),
      booking_status: :confirmed,
      customer_first_name: "Léonard",
      customer_last_name: "Boisson"
    )

    assert_not booking.valid?
    assert booking.errors[:customer_email].any?
  end

  test "confirmed booking requires valid email format" do
    booking = Booking.new(
      client: @client,
      enseigne: @enseigne,
      service: @service,
      booking_start_time: Time.zone.local(2026, 3, 16, 11, 0, 0),
      booking_end_time: Time.zone.local(2026, 3, 16, 11, 30, 0),
      booking_status: :confirmed,
      customer_first_name: "Léonard",
      customer_last_name: "Boisson",
      customer_email: "not-an-email"
    )

    assert_not booking.valid?
    assert booking.errors[:customer_email].any?
  end

  test "confirmed booking is valid with complete customer information" do
    booking = Booking.new(
      client: @client,
      enseigne: @enseigne,
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
      enseigne: @enseigne,
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
      enseigne: @enseigne,
      service: other_service,
      booking_start_time: Time.zone.local(2026, 3, 16, 12, 0, 0),
      booking_end_time: Time.zone.local(2026, 3, 16, 12, 30, 0),
      booking_status: :pending,
      booking_expires_at: Time.zone.local(2026, 3, 15, 10, 5, 0)
    )

    assert_not booking.valid?
    assert_includes booking.errors[:service], "must belong to the same client"
  end

  test "booking without enseigne is invalid" do
    booking = Booking.new(
      client: @client,
      service: @service,
      booking_start_time: Time.zone.local(2026, 3, 16, 13, 0, 0),
      booking_end_time: Time.zone.local(2026, 3, 16, 13, 30, 0),
      booking_status: :pending,
      booking_expires_at: Time.zone.local(2026, 3, 15, 10, 5, 0),
      enseigne: nil
    )

    assert_not booking.valid?
    assert_includes booking.errors[:enseigne], "must exist"
  end

  test "booking accepts enseigne from the same client" do
    booking = Booking.new(
      client: @client,
      service: @service,
      enseigne: @enseigne,
      booking_start_time: Time.zone.local(2026, 3, 16, 13, 30, 0),
      booking_end_time: Time.zone.local(2026, 3, 16, 14, 0, 0),
      booking_status: :pending,
      booking_expires_at: Time.zone.local(2026, 3, 15, 10, 5, 0)
    )

    assert booking.valid?
  end

  test "enseigne must belong to the same client when present" do
    other_client = Client.create!(
      name: "Autre client",
      slug: "autre-client-enseigne"
    )
    other_enseigne = other_client.enseignes.create!(name: "Enseigne externe")

    booking = Booking.new(
      client: @client,
      service: @service,
      enseigne: other_enseigne,
      booking_start_time: Time.zone.local(2026, 3, 16, 14, 0, 0),
      booking_end_time: Time.zone.local(2026, 3, 16, 14, 30, 0),
      booking_status: :pending,
      booking_expires_at: Time.zone.local(2026, 3, 15, 10, 5, 0)
    )

    assert_not booking.valid?
    assert_includes booking.errors[:enseigne], "must belong to the same client"
  end

  # =========================================================
  # MÉTHODES MÉTIER
  # =========================================================

  test "expired? returns true when booking_expires_at is in the past" do
    travel_to Time.zone.local(2026, 3, 15, 10, 0, 0) do
      booking = Booking.new(
        client: @client,
        enseigne: @enseigne,
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
        enseigne: @enseigne,
        service: @service,
        booking_start_time: Time.zone.local(2026, 3, 16, 10, 0, 0),
        booking_end_time: Time.zone.local(2026, 3, 16, 10, 30, 0),
        booking_status: :pending,
        booking_expires_at: BookingRules.pending_expires_at
      )

      assert_not booking.expired?
    end
  end

  test "confirmable? returns true for non expired pending booking" do
    travel_to Time.zone.local(2026, 3, 15, 10, 0, 0) do
      booking = Booking.new(
        client: @client,
        enseigne: @enseigne,
        service: @service,
        booking_start_time: Time.zone.local(2026, 3, 16, 10, 0, 0),
        booking_end_time: Time.zone.local(2026, 3, 16, 10, 30, 0),
        booking_status: :pending,
        booking_expires_at: BookingRules.pending_expires_at
      )

      assert booking.confirmable?
    end
  end

  test "confirmable? returns false for expired pending booking" do
    travel_to Time.zone.local(2026, 3, 15, 10, 0, 0) do
      booking = Booking.new(
        client: @client,
        enseigne: @enseigne,
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
      enseigne: @enseigne,
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
        enseigne: @enseigne,
        service: @service,
        booking_start_time: Time.zone.local(2026, 3, 16, 9, 0, 0),
        booking_end_time: Time.zone.local(2026, 3, 16, 9, 30, 0),
        booking_status: :pending,
        booking_expires_at: BookingRules.pending_expires_at
      )

      expired_pending = @client.bookings.create!(
        enseigne: @enseigne,
        service: @service,
        booking_start_time: Time.zone.local(2026, 3, 16, 9, 30, 0),
        booking_end_time: Time.zone.local(2026, 3, 16, 10, 0, 0),
        booking_status: :pending,
        booking_expires_at: 1.minute.ago
      )

      confirmed = @client.bookings.create!(
        enseigne: @enseigne,
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
        enseigne: @enseigne,
        service: @service,
        booking_start_time: Time.zone.local(2026, 3, 16, 11, 0, 0),
        booking_end_time: Time.zone.local(2026, 3, 16, 11, 30, 0),
        booking_status: :pending,
        booking_expires_at: BookingRules.pending_expires_at
      )

      expired_pending = @client.bookings.create!(
        enseigne: @enseigne,
        service: @service,
        booking_start_time: Time.zone.local(2026, 3, 16, 11, 30, 0),
        booking_end_time: Time.zone.local(2026, 3, 16, 12, 0, 0),
        booking_status: :pending,
        booking_expires_at: 1.minute.ago
      )

      confirmed = @client.bookings.create!(
        enseigne: @enseigne,
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

  # Ensures scope active_pending stays aligned with BookingRules.booking_expired?
  test "active_pending scope is consistent with BookingRules.booking_expired?" do
    now = Time.zone.local(2026, 3, 15, 12, 0, 0)
    travel_to now do
      past_booking = @client.bookings.create!(
        enseigne: @enseigne,
        service: @service,
        booking_start_time: Time.zone.local(2026, 3, 16, 9, 0, 0),
        booking_end_time: Time.zone.local(2026, 3, 16, 9, 30, 0),
        booking_status: :pending,
        booking_expires_at: 1.minute.ago
      )
      now_booking = @client.bookings.create!(
        enseigne: @enseigne,
        service: @service,
        booking_start_time: Time.zone.local(2026, 3, 16, 9, 30, 0),
        booking_end_time: Time.zone.local(2026, 3, 16, 10, 0, 0),
        booking_status: :pending,
        booking_expires_at: now
      )
      future_booking = @client.bookings.create!(
        enseigne: @enseigne,
        service: @service,
        booking_start_time: Time.zone.local(2026, 3, 16, 10, 0, 0),
        booking_end_time: Time.zone.local(2026, 3, 16, 10, 30, 0),
        booking_status: :pending,
        booking_expires_at: BookingRules.pending_expires_at
      )

      assert BookingRules.booking_expired?(past_booking, now: now), "past should be expired"
      assert BookingRules.booking_expired?(now_booking, now: now), "expires_at == now should be expired"
      assert_not BookingRules.booking_expired?(future_booking, now: now), "future should not be expired"

      active_ids = Booking.active_pending.pluck(:id)
      assert_not_includes active_ids, past_booking.id
      assert_not_includes active_ids, now_booking.id
      assert_includes active_ids, future_booking.id
    end
  end

  test "slot_blocked? returns true when slot is blocked by confirmed booking" do
    slot = Time.zone.local(2026, 3, 16, 14, 0, 0)

    @client.bookings.create!(
      enseigne: @enseigne,
      service: @service,
      booking_start_time: slot,
      booking_end_time: slot + 30.minutes,
      booking_status: :confirmed,
      customer_first_name: "Léonard",
      customer_last_name: "Boisson",
      customer_email: "leo@example.com"
    )

    assert Bookings::Availability.slot_blocked?(client: @client, enseigne: @enseigne, service: @service, booking_start_time: slot)
  end

  test "slot_blocked? returns false when no blocking booking exists" do
    slot = Time.zone.local(2026, 3, 16, 15, 0, 0)

    assert_not Bookings::Availability.slot_blocked?(client: @client, enseigne: @enseigne, service: @service, booking_start_time: slot)
  end

  test "slot_blocked? returns true when overlapping booking has different start_time" do
    existing_start = Time.zone.local(2026, 3, 16, 10, 0, 0)
    existing_end   = existing_start + 30.minutes
    overlapping_start = Time.zone.local(2026, 3, 16, 10, 15, 0)

    @client.bookings.create!(
      enseigne: @enseigne,
      service: @service,
      booking_start_time: existing_start,
      booking_end_time: existing_end,
      booking_status: :confirmed,
      customer_first_name: "Léonard",
      customer_last_name: "Boisson",
      customer_email: "leo@example.com"
    )

    assert Bookings::Availability.slot_blocked?(client: @client, enseigne: @enseigne, service: @service, booking_start_time: overlapping_start)
  end

  test "slot_blocked? treats end_equals_start as no overlap" do
    existing_start = Time.zone.local(2026, 3, 16, 10, 0, 0)
    existing_end   = existing_start + 30.minutes
    border_start   = existing_end

    @client.bookings.create!(
      enseigne: @enseigne,
      service: @service,
      booking_start_time: existing_start,
      booking_end_time: existing_end,
      booking_status: :confirmed,
      customer_first_name: "Léonard",
      customer_last_name: "Boisson",
      customer_email: "leo@example.com"
    )

    assert_not Bookings::Availability.slot_blocked?(client: @client, enseigne: @enseigne, service: @service, booking_start_time: border_start)
  end

  test "slot_blocked? ignores bookings from another enseigne of the same client" do
    slot = Time.zone.local(2026, 3, 16, 16, 0, 0)

    @client.bookings.create!(
      enseigne: @enseigne,
      service: @service,
      booking_start_time: slot,
      booking_end_time: slot + 30.minutes,
      booking_status: :confirmed,
      customer_first_name: "Léonard",
      customer_last_name: "Boisson",
      customer_email: "leo@example.com"
    )

    assert_not Bookings::Availability.slot_blocked?(client: @client, enseigne: @other_enseigne, service: @service, booking_start_time: slot)
  end

  test "database rejects bookings without enseigne_id" do
    now = Time.current

    assert_raises ActiveRecord::NotNullViolation do
      Booking.insert_all!([
        {
          client_id: @client.id,
          service_id: @service.id,
          enseigne_id: nil,
          created_at: now,
          updated_at: now
        }
      ])
    end
  end

  test "database enforces non null booking_start_time" do
    now = Time.current

    assert_raises ActiveRecord::NotNullViolation do
      Booking.insert_all!([
        {
          client_id: @client.id,
          enseigne_id: @enseigne.id,
          service_id: @service.id,
          booking_start_time: nil,
          booking_end_time: now + 30.minutes,
          booking_status: "confirmed",
          created_at: now,
          updated_at: now
        }
      ])
    end
  end

  test "database enforces non null booking_end_time" do
    now = Time.current

    assert_raises ActiveRecord::NotNullViolation do
      Booking.insert_all!([
        {
          client_id: @client.id,
          enseigne_id: @enseigne.id,
          service_id: @service.id,
          booking_start_time: now,
          booking_end_time: nil,
          booking_status: "confirmed",
          created_at: now,
          updated_at: now
        }
      ])
    end
  end

  test "database enforces non null booking_status" do
    now = Time.current

    assert_raises ActiveRecord::NotNullViolation do
      Booking.insert_all!([
        {
          client_id: @client.id,
          enseigne_id: @enseigne.id,
          service_id: @service.id,
          booking_start_time: now,
          booking_end_time: now + 30.minutes,
          booking_status: nil,
          created_at: now,
          updated_at: now
        }
      ])
    end
  end

  test "database enforces allowed booking_status values" do
    now = Time.current

    assert_raises ActiveRecord::StatementInvalid do
      Booking.insert_all!([
        {
          client_id: @client.id,
          enseigne_id: @enseigne.id,
          service_id: @service.id,
          booking_start_time: now,
          booking_end_time: now + 30.minutes,
          booking_status: "archived",
          created_at: now,
          updated_at: now
        }
      ])
    end
  end

  test "database enforces booking_end_time after booking_start_time" do
    now = Time.current

    assert_raises ActiveRecord::StatementInvalid do
      Booking.insert_all!([
        {
          client_id: @client.id,
          enseigne_id: @enseigne.id,
          service_id: @service.id,
          booking_start_time: now,
          booking_end_time: now,
          booking_status: "confirmed",
          created_at: now,
          updated_at: now
        }
      ])
    end
    assert_raises ActiveRecord::StatementInvalid do
      Booking.insert_all!([
        {
          client_id: @client.id,
          enseigne_id: @enseigne.id,
          service_id: @service.id,
          booking_start_time: now,
          booking_end_time: now - 30.minutes,
          booking_status: "confirmed",
          created_at: now,
          updated_at: now
        }
      ])
    end
  end

  test "database allows same confirmed slot in two enseignes of the same client" do
    slot = Time.zone.local(2026, 3, 16, 17, 0, 0)

    @client.bookings.create!(
      enseigne: @enseigne,
      service: @service,
      booking_start_time: slot,
      booking_end_time: slot + 30.minutes,
      booking_status: :confirmed,
      customer_first_name: "Jean",
      customer_last_name: "Dupont",
      customer_email: "jean@example.com"
    )

    assert_nothing_raised do
      @client.bookings.create!(
        enseigne: @other_enseigne,
        service: @service,
        booking_start_time: slot,
        booking_end_time: slot + 30.minutes,
        booking_status: :confirmed,
        customer_first_name: "Marie",
        customer_last_name: "Martin",
        customer_email: "marie@example.com"
      )
    end
  end

  test "database rejects pending booking without booking_expires_at" do
    now = Time.current

    error = assert_raises ActiveRecord::StatementInvalid do
      Booking.insert_all!([
        {
          client_id: @client.id,
          enseigne_id: @enseigne.id,
          service_id: @service.id,
          booking_start_time: now,
          booking_end_time: now + 30.minutes,
          booking_status: "pending",
          pending_access_token: SecureRandom.urlsafe_base64(24),
          created_at: now,
          updated_at: now
        }
      ])
    end

    assert_includes error.message, "bookings_pending_requires_booking_expires_at"
  end

  test "database rejects pending booking without pending_access_token" do
    now = Time.current

    error = assert_raises ActiveRecord::StatementInvalid do
      Booking.insert_all!([
        {
          client_id: @client.id,
          enseigne_id: @enseigne.id,
          service_id: @service.id,
          booking_start_time: now,
          booking_end_time: now + 30.minutes,
          booking_status: "pending",
          booking_expires_at: now + 5.minutes,
          created_at: now,
          updated_at: now
        }
      ])
    end

    assert_includes error.message, "bookings_pending_requires_pending_access_token"
  end

  test "database rejects pending booking with empty pending_access_token" do
    now = Time.current

    error = assert_raises ActiveRecord::StatementInvalid do
      Booking.insert_all!([
        {
          client_id: @client.id,
          enseigne_id: @enseigne.id,
          service_id: @service.id,
          booking_start_time: now,
          booking_end_time: now + 30.minutes,
          booking_status: "pending",
          booking_expires_at: now + 5.minutes,
          pending_access_token: "",
          created_at: now,
          updated_at: now
        }
      ])
    end

    assert_includes error.message, "bookings_pending_requires_pending_access_token"
  end

  test "database rejects pending booking with blank pending_access_token" do
    now = Time.current

    error = assert_raises ActiveRecord::StatementInvalid do
      Booking.insert_all!([
        {
          client_id: @client.id,
          enseigne_id: @enseigne.id,
          service_id: @service.id,
          booking_start_time: now,
          booking_end_time: now + 30.minutes,
          booking_status: "pending",
          booking_expires_at: now + 5.minutes,
          pending_access_token: "   ",
          created_at: now,
          updated_at: now
        }
      ])
    end

    assert_includes error.message, "bookings_pending_requires_pending_access_token"
  end

  test "database rejects confirmed booking without customer_first_name" do
    now = Time.current

    error = assert_raises ActiveRecord::StatementInvalid do
      Booking.insert_all!([
        {
          client_id: @client.id,
          enseigne_id: @enseigne.id,
          service_id: @service.id,
          booking_start_time: now,
          booking_end_time: now + 30.minutes,
          booking_status: "confirmed",
          customer_last_name: "Dupont",
          customer_email: "dupont@example.com",
          confirmation_token: SecureRandom.uuid,
          created_at: now,
          updated_at: now
        }
      ])
    end

    assert_includes error.message, "bookings_confirmed_requires_customer_first_name"
  end

  test "database rejects confirmed booking with empty customer_first_name" do
    now = Time.current

    error = assert_raises ActiveRecord::StatementInvalid do
      Booking.insert_all!([
        {
          client_id: @client.id,
          enseigne_id: @enseigne.id,
          service_id: @service.id,
          booking_start_time: now,
          booking_end_time: now + 30.minutes,
          booking_status: "confirmed",
          customer_first_name: "",
          customer_last_name: "Dupont",
          customer_email: "dupont@example.com",
          confirmation_token: SecureRandom.uuid,
          created_at: now,
          updated_at: now
        }
      ])
    end

    assert_includes error.message, "bookings_confirmed_requires_customer_first_name"
  end

  test "database rejects confirmed booking with blank customer_first_name" do
    now = Time.current

    error = assert_raises ActiveRecord::StatementInvalid do
      Booking.insert_all!([
        {
          client_id: @client.id,
          enseigne_id: @enseigne.id,
          service_id: @service.id,
          booking_start_time: now,
          booking_end_time: now + 30.minutes,
          booking_status: "confirmed",
          customer_first_name: "   ",
          customer_last_name: "Dupont",
          customer_email: "dupont@example.com",
          confirmation_token: SecureRandom.uuid,
          created_at: now,
          updated_at: now
        }
      ])
    end

    assert_includes error.message, "bookings_confirmed_requires_customer_first_name"
  end

  test "database rejects confirmed booking without customer_last_name" do
    now = Time.current

    error = assert_raises ActiveRecord::StatementInvalid do
      Booking.insert_all!([
        {
          client_id: @client.id,
          enseigne_id: @enseigne.id,
          service_id: @service.id,
          booking_start_time: now,
          booking_end_time: now + 30.minutes,
          booking_status: "confirmed",
          customer_first_name: "Jean",
          customer_email: "dupont@example.com",
          confirmation_token: SecureRandom.uuid,
          created_at: now,
          updated_at: now
        }
      ])
    end

    assert_includes error.message, "bookings_confirmed_requires_customer_last_name"
  end

  test "database rejects confirmed booking with empty customer_last_name" do
    now = Time.current

    error = assert_raises ActiveRecord::StatementInvalid do
      Booking.insert_all!([
        {
          client_id: @client.id,
          enseigne_id: @enseigne.id,
          service_id: @service.id,
          booking_start_time: now,
          booking_end_time: now + 30.minutes,
          booking_status: "confirmed",
          customer_first_name: "Jean",
          customer_last_name: "",
          customer_email: "dupont@example.com",
          confirmation_token: SecureRandom.uuid,
          created_at: now,
          updated_at: now
        }
      ])
    end

    assert_includes error.message, "bookings_confirmed_requires_customer_last_name"
  end

  test "database rejects confirmed booking with blank customer_last_name" do
    now = Time.current

    error = assert_raises ActiveRecord::StatementInvalid do
      Booking.insert_all!([
        {
          client_id: @client.id,
          enseigne_id: @enseigne.id,
          service_id: @service.id,
          booking_start_time: now,
          booking_end_time: now + 30.minutes,
          booking_status: "confirmed",
          customer_first_name: "Jean",
          customer_last_name: "   ",
          customer_email: "dupont@example.com",
          confirmation_token: SecureRandom.uuid,
          created_at: now,
          updated_at: now
        }
      ])
    end

    assert_includes error.message, "bookings_confirmed_requires_customer_last_name"
  end

  test "database rejects confirmed booking without customer_email" do
    now = Time.current

    error = assert_raises ActiveRecord::StatementInvalid do
      Booking.insert_all!([
        {
          client_id: @client.id,
          enseigne_id: @enseigne.id,
          service_id: @service.id,
          booking_start_time: now,
          booking_end_time: now + 30.minutes,
          booking_status: "confirmed",
          customer_first_name: "Jean",
          customer_last_name: "Dupont",
          confirmation_token: SecureRandom.uuid,
          created_at: now,
          updated_at: now
        }
      ])
    end

    assert_includes error.message, "bookings_confirmed_requires_customer_email"
  end

  test "database rejects confirmed booking with empty customer_email" do
    now = Time.current

    error = assert_raises ActiveRecord::StatementInvalid do
      Booking.insert_all!([
        {
          client_id: @client.id,
          enseigne_id: @enseigne.id,
          service_id: @service.id,
          booking_start_time: now,
          booking_end_time: now + 30.minutes,
          booking_status: "confirmed",
          customer_first_name: "Jean",
          customer_last_name: "Dupont",
          customer_email: "",
          confirmation_token: SecureRandom.uuid,
          created_at: now,
          updated_at: now
        }
      ])
    end

    assert_includes error.message, "bookings_confirmed_requires_customer_email"
  end

  test "database rejects confirmed booking with blank customer_email" do
    now = Time.current

    error = assert_raises ActiveRecord::StatementInvalid do
      Booking.insert_all!([
        {
          client_id: @client.id,
          enseigne_id: @enseigne.id,
          service_id: @service.id,
          booking_start_time: now,
          booking_end_time: now + 30.minutes,
          booking_status: "confirmed",
          customer_first_name: "Jean",
          customer_last_name: "Dupont",
          customer_email: "   ",
          confirmation_token: SecureRandom.uuid,
          created_at: now,
          updated_at: now
        }
      ])
    end

    assert_includes error.message, "bookings_confirmed_requires_customer_email"
  end

  test "database rejects confirmed booking without confirmation_token" do
    now = Time.current

    error = assert_raises ActiveRecord::StatementInvalid do
      Booking.insert_all!([
        {
          client_id: @client.id,
          enseigne_id: @enseigne.id,
          service_id: @service.id,
          booking_start_time: now,
          booking_end_time: now + 30.minutes,
          booking_status: "confirmed",
          customer_first_name: "Jean",
          customer_last_name: "Dupont",
          customer_email: "dupont@example.com",
          created_at: now,
          updated_at: now
        }
      ])
    end

    assert_includes error.message, "bookings_confirmed_requires_confirmation_token"
  end

  test "database rejects confirmed booking with empty confirmation_token" do
    now = Time.current

    error = assert_raises ActiveRecord::StatementInvalid do
      Booking.insert_all!([
        {
          client_id: @client.id,
          enseigne_id: @enseigne.id,
          service_id: @service.id,
          booking_start_time: now,
          booking_end_time: now + 30.minutes,
          booking_status: "confirmed",
          customer_first_name: "Jean",
          customer_last_name: "Dupont",
          customer_email: "dupont@example.com",
          confirmation_token: "",
          created_at: now,
          updated_at: now
        }
      ])
    end

    assert_includes error.message, "bookings_confirmed_requires_confirmation_token"
  end

  test "database rejects confirmed booking with blank confirmation_token" do
    now = Time.current

    error = assert_raises ActiveRecord::StatementInvalid do
      Booking.insert_all!([
        {
          client_id: @client.id,
          enseigne_id: @enseigne.id,
          service_id: @service.id,
          booking_start_time: now,
          booking_end_time: now + 30.minutes,
          booking_status: "confirmed",
          customer_first_name: "Jean",
          customer_last_name: "Dupont",
          customer_email: "dupont@example.com",
          confirmation_token: "   ",
          created_at: now,
          updated_at: now
        }
      ])
    end

    assert_includes error.message, "bookings_confirmed_requires_confirmation_token"
  end

  test "database accepts insert for cross-table coherent booking" do
    now = Time.current

    assert_difference "Booking.count", 1 do
      Booking.insert_all!([
        {
          client_id: @client.id,
          enseigne_id: @enseigne.id,
          service_id: @service.id,
          booking_start_time: now,
          booking_end_time: now + 30.minutes,
          booking_status: "pending",
          booking_expires_at: now + 5.minutes,
          pending_access_token: SecureRandom.urlsafe_base64(24),
          created_at: now,
          updated_at: now
        }
      ])
    end
  end

  test "database rejects insert when service belongs to another client" do
    now = Time.current
    other_client = Client.create!(name: "Other client", slug: "other-client-cross-table-service")
    other_service = other_client.services.create!(name: "Other service", duration_minutes: 30, price_cents: 1200)

    error = assert_raises ActiveRecord::StatementInvalid do
      Booking.insert_all!([
        {
          client_id: @client.id,
          enseigne_id: @enseigne.id,
          service_id: other_service.id,
          booking_start_time: now,
          booking_end_time: now + 30.minutes,
          booking_status: "pending",
          booking_expires_at: now + 5.minutes,
          pending_access_token: SecureRandom.urlsafe_base64(24),
          created_at: now,
          updated_at: now
        }
      ])
    end

    assert_includes error.message, "bookings.client_id must match services.client_id"
  end

  test "database rejects insert when enseigne belongs to another client" do
    now = Time.current
    other_client = Client.create!(name: "Other client", slug: "other-client-cross-table-enseigne")
    other_enseigne = other_client.enseignes.create!(name: "Other enseigne", full_address: "2 rue du test")

    error = assert_raises ActiveRecord::StatementInvalid do
      Booking.insert_all!([
        {
          client_id: @client.id,
          enseigne_id: other_enseigne.id,
          service_id: @service.id,
          booking_start_time: now,
          booking_end_time: now + 30.minutes,
          booking_status: "pending",
          booking_expires_at: now + 5.minutes,
          pending_access_token: SecureRandom.urlsafe_base64(24),
          created_at: now,
          updated_at: now
        }
      ])
    end

    assert_includes error.message, "bookings.client_id must match enseignes.client_id"
  end

  test "database rejects insert when service and enseigne match each other but not client_id" do
    now = Time.current
    other_client = Client.create!(name: "Other client", slug: "other-client-cross-table-both")
    other_service = other_client.services.create!(name: "Other service", duration_minutes: 30, price_cents: 1200)
    other_enseigne = other_client.enseignes.create!(name: "Other enseigne", full_address: "3 rue du test")

    error = assert_raises ActiveRecord::StatementInvalid do
      Booking.insert_all!([
        {
          client_id: @client.id,
          enseigne_id: other_enseigne.id,
          service_id: other_service.id,
          booking_start_time: now,
          booking_end_time: now + 30.minutes,
          booking_status: "pending",
          booking_expires_at: now + 5.minutes,
          pending_access_token: SecureRandom.urlsafe_base64(24),
          created_at: now,
          updated_at: now
        }
      ])
    end

    assert_includes error.message, "bookings.client_id must match services.client_id"
  end

  test "database rejects update when service_id is changed to another client service" do
    booking = @client.bookings.create!(
      enseigne: @enseigne,
      service: @service,
      booking_start_time: Time.zone.local(2026, 3, 16, 18, 0, 0),
      booking_end_time: Time.zone.local(2026, 3, 16, 18, 30, 0),
      booking_status: :pending,
      booking_expires_at: BookingRules.pending_expires_at
    )
    other_client = Client.create!(name: "Other client", slug: "other-client-update-service")
    other_service = other_client.services.create!(name: "Other service", duration_minutes: 30, price_cents: 1200)

    error = assert_raises ActiveRecord::StatementInvalid do
      Booking.where(id: booking.id).update_all(service_id: other_service.id)
    end

    assert_includes error.message, "bookings.client_id must match services.client_id"
  end

  test "database rejects update when enseigne_id is changed to another client enseigne" do
    booking = @client.bookings.create!(
      enseigne: @enseigne,
      service: @service,
      booking_start_time: Time.zone.local(2026, 3, 16, 19, 0, 0),
      booking_end_time: Time.zone.local(2026, 3, 16, 19, 30, 0),
      booking_status: :pending,
      booking_expires_at: BookingRules.pending_expires_at
    )
    other_client = Client.create!(name: "Other client", slug: "other-client-update-enseigne")
    other_enseigne = other_client.enseignes.create!(name: "Other enseigne", full_address: "4 rue du test")

    error = assert_raises ActiveRecord::StatementInvalid do
      Booking.where(id: booking.id).update_all(enseigne_id: other_enseigne.id)
    end

    assert_includes error.message, "bookings.client_id must match enseignes.client_id"
  end

  test "database rejects update when client_id is changed alone and breaks cross-table consistency" do
    booking = @client.bookings.create!(
      enseigne: @enseigne,
      service: @service,
      booking_start_time: Time.zone.local(2026, 3, 16, 20, 0, 0),
      booking_end_time: Time.zone.local(2026, 3, 16, 20, 30, 0),
      booking_status: :pending,
      booking_expires_at: BookingRules.pending_expires_at
    )
    other_client = Client.create!(name: "Other client", slug: "other-client-update-client-id")

    error = assert_raises ActiveRecord::StatementInvalid do
      Booking.where(id: booking.id).update_all(client_id: other_client.id)
    end

    assert_includes error.message, "bookings.client_id must match services.client_id"
  end
end
