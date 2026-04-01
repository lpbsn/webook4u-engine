# Test Onboarding

## Objectif

Ce document aide un nouveau developpeur a comprendre rapidement :

- comment les tests sont organises
- quel type de test utiliser selon le besoin
- quels fichiers lire en premier
- quelles conventions implicites du repo ne pas casser

Il decrit l'etat actuel de la suite de tests, pas une cible future.

## 1. Vue d'ensemble

Le projet utilise la stack de test Rails par defaut avec Minitest.

La suite actuelle couvre surtout :

- le flow public de reservation
- les services metier de reservation
- les modeles et leurs invariants
- les migrations sensibles
- quelques jobs et points d'infrastructure

Le principe general est simple :

- tests d'integration pour verifier le parcours utilisateur
- tests de services pour verifier la logique metier
- tests de modeles pour les validations et invariants
- tests de migration pour les changements de schema a risque

## 2. Structure des tests

La structure suit globalement celle du code :

- `test/integration`
  - parcours complets HTTP / UX serveur
- `test/services/bookings`
  - logique metier du domaine booking
- `test/models`
  - validations, contraintes, migrations et infrastructure DB
- `test/controllers`
  - comportement de controleurs et redirections
- `test/jobs`
  - jobs simples

Point important :

- le coeur du projet est davantage securise par les tests de services et d'integration que par des tests de controllers massifs

## 3. Fichiers a lire en premier

Pour comprendre vite la suite, lis dans cet ordre :

1. [test/test_helper.rb](/Users/leobsn/Desktop/webook4u-engine/test/test_helper.rb)
2. [test/integration/booking_flow_test.rb](/Users/leobsn/Desktop/webook4u-engine/test/integration/booking_flow_test.rb)
3. [test/services/bookings/slot_decision_test.rb](/Users/leobsn/Desktop/webook4u-engine/test/services/bookings/slot_decision_test.rb)
4. [test/services/bookings/create_pending_test.rb](/Users/leobsn/Desktop/webook4u-engine/test/services/bookings/create_pending_test.rb)
5. [test/services/bookings/confirm_test.rb](/Users/leobsn/Desktop/webook4u-engine/test/services/bookings/confirm_test.rb)
6. un test de migration representatif, par exemple [test/models/remove_confirmation_email_sent_at_from_bookings_migration_test.rb](/Users/leobsn/Desktop/webook4u-engine/test/models/remove_confirmation_email_sent_at_from_bookings_migration_test.rb)

## 4. Ce que configure test_helper

Le fichier [test/test_helper.rb](/Users/leobsn/Desktop/webook4u-engine/test/test_helper.rb) contient plusieurs conventions importantes :

- `parallelize(workers: :number_of_processors)`
  - la suite normale tourne en parallele
- `fixtures :all`
  - les fixtures YAML sont chargees globalement
- helpers communs
  - `create_weekday_opening_hours_for`
  - `create_weekday_opening_hours_for_enseigne`
- une classe speciale :
  - `SchemaMutationMigrationTestCase`

Cette derniere est importante :

- les tests de migration qui appellent `migration.up` / `migration.down` mutent le schema partage
- ils ne doivent donc pas tourner comme des tests paralleles ordinaires

## 5. Comment choisir le bon type de test

### Integration

Utilise un test d'integration quand tu veux valider :

- un parcours utilisateur complet
- des redirects
- des messages d'erreur visibles
- la cooperation entre controller, service, modele et vues

Exemple principal :

- [test/integration/booking_flow_test.rb](/Users/leobsn/Desktop/webook4u-engine/test/integration/booking_flow_test.rb)

### Service

Utilise un test de service quand tu veux valider :

- une regle metier
- un code d'erreur
- une orchestration transactionnelle
- une frontiere claire entre services

Exemples importants :

- [test/services/bookings/slot_decision_test.rb](/Users/leobsn/Desktop/webook4u-engine/test/services/bookings/slot_decision_test.rb)
- [test/services/bookings/create_pending_test.rb](/Users/leobsn/Desktop/webook4u-engine/test/services/bookings/create_pending_test.rb)
- [test/services/bookings/confirm_test.rb](/Users/leobsn/Desktop/webook4u-engine/test/services/bookings/confirm_test.rb)

### Model

Utilise un test de modele quand tu veux valider :

- une validation Active Record
- une methode metier du modele
- un invariant structurel expose au niveau modele

Exemple :

- [test/models/booking_test.rb](/Users/leobsn/Desktop/webook4u-engine/test/models/booking_test.rb)

### Migration

Utilise un test de migration quand tu modifies :

- une contrainte
- un trigger
- une colonne sensible
- un comportement de schema non trivial

Exemples :

- [test/models/add_confirmed_booking_overlap_protection_migration_test.rb](/Users/leobsn/Desktop/webook4u-engine/test/models/add_confirmed_booking_overlap_protection_migration_test.rb)
- [test/models/remove_confirmation_email_sent_at_from_bookings_migration_test.rb](/Users/leobsn/Desktop/webook4u-engine/test/models/remove_confirmation_email_sent_at_from_bookings_migration_test.rb)

## 6. Ce que les tests protègent vraiment

Les zones les plus importantes actuellement sont :

- le flow public complet
- la creation de `pending`
- la confirmation
- l'expiration des `pending`
- la resolution des creneaux visibles
- la decision metier de reservabilite
- les garde-fous PostgreSQL et migrations sensibles

Si tu touches une de ces zones, il faut en general mettre a jour :

- au moins un test de service
- parfois un test d'integration
- parfois un test de migration si le changement touche la base

## 7. Patterns utiles du repo

### Voyager par le flow nominal d'abord

Le repo privilegie des tests lisibles qui suivent un flow clair :

- setup metier simple
- action
- assertion sur le resultat

Le meilleur exemple est [test/integration/booking_flow_test.rb](/Users/leobsn/Desktop/webook4u-engine/test/integration/booking_flow_test.rb).

### Utiliser travel_to quand le temps compte

Le domaine depend fortement du temps :

- minimum notice
- expiration des `pending`
- dates de booking

Beaucoup de tests utilisent donc `travel_to`.

Si ton changement touche le temps, fais pareil.

### Tester les codes d'erreur, pas seulement le succes

La logique metier du moteur de reservation est beaucoup exprimee par des erreurs de service :

- `INVALID_SLOT`
- `SLOT_UNAVAILABLE`
- `SLOT_NOT_BOOKABLE`
- `SESSION_EXPIRED`
- etc.

Quand tu modifies un service, pense a tester :

- le cas nominal
- le code d'erreur attendu
- le cas limite pertinent

### Verifier les frontieres entre services

Le repo teste souvent qu'un service n'appelle pas un autre composant qu'il ne doit plus consulter.

Exemple :

- `SlotDecision` ne doit pas recalculer `AvailableSlots`

Ce type de test protege les responsabilites architecturales, pas seulement le resultat fonctionnel.

## 8. Commandes utiles

Workflow standard :

```bash
bin/check
```

Equivalent explicite :

```bash
bin/rails test
```

Lancer un fichier precis :

```bash
bin/rails test test/integration/booking_flow_test.rb
```

Lancer plusieurs fichiers cibles :

```bash
bin/rails test test/services/bookings/slot_decision_test.rb test/services/bookings/create_pending_test.rb
```

Pour les tests de migration qui mutent le schema, il est souvent plus prudent de rester en execution simple si besoin.

## 9. Ce qu'il faut eviter

- ajouter un test de controller quand un test de service ou d'integration couvre deja mieux le besoin
- tester la meme chose a trois niveaux sans raison
- casser l'isolation des tests de migration
- oublier `travel_to` quand le temps influence la regle
- ecrire un test tres bas niveau alors que le risque reel est sur le flow utilisateur

## 10. Checklist rapide avant un changement

- Quel niveau de test correspond vraiment au risque de ton changement ?
- Le comportement metier est-il deja capture par un test existant ?
- Ton changement touche-t-il le temps, les tokens, les overlaps ou les statuts ?
- Faut-il proteger une frontiere architecturale, pas seulement un resultat ?
- Le changement touche-t-il la base au point d'exiger un test de migration ?

Si tu ne sais pas par ou commencer, pars du flow utilisateur, puis descends au service central concerne.
