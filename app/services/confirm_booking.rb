class ConfirmBooking
  Result = Struct.new(:success?, :booking, :error_message, keyword_init: true)

  def initialize(booking:, booking_params:)
    @booking = booking
    @booking_params = booking_params
  end

  def call
    return failure("Cette réservation ne peut plus être confirmée. Veuillez recommencer votre sélection.") unless booking.pending?
    return failure("Votre session a expiré. Veuillez renouveler votre réservation.") if booking.expired?

    BookingSlotLock.with_lock(
      client_id: booking.client_id,
      booking_start_time: booking.booking_start_time
    ) do
      if BookingAvailability.slot_blocked?(
        client: booking.client,
        booking_start_time: booking.booking_start_time,
        exclude_booking_id: booking.id
      )
        return failure("Le créneau sélectionné n'est plus disponible.")
      end

      booking.update!(
        customer_first_name: booking_params[:customer_first_name],
        customer_last_name: booking_params[:customer_last_name],
        customer_email: booking_params[:customer_email],
        booking_status: :confirmed
      )
    end

    success(booking)
  rescue ActiveRecord::RecordInvalid
    failure("Le formulaire contient des erreurs.")
  rescue ActiveRecord::RecordNotUnique
    failure("Le créneau sélectionné vient d'être réservé par un autre utilisateur.")
  end

  private

  attr_reader :booking, :booking_params

  def success(booking)
    Result.new(success?: true, booking: booking, error_message: nil)
  end

  def failure(message)
    Result.new(success?: false, booking: booking, error_message: message)
  end
end
