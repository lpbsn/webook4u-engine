class BookingsController < ApplicationController
  layout "booking"
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
      redirect_to booking_success_path(@client.slug, @booking)
    else
      if @booking.errors.any?
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
    @booking = @client.bookings.find(params[:id])
    @service = @booking.service
  end

  private

  def booking_params
    params.require(:booking).permit(
      :customer_first_name,
      :customer_last_name,
      :customer_email
    )
  end
end
