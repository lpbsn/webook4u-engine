# frozen_string_literal: true

module Bookings
  module Errors
    INVALID_SLOT              = :invalid_slot
    SLOT_UNAVAILABLE          = :slot_unavailable
    SLOT_NOT_BOOKABLE         = :slot_not_bookable
    PENDING_CREATION_FAILED   = :pending_creation_failed
    NOT_PENDING               = :not_pending
    SESSION_EXPIRED           = :session_expired
    FORM_INVALID              = :form_invalid
    SLOT_TAKEN_DURING_CONFIRM = :slot_taken_during_confirm

    MESSAGES = {
      INVALID_SLOT => "Le créneau sélectionné est invalide.",
      SLOT_UNAVAILABLE => "Le créneau sélectionné n'est plus disponible.",
      SLOT_NOT_BOOKABLE => "Le créneau sélectionné n'est pas réservable.",
      PENDING_CREATION_FAILED => "Impossible de créer la réservation temporaire.",
      NOT_PENDING => "Cette réservation ne peut plus être confirmée. Veuillez recommencer votre sélection.",
      SESSION_EXPIRED => "Votre session a expiré. Veuillez renouveler votre réservation.",
      FORM_INVALID => "Le formulaire contient des erreurs.",
      SLOT_TAKEN_DURING_CONFIRM => "Le créneau sélectionné vient d'être réservé par un autre utilisateur."
    }.freeze

    def self.message_for(code)
      MESSAGES[code]
    end
  end
end
