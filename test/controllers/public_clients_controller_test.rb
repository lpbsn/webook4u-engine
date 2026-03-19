require "test_helper"

class PublicClientsControllerTest < ActionDispatch::IntegrationTest
  include ActiveSupport::Testing::TimeHelpers

  test "GET show returns success for valid client slug" do
    client = Client.create!(name: "Salon", slug: "salon")
    get public_client_url(client.slug)
    assert_response :success
  end

  test "GET show returns 404 for unknown client slug" do
    get public_client_url("slug-inexistant-xyz")
    assert_response :not_found
  end

  test "date input has min set to today to prevent past date selection" do
    client = Client.create!(name: "Salon Min", slug: "salon-min")
    service = client.services.create!(name: "Coupe", duration_minutes: 30, price_cents: 2500)

    travel_to Time.zone.local(2026, 3, 15, 8, 0, 0) do
      get public_client_url(client.slug), params: { service_id: service.id }
      assert_response :success
      assert_select 'input[name="date"][min=?]', Date.current.iso8601
    end
  end

  # We assert no start_time input (slot choice) instead of recap copy ("Date :", "—") so the test is stable if labels change.
  # When date is beyond max_future_days, safe_date is nil so the slots step is not rendered.
  test "rejects date beyond max_future_days and does not show slots" do
    client = Client.create!(name: "Salon", slug: "salon")
    service = client.services.create!(name: "Coupe", duration_minutes: 30, price_cents: 2500)

    travel_to Time.zone.local(2026, 3, 15, 8, 0, 0) do
      date_beyond = (Date.current + (BookingRules.max_future_days + 1).days).iso8601
      get public_client_url(client.slug), params: { service_id: service.id, date: date_beyond }
      assert_response :success
      assert_select 'input[name="start_time"]', count: 0
    end
  end
end
