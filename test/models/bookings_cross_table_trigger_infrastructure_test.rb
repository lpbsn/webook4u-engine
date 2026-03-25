require "test_helper"

class BookingsCrossTableTriggerInfrastructureTest < ActiveSupport::TestCase
  test "bootstraped database contains bookings cross-table consistency function" do
    function_exists = ActiveRecord::Base.connection.select_value(<<~SQL.squish)
      SELECT EXISTS (
        SELECT 1
        FROM pg_proc
        WHERE proname = 'enforce_bookings_client_consistency'
      )
    SQL

    assert function_exists, "Expected SQL function enforce_bookings_client_consistency to exist in prepared database"
  end

  test "bootstraped database contains bookings cross-table consistency trigger" do
    trigger_exists = ActiveRecord::Base.connection.select_value(<<~SQL.squish)
      SELECT EXISTS (
        SELECT 1
        FROM pg_trigger t
        JOIN pg_class c ON c.oid = t.tgrelid
        WHERE t.tgname = 'bookings_client_consistency_trigger'
          AND c.relname = 'bookings'
          AND NOT t.tgisinternal
      )
    SQL

    assert trigger_exists, "Expected trigger bookings_client_consistency_trigger on bookings to exist in prepared database"
  end
end
