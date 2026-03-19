## 1. Résumé exécutif

- **Rôle de `BookingRules`**: `BookingRules` centralise des **constantes** et **prédicats simples** qui définissent le cadre du réservable (pas de 30 min, horaires 9–18, jours ouvrés, min notice 30 min, horizon 30 jours, expiration pending 5 min) et la règle “expired”. Implémenté dans `app/services/booking_rules.rb` et consommé par `Bookings::AvailableSlots`, `Bookings::Input`, `Bookings::CreatePending` et le modèle `Booking` (voir en-tête de `booking_rules.rb`).
- **Synthèse du fonctionnement**: le moteur expose une page publique qui calcule des slots théoriques (`Bookings::PublicPage` → `Bookings::AvailableSlots`). Quand l’utilisateur ouvre un slot, le système crée un **booking `pending`** qui **bloque temporairement** le créneau (via scope `active_pending`). La confirmation transforme ce pending en **`confirmed`** si la session n’a pas expiré et si le slot n’est toujours pas bloqué. La concurrence est gérée par un **verrou transactionnel PG advisory lock** + une **contrainte DB d’unicité** sur les bookings `confirmed`.

---

## 2. Vue d’ensemble du flux de réservation

### Étape par étape

- **Consultation (page publique / choix service)**  
  - **Service**: `Bookings::PublicPage#call` (`app/services/bookings/public_page.rb`)  
  - **Règle**: le système charge `Client` (par `slug`), la liste des `services`, parse la `date` via `Bookings::Input.safe_date`, puis calcule les slots via `Bookings::AvailableSlots` si `selected_service` + `date` présents.

- **Sélection du slot (slots “théoriques”)**  
  - **Service**: `Bookings::AvailableSlots#call` (`app/services/bookings/available_slots.rb`)  
  - **Règle**: génère une grille de créneaux (pas 30 min) dans les horaires d’ouverture et filtre min notice + conflits (confirmed + pending actif).

- **Création pending (réservation temporaire)**  
  - **HTTP**: `BookingsController#new` (`app/controllers/bookings_controller.rb`)  
  - **Sanitization**: `Bookings::Input.safe_time(params[:start_time])` (`app/services/bookings/input.rb`)  
  - **Service**: `Bookings::CreatePending#call` (`app/services/bookings/create_pending.rb`)  
  - **Effet**: si OK, crée un `Booking` `pending` avec `booking_expires_at` à now + 5 minutes.

- **Confirmation**  
  - **HTTP**: `BookingsController#create` (`app/controllers/bookings_controller.rb`)  
  - **Service**: `Bookings::Confirm#call` (`app/services/bookings/confirm.rb`)  
  - **Effet**: si OK, `booking_status` devient `confirmed`, un `confirmation_token` est généré, les infos client sont persistées.

- **Success**  
  - **HTTP**: `BookingsController#success` récupère le booking via `confirmation_token` scoppé au client (`app/controllers/bookings_controller.rb`).  
  - **Test de référence**: `test/integration/booking_flow_test.rb` décrit explicitement le flux complet “public → new (pending) → confirm → success”.

### Acteurs et objets principaux

- **Client**: propriétaire du catalogue et du calendrier (scope de concurrence et d’unicité).  
- **Service**: définit la **durée** (et le prix), utilisée pour calculer `booking_end_time` et les overlaps (`db/schema.rb`, table `services`).  
- **Booking**: agrégat de réservation avec `booking_status`, temps (start/end/expires), infos client, token de confirmation (`app/models/booking.rb`, `db/schema.rb`).

---

## Protection anti-spam (MVP)

### Description

- Le système inclut une **protection anti-spam minimale** afin de limiter les abus simples (scripts basiques, enchaînement de requêtes, répétitions).
- Il s’agit d’un **garde-fou technique transversal** (rate limiting) appliqué au niveau des points d’entrée HTTP du flux de réservation.

### Périmètre

- **Actions concernées** :
  - **Création pending** : `BookingsController#new` (GET) — route qui déclenche la création d’un booking `pending`.
  - **Confirmation** : `BookingsController#create` (POST) — route qui confirme un booking `pending`.
- **Actions non concernées** :
  - La **page publique** (`PublicClientsController#show`) n’est pas soumise à ce mécanisme.
  - La **page success** (`BookingsController#success`) n’est pas soumise à ce mécanisme.

### Comportement

#### Cas GET `BookingsController#new` (création pending)

- **En cas de dépassement** :
  - ne **pas** créer de booking `pending`,
  - ne **pas** appeler `Bookings::CreatePending`,
  - conserver un **rendu HTML cohérent** (ex. redirection vers la page publique),
  - afficher un **message dédié** (distinct des erreurs métier comme “créneau indisponible”).

#### Cas POST `BookingsController#create` (confirmation)

- **En cas de dépassement** :
  - ne **pas** appeler `Bookings::Confirm`,
  - ne **pas** confirmer le booking (il reste `pending`),
  - retourner une **réponse HTTP 429**,
  - afficher un **message dédié** (distinct des erreurs métier).

#### Cas nominal

- Aucun impact sur le parcours utilisateur normal (consultation → sélection → pending → confirmation → success).

### Nature du mécanisme

- Basé sur du **rate limiting par IP**.
- **Seuils configurables** (valeurs ajustables selon contexte).
- Objectif : **réduire les abus simples** sans introduire d’authentification ni de CAPTCHA.

### Positionnement métier

- Ce mécanisme **n’est pas une règle métier** de réservation.
- Il ne modifie pas :
  - les règles de **disponibilité** (génération des slots, overlaps, pending actif),
  - les règles de **confirmation** (pending, expiration, validations, unicité).
- Il agit uniquement comme un **garde-fou technique** sur la fréquence d’appels aux points d’entrée.

---

## 3. Règles métier explicites

### 3.1 Création d’un booking pending

- **Règle: un pending ne peut être créé sans `booking_start_time` valide**  
  - **Où**: `Bookings::CreatePending#call` → `return failure(Errors::INVALID_SLOT) if booking_start_time.nil?` (`app/services/bookings/create_pending.rb`)  
  - **Effet**: aucun booking créé, message “créneau invalide” (`app/services/bookings/errors.rb`).

- **Règle: le slot doit être “réservable” selon la grille système** (pas juste un timestamp arbitraire)  
  - **Où**: `Bookings::CreatePending` appelle `Availability.valid_generated_slot?` (`app/services/bookings/create_pending.rb`) qui vérifie l’inclusion dans `AvailableSlots#call` (`app/services/bookings/availability.rb`)  
  - **Effet**: refus `SLOT_NOT_BOOKABLE` si le slot n’est pas dans la grille (ex: hors horaires, week-end, avant min notice, etc.). Test: “fails when slot is not generated by the system” (`test/services/bookings/create_pending_test.rb`).

- **Règle: le slot ne doit pas être déjà bloqué** (confirmed OU pending actif)  
  - **Où**: `Bookings::CreatePending` → `Availability.slot_blocked?` (`app/services/bookings/create_pending.rb`).  
    - `slot_blocked?` consulte `BlockingBookings.overlapping(...).exists?` (`app/services/bookings/availability.rb` / `app/services/bookings/blocking_bookings.rb`)  
    - “bloquant” = scope `Booking.blocking_slot = confirmed OR active_pending` (`app/models/booking.rb`)  
  - **Effet**: refus `SLOT_UNAVAILABLE` si overlap. Tests: confirmed bloque, pending actif bloque, pending expiré ne bloque plus (`test/services/bookings/create_pending_test.rb`).

- **Règle: création du pending et de son expiration**  
  - **Où**: `Booking.create!(booking_status: :pending, booking_expires_at: BookingRules.pending_expires_at)` (`app/services/bookings/create_pending.rb`) et `BookingRules.pending_expires_at` = now + 5 minutes (`app/services/booking_rules.rb`)  
  - **Effet**: le pending a une “session” de 5 minutes (validité temporelle).

- **Règle de concurrence (création pending)**  
  - **Où**: bloc `SlotLock.with_lock(client_id:, booking_start_time:)` (`app/services/bookings/create_pending.rb`)  
  - **Effet**: sérialise les créations/confirmations concurrentes sur la même clé (client + start_time), via `pg_advisory_xact_lock` transactionnel (`app/services/bookings/slot_lock.rb`).

### 3.2 Confirmation d’un booking

- **Règle: seule une réservation `pending` peut être confirmée**  
  - **Où**: `return failure(Errors::NOT_PENDING) unless booking.pending?` (`app/services/bookings/confirm.rb`)  
  - **Effet**: on refuse de confirmer un booking déjà `confirmed` (ou autre). Test: `test/services/bookings/confirm_test.rb` “fails when booking is no longer pending”.

- **Règle: la confirmation est impossible si la session (pending) est expirée**  
  - **Où**: `return failure(Errors::SESSION_EXPIRED) if booking.expired?` (`app/services/bookings/confirm.rb`)  
  - **Expiration**: `Booking#expired?` délègue à `BookingRules.booking_expired?` qui considère expiré si `booking_expires_at` blank ou `<= now` (`app/models/booking.rb`, `app/services/booking_rules.rb`)  
  - **Effet**: refus “session expirée”. Test: `test/services/bookings/confirm_test.rb` “fails when pending booking is expired”.

- **Règle: re-check de disponibilité au moment de confirmer** (anti-TOCTOU)  
  - **Où**: dans le lock `SlotLock.with_lock`, `Confirm` appelle `Availability.slot_blocked?` avec `exclude_booking_id: booking.id` (`app/services/bookings/confirm.rb`)  
  - **Effet**: si quelqu’un a confirmé/posé un pending actif qui overlap, la confirmation échoue `SLOT_UNAVAILABLE` et le booking reste `pending`. Tests: “fails when another booking already blocks the same slot” + cas d’overlap partiel (`test/services/bookings/confirm_test.rb`).

- **Règle: données client requises pour `confirmed`**  
  - **Où**: `booking.update!(customer_*, booking_status: :confirmed)` (`app/services/bookings/confirm.rb`) + validations conditionnelles `if: :confirmed?` (`app/models/booking.rb`)  
  - **Effet**: si formulaire invalide, `Confirm` rescue `ActiveRecord::RecordInvalid` → `FORM_INVALID` et le booking reste `pending`. Test: `test/services/bookings/confirm_test.rb` “fails when booking params are invalid”.

- **Règle: génération de `confirmation_token` unique**  
  - **Où**: `confirmation_token: SecureRandom.uuid` (`app/services/bookings/confirm.rb`) + index unique `confirmation_token` (`db/migrate/20260318091500_add_confirmation_token_to_bookings.rb`, visible dans `db/schema.rb`)  
  - **Effet**: permet la page success (`BookingsController#success` récupère par token).

- **Garde-fou DB: un seul `confirmed` par (client, start_time)**  
  - **Où**: index unique partiel `where booking_status='confirmed'` (`db/migrate/20260316073931_add_unique_confirmed_slot_index_to_bookings.rb`, visible dans `db/schema.rb`)  
  - **Effet**: si course malgré checks, la DB lève `RecordNotUnique`; `Confirm` retourne `SLOT_TAKEN_DURING_CONFIRM` (`app/services/bookings/confirm.rb`, `app/services/bookings/errors.rb`). Test: `test/services/bookings/booking_duplicates_flow_test.rb`.

### 3.3 Disponibilité / blocage de slot

- **Règle: disponibilité = grille générée − créneaux en overlap avec “bloquants”**  
  - **Où**: `Bookings::AvailableSlots#call` génère des slots et retire ceux dont l’intervalle overlap un intervalle bloquant (`app/services/bookings/available_slots.rb`)  
  - **“Bloquant”**: `BlockingBookings.overlapping` s’appuie sur `client.bookings.blocking_slot` et un overlap SQL (`booking_start_time < end AND booking_end_time > start`) (`app/services/bookings/blocking_bookings.rb`, `app/models/booking.rb`)  
  - **Effet concret**: confirmed bloque, pending actif bloque, pending expiré ne bloque plus. Tests: `test/services/bookings/available_slots_test.rb` + `create_pending_test.rb`.

- **Règle d’overlap (semi-ouverte)**  
  - **Où**: `Availability.overlap?(start_a, end_a, start_b, end_b) = start_a < end_b && end_a > start_b` (`app/services/bookings/availability.rb`)  
  - **Effet**: un slot qui commence exactement à la fin d’un booking est **autorisé** (cas “border”). Tests explicites:  
    - pending autorisé à `confirmed_end` (`test/services/bookings/create_pending_test.rb`)  
    - confirmation autorisée si commence à `first_end` (`test/services/bookings/confirm_test.rb`)  
    - et `AvailableSlots` conserve 09:30 quand un booking finit à 09:30 (`test/services/bookings/available_slots_test.rb`).

- **Règle: la durée de service drive l’intervalle réellement bloqué**  
  - **Où**: `booking_end_time = booking_start_time + service.duration_minutes.minutes` en create pending (`app/services/bookings/create_pending.rb`) et dans les checks de blocage (`app/services/bookings/availability.rb`)  
  - **Effet**: le système raisonne en intervalles (pas juste “start_time”).

### 3.4 Expiration / session

- **Règle: expiration pending = 5 minutes**  
  - **Où**: `BookingRules::PENDING_EXPIRATION_MINUTES = 5` + `pending_expires_at` (`app/services/booking_rules.rb`) et utilisé à la création pending (`app/services/bookings/create_pending.rb`)  
  - **Effet**: après expiration, le booking `pending` n’est plus “bloquant” (scope `active_pending`), et n’est plus confirmable (`Booking#confirmable?`, `Booking#expired?`).

- **Règle: un pending sans `booking_expires_at` est considéré expiré**  
  - **Où**: `BookingRules.booking_expired?` retourne `true` si `booking_expires_at.blank?` (`app/services/booking_rules.rb`)  
  - **Effet**: robustesse “fail closed” si donnée manquante.

> Déduction indirecte (signalée): il n’y a pas de mécanisme observé ici qui “annule”/supprime les pending expirés; la logique d’expiration est appliquée via scopes/conditions (ex: `active_pending`, `expired?`). Cela découle de la lecture des services/tests et du fait que `booking_status` reste `pending` dans les échecs de confirm.

### 3.5 Erreurs métier et cas de refus

- **Catalogue des erreurs et messages UX**  
  - **Où**: `Bookings::Errors` (`app/services/bookings/errors.rb`)  
  - **Codes utilisés**:
    - `INVALID_SLOT`: start_time nil / non parsable (souvent issu de `Bookings::Input.safe_time`)  
    - `SLOT_NOT_BOOKABLE`: slot hors grille système  
    - `SLOT_UNAVAILABLE`: slot bloqué (confirmed ou pending actif, overlap)  
    - `PENDING_CREATION_FAILED`: `Booking.create!` invalide  
    - `NOT_PENDING`: tentative de confirmer un booking non pending  
    - `SESSION_EXPIRED`: pending expiré  
    - `FORM_INVALID`: validations confirmed (nom/email)  
    - `SLOT_TAKEN_DURING_CONFIRM`: conflit DB “dernier rempart”

- **Comportement controller (rediriger vs re-render form)**  
  - **Où**: `BookingsController#create` (`app/controllers/bookings_controller.rb`)  
  - **Effet**:
    - si `Confirm` échoue **avec erreurs de validation sur `@booking`** (`@booking.errors.any?`), il re-render `:new` en 422 (UX “corriger le formulaire”)  
    - sinon, redirect vers page publique avec `alert` (UX “recommencer/slot plus dispo/session expirée/etc.”).  
  - `BookingsController#new` redirige toujours vers la page publique en cas d’échec de pending.

---

## 4. Cycle de vie du booking

### Statuts identifiés

- **`pending`**, **`confirmed`**, **`failed`**: enum dans `Booking` (`app/models/booking.rb`).

### Transitions possibles (confirmées par le code)

- **`pending` → `confirmed`**  
  - **Condition**: pending + non expiré + slot non bloqué au moment de confirmer + params valides  
  - **Où**: `Bookings::Confirm#call` (`app/services/bookings/confirm.rb`)

### Conditions d’entrée / sortie

- **Entrée `pending`**: via `Bookings::CreatePending` si slot “généré” et non bloqué (`app/services/bookings/create_pending.rb`).  
- **Sortie `pending`**:
  - soit par confirmation (transition ci-dessus),
  - soit “expiration logique” (reste `pending` en DB mais n’est plus bloquant/confirmable via `active_pending`/`expired?`).

### Cas interdits

- Confirmer un booking **non pending** (`NOT_PENDING`) (`app/services/bookings/confirm.rb`).  
- Confirmer un pending **expiré** (`SESSION_EXPIRED`).  
- Confirmer si un overlap existe au moment de confirmer (`SLOT_UNAVAILABLE`).  
- Avoir **deux confirmed** sur le même `(client_id, booking_start_time)` (interdit DB) (`db/migrate/20260316073931...`).

---

## 5. Hypothèses MVP (implicites mais solidement suggérées par le code)

> Toutes les hypothèses ci-dessous sont **déduites** du comportement implémenté (services/tests). Je les marque comme “hypothèses MVP” car elles reflètent des simplifications/choix visibles, sans être formulées comme règles métier “produit” dans un document.

- **Hypothèse: calendrier simple, pas de gestion d’horaires variables**  
  - Horaires d’ouverture fixes 9–18 et jours ouvrés lundi–vendredi (`BookingRules`, `AvailableSlots`). Pas de fermeture exceptionnelle, vacances, jours fériés, pauses, capacité multiple.

- **Hypothèse: pas de “ressource” (employé/salle) → capacité = 1 par client**  
  - L’unicité/concurrence est scoppée au `client_id` (lock et index unique partiel). Le “calendrier” est celui du client, pas d’une ressource interne.

- **Hypothèse: un slot valable doit provenir de la grille**  
  - Refus explicite des timestamps hors slots générés (`Availability.valid_generated_slot?`). Cela simplifie la QA (on teste une grille), mais limite la flexibilité (ex: début à :15 impossible sauf si généré).

- **Hypothèse: la “session de réservation” = pending 5 min, sans paiement obligatoire**  
  - `booking_expires_at` gère un hold temporaire.  
  - Présence de champs Stripe (`stripe_session_id`, `stripe_payment_intent` dans `db/schema.rb`) mais **aucune règle** visible ici qui les impose pour confirmer. Dans le MVP, ces champs sont **présents mais non exploités** (réservés à une intégration paiement ultérieure).

- **Hypothèse: pas de nettoyage des pending expirés**  
  - Le système fonctionne sans purge; il ignore les expired pour le blocage (`active_pending`). Acceptable MVP, mais implique accumulation en base.

- **Hypothèse: pas de modification/annulation/replanification dans le flux MVP**  
  - Aucun service visible “cancel/reschedule”, uniquement create pending + confirm + success.

---

## Hypothèses et limites du MVP

- **Statut `failed` et champs Stripe**  
  - Le statut `failed` existe dans l’enum `Booking`, mais aucun flux applicatif observé ne l’utilise/assigne dans le MVP.  
  - Les champs Stripe (`stripe_session_id`, `stripe_payment_intent`) sont présents en base mais **non utilisés** dans les règles de confirmation actuelles. Ils sont **réservés** à une future intégration paiement (ex: session checkout, payment intent) et ne doivent pas être interprétés comme une précondition MVP.

- **Anti-spam**  
  - Une **protection anti-spam minimale** est en place sous forme de **rate limiting par IP**, appliqué uniquement sur :
    - la **création pending** (`BookingsController#new`),
    - la **confirmation** (`BookingsController#create`).
  - Cette protection est volontairement **simple** (MVP) : elle vise les abus automatisés basiques et les répétitions, et **ne protège pas** contre des attaques avancées (changement d’IP, botnets, etc.).
  - Elle ne remplace pas les garde-fous métier existants (disponibilité, expiration pending, locks / unicité DB) et n’en modifie pas la logique.

- **Gestion des slots (“un seul hold par slot exact”)**  
  - **Lock technique**: la sérialisation repose sur `SlotLock` avec la clé `(client_id, booking_start_time)` (slot “exact” au sens *start_time*).  
  - **Logique métier réelle**: la disponibilité et les refus ne sont pas basés sur l’égalité de `start_time` mais sur les **overlaps d’intervalles** \([start,end)\) calculés via la durée de service (confirmed + pending actif bloquent par overlap).  
  - En conséquence, “un seul hold par slot exact” décrit la **portée du verrou** (clé de lock), pas la règle de blocage globale, qui est **intervalle-based**.

- **Bypass des règles d’entrée (appels internes)**  
  - Certaines garanties semblent dépendre de points d’entrée comme `Bookings::Input` (ex: horizon 30 jours) et des controllers (sanitization des params).  
  - Des appels internes directs à des services (ou à `AvailableSlots` sans passer par `Input`) pourraient **contourner** certaines validations de bord (horizon, parsing/sanitization, etc.).  
  - Hypothèse MVP: ces chemins internes sont “de confiance” aujourd’hui; c’est un point à **sécuriser plus tard** si l’API interne s’élargit.

---

## 6. Zones floues / à valider

- **Statut `failed`**  
  - Présent dans `Booking` mais aucun flux ne le met à jour dans le MVP. Question: à quoi sert-il (paiement, abandon, autre) et à quel moment serait-il assigné ?

- **Règles “produit” non modélisées**  
  - Pas de “maximum bookings par jour”, pas de politique anti-spam, pas de “customer déjà existant”, pas de consentement/validation additionnelle.

- **Portée exacte du lock `SlotLock`**  
  - Clé = `(client_id, booking_start_time.to_i)` (`app/services/bookings/slot_lock.rb`).  
  - Clarification: le lock sérialise *par start_time exact*, alors que la règle métier de blocage est principalement *par overlap d’intervalles* (checks + scope overlap). Question: veut-on une protection “verrou intervalle” (non fait) ou le best-effort actuel suffit-il au MVP ?

- **Validité de `AvailableSlots` hors `Bookings::Input`**  
  - `Bookings::Input` applique l’horizon 30 jours, mais `AvailableSlots` ne le fait pas. Si un autre appel interne bypass `Input`, l’horizon peut être contourné (ambiguïté d’API interne, pas forcément un bug produit).

- **Stripe**  
  - Champs présents en DB, mais **aucune règle** dans `Confirm` n’exige un paiement (MVP “sans paiement obligatoire”). Question MVP: “confirmation = réservation ferme sans paiement” est-il intentionnel, et si non, quand/Comment Stripe doit-il impacter `confirmed/failed` ?

---

## 7. Lecture critique

### Ce qui est sain

- **Single source of truth** explicite pour les paramètres “cadre de réservation” (`BookingRules`) et usage cohérent côté services + modèle.
- **Double protection concurrence**:
  - lock transactionnel PG (`SlotLock`) pour sérialiser,
  - contrainte DB unique partielle pour interdire définitivement les doublons confirmed.
- **Anti-TOCTOU**: re-check de disponibilité au moment de confirmer dans la section critique (`Confirm`).

### Ce qui est fragile (impact métier)

- **Expiration “logique” sans lifecycle explicite**: les pending expirés restent en base et le statut ne reflète pas l’expiration (risque de confusion métier/analytics/ops).
- **Couplage “réservable = appartenir à la grille”**: très robuste mais potentiellement contraignant (pas d’ajustement manuel, pas de slots atypiques).
- **Cadre d’ouverture fixe**: acceptable MVP, mais c’est un choix produit fort (pas d’exception).

### Ce qui mérite une clarification documentaire prioritaire

- **Définition exacte de “slot disponible”**: grille + min notice + overlap + pending actif (et le fait que “fin = début” ne bloque pas).  
- **Règle pending vs confirmed**: pending bloque temporairement, confirmed bloque durablement; pending expiré ne bloque plus.  
- **Concurrence**: ce qui est garanti (un seul confirmed par slot et client) vs ce qui est seulement “best effort” applicatif.

---

## 8. Proposition de documentation cible (structure idéale)

- **1. Domain model (MVP)**  
  - Entités (`Client`, `Service`, `Booking`) + champs métier (start/end/expires/status/token) + invariants (`end > start`, service appartient au client).
- **2. Booking lifecycle**  
  - États (`pending/confirmed/failed`) + transitions + responsabilités (qui crée/qui confirme/qui lit) + diagramme simple.
- **3. Booking Rules (single source)**  
  - Paramètres (`BookingRules`): horaires, jours ouvrés, pas, min notice, horizon, expiration, définition `expired`.
- **4. Availability semantics**  
  - “Slot théorique” vs “slot réservable” (grille + filtres)  
  - Overlap semantics \([start,end)\) + exemples bord.
- **5. Pending creation rules**  
  - Préconditions, erreurs, effets en DB, verrouillage.
- **6. Confirmation rules**  
  - Préconditions, re-check, validations client, erreurs, effets, token, garde DB.
- **7. Concurrency & data integrity**  
  - Advisory lock (clés, portée, transaction), index unique partiel, comportements en course.
- **8. MVP assumptions & non-goals**  
  - Ce que le système ne gère pas (annulation, ressources multiples, exceptions horaires, paiement obligatoire, purge des pending).
- **9. Error catalog & UX mapping**  
  - `Bookings::Errors` + “redirect vs re-render” côté controller.
- **10. Test references**  
  - Liste des tests qui font foi pour chaque règle (CreatePending/Confirm/AvailableSlots/Flow/Duplicates).