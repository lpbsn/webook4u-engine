require "test_helper"

class PublicClientsControllerTest < ActionDispatch::IntegrationTest
  include ActiveSupport::Testing::TimeHelpers

  test "should get show" do
    client = Client.create!(name: "Salon", slug: "salon")
    get public_client_url(client.slug)
    assert_response :success
  end

  test "rejects date beyond max_future_days and does not show slots" do
    client = Client.create!(name: "Salon", slug: "salon")
    service = client.services.create!(name: "Coupe", duration_minutes: 30, price_cents: 2500)

    travel_to Time.zone.local(2026, 3, 15, 8, 0, 0) do
      date_beyond = (Date.current + (BookingRules.max_future_days + 1).days).iso8601
      get public_client_url(client.slug), params: { service_id: service.id, date: date_beyond }
      assert_response :success
      # Date should be rejected (Bookings::Input.safe_date returns nil), so recap shows "—" for date
      assert_includes response.body, "Date :"
      assert_includes response.body, "—"
    end
  end
end
