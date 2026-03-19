# frozen_string_literal: true

require "test_helper"
require "digest"

class BookingsRateLimitTest < ActiveSupport::TestCase
  setup do
    Rails.cache.clear
  end

  test "env parsing is safe for nil, empty and non-numeric values" do
    old_pending = ENV["BOOKINGS_RATE_LIMIT_PENDING_MAX"]
    old_confirm = ENV["BOOKINGS_RATE_LIMIT_CONFIRM_MAX"]
    old_period = ENV["BOOKINGS_RATE_LIMIT_PERIOD_SECONDS"]

    ENV.delete("BOOKINGS_RATE_LIMIT_PENDING_MAX")
    ENV["BOOKINGS_RATE_LIMIT_CONFIRM_MAX"] = ""
    ENV["BOOKINGS_RATE_LIMIT_PERIOD_SECONDS"] = "nope"

    assert_equal 5, Bookings::RateLimit.pending_creation_limit
    assert_equal 8, Bookings::RateLimit.confirmation_limit
    assert_equal 600, Bookings::RateLimit.period_seconds
  ensure
    ENV["BOOKINGS_RATE_LIMIT_PENDING_MAX"] = old_pending
    ENV["BOOKINGS_RATE_LIMIT_CONFIRM_MAX"] = old_confirm
    ENV["BOOKINGS_RATE_LIMIT_PERIOD_SECONDS"] = old_period
  end
end
