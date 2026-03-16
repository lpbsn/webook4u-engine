class PublicClientsController < ApplicationController
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
    # ---------------------------------------------------------
    # Chargement du client via le slug dans l'URL
    # ex : /salon-des-gate
    # ---------------------------------------------------------
    @client = Client.find_by!(slug: params[:slug])

    # Liste des prestations proposées par le client
    @services = @client.services


    # ---------------------------------------------------------
    # Prestation sélectionnée
    #
    # Quand l'utilisateur clique sur un bouton prestation,
    # on reçoit service_id dans l'URL.
    # ---------------------------------------------------------
    @selected_service = if params[:service_id].present?
      @client.services.find(params[:service_id])
    end


    # ---------------------------------------------------------
    # Sécurisation de la date envoyée dans l'URL
    #
    # Exemple URL :
    # /salon-des-gate?service_id=1&date=2026-03-20
    #
    # safe_date protège contre :
    # - dates invalides
    # - dates passées
    # - réservations trop lointaines
    # ---------------------------------------------------------
    @date = safe_date(params[:date])


    # ---------------------------------------------------------
    # Génération des créneaux disponibles
    #
    # Les créneaux ne sont générés que si :
    # - une prestation est sélectionnée
    # - une date est sélectionnée
    #
    # La logique métier se trouve dans :
    # app/services/available_slots_generator.rb
    # ---------------------------------------------------------
    @slots = if @selected_service.present? && @date.present?
      AvailableSlotsGenerator.new(
        client: @client,
        service: @selected_service,
        date: @date
      ).call
    else
      []
    end
  end


  private


  # =========================================================
  # SÉCURISATION DES DATES
  #
  # Cette méthode protège contre les manipulations d'URL.
  #
  # Exemples refusés :
  # ?date=bonjour
  # ?date=2000-01-01
  # ?date=2050-01-01
  #
  # Règles :
  # - date >= aujourd'hui
  # - date <= aujourd'hui + 30 jours
  # =========================================================
  def safe_date(date_param)
    return nil if date_param.blank?

    begin
      parsed_date = Date.iso8601(date_param)

      # Empêche réservation dans le passé
      return nil if parsed_date < Date.current

      # Empêche réservation trop loin dans le futur
      return nil if parsed_date > Date.current + 30.days

      parsed_date

    rescue ArgumentError
      # Si la date est invalide
      nil
    end
  end
end
