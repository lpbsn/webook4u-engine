module BookingsHelper
  def booking_customer_name(booking)
    booking.customer_full_name
  end

  def booking_formatted_slot(booking)
    booking.booking_start_time.strftime("%d/%m/%Y à %H:%M")
  end
end
