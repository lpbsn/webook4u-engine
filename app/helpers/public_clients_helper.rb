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
    number_to_currency(service.price_cents.to_f / 100, unit: "€")
  end

  def public_client_slot_label(slot_time)
    slot_time.strftime("%H:%M")
  end
end
