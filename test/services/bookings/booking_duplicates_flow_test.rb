require "test_helper"

class BookingDuplicatesFlowTest < ActionDispatch::IntegrationTest
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
  # Un créneau déjà réservé en confirmed doit être refusé
  # =========================================================
  test "new refuses a slot already confirmed" do
    travel_to Time.zone.local(2026, 3, 15, 8, 0, 0) do
      slot = Time.zone.local(2026, 3, 16, 10, 0, 0)

      @client.bookings.create!(
        service: @service,
        booking_start_time: slot,
        booking_end_time: slot + 30.minutes,
        booking_status: :confirmed,
        customer_first_name: "Leonard",
        customer_last_name: "Boisson",
        customer_email: "leo@example.com"
      )

      assert_no_difference "Booking.count" do
        get new_service_booking_path(@client.slug, @service, start_time: slot)
      end

      assert_redirected_to public_client_path(
        @client.slug,
        service_id: @service.id,
        date: slot.to_date
      )
    end
  end

  # =========================================================
  # Un créneau déjà réservé en pending non expiré doit être refusé
  # =========================================================
  test "new refuses a slot already blocked by active pending" do
    travel_to Time.zone.local(2026, 3, 15, 8, 0, 0) do
      slot = Time.zone.local(2026, 3, 16, 11, 0, 0)

      @client.bookings.create!(
        service: @service,
        booking_start_time: slot,
        booking_end_time: slot + 30.minutes,
        booking_status: :pending,
        booking_expires_at: BookingRules.pending_expires_at
      )

      assert_no_difference "Booking.count" do
        get new_service_booking_path(@client.slug, @service, start_time: slot)
      end

      assert_redirected_to public_client_path(
        @client.slug,
        service_id: @service.id,
        date: slot.to_date
      )
    end
  end

  # =========================================================
  # Un pending expiré ne doit plus bloquer le créneau
  # =========================================================
  test "new allows a slot previously blocked by expired pending" do
    travel_to Time.zone.local(2026, 3, 15, 8, 0, 0) do
      slot = Time.zone.local(2026, 3, 16, 12, 0, 0)

      @client.bookings.create!(
        service: @service,
        booking_start_time: slot,
        booking_end_time: slot + 30.minutes,
        booking_status: :pending,
        booking_expires_at: 1.minute.ago
      )

      assert_difference "Booking.count", 1 do
        get new_service_booking_path(@client.slug, @service, start_time: slot)
      end

      booking = Booking.last
      assert_equal "pending", booking.booking_status
      assert_equal slot, booking.booking_start_time
    end
  end

  # =========================================================
  # Si un autre booking a confirmé le même créneau entre-temps,
  # la confirmation du booking courant doit être refusée
  # =========================================================
  test "create refuses confirmation when another booking confirmed the same slot in the meantime" do
    travel_to Time.zone.local(2026, 3, 15, 8, 0, 0) do
      slot = Time.zone.local(2026, 3, 16, 13, 0, 0)

      pending_booking = @client.bookings.create!(
        service: @service,
        booking_start_time: slot,
        booking_end_time: slot + 30.minutes,
        booking_status: :pending,
        booking_expires_at: BookingRules.pending_expires_at
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

      post confirm_booking_path(@client.slug, pending_booking), params: {
        booking: {
          customer_first_name: "Leonard",
          customer_last_name: "Boisson",
          customer_email: "leo@example.com"
        }
      }

      assert_redirected_to public_client_path(
        @client.slug,
        service_id: @service.id,
        date: slot.to_date
      )

      pending_booking.reload
      assert_equal "pending", pending_booking.booking_status
      assert_nil pending_booking.customer_first_name
      assert_nil pending_booking.customer_last_name
    end
  end

  # =========================================================
  # Vérifie la protection finale côté base de données :
  # impossible d'avoir 2 confirmed sur le même créneau
  # pour le même client
  # =========================================================
  test "database unique index prevents duplicate confirmed bookings on the same slot" do
    travel_to Time.zone.local(2026, 3, 15, 8, 0, 0) do
      slot = Time.zone.local(2026, 3, 16, 14, 0, 0)

      @client.bookings.create!(
        service: @service,
        booking_start_time: slot,
        booking_end_time: slot + 30.minutes,
        booking_status: :confirmed,
        customer_first_name: "Leonard",
        customer_last_name: "Boisson",
        customer_email: "leo@example.com"
      )

      assert_raises ActiveRecord::RecordNotUnique do
        @client.bookings.create!(
          service: @service,
          booking_start_time: slot,
          booking_end_time: slot + 30.minutes,
          booking_status: :confirmed,
          customer_first_name: "Other",
          customer_last_name: "User",
          customer_email: "other@example.com"
        )
      end
    end
  end

  # =========================================================
  # Pour un autre client, le même créneau doit rester possible
  # (l'unicité est par client)
  # =========================================================
  test "same slot is allowed for another client" do
    travel_to Time.zone.local(2026, 3, 15, 8, 0, 0) do
      other_client = Client.create!(
        name: "Maigris Mon Gros",
        slug: "maigris-mon-gros"
      )

      other_service = other_client.services.create!(
        name: "Séance individuelle",
        duration_minutes: 30,
        price_cents: 4000
      )

      slot = Time.zone.local(2026, 3, 16, 15, 0, 0)

      @client.bookings.create!(
        service: @service,
        booking_start_time: slot,
        booking_end_time: slot + 30.minutes,
        booking_status: :confirmed,
        customer_first_name: "Leonard",
        customer_last_name: "Boisson",
        customer_email: "leo@example.com"
      )

      assert_nothing_raised do
        other_client.bookings.create!(
          service: other_service,
          booking_start_time: slot,
          booking_end_time: slot + 30.minutes,
          booking_status: :confirmed,
          customer_first_name: "Other",
          customer_last_name: "User",
          customer_email: "other@example.com"
        )
      end
    end
  end
end
