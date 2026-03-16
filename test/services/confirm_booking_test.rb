require "test_helper"

class ConfirmBookingTest < ActiveSupport::TestCase
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

  test "confirms a valid pending booking" do
    travel_to Time.zone.local(2026, 3, 15, 8, 0, 0) do
      booking = @client.bookings.create!(
        service: @service,
        booking_start_time: Time.zone.local(2026, 3, 16, 10, 0, 0),
        booking_end_time: Time.zone.local(2026, 3, 16, 10, 30, 0),
        booking_status: :pending,
        booking_expires_at: 5.minutes.from_now
      )

      result = ConfirmBooking.new(
        booking: booking,
        booking_params: {
          customer_first_name: "Léonard",
          customer_last_name: "Boisson",
          customer_email: "leo@example.com"
        }
      ).call

      assert result.success?
      assert_equal booking, result.booking
      assert_nil result.error_message

      booking.reload
      assert_equal "confirmed", booking.booking_status
      assert_equal "Léonard", booking.customer_first_name
      assert_equal "Boisson", booking.customer_last_name
      assert_equal "leo@example.com", booking.customer_email
    end
  end

  test "fails when booking is no longer pending" do
    booking = @client.bookings.create!(
      service: @service,
      booking_start_time: Time.zone.local(2026, 3, 16, 11, 0, 0),
      booking_end_time: Time.zone.local(2026, 3, 16, 11, 30, 0),
      booking_status: :confirmed,
      customer_first_name: "Léonard",
      customer_last_name: "Boisson",
      customer_email: "leo@example.com"
    )

    result = ConfirmBooking.new(
      booking: booking,
      booking_params: {
        customer_first_name: "Test",
        customer_last_name: "User",
        customer_email: "test@example.com"
      }
    ).call

    assert_not result.success?
    assert_equal booking, result.booking
    assert_equal "Cette réservation ne peut plus être confirmée. Veuillez recommencer votre sélection.", result.error_message
  end

  test "fails when pending booking is expired" do
    travel_to Time.zone.local(2026, 3, 15, 8, 0, 0) do
      booking = @client.bookings.create!(
        service: @service,
        booking_start_time: Time.zone.local(2026, 3, 16, 12, 0, 0),
        booking_end_time: Time.zone.local(2026, 3, 16, 12, 30, 0),
        booking_status: :pending,
        booking_expires_at: 1.minute.ago
      )

      result = ConfirmBooking.new(
        booking: booking,
        booking_params: {
          customer_first_name: "Léonard",
          customer_last_name: "Boisson",
          customer_email: "leo@example.com"
        }
      ).call

      assert_not result.success?
      assert_equal "Votre session a expiré. Veuillez renouveler votre réservation.", result.error_message
    end
  end

  test "fails when another booking already blocks the same slot" do
    travel_to Time.zone.local(2026, 3, 15, 8, 0, 0) do
      slot = Time.zone.local(2026, 3, 16, 13, 0, 0)

      booking = @client.bookings.create!(
        service: @service,
        booking_start_time: slot,
        booking_end_time: slot + 30.minutes,
        booking_status: :pending,
        booking_expires_at: 5.minutes.from_now
      )

      @client.bookings.create!(
        service: @service,
        booking_start_time: slot,
        booking_end_time: slot + 30.minutes,
        booking_status: :confirmed,
        customer_first_name: "Other",
        customer_last_name: "User",
        customer_email: "other@example.com"
      )

      result = ConfirmBooking.new(
        booking: booking,
        booking_params: {
          customer_first_name: "Léonard",
          customer_last_name: "Boisson",
          customer_email: "leo@example.com"
        }
      ).call

      assert_not result.success?
      assert_equal "Le créneau sélectionné n'est plus disponible.", result.error_message

      booking.reload
      assert_equal "pending", booking.booking_status
    end
  end

  test "fails when booking params are invalid" do
    travel_to Time.zone.local(2026, 3, 15, 8, 0, 0) do
      booking = @client.bookings.create!(
        service: @service,
        booking_start_time: Time.zone.local(2026, 3, 16, 14, 0, 0),
        booking_end_time: Time.zone.local(2026, 3, 16, 14, 30, 0),
        booking_status: :pending,
        booking_expires_at: 5.minutes.from_now
      )

      result = ConfirmBooking.new(
        booking: booking,
        booking_params: {
          customer_first_name: "",
          customer_last_name: "",
          customer_email: "not-an-email"
        }
      ).call

      assert_not result.success?
      assert_equal booking, result.booking
      assert_equal "Le formulaire contient des erreurs.", result.error_message

      booking.reload
      assert_equal "pending", booking.booking_status
    end
  end
end
