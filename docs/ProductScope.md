# Perimetre Produit

## Objectif

Ce document définit le périmètre produit actuel de Webook4u avec une lecture produit et stratégique.

Son rôle est de garder un cadre clair sur le produit, d’éviter les faux signaux produit, et d’aligner l’équipe sur ce que le produit est aujourd’hui, ce qu’il n’est pas encore, et ce qu’il prépare pour la suite.

## Intention produit

Webook4u est aujourd’hui un moteur de réservation public simple.

L’objectif actuel n’est pas de construire une plateforme complète de réservation.
L’objectif actuel est de rendre fiable la sélection, le blocage temporaire et la confirmation d’un créneau, afin de pouvoir itérer vite sans construire une base fragile.

Dans son état actuel, le produit doit surtout bien faire une chose :

- permettre à un utilisateur final de réserver un créneau via un tunnel public court et compréhensible

## Promesse actuelle

Aujourd’hui, la promesse produit est la suivante :

- choisir un lieu
- choisir une prestation
- choisir une date
- choisir un créneau disponible
- confirmer une réservation

Il s’agit d’un moteur de réservation.
Ce n’est pas encore un moteur de paiement.
Ce n’est pas encore un moteur d’opérations.
Ce n’est pas encore un moteur de gestion de planning staff.

## Ce que le produit supporte réellement aujourd’hui

Le produit supporte actuellement :

- une page publique accessible via un `slug` client
- la sélection d’une enseigne
- la sélection d’une prestation
- la sélection d’une date
- l’affichage des créneaux disponibles
- le blocage temporaire d’un créneau via une réservation `pending`
- la confirmation d’une réservation avec prénom, nom et email
- une page de succès après confirmation

## Hypothèses stratégiques actuel

Webook4U repose actuellement sur les hypothèses suivantes :

- les prestations sont partagées entre toutes les enseignes d’un même client
- les horaires peuvent encore venir du niveau `client` comme fallback temporaire
- la cible produit reste un modèle de disponibilité piloté par `enseigne`
- la disponibilité est aujourd’hui calculée par Webook4u à partir des horaires et des réservations connues
- chaque enseigne est aujourd’hui traitée comme si elle ne disposait que d’une seule capacité de réservation à un instant donné

Ce dernier point est important :

- un créneau correspond actuellement à une seule capacité disponible par enseigne
- le système ne modélise pas encore plusieurs membres du staff disponibles sur le même créneau

Cette simplification est volontaire pour l'instant.
Elle n’est pas le modèle cible du produit.

## Ce que le produit ne promet pas encore

Le produit ne promet pas encore :

- le paiement en ligne
- une validation du paiement avant confirmation de réservation
- la gestion des échecs de paiement
- l’usage du statut `failed` dans le flux utilisateur
- l’annulation
- la replanification
- un espace client
- des workflows de back-office opérationnel
- la gestion de plusieurs staffs disponibles sur un même créneau
- l’ingestion de créneaux directement depuis le CRM du client

Ces sujets appartiennent à la suite du produit, pas au périmètre actif

## Principaux risques de mauvaise interprétation produit

### L’affichage du prix peut faire croire à un paiement

L’interface affiche aujourd’hui un prix et un wording proche de `Montant à payer`.

Risque :

- des parties prenantes peuvent croire que l'appli inclut déjà le paiement
- des utilisateurs peuvent comprendre que la réservation dépend d’un checkout en ligne
- les discussions produit peuvent partir d’une perception trop avancée de ce qui est réellement livré

Réalité actuelle :

- le prix est uniquement informatif
- la confirmation actuelle est une confirmation de réservation, pas une confirmation de paiement

### La présence de champs Stripe peut faire croire à un scope paiement actif

Le modèle de données contient déjà des champs liés à Stripe.

Risque :

- l’équipe peut croire que Stripe fait déjà partie du flux produit
- la roadmap peut paraître plus avancée qu’elle ne l’est réellement

Réalité actuelle :

- ces champs sont des réserves pour une phase ultérieure
- ils ne participent pas au flux actif

### Le statut `failed` peut faire croire à un cycle de vie déjà complet

Le modèle de réservation expose déjà un état `failed`.

Risque :

- l’équipe peut commencer à raisonner comme si les échecs de paiement ou de réservation étaient déjà intégrés au produit

Réalité actuelle :

- le cycle de vie actif repose en pratique sur `pending` et `confirmed`
- `failed` appartient à une étape produit ultérieure

### La capacité actuelle peut être prise pour le modèle cible

Le moteur actuel se comporte comme si une enseigne ne pouvait absorber qu’une seule réservation à la fois sur un créneau donné.

Risque :

- l’implémentation actuelle peut être prise pour le vrai modèle métier cible
- certaines décisions peuvent être prises comme si l’unicité d’un créneau par enseigne était une règle définitive

Réalité actuelle :

- c’est une simplification pour stabiliser le moteur de réservation
- à terme, le produit devra intégrer la notion de staff disponible
- un même créneau pourra exister plusieurs fois si plusieurs staffs sont disponibles dans la même enseigne

### Le calcul interne des créneaux peut être pris pour la source définitive des disponibilités

Aujourd’hui, les créneaux sont calculés en interne à partir des horaires et des réservations connues de l’application.

Risque :

- l’équipe peut sur-adapter l’architecture à un modèle où l’application reste l’unique source de vérité des disponibilités

Réalité actuelle :

- aujourd’hui, Webook4u reste le mode actif de calcul de disponibilité
- à terme, les créneaux pourront aussi être reçus directement depuis le CRM du client
- certains clients pourront conserver le mode interne, d’autres imposer une source CRM
- le moteur doit donc être pensé comme un système capable d’intégrer des disponibilités externes, et pas seulement de les générer en interne
- cette future variation de source ne change pas l’invariant cross-table actuel de `Booking`

## Narration produit correcte

La bonne manière de décrire le produit aujourd’hui est :

- Webook4u est un moteur de réservation public
- le système maintient temporairement un créneau avant confirmation
- une réservation peut être confirmée sans paiement
- le prix affiché est actuellement informatif
- les prestations restent aujourd’hui définies au niveau du client
- l’enseigne porte le contexte concret de réservation et de disponibilité
- les horaires au niveau `client` sont un fallback transitoire
- la disponibilité est actuellement calculée en interne par Webook4u
- la capacité actuelle est volontairement simplifiée à un staff implicite par enseigne
- les disponibilités pourront plus tard venir aussi de systèmes externes comme les CRM clients

## Direction stratégique

Le prochain palier produit utile n’est pas une grande refonte.
La bonne direction est de solidifier le cœur de réservation actuel tout en gardant le modèle futur ouvert.

La stratégie doit être :

- fiabiliser le moteur actuel de réservation
- réduire les faux signaux dans le wording et la communication produit
- clarifier partout la promesse réelle du produit
- garder le domaine prêt pour la future notion de capacité / staff
- garder le domaine prêt pour l’intégration future de disponibilités externes
- n’ajouter le paiement qu’après cette stabilisation

## Trajectoire d’évolution produit

La trajectoire la plus logique est :

1. stabiliser le flux public de réservation et de confirmation
2. supprimer les ambiguïtés de wording produit
3. clarifier le domaine autour des enseignes et de la disponibilité
4. préparer la prise en compte de capacités multiples / multi-staff
5. préparer l’ingestion de créneaux depuis les CRM clients
6. ajouter le paiement et les états d’échec associés

## Résumé

Webook4u est aujourd’hui un moteur de réservation avec une promesse volontairement étroite :

- trouver un créneau
- le maintenir brièvement
- confirmer une réservation

Le produit actuel est volontairement plus simple que le modèle cible.

Il ne couvre pas encore :

- le paiement
- un cycle de vie métier complet de réservation
- les capacités multi-staff
- l’ingestion native des disponibilités depuis le CRM client
