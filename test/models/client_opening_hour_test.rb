require "test_helper"

class ClientOpeningHourTest < ActiveSupport::TestCase
  setup do
    @client = Client.create!(name: "Salon horaires", slug: "salon-horaires")
  end

  test "valid opening hour saves without errors" do
    opening_hour = ClientOpeningHour.new(
      client: @client,
      day_of_week: 1,
      opens_at: "09:00",
      closes_at: "18:00"
    )

    assert opening_hour.valid?
  end

  test "day_of_week is required" do
    opening_hour = ClientOpeningHour.new(client: @client, opens_at: "09:00", closes_at: "18:00")

    assert_not opening_hour.valid?
    assert_includes opening_hour.errors[:day_of_week], "can't be blank"
  end

  test "opens_at is required" do
    opening_hour = ClientOpeningHour.new(client: @client, day_of_week: 1, closes_at: "18:00")

    assert_not opening_hour.valid?
    assert_includes opening_hour.errors[:opens_at], "can't be blank"
  end

  test "closes_at is required" do
    opening_hour = ClientOpeningHour.new(client: @client, day_of_week: 1, opens_at: "09:00")

    assert_not opening_hour.valid?
    assert_includes opening_hour.errors[:closes_at], "can't be blank"
  end

  test "opens_at must be before closes_at" do
    opening_hour = ClientOpeningHour.new(
      client: @client,
      day_of_week: 1,
      opens_at: "18:00",
      closes_at: "09:00"
    )

    assert_not opening_hour.valid?
    assert_includes opening_hour.errors[:opens_at], "must be before closes_at"
  end
end
