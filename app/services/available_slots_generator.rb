# =========================================================
# AVAILABLE SLOTS GENERATOR
#
# Service responsable de générer les créneaux disponibles
# pour une prestation donnée à une date donnée.
#
# Ce service prend en compte :
# - les horaires d'ouverture
# - la durée de la prestation
# - les créneaux déjà réservés
# - les créneaux trop proches dans le temps
# - les jours non réservables
#
# Utilisé dans :
# PublicClientsController
# =========================================================

class AvailableSlotsGenerator
  # ---------------------------------------------------------
  # Durée entre chaque créneau affiché
  # (ex : 9:00, 9:30, 10:00, etc.)
  # ---------------------------------------------------------
  SLOT_DURATION = 30.minutes

  # ---------------------------------------------------------
  # Horaires de travail du client
  # (MVP simplifié)
  # ---------------------------------------------------------
  DAY_START_HOUR = 9
  DAY_END_HOUR = 18


  # =========================================================
  # INITIALISATION DU SERVICE
  #
  # client  -> le client (salon, coach, etc.)
  # service -> la prestation choisie
  # date    -> la date sélectionnée
  # =========================================================
  def initialize(client:, service:, date:)
    @client = client
    @service = service
    @date = date.to_date
  end


  # =========================================================
  # MÉTHODE PRINCIPALE
  #
  # Retourne la liste finale des créneaux disponibles.
  # =========================================================
  def call
    # Si le jour n'est pas réservable (week-end)
    return [] unless bookable_day?

    # On enlève les créneaux déjà pris
    slots.reject { |slot| blocked_slot_starts.include?(slot) }
  end


  private


  # ---------------------------------------------------------
  # Accès aux variables initialisées
  # ---------------------------------------------------------
  attr_reader :client, :service, :date


  # =========================================================
  # DÉTERMINE SI LE JOUR EST RÉSERVABLE
  #
  # Pour le MVP :
  # lundi → vendredi uniquement
  # =========================================================
  def bookable_day?
    date.monday? ||
    date.tuesday? ||
    date.wednesday? ||
    date.thursday? ||
    date.friday?
  end


  # =========================================================
  # GÉNÉRATION DES CRÉNEAUX DE LA JOURNÉE
  #
  # Exemple :
  # 09:00
  # 09:30
  # 10:00
  # etc.
  #
  # La boucle s'arrête quand la prestation ne peut plus
  # finir avant la fermeture.
  # =========================================================
  def slots
    start_of_day = date.in_time_zone.change(hour: DAY_START_HOUR, min: 0)
    end_of_day = date.in_time_zone.change(hour: DAY_END_HOUR, min: 0)

    result = []
    current_slot = start_of_day

    while current_slot + service.duration_minutes.minutes <= end_of_day
      result << current_slot
      current_slot += SLOT_DURATION
    end

    # Supprime les créneaux trop proches de maintenant
    result.reject { |slot| slot < minimum_bookable_time }
  end


  # =========================================================
  # RÈGLE MÉTIER : ANTICIPATION MINIMALE
  #
  # Empêche de réserver un créneau trop proche
  #
  # Exemple :
  # si maintenant = 14:10
  # créneaux possibles à partir de 14:40
  # =========================================================
  def minimum_bookable_time
    Time.zone.now + 30.minutes
  end


  # =========================================================
  # CRÉNEAUX BLOQUÉS
  #
  # On récupère tous les créneaux déjà pris pour ce jour :
  #
  # - réservations confirmées
  # - réservations pending encore actives
  #
  # La logique blocking_slot est définie dans le modèle Booking
  # =========================================================
  def blocked_slot_starts
    client.bookings
          .blocking_slot
          .where(booking_start_time: day_range)
          .pluck(:booking_start_time)
          .to_set
  end


  # =========================================================
  # PLAGE DE TEMPS DE LA JOURNÉE
  #
  # Exemple :
  # 2026-03-20 00:00 → 2026-03-20 23:59
  #
  # Permet de filtrer les bookings du jour.
  # =========================================================
  def day_range
    date.in_time_zone.all_day
  end
end
