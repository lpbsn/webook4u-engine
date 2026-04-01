# Perimetre Produit

## Objectif

Ce document définit le périmètre produit actuel de Webook4u avec une lecture produit et stratégique.

Son rôle est de garder un cadre clair sur le produit, d’eviter les faux signaux produit, et d’aligner l’equipe sur ce que le produit est aujourd’hui.

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
- la disponibilité est aujourd’hui calculée par Webook4u à partir des horaires et des réservations connues
- chaque enseigne est aujourd’hui traitée comme si elle ne disposait que d’une seule capacité de réservation à un instant donné

Ce dernier point est important :

- un créneau correspond actuellement à une seule capacité disponible par enseigne
- le système ne modélise pas encore plusieurs membres du staff disponibles sur le même créneau

Cette simplification est volontaire dans l'etat actuel du produit.

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

Ces sujets n'appartiennent pas au périmètre actif

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
- le périmètre livré peut paraître plus avancé qu’il ne l’est réellement

Réalité actuelle :

- ces champs sont des réserves de schéma sans rôle actif aujourd'hui
- ils ne participent pas au flux actif

### Le statut `failed` peut faire croire à un cycle de vie déjà complet

Le modèle de réservation expose déjà un état `failed`.

Risque :

- l’équipe peut commencer à raisonner comme si les échecs de paiement ou de réservation étaient déjà intégrés au produit

Réalité actuelle :

- le cycle de vie actif repose en pratique sur `pending` et `confirmed`
- `failed` n'appartient pas au flux utilisateur actif
- les erreurs de réservation actuelles ne doivent pas être persistées sous `failed`

### La capacité actuelle peut être prise pour le modèle métier définitif

Le moteur actuel se comporte comme si une enseigne ne pouvait absorber qu’une seule réservation à la fois sur un créneau donné.

Risque :

- l’implémentation actuelle peut être prise pour le vrai modèle métier
- certaines décisions peuvent être prises comme si l’unicité d’un créneau par enseigne était une règle définitive

Réalité actuelle :

- c’est une simplification pour stabiliser le moteur de réservation
- elle ne doit pas être lue comme une preuve que l’unicité par enseigne est la règle métier définitive

### Le calcul interne des créneaux peut être pris pour la source définitive des disponibilités

Aujourd’hui, les créneaux sont calculés en interne à partir des horaires et des réservations connues de l’application.

Risque :

- l’équipe peut sur-adapter l’architecture à un modèle où l’application reste l’unique source de vérité des disponibilités

Réalité actuelle :

- aujourd’hui, Webook4u reste le mode actif de calcul de disponibilité
- cette lecture ne change pas l’invariant cross-table actuel de `Booking`

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

## Garde-fous de lecture

Ces points servent seulement à éviter les mauvaises lectures du repo :

- ne pas déduire un paiement actif de l’affichage du prix, des champs Stripe ou du statut `failed`
- ne pas déduire un modèle multi-staff actif de la structure actuelle
- ne pas projeter une source externe de disponibilités dans le fonctionnement courant tant qu’elle n’est pas implementee

## Résumé

Webook4u est aujourd’hui un moteur de réservation avec une promesse volontairement étroite :

- trouver un créneau
- le maintenir brièvement
- confirmer une réservation

Il ne couvre pas encore :

- le paiement
- un cycle de vie métier complet de réservation
- les capacités multi-staff
- l’ingestion native des disponibilités depuis le CRM client
