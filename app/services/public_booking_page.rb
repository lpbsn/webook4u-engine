class PublicBookingPage
  Result = Struct.new(
    :client,
    :services,
    :selected_service,
    :date,
    :slots,
    keyword_init: true
  )

  def initialize(slug:, service_id:, date_param:)
    @slug = slug
    @service_id = service_id
    @date_param = date_param
  end

  def call
    client = Client.find_by!(slug: slug)
    services = client.services

    selected_service = if service_id.present?
      client.services.find(service_id)
    end

    date = BookingInput.safe_date(date_param)

    slots = if selected_service.present? && date.present?
      AvailableSlotsGenerator.new(client: client, service: selected_service, date: date).call
    else
      []
    end

    Result.new(
      client: client,
      services: services,
      selected_service: selected_service,
      date: date,
      slots: slots
    )
  end

  private

  attr_reader :slug, :service_id, :date_param
end

