# frozen_string_literal: true

require "digest"

module Bookings
  class RateLimit
    MESSAGE = "Trop de tentatives. Réessayez dans quelques minutes."
    DEFAULT_PENDING_LIMIT = 5
    DEFAULT_CONFIRM_LIMIT = 8
    DEFAULT_PERIOD_SECONDS = 600

    def self.allow_pending_creation?(ip:, client_slug:)
      allow?(
        key: cache_key(ip: ip, action: "pending_create", scope: client_slug),
        limit: pending_creation_limit,
        period_seconds: period_seconds
      )
    end

    def self.allow_confirmation?(ip:, client_slug:)
      allow?(
        key: cache_key(ip: ip, action: "confirm", scope: client_slug),
        limit: confirmation_limit,
        period_seconds: period_seconds
      )
    end

    def self.pending_creation_limit
      env_int("BOOKINGS_RATE_LIMIT_PENDING_MAX", default: DEFAULT_PENDING_LIMIT)
    end

    def self.confirmation_limit
      env_int("BOOKINGS_RATE_LIMIT_CONFIRM_MAX", default: DEFAULT_CONFIRM_LIMIT)
    end

    def self.period_seconds
      env_int("BOOKINGS_RATE_LIMIT_PERIOD_SECONDS", default: DEFAULT_PERIOD_SECONDS)
    end

    def self.allow?(key:, limit:, period_seconds:)
      return false if limit <= 0

      count = increment_with_ttl(key, expires_in: period_seconds)
      count <= limit
    end

    def self.cache_key(ip:, action:, scope:)
      ip_hash = Digest::SHA256.hexdigest(ip.to_s)[0, 16]
      "bookings:rate_limit:v1:#{action}:#{scope}:#{ip_hash}"
    end

    def self.increment_with_ttl(key, expires_in:)
      if Rails.cache.respond_to?(:increment)
        value = nil
        begin
          value = Rails.cache.increment(key, 1, expires_in: expires_in, initial: 0)
        rescue ArgumentError, TypeError => e
          # Certains cache stores ne supportent pas les keywords `expires_in:` / `initial:`
          # (ou ont une signature différente). On retombe alors sur le fallback existant.
          Rails.logger.debug(
            "Bookings::RateLimit cache increment failed; key=#{key} error_class=#{e.class}"
          )
        end
        return value unless value.nil?
      end

      current = Rails.cache.read(key).to_i
      next_value = current + 1
      Rails.cache.write(key, next_value, expires_in: expires_in)
      next_value
    end

    def self.env_int(name, default:)
      raw = ENV[name]
      return default if raw.nil? || raw.strip.empty?
      Integer(raw, 10)
    rescue ArgumentError, TypeError
      default
    end

    private_class_method :allow?, :cache_key, :increment_with_ttl, :env_int
  end
end
