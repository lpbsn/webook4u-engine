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
- les tokens doivent rester uniques quand presents.
- les champs requis dependent du statut `pending` ou `confirmed`.

### Invariants de cycle de vie

- un `pending` doit avoir une expiration exploitable.
- un `confirmed` doit porter les informations client necessaires.
- un `pending` expire n'est plus confirmable.

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

### Booking bloquant

Un booking est bloquant si :

- il est `confirmed`
- ou il est `pending` et encore actif

Un `pending` expire ne bloque plus.

### Semantique d'overlap

Le moteur raisonne en intervalles semi-ouverts :

- un overlap existe si `start_a < end_b && end_a > start_b`
- un slot qui commence exactement a la fin d'un autre booking reste autorise

### Duree de service

Le systeme bloque des intervalles reels, pas uniquement des `start_time` :

- `booking_end_time = booking_start_time + service.duration_minutes`

## 5. Concurrence et garde-fous DB

### Advisory lock

- `SlotLock` serialise les creations et confirmations sur la cle `enseigne_id + booking_start_time`
- c'est une protection transactionnelle PostgreSQL de type advisory lock

### Garde-fou d'unicite

- la base interdit deux bookings `confirmed` sur la meme paire `enseigne_id + booking_start_time`

### Portee de la garantie

- le lock est centre sur le `start_time` exact
- la regle metier de blocage reste basee sur les overlaps d'intervalles
- il faut donc distinguer :
  - la cle technique du verrou
  - la logique metier reelle de disponibilite

## 6. Hypotheses MVP encore actives

- calendrier simple :
  - horaires fixes, jours ouvres, pas d'exceptions avancees
- capacite implicite :
  - 1 staff implicite par `enseigne`
- slots issus de la grille :
  - pas de creneaux arbitraires hors generation systeme
- pas de paiement actif :
  - champs Stripe presents mais non utilises dans le flow courant
- pas de purge des pending expires :
  - l'expiration est logique, pas materialisee par un autre statut
- pas d'annulation ni de replanification dans le flux courant

## 7. Zones a surveiller

- `failed` existe deja dans le modele mais pas dans le flux MVP
- la granularite actuelle par `enseigne` ne couvre pas encore le multi-staff
- l'arrivee de disponibilites depuis un CRM devra preserver ou revisiter explicitement les invariants actuels
- certains garde-fous de bord passent encore par les points d'entree applicatifs comme `Bookings::Input`

## 8. Suite logique

- lire [docs/BookingFlow.md](/Users/leobsn/Desktop/webook4u-engine/docs/BookingFlow.md) pour le comportement courant
- lire [docs/FutureInvariantsChecklist.md](/Users/leobsn/Desktop/webook4u-engine/docs/FutureInvariantsChecklist.md) avant tout ajout de paiement, CRM, multi-staff, annulation ou reschedule
