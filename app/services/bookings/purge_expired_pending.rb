# frozen_string_literal: true

module Bookings
  class PurgeExpiredPending
    Result = Struct.new(:deleted_count, :cutoff, keyword_init: true)
    EXPIRED_LINK_CONTEXT_CACHE_KEY_PREFIX = "bookings:expired_pending_link".freeze
    EXPIRED_LINK_CONTEXT_TTL = 35.days

    def self.call(cutoff: Time.zone.now)
      new(cutoff: cutoff).call
    end

    def initialize(cutoff:)
      @cutoff = cutoff
    end

    def call
      expired_pending_rows = Booking.pending
                                   .where("booking_expires_at < ?", cutoff)
                                   .select(:id, :client_id, :enseigne_id, :service_id, :booking_start_time, :pending_access_token)
                                   .to_a

      cache_expired_link_contexts!(expired_pending_rows)

      deleted_count = Booking.where(id: expired_pending_rows.map(&:id)).delete_all

      Result.new(deleted_count: deleted_count, cutoff: cutoff)
    end

    def self.expired_link_context_for(client_id:, token:)
      Rails.cache.read(expired_link_context_cache_key(client_id: client_id, token: token))
    end

    def self.expired_link_context_cache_key(client_id:, token:)
      "#{EXPIRED_LINK_CONTEXT_CACHE_KEY_PREFIX}:#{client_id}:#{token}"
    end

    private

    attr_reader :cutoff

    def cache_expired_link_contexts!(rows)
      rows.each do |row|
        key = self.class.expired_link_context_cache_key(client_id: row.client_id, token: row.pending_access_token)
        value = {
          enseigne_id: row.enseigne_id,
          service_id: row.service_id,
          date: row.booking_start_time.to_date
        }

        Rails.cache.write(key, value, expires_in: EXPIRED_LINK_CONTEXT_TTL)
      end
    end
  end
end
