# frozen_string_literal: true

require "test_helper"

class BookingRateLimitTest < ActionDispatch::IntegrationTest
  include ActiveSupport::Testing::TimeHelpers

  setup do
    Rails.cache.clear

    @client = Client.create!(
      name: "Client Test",
      slug: "client-test"
    )

    @service = @client.services.create!(
      name: "Service Test",
      duration_minutes: 30,
      price_cents: 2500
    )
  end

  test "GET bookings#new over quota does not create pending and keeps HTML-friendly UX" do
    with_rate_limit_env(pending_max: "0", confirm_max: "100", period_seconds: "600") do
      travel_to Time.zone.local(2026, 3, 15, 8, 0, 0) do
        slot = Time.zone.local(2026, 3, 16, 10, 0, 0)

        assert_no_difference "Booking.count" do
          get new_service_booking_path(@client.slug, @service, start_time: slot),
              headers: { "REMOTE_ADDR" => "1.2.3.4" }
        end

        assert_response :redirect
        follow_redirect!
        assert_response :success
        assert_includes response.body, Bookings::RateLimit::MESSAGE
      end
    end
  end

  test "POST bookings#create over quota returns 429 and does not confirm booking" do
    with_rate_limit_env(pending_max: "100", confirm_max: "0", period_seconds: "600") do
      travel_to Time.zone.local(2026, 3, 15, 8, 0, 0) do
        slot = Time.zone.local(2026, 3, 16, 10, 0, 0)

        get new_service_booking_path(@client.slug, @service, start_time: slot),
            headers: { "REMOTE_ADDR" => "1.2.3.4" }
        assert_response :success

        booking = Booking.last
        assert_equal "pending", booking.booking_status

        post confirm_booking_path(@client.slug, booking),
             params: {
               booking: {
                 customer_first_name: "Test",
                 customer_last_name: "User",
                 customer_email: "test@example.com"
               }
             },
             headers: { "REMOTE_ADDR" => "1.2.3.4" }

        assert_response :too_many_requests
        assert_includes response.body, Bookings::RateLimit::MESSAGE

        booking.reload
        assert_equal "pending", booking.booking_status
      end
    end
  end

  private

  def with_rate_limit_env(pending_max:, confirm_max:, period_seconds:)
    old_pending = ENV["BOOKINGS_RATE_LIMIT_PENDING_MAX"]
    old_confirm = ENV["BOOKINGS_RATE_LIMIT_CONFIRM_MAX"]
    old_period = ENV["BOOKINGS_RATE_LIMIT_PERIOD_SECONDS"]

    ENV["BOOKINGS_RATE_LIMIT_PENDING_MAX"] = pending_max
    ENV["BOOKINGS_RATE_LIMIT_CONFIRM_MAX"] = confirm_max
    ENV["BOOKINGS_RATE_LIMIT_PERIOD_SECONDS"] = period_seconds

    yield
  ensure
    ENV["BOOKINGS_RATE_LIMIT_PENDING_MAX"] = old_pending
    ENV["BOOKINGS_RATE_LIMIT_CONFIRM_MAX"] = old_confirm
    ENV["BOOKINGS_RATE_LIMIT_PERIOD_SECONDS"] = old_period
  end
end
