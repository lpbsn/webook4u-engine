require "test_helper"

class EnseigneOpeningHourTest < ActiveSupport::TestCase
  setup do
    @client = Client.create!(name: "Salon enseigne", slug: "salon-enseigne-horaires")
    @enseigne = @client.enseignes.create!(name: "Enseigne A")
  end

  test "valid opening hour saves without errors" do
    opening_hour = EnseigneOpeningHour.new(
      enseigne: @enseigne,
      day_of_week: 1,
      opens_at: "10:00",
      closes_at: "16:00"
    )

    assert opening_hour.valid?
  end

  test "day_of_week is required" do
    opening_hour = EnseigneOpeningHour.new(enseigne: @enseigne, opens_at: "10:00", closes_at: "16:00")

    assert_not opening_hour.valid?
    assert_includes opening_hour.errors[:day_of_week], "can't be blank"
  end

  test "opens_at is required" do
    opening_hour = EnseigneOpeningHour.new(enseigne: @enseigne, day_of_week: 1, closes_at: "16:00")

    assert_not opening_hour.valid?
    assert_includes opening_hour.errors[:opens_at], "can't be blank"
  end

  test "closes_at is required" do
    opening_hour = EnseigneOpeningHour.new(enseigne: @enseigne, day_of_week: 1, opens_at: "10:00")

    assert_not opening_hour.valid?
    assert_includes opening_hour.errors[:closes_at], "can't be blank"
  end

  test "opens_at must be before closes_at" do
    opening_hour = EnseigneOpeningHour.new(
      enseigne: @enseigne,
      day_of_week: 1,
      opens_at: "16:00",
      closes_at: "10:00"
    )

    assert_not opening_hour.valid?
    assert_includes opening_hour.errors[:opens_at], "must be before closes_at"
  end
end
