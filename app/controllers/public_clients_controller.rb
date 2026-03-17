class PublicClientsController < ApplicationController
  layout "booking"
  # =========================================================
  # PAGE PRINCIPALE DE RÉSERVATION
  #
  # Cette page permet de :
  # 1️⃣ choisir une prestation
  # 2️⃣ choisir une date
  # 3️⃣ afficher les créneaux disponibles
  #
  # Tout se passe sur UNE SEULE PAGE.
  # =========================================================
  def show
    page = Bookings::PublicPage.new(
      slug: params[:slug],
      service_id: params[:service_id],
      date_param: params[:date]
    ).call

    @client = page.client
    @services = page.services
    @selected_service = page.selected_service
    @date = page.date
    @slots = page.slots
  end
end
