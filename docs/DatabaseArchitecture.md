# Database Architecture

## Objectif

Ce document explique la base de donnees de Webook4u telle qu'elle fonctionne aujourd'hui :

- architecture generale
- tables et relations principales
- contraintes et invariants portes par PostgreSQL
- role de la base dans le moteur de reservation
- limites actuelles du schema

Il decrit l'etat courant du repo, pas une cible long terme.

## 1. Vue d'ensemble

### Base utilisee

Le projet utilise PostgreSQL.

En local :

- base de developpement : `webook4u_development`
- base de test : `webook4u_test`

En production, `database.yml` prevoit plusieurs bases :

- `primary`
- `cache`
- `queue`
- `cable`

Aujourd'hui, le domaine metier de reservation documente ici vit dans la base principale.

### Source de verite du schema

Le projet utilise `db/structure.sql` comme source de verite du schema PostgreSQL.

Ce choix est assume parce que certains invariants avances ne tiennent pas correctement dans `schema.rb`, notamment :

- la fonction SQL `enforce_bookings_client_consistency()`
- le trigger `bookings_client_consistency_trigger`

En pratique :

- les migrations modifient la base
- Rails genere ensuite `db/structure.sql`
- lors du bootstrap standard, la base est reconstruite avec la structure SQL reelle
- `db/schema.rb` reste present comme artefact Rails secondaire pour une lecture simple, mais ne doit pas servir de base de decision pour les invariants avances
- toute analyse DB serieuse, revue de migration, ou validation d'invariant doit partir de `db/structure.sql`

Ce point est important : la base ne repose plus uniquement sur une representation Ruby abstraite du schema.

## 2. Modele relationnel actuel

### Decision de domaine actuelle

Le modele metier courant est le suivant :

- `Client` porte le catalogue de `Service`
- `Enseigne` porte le contexte de reservation et de disponibilite
- `Booking` reference explicitement `client`, `enseigne` et `service`
- `Service` reste aujourd'hui partage a l'echelle du `Client`, pas de l'`Enseigne`

Cette lecture est celle du domaine actif du repo aujourd'hui.
Elle fixe le cadre MVP courant sans introduire de modele conceptuel plus large.

### Tables metier principales

- `clients`
- `enseignes`
- `services`
- `bookings`
- `client_opening_hours`
- `enseigne_opening_hours`

### Relations principales

- un `Client` a plusieurs `Enseigne`
- un `Client` a plusieurs `Service`
- un `Client` a plusieurs `Booking`
- une `Enseigne` appartient a un `Client`
- une `Enseigne` a plusieurs `Booking`
- un `Service` appartient a un `Client`
- un `Service` a plusieurs `Booking`
- un `Client` a plusieurs `ClientOpeningHour`
- une `Enseigne` a plusieurs `EnseigneOpeningHour`

### Lecture metier du modele

- `Client` porte l'identite publique du tunnel via `slug`
- `Service` porte le catalogue partage par client
- `Enseigne` porte le contexte de reservation et de disponibilite concret
- `Booking` relie explicitement un client, une enseigne et un service pour materialiser une reservation

### Source de disponibilite

Mode actif aujourd'hui :

- Webook4u calcule la disponibilite a partir des horaires et des bookings connus de l'application

Mode futur possible :

- certains clients pourront imposer leur CRM comme source de verite des disponibilites

Decision importante :

- cette variation future de source ne change pas l'invariant structurel actuel de `Booking`
- tant qu'un booking reference `client`, `service` et `enseigne`, la coherence cross-table reste une regle forte du domaine

## 3. Detail des tables

### `clients`

Rôle :

- entite racine du tunnel public
- porte `name` et `slug`

Points structurants :

- `slug` est requis et unique
- sert de cle publique d'acces aux pages de reservation

### `enseignes`

Role :

- represente un lieu ou point de service
- rattache a un client

Colonnes importantes :

- `client_id`
- `name`
- `full_address`
- `active`

Points structurants :

- `client_id` obligatoire
- une enseigne inactive peut exister mais ne doit pas etre proposee comme choix public actif

### `services`

Role :

- represente une prestation reservable

Colonnes importantes :

- `client_id`
- `name`
- `duration_minutes`
- `price_cents`

Points structurants :

- `duration_minutes > 0`
- `price_cents >= 0`
- le service est aujourd'hui partage entre toutes les enseignes d'un meme client

### `bookings`

Role :

- table centrale du moteur de reservation

Colonnes importantes :

- `client_id`
- `enseigne_id`
- `service_id`
- `booking_start_time`
- `booking_end_time`
- `booking_status`
- `booking_expires_at`
- `pending_access_token`
- `confirmation_token`
- `customer_first_name`
- `customer_last_name`
- `customer_email`
- `stripe_session_id`
- `stripe_payment_intent`

Lecture metier :

- un booking `pending` maintient temporairement un creneau
- un booking `confirmed` represente une reservation confirmee
- `failed` existe deja comme valeur de schema
  - orientation actuelle : futur usage pour un echec paiement persistant
  - ce cadrage reste preparatoire tant que le flux paiement et ses transitions ne sont pas implementes
  - il ne doit pas etre lu comme un statut generique d'erreur metier dans le flux actuel

### `client_opening_hours`

Role :

- stocke les horaires hebdomadaires au niveau client

Statut dans le domaine actuel :

- sert de fallback uniquement lorsqu'aucune plage `enseigne_opening_hours` n'existe pour le jour demande
- la cible produit reste un fonctionnement pilote a terme par `enseigne`

### `enseigne_opening_hours`

Role :

- stocke les horaires hebdomadaires au niveau enseigne

Statut dans le domaine actuel :

- represente la source prioritaire de disponibilite pour le jour concerne
- pour un jour donne, si une enseigne a au moins une plage, ces horaires masquent totalement les horaires `client`

## 4. Contraintes actuellement portees par la base

### Invariants de `bookings`

PostgreSQL protege aujourd'hui les invariants suivants :

- `client_id`, `service_id`, `enseigne_id` non nuls
- `booking_start_time`, `booking_end_time`, `booking_status` non nuls
- `booking_end_time > booking_start_time`
- `booking_status` limite a :
  - `pending`
  - `confirmed`
  - `failed`
- un `pending` doit avoir :
  - `booking_expires_at`
  - `pending_access_token` non vide
- un `confirmed` doit avoir :
  - `customer_first_name` non vide
  - `customer_last_name` non vide
  - `customer_email` non vide
  - `confirmation_token` non vide

### Cohérence cross-table

La base protege egalement un invariant cross-table fort :

- `bookings.client_id = services.client_id`
- `bookings.client_id = enseignes.client_id`

Cette regle est enforcee par :

- la fonction SQL `enforce_bookings_client_consistency()`
- le trigger `bookings_client_consistency_trigger`

Effet :

- impossible d'inserer ou de mettre a jour un booking qui reference un service ou une enseigne d'un autre client, meme si Rails est contourne

### Clés et references

Des foreign keys simples existent sur :

- `bookings.client_id -> clients.id`
- `bookings.service_id -> services.id`
- `bookings.enseigne_id -> enseignes.id`
- `services.client_id -> clients.id`
- `enseignes.client_id -> clients.id`
- `client_opening_hours.client_id -> clients.id`
- `enseigne_opening_hours.enseigne_id -> enseignes.id`

## 5. Indexes importants

### `bookings`

Indexes principaux :

- index sur `client_id`
- index sur `service_id`
- index sur `enseigne_id`
- unique sur `confirmation_token`
- unique sur `pending_access_token`
- unique partiel sur `enseigne_id + booking_start_time` pour les seuls bookings `confirmed`

Ce dernier index est critique :

- il empeche deux reservations `confirmed` sur le meme debut de creneau dans une meme enseigne

### Autres indexes utiles

- unique sur `clients.slug`
- index sur `services.client_id`
- index sur `enseignes.client_id`
- index composes sur les horaires hebdomadaires :
  - `client_id + day_of_week`
  - `enseigne_id + day_of_week`
  - unique exact sur `parent_id + day_of_week + opens_at + closes_at`

### Durcissement des horaires hebdomadaires

Pour `client_opening_hours` et `enseigne_opening_hours`, la strategie retenue est volontairement conservative :

- un doublon exact sur une meme entite et un meme jour est supprime automatiquement pendant la migration
- un overlap non trivial sur une meme entite et un meme jour n'est pas fusionne automatiquement
- si de tels overlaps existent encore, la migration echoue explicitement avec un diagnostic
- les plages contigues restent autorisees
- plusieurs plages disjointes restent autorisees

Effet :

- la base peut ensuite porter des contraintes fortes sans inventer de correction heuristique
- les cas ambigus de donnees horaires doivent etre corriges explicitement avant de poursuivre

## 6. Fonctionnement de la base dans le moteur de reservation

### Creation d'un `pending`

Lorsqu'un utilisateur choisit un creneau :

- Rails verifie que le slot est bien reservable
- un booking `pending` est cree
- `booking_end_time` est derive de la duree du service
- `booking_expires_at` fixe la duree de hold
- `pending_access_token` permet de relire ce pending

La base intervient ici pour :

- garantir la validite structurelle du booking
- garantir la coherence cross-table

### Confirmation

Lors de la confirmation :

- le booking doit encore etre `pending`
- il ne doit pas etre expire
- le slot est reverifie applicativement
- les informations client sont stockees
- le statut passe a `confirmed`

La base intervient ici pour :

- imposer les champs requis du statut `confirmed`
- garantir l'unicite du `confirmation_token`
- empecher le double `confirmed` sur le meme `booking_start_time` pour une meme enseigne

### Disponibilite

La base ne calcule pas les creneaux a elle seule.
Le calcul de disponibilite reste applicatif.

En revanche, la base soutient cette logique en stockant :

- les bookings existants
- leurs intervalles
- leurs statuts
- les horaires de reference

Le moteur applicatif s'appuie ensuite sur ces donnees pour calculer les overlaps et filtrer les slots.

Pour les horaires hebdomadaires :

- la base interdit les doublons exacts et les overlaps sur une meme entite et un meme jour
- la migration de durcissement ne corrige automatiquement que les doublons exacts
- les overlaps non triviaux restent bloquants tant qu'ils ne sont pas corriges manuellement

Resolution metier active :

- pour un jour donne, `enseigne_opening_hours` a priorite totale si au moins une plage existe
- `client_opening_hours` ne sert de fallback que si aucune plage `enseigne_opening_hours` n'existe ce jour-la
- il n'existe pas de fusion partielle entre horaires `client` et `enseigne` pour un meme jour

## 7. Architecture actuelle de disponibilite

### Ce qui est vrai aujourd'hui

- les prestations sont partagees au niveau `client`
- la disponibilite est principalement contextualisee au niveau `enseigne`
- la disponibilite est calculee aujourd'hui par Webook4u a partir des horaires et des bookings connus
- les horaires `client` servent encore de fallback
- la capacite actuelle correspond implicitement a `1 staff` par enseigne a un instant donne
- le code applicatif prepare deja une notion de ressource reservable, mais cette ressource est encore resolue trivialement depuis l'enseigne

### Variation future deja anticipee

- certains clients pourront utiliser leur CRM comme source de verite des disponibilites
- ce changement futur modifie la source des creneaux, pas la definition actuelle de `Booking`
- il ne remet pas en cause l'invariant cross-table `Booking / Client / Service / Enseigne`

### Ce que la base ne modele pas encore

- plusieurs staffs sur un meme creneau
- une capacite multiple sur une meme enseigne
- une source externe de creneaux issue d'un CRM
- un cycle de paiement actif
- annulation ou replanification

## 8. Limites actuelles du schema

Le schema actuel est coherent pour le MVP, mais il faut garder en tete plusieurs limites :

- `failed` existe deja dans `bookings`, mais sans usage metier actif
- sa semantique cible est une intention d'architecture, pas un sujet clos :
  - orientation actuelle : echec du flux de paiement
  - les transitions exactes et leur fermeture definitive restent a finaliser au moment d'introduire le paiement
  - dans l'etat actuel, pas de recyclage pour les erreurs transitoires du tunnel
- les champs Stripe existent, mais ne pilotent pas encore le cycle de vie
- la granularite actuelle par `enseigne` ne suffit pas pour le multi-staff
- la future cible explicite est `bookings.staff_id`, pas un simple compteur de capacite
- la disponibilite externe via CRM n'est pas encore modelisee
- l'expiration des `pending` est logique, pas materialisee par un autre statut

## 9. Comment lire cette base aujourd'hui

La bonne lecture architecture est la suivante :

- `clients` :
  - entree publique et racine commerciale
- `services` :
  - catalogue partage par client
- `enseignes` :
  - contexte de disponibilite concret
- `bookings` :
  - aujourd'hui attaches a un contexte `enseigne`
  - demain attaches a ce contexte plus une ressource explicite de type `staff`
  - verite de reservation
- `*_opening_hours` :
  - support de calcul de disponibilite

La base n'est pas un simple stockage passif.
Elle porte deja une partie importante de la verite metier du moteur.

## 10. Documents associes

- [docs/BookingFlow.md](/Users/leobsn/Desktop/webook4u-engine/docs/BookingFlow.md)
- [docs/BookingInvariants.md](/Users/leobsn/Desktop/webook4u-engine/docs/BookingInvariants.md)
- [docs/FutureInvariantsChecklist.md](/Users/leobsn/Desktop/webook4u-engine/docs/FutureInvariantsChecklist.md)
- [docs/BookingCrossTableAudit.md](/Users/leobsn/Desktop/webook4u-engine/docs/BookingCrossTableAudit.md)
- [README.md](/Users/leobsn/Desktop/webook4u-engine/README.md)
