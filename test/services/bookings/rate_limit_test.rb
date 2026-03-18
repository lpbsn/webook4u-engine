# frozen_string_literal: true

require "test_helper"
require "digest"

class BookingsRateLimitTest < ActiveSupport::TestCase
  setup do
    Rails.cache.clear
  end

  test "falls back when cache increment returns nil" do
    ip = "1.2.3.4"
    slug = "client-test"

    Rails.cache.write("bookings:rate_limit:v1:pending_create:#{slug}:#{Digest::SHA256.hexdigest(ip)[0, 16]}", 0, expires_in: 60)

    Rails.cache.stub(:increment, nil) do
      assert Bookings::RateLimit.allow_pending_creation?(ip: ip, client_slug: slug)
    end
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

