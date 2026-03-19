# frozen_string_literal: true

require "test_helper"

class BookingFlowTest < ActionDispatch::IntegrationTest
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

  test "complete booking flow from public page to confirmation and success" do
    travel_to Time.zone.local(2026, 3, 15, 8, 0, 0) do
      # 1. Accès à la page publique du client
      get public_client_path(@client.slug)
      assert_response :success

      # 2. Sélection service + date pour afficher les créneaux (16 mars 2026 = lundi)
      date_param = "2026-03-16"
      get public_client_path(@client.slug, service_id: @service.id, date: date_param)
      assert_response :success

      # 3. Ouverture du formulaire via GET new (créneau 10h00 = valide dans la grille)
      slot = Time.zone.local(2026, 3, 16, 10, 0, 0)

      assert_difference "Booking.count", 1 do
        get new_service_booking_path(@client.slug, @service, start_time: slot)
      end

      assert_response :success

      # 4. Vérification qu’un booking pending a été créé
      booking = Booking.last
      assert_equal @client.id, booking.client_id
      assert_equal @service.id, booking.service_id
      assert_equal "pending", booking.booking_status, "After GET new, booking should be pending"
      assert_equal slot, booking.booking_start_time

      # 5. Soumission valide via POST confirm
      post confirm_booking_path(@client.slug, booking), params: {
        booking: {
          customer_first_name: "Léonard",
          customer_last_name: "Boisson",
          customer_email: "leo@example.com"
        }
      }

      # 6. Redirection vers booking_success_path
      booking.reload
      assert_redirected_to booking_success_path(@client.slug, booking.confirmation_token)

      follow_redirect!
      assert_response :success

      # 7. Vérification finale : booking confirmé en base
      assert_equal "confirmed", booking.booking_status, "After confirm POST, booking should be confirmed"
      assert_equal "Léonard", booking.customer_first_name
      assert_equal "leo@example.com", booking.customer_email

      # 7. (suite) Éléments clés présents sur la page success
      assert_includes response.body, "Votre réservation est confirmée"
      assert_includes response.body, @client.name
      assert_includes response.body, @service.name
    end
  end
end
