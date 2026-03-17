class Service < ApplicationRecord
  belongs_to :client
  has_many :bookings, dependent: :destroy

  validates :name, presence: true
  validates :duration_minutes, presence: true
  validates :price_cents, presence: true
end
