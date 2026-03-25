# Booking Flow

## 1. Resume executif

- `BookingRules` centralise les constantes et predicates simples qui cadrent le reservable : pas de 30 minutes, horaires 9h-18h, jours ouvres, minimum notice de 30 minutes, horizon de 30 jours, expiration `pending` de 5 minutes.
- Le moteur expose une page publique qui calcule des slots theoriques. Quand un utilisateur choisit un creneau, le systeme cree un booking `pending` qui bloque temporairement l'intervalle. La confirmation transforme ce pending en `confirmed` si la session n'a pas expire et si le slot n'est toujours pas bloque.

## 2. Vue d'ensemble du flux

### Etape par etape

- Consultation :
  - `Bookings::PublicPage#call` charge le `Client` par `slug`, les `services`, parse la date via `Bookings::Input.safe_date`, puis calcule les slots si `selected_service` et `date` sont presents.
- Selection du slot :
  - `Bookings::AvailableSlots#call` genere une grille de creneaux dans les horaires d'ouverture puis applique les filtres de disponibilite.
- Creation `pending` :
  - `BookingsController#create_pending` sanitise `start_time` avec `Bookings::Input.safe_time`, puis delegue a `Bookings::CreatePending#call`.
  - si le slot est reservable, un `Booking` `pending` est cree avec expiration a `now + 5 minutes`.
- Confirmation :
  - `BookingsController#create` delegue a `Bookings::Confirm#call`.
  - si tout est valide, le booking passe a `confirmed`, les informations client sont persistees et un `confirmation_token` est genere.
- Success :
  - `BookingsController#success` relit le booking par `confirmation_token`, scope au `client`.
  - le flux de reference est couvert par `test/integration/booking_flow_test.rb`.

### Acteurs et objets principaux

- `Client` :
  - porte le catalogue de `Service` et les `Enseigne`
  - la page publique est adressee par `slug`
- `Enseigne` :
  - porte le contexte principal de disponibilite, de concurrence et d'unicite de slot
- `Service` :
  - definit la duree et le prix
- `Booking` :
  - porte les temps `start/end/expires`, le statut, les informations client et le token de confirmation

## 3. Regles du flux

### 3.1 Creation d'un booking `pending`

- Un pending ne peut pas etre cree sans `booking_start_time` valide.
- Le slot doit provenir de la grille systeme, pas d'un timestamp arbitraire.
- Le slot ne doit pas deja etre bloque par un `confirmed` ou un `pending` actif.
- Un pending valide recoit une expiration a 5 minutes.
- La creation est serialisee par `SlotLock.with_lock(enseigne_id:, booking_start_time:)`.

### 3.2 Confirmation d'un booking

- Seul un booking `pending` peut etre confirme.
- La confirmation echoue si le pending a expire.
- La disponibilite est reverifiee au moment de confirmer.
- Les champs client sont requis au moment du passage a `confirmed`.
- Une confirmation reussie genere un `confirmation_token` unique.
- En dernier rempart, la DB empeche deux `confirmed` sur la meme paire `enseigne_id + booking_start_time`.

### 3.3 Erreurs metier et UX

- `INVALID_SLOT` :
  - `start_time` invalide ou non parsable
- `SLOT_NOT_BOOKABLE` :
  - slot hors grille
- `SLOT_UNAVAILABLE` :
  - slot deja bloque
- `PENDING_CREATION_FAILED` :
  - echec de creation du pending
- `NOT_PENDING` :
  - tentative de confirmer un booking non pending
- `SESSION_EXPIRED` :
  - pending expire
- `FORM_INVALID` :
  - informations client invalides
- `SLOT_TAKEN_DURING_CONFIRM` :
  - conflit DB detecte au moment de confirmer

Comportement controller :

- si `Confirm` echoue avec erreurs de validation sur `@booking`, le formulaire est re-render en `422`
- sinon, le flow redirige vers la page publique avec `alert`

## 4. Cycle de vie du booking

### Statuts actifs du MVP

- `pending`
- `confirmed`
- `failed` existe dans le modele mais n'est pas exploite dans le flux MVP actuel

### Transition active

- `pending -> confirmed`
  - condition :
    - booking encore pending
    - non expire
    - slot toujours disponible
    - donnees client valides

### Sortie de `pending`

- soit par confirmation
- soit par expiration logique
  - le booking reste `pending` en base
  - il n'est plus bloquant ni confirmable

## 5. Checklist de validation rapide

- La page publique d'un client connu s'affiche correctement.
- Une enseigne active peut etre selectionnee.
- Une prestation peut etre selectionnee.
- Une date valide permet d'afficher des creneaux disponibles.
- Un `start_time` invalide est refuse.
- Un creneau hors grille est refuse.
- Un booking `confirmed` existant bloque le creneau correspondant.
- Un booking `pending` non expire bloque le creneau correspondant.
- Un booking `pending` expire ne bloque plus le creneau.
- La creation d'un `pending` valide fonctionne.
- Le `pending` cree recoit bien une expiration.
- Un `pending` expire ne peut pas etre confirme.
- Un `pending` valide peut etre confirme avec prenom, nom et email.
- Une confirmation invalide re-render le formulaire avec erreurs.
- Une confirmation reussie cree un `confirmation_token`.
- La page de succes s'affiche apres confirmation.
- Deux bookings `confirmed` ne peuvent pas exister sur le meme `booking_start_time` pour une meme `enseigne`.
- Un meme `booking_start_time` reste possible pour une autre `enseigne`.

## 6. References utiles

- `app/services/booking_rules.rb`
- `app/services/bookings/public_page.rb`
- `app/services/bookings/available_slots.rb`
- `app/services/bookings/create_pending.rb`
- `app/services/bookings/confirm.rb`
- `app/controllers/bookings_controller.rb`
- `test/integration/booking_flow_test.rb`
