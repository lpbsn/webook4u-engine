# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

Booking.destroy_all
Service.destroy_all
Client.destroy_all

salon = Client.create!(
  name: "Le Salon Des Gâté",
  slug: "salon-des-gate"
)

coach = Client.create!(
  name: "Maigris Mon Gros",
  slug: "maigris-mon-gros"
)

[
  { name: "Coupe homme", duration_minutes: 30, price_cents: 30 },
  { name: "Coupe femme", duration_minutes: 30, price_cents: 60 },
  { name: "Brushing", duration_minutes: 30, price_cents: 100 }
].each do |attrs|
  salon.services.create!(attrs)
end

[
  { name: "Séance individuelle", duration_minutes: 30, price_cents: 60 },
  { name: "Bilan forme", duration_minutes: 30, price_cents: 30 },
  { name: "Programme découverte", duration_minutes: 30, price_cents: 40 }
].each do |attrs|
  coach.services.create!(attrs)
end
