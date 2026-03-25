# Booking Rules

## Objectif

Ce document sert de point d'entree technique pour le moteur de reservation.

La documentation detaillee a ete decoupee en deux documents :

- [docs/BookingFlow.md](/Users/leobsn/Desktop/webook4u-engine/docs/BookingFlow.md) : flux de reservation, cycle de vie, erreurs et checklist de validation
- [docs/BookingInvariants.md](/Users/leobsn/Desktop/webook4u-engine/docs/BookingInvariants.md) : invariants de domaine et de base de donnees, concurrence, blocage des creneaux et hypotheses MVP

## Comment lire cette documentation

- lire `BookingFlow` pour comprendre ce que fait le moteur aujourd'hui, et dans quel ordre
- lire `BookingInvariants` pour comprendre ce que le systeme garantit structurellement
- lire [docs/FutureInvariantsChecklist.md](/Users/leobsn/Desktop/webook4u-engine/docs/FutureInvariantsChecklist.md) avant d'ajouter un nouveau composant metier

## Documents associes

- [docs/BookingCrossTableAudit.md](/Users/leobsn/Desktop/webook4u-engine/docs/BookingCrossTableAudit.md) : audit historique avant ajout de la protection DB cross-table
- [docs/ProductScope.fr.md](/Users/leobsn/Desktop/webook4u-engine/docs/ProductScope.fr.md) : cadrage produit en francais
- [docs/ProductScope.md](/Users/leobsn/Desktop/webook4u-engine/docs/ProductScope.md) : cadrage produit en anglais
