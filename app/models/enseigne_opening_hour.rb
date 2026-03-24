class EnseigneOpeningHour < ApplicationRecord
  belongs_to :enseigne

  validates :day_of_week, presence: true, inclusion: { in: 0..6 }
  validates :opens_at, presence: true
  validates :closes_at, presence: true
  validate :opens_at_before_closes_at

  private

  def opens_at_before_closes_at
    return if opens_at.blank? || closes_at.blank?
    return if opens_at < closes_at

    errors.add(:opens_at, "must be before closes_at")
  end
end
