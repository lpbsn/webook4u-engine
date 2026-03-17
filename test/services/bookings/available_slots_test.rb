require "test_helper"

class Bookings::AvailableSlotsTest < ActiveSupport::TestCase
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

  test "returns no slots on weekend" do
    travel_to Time.zone.local(2026, 3, 13, 10, 0, 0) do
      saturday = Date.new(2026, 3, 14)

      slots = Bookings::AvailableSlots.new(
        client: @client,
        service: @service,
        date: saturday
      ).call

      assert_equal [], slots
    end
  end

  test "returns slots for a weekday within opening hours" do
    travel_to Time.zone.local(2026, 3, 15, 8, 0, 0) do
      monday = Date.new(2026, 3, 16)

      slots = Bookings::AvailableSlots.new(
        client: @client,
        service: @service,
        date: monday
      ).call

      assert_includes slots, Time.zone.local(2026, 3, 16, 9, 0, 0)
      assert_includes slots, Time.zone.local(2026, 3, 16, 17, 30, 0)
      assert_not_includes slots, Time.zone.local(2026, 3, 16, 18, 0, 0)
    end
  end

  test "does not return slots earlier than minimum bookable time" do
    travel_to Time.zone.local(2026, 3, 16, 14, 10, 0) do
      monday = Date.new(2026, 3, 16)

      slots = Bookings::AvailableSlots.new(
        client: @client,
        service: @service,
        date: monday
      ).call

      assert_not_includes slots, Time.zone.local(2026, 3, 16, 14, 0, 0)
      assert_not_includes slots, Time.zone.local(2026, 3, 16, 14, 30, 0)
      assert_includes slots, Time.zone.local(2026, 3, 16, 15, 0, 0)
    end
  end

  test "excludes confirmed bookings from available slots" do
    travel_to Time.zone.local(2026, 3, 15, 8, 0, 0) do
      monday = Date.new(2026, 3, 16)

      @client.bookings.create!(
        service: @service,
        booking_start_time: Time.zone.local(2026, 3, 16, 10, 0, 0),
        booking_end_time: Time.zone.local(2026, 3, 16, 10, 30, 0),
        booking_status: :confirmed,
        customer_first_name: "Leonard",
        customer_last_name: "Boisson",
        customer_email: "leo@example.com"
      )

      slots = Bookings::AvailableSlots.new(
        client: @client,
        service: @service,
        date: monday
      ).call

      assert_not_includes slots, Time.zone.local(2026, 3, 16, 10, 0, 0)
    end
  end

  test "excludes active pending bookings from available slots" do
    travel_to Time.zone.local(2026, 3, 15, 8, 0, 0) do
      monday = Date.new(2026, 3, 16)

      @client.bookings.create!(
        service: @service,
        booking_start_time: Time.zone.local(2026, 3, 16, 11, 0, 0),
        booking_end_time: Time.zone.local(2026, 3, 16, 11, 30, 0),
        booking_status: :pending,
        booking_expires_at: BookingRules.pending_expires_at
      )

      slots = Bookings::AvailableSlots.new(
        client: @client,
        service: @service,
        date: monday
      ).call

      assert_not_includes slots, Time.zone.local(2026, 3, 16, 11, 0, 0)
    end
  end

  test "does not exclude expired pending bookings from available slots" do
    travel_to Time.zone.local(2026, 3, 15, 8, 0, 0) do
      monday = Date.new(2026, 3, 16)

      @client.bookings.create!(
        service: @service,
        booking_start_time: Time.zone.local(2026, 3, 16, 11, 30, 0),
        booking_end_time: Time.zone.local(2026, 3, 16, 12, 0, 0),
        booking_status: :pending,
        booking_expires_at: 10.minutes.ago
      )

      slots = Bookings::AvailableSlots.new(
        client: @client,
        service: @service,
        date: monday
      ).call

      assert_includes slots, Time.zone.local(2026, 3, 16, 11, 30, 0)
    end
  end

  test "blocks slots when blocking booking starts before first slot of the day" do
    travel_to Time.zone.local(2026, 3, 15, 8, 0, 0) do
      monday = Date.new(2026, 3, 16)

      # Booking confirmé de 08:30 à 09:30 le même jour (avant le premier slot 09:00)
      @client.bookings.create!(
        service: @service,
        booking_start_time: Time.zone.local(2026, 3, 16, 8, 30, 0),
        booking_end_time: Time.zone.local(2026, 3, 16, 9, 30, 0),
        booking_status: :confirmed,
        customer_first_name: "Leonard",
        customer_last_name: "Boisson",
        customer_email: "leo@example.com"
      )

      slots = Bookings::AvailableSlots.new(
        client: @client,
        service: @service,
        date: monday
      ).call

      # Le créneau 09:00–09:30 overlap le booking -> doit être exclu
      assert_not_includes slots, Time.zone.local(2026, 3, 16, 9, 0, 0)

      # Le créneau 09:30–10:00 ne chevauche plus -> doit rester disponible
      assert_includes slots, Time.zone.local(2026, 3, 16, 9, 30, 0)
    end
  end

  test "blocks first slot when booking from previous day overlaps into day" do
    travel_to Time.zone.local(2026, 3, 16, 8, 0, 0) do
      monday = Date.new(2026, 3, 16)

      # Booking confirmé de la veille 23:30 à 09:30 le jour affiché
      @client.bookings.create!(
        service: @service,
        booking_start_time: Time.zone.local(2026, 3, 15, 23, 30, 0),
        booking_end_time:   Time.zone.local(2026, 3, 16, 9, 30, 0),
        booking_status: :confirmed,
        customer_first_name: "Leonard",
        customer_last_name: "Boisson",
        customer_email: "leo@example.com"
      )

      slots = Bookings::AvailableSlots.new(
        client: @client,
        service: @service,
        date: monday
      ).call

      # Le créneau 09:00–09:30 overlap le booking -> doit être exclu
      assert_not_includes slots, Time.zone.local(2026, 3, 16, 9, 0, 0)

      # Le créneau 09:30–10:00 ne chevauche plus -> doit rester disponible
      assert_includes slots, Time.zone.local(2026, 3, 16, 9, 30, 0)
    end
  end
end
