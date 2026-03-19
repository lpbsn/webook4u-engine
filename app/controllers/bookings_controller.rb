class BookingsController < ApplicationController
  layout "booking"
  before_action :enforce_rate_limit_for_pending_creation, only: :new
  before_action :enforce_rate_limit_for_confirmation, only: :create

  def new
    @client = Client.find_by!(slug: params[:slug])
    @service = @client.services.find(params[:service_id])

    booking_start_time = Bookings::Input.safe_time(params[:start_time])

    result = Bookings::CreatePending.new(
      client: @client,
      service: @service,
      booking_start_time: booking_start_time
    ).call

    unless result.success?
      redirect_to public_client_path(
        @client.slug,
        service_id: @service.id,
        date: booking_start_time&.to_date
      ),
                  alert: result.error_message
      return
    end

    @booking = result.booking
    @booking_start_time = @booking.booking_start_time
    @booking_end_time = @booking.booking_end_time
  end

  def create
    @client = Client.find_by!(slug: params[:slug])
    @booking = @client.bookings.find(params[:id])
    @service = @booking.service

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
          service_id: @service.id,
          date: @booking.booking_start_time.to_date
        ),
                    alert: result.error_message
      end
    end
  end

  def success
    @client = Client.find_by!(slug: params[:slug])
    @booking = @client.bookings.find_by!(confirmation_token: params[:token])
    @service = @booking.service
  end

  private

  def enforce_rate_limit_for_pending_creation
    client = Client.find_by!(slug: params[:slug])
    service = client.services.find(params[:service_id])
    booking_start_time = Bookings::Input.safe_time(params[:start_time])

    return if Bookings::RateLimit.allow_pending_creation?(ip: request.remote_ip, client_slug: client.slug)

    redirect_to public_client_path(
      client.slug,
      service_id: service.id,
      date: booking_start_time&.to_date
    ),
                alert: Bookings::RateLimit::MESSAGE
    nil
  end

  def enforce_rate_limit_for_confirmation
    client = Client.find_by!(slug: params[:slug])

    return if Bookings::RateLimit.allow_confirmation?(ip: request.remote_ip, client_slug: client.slug)

    render plain: Bookings::RateLimit::MESSAGE, status: :too_many_requests
    nil
  end

  def booking_params
    params.require(:booking).permit(
      :customer_first_name,
      :customer_last_name,
      :customer_email
    )
  end
end
