class Client < ApplicationRecord
  has_many :services, dependent: :destroy
  has_many :bookings, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
end
