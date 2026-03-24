class BookingsController < ApplicationController
  layout "booking"
  before_action :load_pending_booking_context, only: %i[new create_pending]

  def new
    return unless previewable_slot?

    @booking_end_time = @booking_start_time + @service.duration_minutes.minutes
    @booking = Booking.new(
      client: @client,
      enseigne: @enseigne,
      service: @service,
      booking_start_time: @booking_start_time,
      booking_end_time: @booking_end_time,
      booking_status: :pending
    )
  end

  def create_pending
    result = Bookings::CreatePending.new(
      client: @client,
      enseigne: @enseigne,
      service: @service,
      booking_start_time: @booking_start_time
    ).call

    unless result.success?
      redirect_to_pending_selection(result.error_message)
      return
    end

    redirect_to pending_booking_path(@client.slug, result.booking)
  end

  def create
    @client = Client.find_by!(slug: params[:slug])
    @booking = @client.bookings.find(params[:id])
    @service = @booking.service
    @enseigne = @booking.enseigne

    result = Bookings::Confirm.new(
      booking: @booking,
      booking_params: booking_params
    ).call

    if result.success?
      redirect_to booking_success_path(@client.slug, @booking.confirmation_token)
    else
      if result.error_code == Bookings::Errors::FORM_INVALID
        @booking_start_time = @booking.booking_start_time
        @booking_end_time = @booking.booking_end_time
        flash.now[:alert] = result.error_message
        render :new, status: :unprocessable_entity
      else
        redirect_to public_client_path(
          @client.slug,
          enseigne_id: redirect_enseigne_id(@enseigne),
          service_id: @service.id,
          date: @booking.booking_start_time.to_date
        ),
                    alert: result.error_message
      end
    end
  end

  def show
    @client = Client.find_by!(slug: params[:slug])
    @booking = @client.bookings.pending.find(params[:id])
    @service = @booking.service
    @enseigne = @booking.enseigne
    @booking_start_time = @booking.booking_start_time
    @booking_end_time = @booking.booking_end_time

    render :new
  end

  def success
    @client = Client.find_by!(slug: params[:slug])
    @booking = @client.bookings.find_by!(confirmation_token: params[:token])
    @enseigne = @booking.enseigne
    @service = @booking.service
  end

  private

  def load_pending_booking_context
    @client = Client.find_by!(slug: params[:slug])
    @enseigne = @client.enseignes.active.find(params[:enseigne_id])
    @service = @client.services.find(params[:service_id])
    @booking_start_time = Bookings::Input.safe_time(params[:start_time])
    @booking_date = redirect_date(@booking_start_time)
  end

  def booking_params
    params.require(:booking).permit(
      :customer_first_name,
      :customer_last_name,
      :customer_email
    )
  end

  def redirect_date(booking_start_time)
    Bookings::Input.safe_date(params[:date]) || booking_start_time&.to_date
  end

  def previewable_slot?
    if @booking_start_time.nil?
      redirect_to_pending_selection(Bookings::Errors.message_for(Bookings::Errors::INVALID_SLOT))
      return false
    end

    if Bookings::Availability.slot_blocked?(
      client: @client,
      enseigne: @enseigne,
      service: @service,
      booking_start_time: @booking_start_time
    )
      redirect_to_pending_selection(Bookings::Errors.message_for(Bookings::Errors::SLOT_UNAVAILABLE))
      return false
    end

    unless Bookings::Availability.valid_generated_slot?(
      client: @client,
      enseigne: @enseigne,
      service: @service,
      booking_start_time: @booking_start_time
    )
      redirect_to_pending_selection(Bookings::Errors.message_for(Bookings::Errors::SLOT_NOT_BOOKABLE))
      return false
    end

    true
  end

  def redirect_to_pending_selection(message)
    redirect_to public_client_path(
      @client.slug,
      enseigne_id: @enseigne.id,
      service_id: @service.id,
      date: @booking_date
    ),
                alert: message
  end

  def redirect_enseigne_id(enseigne)
    enseigne&.active? ? enseigne.id : nil
  end
end
