class Service < ApplicationRecord
  belongs_to :client
  has_many :bookings, dependent: :destroy

  validates :name, presence: true
  validates :duration_minutes, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :price_cents, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
