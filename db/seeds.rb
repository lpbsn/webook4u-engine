# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

if Rails.env.development?
  salon = Client.find_or_create_by!(
    slug: "salon-des-gate"
  ) do |client|
    client.name = "Le Salon Des Gâté"
  end

  coach = Client.find_or_create_by!(
    slug: "maigris-mon-gros"
  ) do |client|
    client.name = "Maigris Mon Gros"
  end

  [
    { name: "Coupe homme", duration_minutes: 30, price_cents: 3000 },
    { name: "Coupe femme", duration_minutes: 30, price_cents: 6000 },
    { name: "Brushing", duration_minutes: 30, price_cents: 10000 }
  ].each do |attrs|
    salon.services.find_or_create_by!(
      name: attrs[:name]
    ) do |service|
      service.duration_minutes = attrs[:duration_minutes]
      service.price_cents = attrs[:price_cents]
    end
  end

  [
    { name: "Séance individuelle", duration_minutes: 30, price_cents: 6000 },
    { name: "Bilan forme", duration_minutes: 30, price_cents: 3000 },
    { name: "Programme découverte", duration_minutes: 30, price_cents: 4000 }
  ].each do |attrs|
    coach.services.find_or_create_by!(
      name: attrs[:name]
    ) do |service|
      service.duration_minutes = attrs[:duration_minutes]
      service.price_cents = attrs[:price_cents]
    end
  end
end
