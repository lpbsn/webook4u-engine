# Booking Invariants

## 1. Objectif

Ce document decrit les invariants actifs du moteur de reservation.

Il couvre :

- les invariants de domaine
- les protections base de donnees
- la semantique de disponibilite et de blocage
- les garde-fous de concurrence
- les hypotheses MVP qui influencent encore la structure du modele

## 2. Invariants actifs sur `Booking`

### Invariants de structure

- `booking_start_time`, `booking_end_time` et `booking_status` sont requis.
- `booking_end_time > booking_start_time`.
- `pending_access_token` doit rester globalement unique dans le systeme :
  - unicite dans `bookings`
  - unicite dans `expired_booking_links`
  - et absence de collision croisee `bookings <-> expired_booking_links`
- les champs requis dependent du statut `pending` ou `confirmed`.

### Invariants de cycle de vie

- un `pending` doit avoir une expiration exploitable.
- un `confirmed` doit porter les informations client necessaires.
- un `confirmed` doit etre traite comme un etat terminal dans le flux actuel.
- `failed` existe deja dans le schema, mais son cycle de vie reste a finaliser lors de l'introduction du paiement.
- convention actuelle : ne pas utiliser `failed` pour les erreurs metier transitoires du tunnel.
- un `pending` expire n'est plus confirmable.
- une erreur de transition metier courante n'est pas requalifiee en `failed` dans le flux actuel.

## 3. Cohérence cross-table `Booking / Client / Service / Enseigne`

### Regle metier

- `bookings.client_id = services.client_id`
- `bookings.client_id = enseignes.client_id`

Effet :

- un booking ne peut pas referencer un `service` ou une `enseigne` appartenant a un autre client

### Protection appliquee

- cote Rails :
  - validations `enseigne_belongs_to_client` et `service_belongs_to_client` dans `Booking`
- cote PostgreSQL :
  - trigger ajoute par `db/migrate/20260325130000_add_bookings_client_consistency_trigger.rb`
  - portee : `INSERT` et `UPDATE` sur `bookings`

### Portabilite de la protection

- la fonction SQL et le trigger sont portes par `db/structure.sql`
- cet invariant ne doit plus etre lu comme une simple validation applicative
- il fait partie du socle structurel courant du projet
- une future source CRM des disponibilites ne change pas cet invariant
- tant que `Booking` reference `client`, `service` et `enseigne`, la coherence cross-table reste une regle forte du domaine

### References de validation

- audit prealable :
  - [docs/BookingCrossTableAudit.md](/Users/leobsn/Desktop/webook4u-engine/docs/BookingCrossTableAudit.md)
- tests DB directs :
  - `test/models/booking_test.rb`
- test d'infrastructure :
  - `test/models/bookings_cross_table_trigger_infrastructure_test.rb`
- test de migration :
  - `test/models/add_bookings_client_consistency_trigger_migration_test.rb`

## 4. Disponibilite et blocage des creneaux

### Regle generale

La disponibilite est calculee comme :

- grille systeme generee
- moins les creneaux dont l'intervalle overlap un booking bloquant

### Resolution des horaires

- pour un jour donne, si une enseigne a au moins une plage dans `enseigne_opening_hours`, ces horaires ont priorite totale pour ce jour
- dans ce cas, `client_opening_hours` est ignore pour le jour concerne
- `client_opening_hours` ne sert de fallback que lorsqu'aucune plage `enseigne_opening_hours` n'existe pour le jour demande
- il n'existe pas de fallback partiel ni de fusion entre horaires `client` et `enseigne` pour un meme jour

### Booking bloquant

Un booking est bloquant si :

- il est `confirmed`
- ou il est `pending` et encore actif

Un `pending` expire ne bloque plus.
Il peut encore exister physiquement en base jusqu'au prochain batch de purge.

### Semantique d'overlap

Le moteur raisonne en intervalles semi-ouverts :

- un overlap existe si `start_a < end_b && end_a > start_b`
- un slot qui commence exactement a la fin d'un autre booking reste autorise

### Duree de service

Le systeme bloque des intervalles reels, pas uniquement des `start_time` :

- `booking_end_time = booking_start_time + service.duration_minutes`

## 5. Concurrence et garde-fous DB

### Advisory lock

- `SlotLock` serialise aujourd'hui les creations et confirmations au niveau de l'enseigne entiere
- c'est une protection transactionnelle PostgreSQL de type advisory lock
- cette granularite est un compromis volontaire de l'etape 1
- effet :
  - deux operations sur des creneaux differents de la meme enseigne ne passent pas en parallele
  - le throughput intra-enseigne est donc plus faible que la granularite metier reelle
- ce verrou ne doit pas etre lu comme l'invariant final du domaine
- evolution cible :
  - conserver l'invariant metier d'overlap par intervalle
  - deplacer plus tard la cle de verrou vers un `staff`
  - faire de `staff` la ressource reservable explicite du domaine

### Garde-fou d'unicite

- la base interdit deux bookings `confirmed` dont les intervalles overlapent sur une meme enseigne
- cette protection DB reste un garde-fou MVP, pas la granularite cible long terme
- la cible future est une protection d'overlap sur `staff_id + intervalle`

### Portee de la garantie

- le lock est aujourd'hui centre sur l'enseigne entiere
- la regle metier de blocage reste basee sur les overlaps d'intervalles
- il faut donc distinguer :
  - la cle technique du verrou
  - la logique metier reelle de disponibilite

## 6. Hypotheses MVP encore actives

- calendrier simple :
  - horaires fixes, jours ouvres, pas d'exceptions avancees
- capacite implicite :
  - 1 staff implicite par `enseigne`
- resolution actuelle :
  - contexte public `enseigne` -> ressource reservable triviale unique
- cible :
  - contexte public `enseigne` -> resolution explicite d'un `staff`
- slots issus de la grille :
  - pas de creneaux arbitraires hors generation systeme
- pas de paiement actif :
  - champs Stripe presents mais non utilises dans le flow courant
- `failed` prepare pour un futur usage paiement :
  - le statut existe deja
  - l'orientation actuelle est de ne pas l'utiliser pour les erreurs metier transitoires
  - les transitions exactes restent a definir avec le design paiement
- purge periodique des pending expires :
  - l'expiration reste logique immediatement
  - la suppression physique se fait ensuite par batch
  - un contexte public minimal est conserve durablement dans `expired_booking_links` pour permettre une redirection `SESSION_EXPIRED` apres purge
  - le `pending_access_token` du pending purge reste reserve par cette tombstone et ne peut pas etre recycle
  - aucun nouveau statut n'est introduit
- pas d'annulation ni de replanification dans le flux courant

## 7. Zones a surveiller

- `failed` existe deja dans le modele, mais son activation metier reste un sujet ouvert lie au futur flux paiement
- la granularite actuelle par `enseigne` ne couvre pas encore le multi-staff
- `Bookings::Resource` existe deja comme abstraction de transition vers cette future granularite
- l'arrivee de disponibilites depuis un CRM devra preserver ou revisiter explicitement les invariants actuels
- certains garde-fous de bord passent encore par les points d'entree applicatifs comme `Bookings::Input`

## 8. Suite logique

- lire [docs/BookingFlow.md](/Users/leobsn/Desktop/webook4u-engine/docs/BookingFlow.md) pour le comportement courant
- lire [docs/FutureInvariantsChecklist.md](/Users/leobsn/Desktop/webook4u-engine/docs/FutureInvariantsChecklist.md) avant tout ajout de paiement, CRM, multi-staff, annulation ou reschedule
