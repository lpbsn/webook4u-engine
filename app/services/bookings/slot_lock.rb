# frozen_string_literal: true

module Bookings
  class SlotLock
    # Verrou PostgreSQL transactionnel pour empêcher deux requêtes simultanées
    # de réserver / confirmer le même créneau pour le même client.
    def self.with_lock(client_id:, booking_start_time:)
      lock_key_1 = client_id.to_i
      lock_key_2 = booking_start_time.to_i

      ActiveRecord::Base.transaction do
        ActiveRecord::Base.connection.execute(
          "SELECT pg_advisory_xact_lock(#{lock_key_1}, #{lock_key_2})"
        )

        yield
      end
    end
  end
end
