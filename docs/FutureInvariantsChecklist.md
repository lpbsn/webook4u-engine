# Future Invariants Checklist

## Objectif du document

Ce document sert de memo prospectif de conception.

Il liste les invariants de base de donnees et de domaine qui ne sont pas necessaires pour comprendre ou maintenir le systeme courant, mais qui devront etre explicitement revisites si le perimetre produit evolue.

Le but est simple :

- ne pas oublier les invariants quand le produit evolue
- eviter d'ajouter un nouveau composant sans revoir les contraintes de verite en base
- garder `Booking` et la disponibilite coherents quand le moteur changera de dimension

Ce document n'est pas une reference de fonctionnement courant.
Il ne doit pas etre lu comme un prerequis standard pour comprendre le moteur actuel.

## Regle de travail

A chaque ajout d'un composant produit majeur, se poser cette question :

> est-ce que ce composant introduit un nouvel etat metier, une nouvelle source de verite, une nouvelle capacite, ou une nouvelle relation de dependance qui doit etre protegee au niveau DB ?

Si la reponse est oui, ce document peut servir de garde-fou avant implementation finale.

## Etat actuel

Pour le perimetre actuel, les invariants essentiels de `Booking` sont couverts.

Cela inclut notamment :

- statuts autorises
- ordre temporel `booking_end_time > booking_start_time`
- champs requis selon `pending` et `confirmed`
- unicite des tokens
- protection contre le double booking `confirmed` sur une meme enseigne et un meme debut de creneau
- coherence cross-table entre `Booking`, `Service` et `Enseigne` pour un meme `client`

Ce document ne remet pas en cause cet etat.
Il liste uniquement les invariants futurs a ne pas oublier.

## Invariant courant a preserver

Le socle actuel impose deja un invariant fort sur `Booking` :

- `bookings.client_id = services.client_id`
- `bookings.client_id = enseignes.client_id`

Cet invariant ne doit pas etre casse implicitement par les futurs travaux.

En pratique :

- l'ajout d'un CRM comme source de verite
- l'ajout de multi-source
- l'ajout de staff / capacite multiple

ne devront pas invalider cette coherence sans decision explicite et documentee sur l'evolution du modele.

Si le domaine evolue au point de rendre cet invariant insuffisant ou obsolete, il faudra :

- le documenter explicitement
- definir son remplacement
- proteger le nouvel invariant au niveau DB

## 1. Paiement

### Quand relire cette section

- ajout d'un checkout Stripe
- ajout d'un `PaymentIntent`
- ajout d'un statut de paiement
- confirmation conditionnee au paiement

### Invariants futurs a verifier

- un booking payant ne doit pas pouvoir etre `confirmed` sans preuve de paiement attendue
- cible de conception actuelle : `failed` pour l'echec du flux paiement, sous reserve de validation finale
- definir explicitement si `failed` doit etre terminal, et dans quelles limites
- un booking `confirmed` doit-il exiger un `stripe_payment_intent` ou un `stripe_session_id`
- un booking non paye peut-il rester `pending`
- un booking paye mais non confirme est-il possible
- un meme paiement peut-il etre rattache a plusieurs bookings

### Questions de DB a traiter

- faut-il des `CHECK` conditionnels supplementaires selon `booking_status`
- faut-il une contrainte d'unicite sur `stripe_payment_intent`
- faut-il une contrainte d'unicite sur `stripe_session_id`
- faut-il separer etat de reservation et etat de paiement

## 2. Statut `failed`

### Quand relire cette section

- activation reelle du statut `failed`
- gestion des echecs de paiement
- gestion d'echecs de creation ou de confirmation

### Invariants futurs a verifier

- un booking `failed` doit-il porter une cause de paiement explicite ou une trace annexe
- un booking `failed` peut-il garder un `pending_access_token`
- un booking `failed` doit-il conserver ou non un `confirmation_token`
- un booking `failed` bloque-t-il encore un creneau

### Questions de DB a traiter

- faut-il un champ `failure_reason`
- faut-il des `CHECK` conditionnels propres a `failed`
- faut-il interdire certains champs quand le statut vaut `failed`

## 3. Staff / capacite par enseigne

### Quand relire cette section

- introduction d'une entite `Staff`
- ajout d'une capacite multiple sur un meme creneau
- disponibilite differente selon les personnes

### Invariants futurs a verifier

- un booking devra-t-il etre rattache a un `staff_id`
- un meme creneau pourra exister plusieurs fois si plusieurs staffs sont disponibles
- la contrainte actuelle d'unicite par `enseigne_id + booking_start_time` ne sera alors plus suffisante
- la notion de blocage devra etre recalculée par staff, par capacite, ou par ressource

### Questions de DB a traiter

- faut-il une FK `staff_id` sur `bookings`
- faut-il remplacer l'unicite actuelle par une unicite sur `staff_id + booking_start_time`
- faut-il modeliser la capacite comme une ressource dediee plutot qu'un simple compteur
- faut-il separer disponibilite calculee et disponibilite reservee

## 4. Creneaux fournis par le CRM client

### Quand relire cette section

- reception des disponibilites depuis un CRM
- synchronisation de creneaux externes
- import de ressources ou d'agendas externes

### Invariants futurs a verifier

- la source de verite des creneaux ne sera plus uniquement interne
- il faudra savoir si un creneau vient du moteur ou d'une source externe
- il faudra definir si un booking doit conserver une reference vers le creneau source externe
- il faudra proteger la coherence entre identifiant externe, enseigne, date et disponibilite

### Questions de DB a traiter

- faut-il un champ `external_slot_id`
- faut-il stocker la source du creneau
- faut-il une contrainte d'unicite sur la cle externe recue depuis le CRM
- faut-il historiser les resynchronisations

## 5. Exceptions horaires et calendrier avance

### Quand relire cette section

- fermeture exceptionnelle
- jours feries
- horaires specifiques a une date
- indisponibilites manuelles

### Invariants futurs a verifier

- les horaires hebdomadaires ne suffiront plus comme unique modele
- il faudra prioriser correctement horaires standards et exceptions
- la disponibilite ne devra pas etre derivee d'horaires contradictoires
- le socle hebdomadaire actuel repose seulement sur une deduplication exacte automatique
- les overlaps non triviaux sur horaires hebdomadaires restent volontairement bloquants et non auto-fusionnes

### Questions de DB a traiter

- faut-il une table d'exceptions horaires
- faut-il des contraintes d'unicite par date et enseigne
- faut-il interdire des recouvrements d'exceptions sur une meme ressource

## 6. Annulation / replanification

### Quand relire cette section

- ajout d'un flux d'annulation
- ajout d'un flux de modification de reservation

### Invariants futurs a verifier

- un booking annule bloque-t-il encore un creneau
- faut-il garder l'historique des changements
- la replanification est-elle une mutation du booking ou la creation d'un nouveau booking

### Questions de DB a traiter

- faut-il un statut `cancelled`
- faut-il des timestamps comme `cancelled_at`
- faut-il une table d'historique plutot qu'un simple update en place

## 7. Multi-source et separation des etats

### Quand relire cette section

- ajout de paiements
- ajout de CRM
- ajout de staff
- ajout d'annulation ou reschedule

### Invariants futurs a verifier

- `booking_status` risque de devenir insuffisant comme seul axe de verite
- il faudra peut-etre separer :
- etat de reservation
- etat de paiement
- etat de synchronisation externe

### Questions de conception

- garder un enum unique ou separer plusieurs colonnes d'etat
- garder un modele simple ou introduire des transitions plus explicites

## Checklist de validation avant merge d'un nouveau composant

- le nouveau composant introduit-il un nouvel etat metier
- le nouveau composant ajoute-t-il une nouvelle source de verite
- le nouveau composant change-t-il la granularite de disponibilite
- le nouveau composant rend-il insuffisante une contrainte DB existante
- faut-il ajouter un `CHECK`, une FK, une unicite, ou une nouvelle table support
- le schema protege-t-il encore la realite metier si Rails est contourne

## Resume

Le moteur actuel est coherent pour le MVP actuel.

En revanche, les prochains composants les plus susceptibles d'imposer de nouveaux invariants DB sont :

- paiement
- statut `failed`
- staff / capacite multiple
- disponibilites recues depuis le CRM client
- exceptions horaires
- annulation et replanification

Ce document doit etre traite comme une checklist d'architecture evolutive, pas comme une reference du systeme courant.

Rappel de lecture :

- `failed` ne doit pas etre utilise comme statut fourre-tout pour des erreurs metier ou techniques
- tant que le paiement n'est pas branche, les erreurs de parcours restent des resultats de service non persistants
- cette orientation sur `failed` est preparatoire : elle ne vaut pas cloture definitive des transitions de statut
