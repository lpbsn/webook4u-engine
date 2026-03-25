class Booking < ApplicationRecord
  before_validation :ensure_pending_access_token
  before_validation :ensure_confirmation_token

  # =========================================================
  # ASSOCIATIONS
  # =========================================================
  belongs_to :client
  belongs_to :enseigne
  belongs_to :service

  # =========================================================
  # ENUM MÉTIER
  # =========================================================
  enum :booking_status, {
    pending: "pending",
    confirmed: "confirmed",
    failed: "failed"
  }

  # =========================================================
  # VALIDATIONS GÉNÉRALES
  # =========================================================
  validates :booking_start_time, presence: true
  validates :booking_end_time, presence: true
  validates :booking_status, presence: true

  # =========================================================
  # VALIDATIONS CONDITIONNELLES
  # =========================================================
  validates :booking_expires_at, presence: true, if: :pending?
  validates :pending_access_token, presence: true, uniqueness: true, if: :pending?

  validates :customer_first_name, presence: true, if: :confirmed?
  validates :customer_last_name, presence: true, if: :confirmed?
  validates :customer_email, presence: true, if: :confirmed?
  validates :confirmation_token, presence: true, uniqueness: true, if: :confirmed?

  validates :customer_email,
            format: { with: URI::MailTo::EMAIL_REGEXP },
            if: :confirmed?

  # =========================================================
  # VALIDATIONS MÉTIER
  # =========================================================
  validate :booking_end_time_after_booking_start_time
  validate :enseigne_belongs_to_client
  validate :service_belongs_to_client

  # =========================================================
  # SCOPES
  # =========================================================
  scope :active_pending, -> { pending.where("booking_expires_at > ?", Time.zone.now) }
  scope :blocking_slot, -> { confirmed.or(active_pending) }

  # =========================================================
  # MÉTHODES MÉTIER
  # =========================================================
  def expired?
    BookingRules.booking_expired?(self)
  end

  def confirmable?
    pending? && !expired?
  end

  def customer_full_name
    [ customer_first_name, customer_last_name ].compact.join(" ")
  end

  private

  def booking_end_time_after_booking_start_time
    return if booking_start_time.blank? || booking_end_time.blank?
    return if booking_end_time > booking_start_time

    errors.add(:booking_end_time, "must be after booking_start_time")
  end

  def enseigne_belongs_to_client
    return if client.blank? || enseigne.blank?
    return if enseigne.client_id == client_id

    errors.add(:enseigne, "must belong to the same client")
  end

  def service_belongs_to_client
    return if client.blank? || service.blank?
    return if service.client_id == client_id

    errors.add(:service, "must belong to the same client")
  end

  def ensure_pending_access_token
    return unless pending?
    return if pending_access_token.present?

    self.pending_access_token = generate_pending_access_token
  end

  def ensure_confirmation_token
    return unless confirmed?
    return if confirmation_token.present?

    self.confirmation_token = generate_confirmation_token
  end

  def generate_pending_access_token
    loop do
      token = SecureRandom.urlsafe_base64(24)
      break token unless self.class.exists?(pending_access_token: token)
    end
  end

  def generate_confirmation_token
    loop do
      token = SecureRandom.uuid
      break token unless self.class.exists?(confirmation_token: token)
    end
  end
end
