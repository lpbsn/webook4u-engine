# Database Onboarding

## Objectif

Ce document aide un nouveau developpeur a comprendre rapidement :

- quelle est la vraie source de verite DB du projet
- quelles tables comptent vraiment
- quels invariants sont portes par PostgreSQL
- comment lire le schema sans se tromper

Il decrit l'etat actuel de la base du repo.

## 1. Regle la plus importante

Pour ce projet :

- `db/structure.sql` est la seule reference DB serieuse
- `db/schema.rb` est un artefact Rails secondaire utile pour lecture rapide

Quand tu analyses :

- un invariant
- un trigger
- une contrainte
- une migration sensible

il faut partir de [db/structure.sql](/Users/leobsn/Desktop/webook4u-engine/db/structure.sql), pas de [db/schema.rb](/Users/leobsn/Desktop/webook4u-engine/db/schema.rb).

## 2. Pourquoi structure.sql fait foi

Le projet depend de protections PostgreSQL que `schema.rb` ne represente pas suffisamment bien ou pas de maniere decisionnelle.

Exemples visibles dans [db/structure.sql](/Users/leobsn/Desktop/webook4u-engine/db/structure.sql) :

- fonction `enforce_bookings_client_consistency()`
- fonction `enforce_global_pending_access_token_uniqueness()`
- trigger `bookings_client_consistency_trigger`
- triggers de protection globale sur `pending_access_token`
- contrainte d'overlap des bookings confirmes

`db/schema.rb` reste utile pour une lecture rapide des colonnes, index et relations simples.
Mais si tu dois prendre une decision technique, il ne suffit pas.

## 3. Tables metier a connaitre en premier

Les tables principales sont :

- `clients`
- `enseignes`
- `services`
- `bookings`
- `expired_booking_links`
- `client_opening_hours`
- `enseigne_opening_hours`

Dans [db/structure.sql](/Users/leobsn/Desktop/webook4u-engine/db/structure.sql), elles apparaissent notamment ici :

- `bookings` autour de la table `public.bookings`
- `client_opening_hours`
- `clients`
- `enseigne_opening_hours`
- `enseignes`
- `expired_booking_links`
- `services`

## 4. Lecture metier simple des tables

### clients

- racine publique du tunnel
- porte `name` et `slug`

### enseignes

- lieux rattachés a un client
- contexte concret de reservation

### services

- prestations partagees au niveau client
- pas specialisees par enseigne aujourd'hui

### bookings

- table centrale du domaine
- porte :
  - references `client`, `enseigne`, `service`
  - `booking_start_time`, `booking_end_time`
  - `booking_status`
  - donnees client
  - tokens publics

### expired_booking_links

- retention minimale apres purge d'un `pending` expire
- evite qu'un ancien lien public devienne un “not found” muet

### opening_hours

- `client_opening_hours`
  - fallback d'horaires
- `enseigne_opening_hours`
  - source prioritaire si presente sur le jour demande

## 5. Invariants a retenir tout de suite

### Invariants sur bookings

PostgreSQL protege notamment :

- `booking_start_time`, `booking_end_time`, `booking_status` requis
- `booking_end_time > booking_start_time`
- statuts limites a `pending`, `confirmed`, `failed`
- un `pending` doit avoir :
  - `booking_expires_at`
  - `pending_access_token`
- un `confirmed` doit avoir :
  - `customer_first_name`
  - `customer_last_name`
  - `customer_email`
  - `confirmation_token`

### Coherence cross-table

La base interdit qu'un booking reference :

- un `service` d'un autre client
- une `enseigne` d'un autre client

Cette protection n'est pas seulement applicative.
Elle est aussi enforcee par fonction SQL + trigger.

### Unicite globale des pending tokens

`pending_access_token` doit rester unique :

- dans `bookings`
- dans `expired_booking_links`
- et entre les deux tables

### Overlap des bookings confirmes

La base interdit deux `confirmed` qui overlapent sur une meme `enseigne`.

Cette protection existe au niveau PostgreSQL via une contrainte d'exclusion.

## 6. Ce que schema.rb montre bien et ce qu'il ne suffit pas a montrer

Dans [db/schema.rb](/Users/leobsn/Desktop/webook4u-engine/db/schema.rb), tu peux lire rapidement :

- colonnes
- foreign keys
- index simples
- check constraints exposees par Rails

Mais pour ce projet, `schema.rb` n'est pas suffisant pour raisonner correctement sur :

- les triggers
- les fonctions SQL
- la verite operationnelle complete du schema PostgreSQL

Conclusion pratique :

- lis `schema.rb` pour te reperer vite
- lis `structure.sql` pour analyser serieusement

## 7. Ce que la base garantit pour le flow public

Le flow public de reservation s'appuie sur des garanties DB reelles :

- deux confirmations incompatibles ne doivent pas coexister
- un `pending_access_token` ne doit pas etre recycle
- un booking doit rester coherent avec son `client`
- les contraintes de statut ne doivent pas etre contournables par erreur applicative

Autrement dit :

- la logique metier ne vit pas uniquement dans Rails
- PostgreSQL fait partie du coeur du domaine

## 8. Comment lire une migration dans ce projet

Quand tu lis ou ecris une migration :

1. commence par identifier si elle touche :
   - une simple colonne
   - un invariant
   - un trigger
   - une contrainte d'overlap
2. relis ensuite [db/structure.sql](/Users/leobsn/Desktop/webook4u-engine/db/structure.sql)
3. verifie s'il existe deja :
   - un test de migration
   - un test d'infrastructure DB
   - un test de modele qui encode l'invariant

Dans ce repo, une migration sensible doit souvent etre lue avec ses tests.

## 9. Fichiers a lire en premier si tu touches a la DB

Ordre recommande :

1. [docs/DatabaseArchitecture.md](/Users/leobsn/Desktop/webook4u-engine/docs/DatabaseArchitecture.md)
2. [docs/BookingInvariants.md](/Users/leobsn/Desktop/webook4u-engine/docs/BookingInvariants.md)
3. [db/structure.sql](/Users/leobsn/Desktop/webook4u-engine/db/structure.sql)
4. [db/schema.rb](/Users/leobsn/Desktop/webook4u-engine/db/schema.rb)
5. les tests de migration et d'infrastructure dans [test/models](/Users/leobsn/Desktop/webook4u-engine/test/models/booking_test.rb)

## 10. Tests DB utiles a connaitre

Quelques tests importants :

- [test/models/booking_test.rb](/Users/leobsn/Desktop/webook4u-engine/test/models/booking_test.rb)
- [test/models/bookings_cross_table_trigger_infrastructure_test.rb](/Users/leobsn/Desktop/webook4u-engine/test/models/bookings_cross_table_trigger_infrastructure_test.rb)
- [test/models/add_bookings_client_consistency_trigger_migration_test.rb](/Users/leobsn/Desktop/webook4u-engine/test/models/add_bookings_client_consistency_trigger_migration_test.rb)
- [test/models/add_confirmed_booking_overlap_protection_migration_test.rb](/Users/leobsn/Desktop/webook4u-engine/test/models/add_confirmed_booking_overlap_protection_migration_test.rb)
- [test/models/enforce_global_pending_access_token_uniqueness_migration_test.rb](/Users/leobsn/Desktop/webook4u-engine/test/models/enforce_global_pending_access_token_uniqueness_migration_test.rb)

## 11. Questions a se poser avant de toucher au schema

- Est-ce que la modification touche un invariant deja porte par PostgreSQL ?
- Est-ce qu'un simple changement Rails risque de contourner une protection DB existante ?
- Est-ce que la migration doit etre lue dans `structure.sql` apres generation ?
- Est-ce qu'un test de migration ou d'infrastructure DB doit accompagner le changement ?
- Est-ce que tu es en train de raisonner depuis `schema.rb` alors que tu devrais lire `structure.sql` ?

Si tu modifies `bookings`, les tokens, les contraintes ou les overlaps, pars du principe que la base fait partie du domaine et non d'un simple stockage.
