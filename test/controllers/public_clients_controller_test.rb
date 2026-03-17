require "test_helper"

class PublicClientsControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    client = Client.create!(name: "Salon", slug: "salon")
    get public_client_url(client.slug)
    assert_response :success
  end
end
