module PublicClientsHelper
  def public_client_selected_service_name(selected_service)
    selected_service&.name || "—"
  end

  def public_client_selected_date(date)
    date.present? ? date.strftime("%d/%m/%Y") : "—"
  end

  def public_client_formatted_date(date)
    date.strftime("%d/%m/%Y")
  end

  def public_client_service_price(service)
    format_price_cents(service.price_cents)
  end

  def public_client_slot_label(slot_time)
    slot_time.strftime("%H:%M")
  end
end
