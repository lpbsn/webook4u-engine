class Client < ApplicationRecord
  class AmbiguousLegacyEnseigneError < StandardError; end

  has_many :client_opening_hours, dependent: :destroy
  has_many :services, dependent: :destroy
  has_many :bookings, dependent: :destroy
  has_many :enseignes, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  # Legacy helper kept for backfill and historical data maintenance only.
  def resolve_legacy_enseigne!
    with_lock do
      current_enseignes = enseignes.order(:id).to_a

      return enseignes.create!(name: name, full_address: nil, active: true) if current_enseignes.empty?
      return current_enseignes.first if current_enseignes.one?

      raise AmbiguousLegacyEnseigneError,
            "Client #{id} has multiple enseignes; explicit selection is required"
    end
  end
end
