# Unit tests for BookingRules (single source of truth for booking business rules).
# Secures refactor 2.1: any change to a rule value must keep these expectations.

require "test_helper"

class BookingRulesTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

  # --- Constants / API ---

  test "slot_duration returns 30 minutes" do
    assert_equal 30.minutes, BookingRules.slot_duration
  end

  test "day_start_hour is 9" do
    assert_equal 9, BookingRules.day_start_hour
  end

  test "day_end_hour is 18" do
    assert_equal 18, BookingRules.day_end_hour
  end

  test "min_notice_minutes is 30" do
    assert_equal 30, BookingRules.min_notice_minutes
  end

  test "max_future_days is 30" do
    assert_equal 30, BookingRules.max_future_days
  end

  test "pending_expiration_minutes is 5" do
    assert_equal 5, BookingRules.pending_expiration_minutes
  end

  # --- minimum_bookable_time ---

  test "minimum_bookable_time is now + 30 minutes" do
    travel_to Time.zone.local(2026, 3, 16, 14, 0, 0) do
      min_time = BookingRules.minimum_bookable_time
      assert_equal Time.zone.local(2026, 3, 16, 14, 30, 0), min_time
    end
  end

  test "minimum_bookable_time accepts custom now" do
    base = Time.zone.local(2026, 3, 16, 10, 0, 0)
    min_time = BookingRules.minimum_bookable_time(now: base)
    assert_equal base + 30.minutes, min_time
  end

  # --- pending_expires_at ---

  test "pending_expires_at is from + 5 minutes" do
    base = Time.zone.local(2026, 3, 16, 10, 0, 0)
    expires = BookingRules.pending_expires_at(from: base)
    assert_equal base + 5.minutes, expires
  end

  test "pending_expires_at defaults to Time.zone.now when from not given" do
    travel_to Time.zone.local(2026, 3, 16, 12, 0, 0) do
      expires = BookingRules.pending_expires_at
      assert_equal BookingRules.pending_expiration_minutes.minutes.from_now, expires
    end
  end

  # --- bookable_day? ---

  test "bookable_day? returns true for Monday through Friday" do
    [ Date.new(2026, 3, 16),  # Monday
      Date.new(2026, 3, 17),  # Tuesday
      Date.new(2026, 3, 18),  # Wednesday
      Date.new(2026, 3, 19),  # Thursday
      Date.new(2026, 3, 20)   # Friday
    ].each do |d|
      assert BookingRules.bookable_day?(d), "Expected #{d} (weekday) to be bookable"
    end
  end

  test "bookable_day? returns false for Saturday and Sunday" do
    [ Date.new(2026, 3, 21),  # Saturday
      Date.new(2026, 3, 22)   # Sunday
    ].each do |d|
      assert_not BookingRules.bookable_day?(d), "Expected #{d} (weekend) not to be bookable"
    end
  end

  test "bookable_day? accepts a Time and converts to date" do
    monday_noon = Time.zone.local(2026, 3, 16, 12, 0, 0)
    assert BookingRules.bookable_day?(monday_noon)

    saturday_noon = Time.zone.local(2026, 3, 21, 12, 0, 0)
    assert_not BookingRules.bookable_day?(saturday_noon)
  end

  # --- booking_expired? ---

  test "booking_expired? returns true when booking_expires_at is blank" do
    booking = Struct.new(:booking_expires_at).new(nil)
    assert BookingRules.booking_expired?(booking)
  end

  test "booking_expired? returns true when booking_expires_at is in the past" do
    travel_to Time.zone.local(2026, 3, 16, 12, 0, 0) do
      booking = Struct.new(:booking_expires_at).new(1.minute.ago)
      assert BookingRules.booking_expired?(booking)
    end
  end

  test "booking_expired? returns false when booking_expires_at is in the future" do
    travel_to Time.zone.local(2026, 3, 16, 12, 0, 0) do
      booking = Struct.new(:booking_expires_at).new(5.minutes.from_now)
      assert_not BookingRules.booking_expired?(booking)
    end
  end

  test "booking_expired? returns true when booking_expires_at equals now (boundary)" do
    now = Time.zone.local(2026, 3, 16, 12, 0, 0)
    booking = Struct.new(:booking_expires_at).new(now)
    assert BookingRules.booking_expired?(booking, now: now)
  end
end
