class BookingSlotLock
  # =========================================================
  # Verrou PostgreSQL transactionnel
  #
  # Objectif :
  # empêcher deux requêtes simultanées de réserver /
  # confirmer le même créneau pour le même client.
  #
  # Le verrou repose sur :
  # - client_id
  # - booking_start_time converti en entier
  # =========================================================
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
