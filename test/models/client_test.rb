# frozen_string_literal: true

require "test_helper"

class ClientTest < ActiveSupport::TestCase
  test "valid client saves without errors" do
    client = Client.new(name: "Salon A", slug: "salon-a")
    assert client.valid?
  end

  test "name is required" do
    client = Client.new(name: nil, slug: "salon-b")
    assert_not client.valid?
    assert_includes client.errors[:name], "can't be blank"
  end

  test "slug is required" do
    client = Client.new(name: "Salon C", slug: nil)
    assert_not client.valid?
    assert_includes client.errors[:slug], "can't be blank"
  end

  test "slug must be unique" do
    Client.create!(name: "Salon D", slug: "slug-dupe")

    duplicate = Client.new(name: "Autre", slug: "slug-dupe")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:slug], "has already been taken"
  end

  test "database enforces unique slug" do
    timestamp = Time.current

    Client.insert_all!([
      { name: "Salon DB A", slug: "db-slug-dupe", created_at: timestamp, updated_at: timestamp }
    ])

    assert_raises ActiveRecord::RecordNotUnique do
      Client.insert_all!([
        { name: "Salon DB B", slug: "db-slug-dupe", created_at: timestamp, updated_at: timestamp }
      ])
    end
  end

  test "database enforces non null slug" do
    timestamp = Time.current

    assert_raises ActiveRecord::NotNullViolation do
      Client.insert_all!([
        { name: "Salon Sans Slug", slug: nil, created_at: timestamp, updated_at: timestamp }
      ])
    end
  end

  test "destroying client destroys associated services" do
    client = Client.create!(name: "Salon E", slug: "salon-e")
    client.services.create!(name: "Coupe", duration_minutes: 30, price_cents: 1500)

    assert_difference "Service.count", -1 do
      client.destroy
    end
  end

  test "resolve_legacy_enseigne! creates a default enseigne when none exists" do
    client = Client.create!(name: "Salon Legacy", slug: "salon-legacy")

    enseigne = client.resolve_legacy_enseigne!
    same_enseigne = client.resolve_legacy_enseigne!

    assert_equal "Salon Legacy", enseigne.name
    assert_nil enseigne.full_address
    assert_equal true, enseigne.active
    assert_equal [ enseigne.id ], client.enseignes.pluck(:id)
    assert_equal enseigne, same_enseigne
  end

  test "resolve_legacy_enseigne! reuses the existing enseigne when there is only one" do
    client = Client.create!(name: "Salon One", slug: "salon-one")
    enseigne = client.enseignes.create!(name: "Unique enseigne")

    assert_equal enseigne, client.resolve_legacy_enseigne!
  end

  test "resolve_legacy_enseigne! raises when several enseignes exist" do
    client = Client.create!(name: "Salon Multi", slug: "salon-multi")
    client.enseignes.create!(name: "Enseigne A")
    client.enseignes.create!(name: "Enseigne B")

    assert_raises Client::AmbiguousLegacyEnseigneError do
      client.resolve_legacy_enseigne!
    end
  end

  test "destroying client destroys associated enseignes" do
    client = Client.create!(name: "Salon Enseignes", slug: "salon-enseignes")
    client.enseignes.create!(name: "Enseigne A")

    assert_difference "Enseigne.count", -1 do
      client.destroy
    end
  end

  test "destroying client destroys associated bookings" do
    client = Client.create!(name: "Salon F", slug: "salon-f")
    enseigne = client.enseignes.create!(name: "Enseigne F")
    service = client.services.create!(name: "Coupe", duration_minutes: 30, price_cents: 1500)
    client.bookings.create!(
      enseigne: enseigne,
      service: service,
      booking_start_time: 2.days.from_now.change(hour: 10, min: 0, sec: 0),
      booking_end_time: 2.days.from_now.change(hour: 10, min: 30, sec: 0),
      booking_status: :confirmed,
      customer_first_name: "Jean",
      customer_last_name: "Dupont",
      customer_email: "jean@example.com"
    )

    assert_difference "Booking.count", -1 do
      client.destroy
    end
  end
end
