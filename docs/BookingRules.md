# Booking Rules

## Objectif

Ce document sert de point d'entree technique pour le moteur de reservation.

La documentation detaillee a ete decoupee en deux documents :

- [docs/BookingFlow.md](/Users/leobsn/Desktop/webook4u-engine/docs/BookingFlow.md) : flux de reservation, cycle de vie, erreurs et checklist de validation
- [docs/BookingInvariants.md](/Users/leobsn/Desktop/webook4u-engine/docs/BookingInvariants.md) : invariants de domaine et de base de donnees, concurrence, blocage des creneaux et hypotheses MVP

## Comment lire cette documentation

- lire `BookingFlow` pour comprendre ce que fait le moteur aujourd'hui, et dans quel ordre
- lire `BookingInvariants` pour comprendre ce que le systeme garantit structurellement
- pour toute analyse DB serieuse, partir de `db/structure.sql` ; `db/schema.rb` reste un artefact Rails secondaire de lecture simple
- lire [docs/FutureInvariantsChecklist.md](/Users/leobsn/Desktop/webook4u-engine/docs/FutureInvariantsChecklist.md) seulement si le perimetre courant evolue avec un nouveau composant metier ou une nouvelle source de verite

## Documents associes

- [docs/DatabaseArchitecture.md](/Users/leobsn/Desktop/webook4u-engine/docs/DatabaseArchitecture.md) : lecture SQL et structurelle de la base actuelle
- [docs/ProductScope.md](/Users/leobsn/Desktop/webook4u-engine/docs/ProductScope.md) : cadrage produit courant
