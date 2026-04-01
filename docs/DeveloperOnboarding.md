# Developer Onboarding

## Objectif

Ce document aide un nouveau developpeur a comprendre rapidement :

- ce que fait le projet aujourd'hui
- ou se trouve la logique importante
- comment lire le code dans le bon ordre
- quelles hypotheses de domaine ne pas casser

Il decrit l'etat actuel du repo, pas une cible future.

## 1. Ce qu'est le projet

Webook4u est aujourd'hui un moteur de reservation public Ruby on Rails.

Le flow actif est volontairement simple :

1. un utilisateur arrive sur une page publique via le `slug` d'un `client`
2. il choisit une `enseigne`
3. il choisit un `service`
4. il choisit une date
5. il voit les creneaux visibles
6. il cree un `booking` temporaire `pending`
7. il confirme ce booking
8. il arrive sur une page de succes

Le produit actuel ne couvre pas encore :

- paiement actif
- annulation
- replanification
- back-office metier
- multi-staff

## 2. Modele metier minimal

Les entites principales sont :

- `Client`
  - racine commerciale du tunnel public
  - expose un `slug`
- `Enseigne`
  - lieu concret de reservation
  - porte le contexte de disponibilite
- `Service`
  - prestation partagee entre les enseignes d'un meme client
- `Booking`
  - reservation avec statut, horaire et donnees client
- `ExpiredBookingLink`
  - retention minimale d'un lien public expire apres purge d'un `pending`

Le cycle de vie actif de `Booking` est :

- `pending`
- `confirmed`

`failed` existe dans le schema, mais n'est pas un statut du flow actif courant.

## 3. Lecture rapide du repo

Si tu arrives sur le projet, lis dans cet ordre :

1. [README.md](/Users/leobsn/Desktop/webook4u-engine/README.md)
2. [docs/ProductScope.md](/Users/leobsn/Desktop/webook4u-engine/docs/ProductScope.md)
3. [docs/BookingFlow.md](/Users/leobsn/Desktop/webook4u-engine/docs/BookingFlow.md)
4. [docs/BookingInvariants.md](/Users/leobsn/Desktop/webook4u-engine/docs/BookingInvariants.md)
5. [docs/DatabaseArchitecture.md](/Users/leobsn/Desktop/webook4u-engine/docs/DatabaseArchitecture.md)

Ensuite seulement, lis le code.

## 4. Structure du code

### Controllers

- [app/controllers/public_clients_controller.rb](/Users/leobsn/Desktop/webook4u-engine/app/controllers/public_clients_controller.rb)
  - construit la page publique de reservation
- [app/controllers/bookings_controller.rb](/Users/leobsn/Desktop/webook4u-engine/app/controllers/bookings_controller.rb)
  - orchestre creation du `pending`, confirmation, gestion du token public, redirections

Les controllers doivent rester fins.
La logique metier importante est dans les services.

### Models

- [app/models/client.rb](/Users/leobsn/Desktop/webook4u-engine/app/models/client.rb)
- [app/models/enseigne.rb](/Users/leobsn/Desktop/webook4u-engine/app/models/enseigne.rb)
- [app/models/service.rb](/Users/leobsn/Desktop/webook4u-engine/app/models/service.rb)
- [app/models/booking.rb](/Users/leobsn/Desktop/webook4u-engine/app/models/booking.rb)
- [app/models/expired_booking_link.rb](/Users/leobsn/Desktop/webook4u-engine/app/models/expired_booking_link.rb)

Le modele le plus important a comprendre est `Booking`.

### Services metier

Le coeur du domaine vit dans [app/services/bookings](/Users/leobsn/Desktop/webook4u-engine/app/services/bookings).

Les services a lire en premier :

- [app/services/bookings/public_page.rb](/Users/leobsn/Desktop/webook4u-engine/app/services/bookings/public_page.rb)
  - assemble les donnees de la page publique
- [app/services/bookings/available_slots.rb](/Users/leobsn/Desktop/webook4u-engine/app/services/bookings/available_slots.rb)
  - produit la grille visible cote UX
- [app/services/bookings/slot_decision.rb](/Users/leobsn/Desktop/webook4u-engine/app/services/bookings/slot_decision.rb)
  - point d'entree metier central pour savoir si un creneau est encore reservable
- [app/services/bookings/create_pending.rb](/Users/leobsn/Desktop/webook4u-engine/app/services/bookings/create_pending.rb)
  - orchestration transactionnelle de creation d'un `pending`
- [app/services/bookings/confirm.rb](/Users/leobsn/Desktop/webook4u-engine/app/services/bookings/confirm.rb)
  - orchestration transactionnelle de confirmation

Services de support importants :

- [app/services/bookings/schedule_resolver.rb](/Users/leobsn/Desktop/webook4u-engine/app/services/bookings/schedule_resolver.rb)
- [app/services/bookings/blocking_bookings.rb](/Users/leobsn/Desktop/webook4u-engine/app/services/bookings/blocking_bookings.rb)
- [app/services/bookings/slot_lock.rb](/Users/leobsn/Desktop/webook4u-engine/app/services/bookings/slot_lock.rb)
- [app/services/bookings/public_pending_token_resolver.rb](/Users/leobsn/Desktop/webook4u-engine/app/services/bookings/public_pending_token_resolver.rb)
- [app/services/bookings/purge_expired_pending.rb](/Users/leobsn/Desktop/webook4u-engine/app/services/bookings/purge_expired_pending.rb)
- [app/services/booking_rules.rb](/Users/leobsn/Desktop/webook4u-engine/app/services/booking_rules.rb)

### Views

Les vues actives du tunnel sont dans :

- [app/views/public_clients](/Users/leobsn/Desktop/webook4u-engine/app/views/public_clients/show.html.erb)
- [app/views/bookings](/Users/leobsn/Desktop/webook4u-engine/app/views/bookings/show.html.erb)

Le frontend reste simple et majoritairement server-rendered.

### Tests

La structure de test suit la structure du code :

- `test/models`
- `test/services/bookings`
- `test/controllers`
- `test/integration`

Les tests a lire en premier pour comprendre le comportement global :

- [test/integration/booking_flow_test.rb](/Users/leobsn/Desktop/webook4u-engine/test/integration/booking_flow_test.rb)
- [test/services/bookings/slot_decision_test.rb](/Users/leobsn/Desktop/webook4u-engine/test/services/bookings/slot_decision_test.rb)
- [test/services/bookings/create_pending_test.rb](/Users/leobsn/Desktop/webook4u-engine/test/services/bookings/create_pending_test.rb)
- [test/services/bookings/confirm_test.rb](/Users/leobsn/Desktop/webook4u-engine/test/services/bookings/confirm_test.rb)

## 5. Point d'entree HTTP

Les routes sont volontairement peu nombreuses dans [config/routes.rb](/Users/leobsn/Desktop/webook4u-engine/config/routes.rb).

Les principales sont :

- `GET /:slug`
  - page publique de reservation
- `POST /:slug/services/:service_id/bookings`
  - creation explicite du `pending`
- `GET /:slug/bookings/:token`
  - affichage du formulaire d'un `pending`
- `POST /:slug/bookings/:token/confirm`
  - confirmation du booking
- `GET /:slug/bookings/:token/success`
  - page de succes

## 6. Regles de domaine a ne pas casser

Les regles les plus sensibles sont :

- les `services` sont partages au niveau `client`
- l'`enseigne` porte le contexte concret de reservation
- la capacite actuelle est implicite : une seule ressource par enseigne
- `AvailableSlots` produit la grille visible
- `SlotDecision` porte la decision metier de reservabilite
- `CreatePending` et `Confirm` sont des orchestrateurs transactionnels
- un `pending` expire ne bloque plus et ne peut plus etre confirme
- un `confirmed` ne doit pas overlap un autre `confirmed` de la meme enseigne

## 7. Ce que la base garantit

La base PostgreSQL porte une partie critique du domaine.

Il faut retenir :

- `db/structure.sql` est la seule reference DB serieuse
- `db/schema.rb` est utile pour lecture rapide, mais pas pour raisonner sur les invariants PostgreSQL avances
- les triggers, contraintes et protections d'overlap sont importants
- le lock transactionnel `SlotLock` protege la fenetre critique de creation/confirmation

Avant une decision de schema ou une migration sensible, lis :

- [docs/DatabaseArchitecture.md](/Users/leobsn/Desktop/webook4u-engine/docs/DatabaseArchitecture.md)
- [docs/BookingInvariants.md](/Users/leobsn/Desktop/webook4u-engine/docs/BookingInvariants.md)

## 8. Workflow local utile

Le workflow standard est :

```bash
bin/setup --skip-server
bin/dev
bin/check
```

A retenir :

- `bin/setup --skip-server` valide et prepare l'environnement local
- `bin/check` est un alias simple vers `bin/rails test`
- le projet est pense d'abord pour usage solo local

## 9. Comment contribuer sans se perdre

Quand tu touches au coeur de reservation :

1. commence par identifier si tu modifies la grille visible, la decision metier, ou l'orchestration transactionnelle
2. verifie les invariants existants avant de proposer une nouvelle abstraction
3. garde les controllers fins
4. evite de remettre la logique metier dans les vues ou controllers
5. appuie-toi sur les tests de services et d'integration

## 10. Questions a se poser avant un changement

- Est-ce que le changement touche la grille visible (`AvailableSlots`) ou la reservabilite metier (`SlotDecision`) ?
- Est-ce que le changement modifie un invariant PostgreSQL existant ?
- Est-ce que le changement introduit une abstraction prematuree orientee multi-staff ou equipe ?
- Est-ce que le comportement attendu est deja capture par un test d'integration ou un test de service ?

Si la reponse touche a la base, aux tokens, aux overlaps ou aux transitions de statut, lis la doc avant de coder.
