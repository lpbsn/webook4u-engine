class Client < ApplicationRecord
  has_many :client_opening_hours, dependent: :destroy
  has_many :services, dependent: :destroy
  has_many :bookings, dependent: :destroy
  has_many :enseignes, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
end
