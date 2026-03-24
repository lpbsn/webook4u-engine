## 1. Cartographie globale des tests

### Modèles
- Fichiers: `test/models/booking_test.rb`
- Rôle: sécuriser les validations et comportements intrinsèques du modèle `Booking` (états, scopes, méthodes métier).
- Couverture: **métier + technique** (règles de validité, cohérence client/service, scopes SQL).
- Niveau de confiance: **élevé** sur `Booking`, **faible** sur les autres modèles (`Client`/`Service` non testés directement).

### Services
- Fichiers:  
  `test/services/bookings/available_slots_test.rb`  
  `test/services/bookings/create_pending_test.rb`  
  `test/services/bookings/confirm_test.rb`  
  `test/services/bookings/input_test.rb`  
  `test/services/bookings/booking_rules_test.rb`  
  `test/services/bookings/blocking_bookings_test.rb`
- Rôle: cœur de la logique métier de réservation (créneaux, verrouillage fonctionnel, expiration, confirmation, sanitation input, règles temporelles).
- Couverture: **majoritairement métier**, avec une part technique (overlaps SQL/scopes).
- Niveau de confiance: **élevé** sur le domaine booking; **moyen** sur concurrence réelle (lock PostgreSQL peu testé en condition concurrente).

### Contrôleurs
- Fichiers:  
  `test/controllers/bookings_controller_test.rb`  
  `test/controllers/public_clients_controller_test.rb`
- Rôle: vérifier le contrat HTTP (status, redirect, flash, rendu) et les erreurs UX.
- Couverture: **technique HTTP** + comportement observable côté web.
- Niveau de confiance: **élevé** sur les chemins principaux et erreurs courantes.

### Intégration
- Fichiers:  
  `test/integration/booking_flow_test.rb`  
  `test/services/bookings/booking_duplicates_flow_test.rb` *(fichier en `services`, mais de type intégration via `ActionDispatch::IntegrationTest`)*
- Rôle: valider les parcours utilisateur bout en bout.
- Couverture: **métier transverse** (enchaînement réel des couches).
- Niveau de confiance: **élevé** sur le flux principal et anti-doublons; **moyen** sur variations UX périphériques.

---

## 2. Couverture fonctionnelle (prioritaire)

### Flow principal garanti
Le parcours utilisateur complet est couvert de bout en bout dans `test/integration/booking_flow_test.rb` :
- page publique client
- choix service/date et affichage créneaux
- ouverture formulaire sur créneau valide
- création `pending`
- confirmation avec données client
- redirection success + booking final en `confirmed`

### Cas couverts (fichier + niveau)

- **slot valide**
  - `test/integration/booking_flow_test.rb` (**integration**)
  - `test/controllers/bookings_controller_test.rb` (**controller**)
  - `test/services/bookings/create_pending_test.rb` (**service**)

- **slot invalide**
  - `test/controllers/bookings_controller_test.rb` (start_time invalide / hors fenêtre future) (**controller**)
  - `test/services/bookings/create_pending_test.rb` (nil) (**service**)
  - `test/services/bookings/input_test.rb` (parse date/time invalides) (**service**)

- **slot non bookable (hors grille générée)**
  - `test/controllers/bookings_controller_test.rb` (**controller**)
  - `test/services/bookings/create_pending_test.rb` (**service**)

- **slot déjà pris / indisponible**
  - `test/services/bookings/create_pending_test.rb` (**service**)
  - `test/services/bookings/confirm_test.rb` (**service**)
  - `test/services/bookings/booking_duplicates_flow_test.rb` (**integration**)

- **pending expiré**
  - `test/services/bookings/create_pending_test.rb` (ne bloque plus) (**service**)
  - `test/services/bookings/confirm_test.rb` (confirmation refusée) (**service**)
  - `test/controllers/bookings_controller_test.rb` (redirect + flash) (**controller**)

- **confirmation valide**
  - `test/integration/booking_flow_test.rb` (**integration**)
  - `test/controllers/bookings_controller_test.rb` (**controller**)
  - `test/services/bookings/confirm_test.rb` (**service**)

- **confirmation impossible (expiré / déjà confirmé)**
  - `test/controllers/bookings_controller_test.rb` (**controller**)
  - `test/services/bookings/confirm_test.rb` (**service**)

- **doublons**
  - `test/services/bookings/booking_duplicates_flow_test.rb` (**integration**)  
    - refus de créneau déjà confirmé  
    - refus de créneau avec pending actif  
    - pending expiré autorise reprise  
    - protection DB `RecordNotUnique` sur confirmed même slot/client  
    - même slot autorisé pour autre client

---

## 3. Règles métier testées

- **Disponibilité des créneaux**
  - Où: `available_slots_test`, `create_pending_test`, `booking_duplicates_flow_test`
  - Niveau: service + intégration
  - Confiance: **élevée**

- **Overlap bookings**
  - Où: `blocking_bookings_test`, `booking_test` (`slot_blocked?`), `create_pending_test`, `confirm_test`
  - Niveau: service + modèle
  - Confiance: **élevée** (inclut cas frontière end==start)

- **Expiration pending**
  - Où: `booking_rules_test`, `booking_test`, `create_pending_test`, `confirm_test`, `bookings_controller_test`
  - Niveau: service + modèle + contrôleur
  - Confiance: **élevée**

- **Règles de confirmation**
  - Où: `confirm_test`, `bookings_controller_test`, `booking_flow_test`
  - Niveau: service + contrôleur + intégration
  - Confiance: **élevée**

- **Contraintes client/service**
  - Où: `booking_test` (service doit appartenir au client), `booking_duplicates_flow_test` (unicité par client)
  - Niveau: modèle + intégration
  - Confiance: **élevée** sur booking; **moyenne** hors booking.

- **Validation des inputs (date/time)**
  - Où: `input_test`, `public_clients_controller_test`, `bookings_controller_test`
  - Niveau: service + contrôleur
  - Confiance: **élevée**

---

## 4. Architecture technique de la suite

- Séparation nette des responsabilités:
  - **intégration**: parcours utilisateur réels
  - **services**: logique métier pure
  - **modèle**: validations/scopes/règles data
  - **contrôleurs**: contrat HTTP (status, redirect, flash, rendu)
- Très peu de mocks/stubs complexes: forte utilisation d’objets Rails réels et DB réelle.
- Usage systématique de `travel_to` pour fiabiliser les règles temporelles (expiration, fenêtre de réservation, min notice).
- Les assertions évitent souvent le couplage fragile aux textes UI (ex: présence/absence d’éléments plutôt que labels complets).
- Style orienté comportement observable: effets en base + réponse HTTP + redirections, pas de tests “internals”.

---

## 5. Qualité de la suite

### Points forts
- Bonne lisibilité: noms de tests explicites, commentaires utiles, scénarios concrets.
- Cohérence de structure par couche (service/modèle/controller/intégration).
- Robustesse temporelle grâce à `travel_to`.
- Forte valeur métier: couvre les vrais risques (indispo, expiration, conflit, confirmation).
- Défense en profondeur: règles métier + protection DB (unicité).

### Points faibles
- Hétérogénéité de placement: `booking_duplicates_flow_test` est un test d’intégration rangé dans `services`.
- Couverture partielle hors domaine booking (`Client`, `Service`, `PublicPage`, `SlotLock` peu ou pas testés directement).
- Quelques assertions encore dépendantes de messages exacts (moins stable si wording change).
- Peu de validation spécifique sur concurrence réelle (lock advisory PostgreSQL non stress-testé).

---

## 6. Limites actuelles

- Zones métier peu couvertes:
  - `Client` et `Service` (validations/associations non testées directement).
  - `Bookings::PublicPage` non testé en service isolé.
- Cas edge manquants:
  - tests de concurrence multi-thread/process (race réelle sur `SlotLock`).
  - variations timezone/DST.
  - comportements sur durées de service différentes de 30 min.
- Scénarios utilisateur manquants:
  - multi-services complexes sur même client.
  - erreurs 404/invalid slug/service_id en profondeur de parcours.
  - couverture UX “contenu de page” limitée hors page success.

---

## 7. Règles implicites à conserver

- **Pas de tests trompeurs**: chaque test doit refléter un comportement réellement observable.
- **Un scénario = un niveau**: éviter de dupliquer le même risque à tous les étages sans valeur.
- **Pas de couplage à l’implémentation**: tester contrat/effet, pas détails internes.
- **Le test doit casser si le comportement casse**: priorité aux assertions métier (DB + HTTP + flow).
- **Pas de tests “pour faire du vert”**: supprimer/éviter les tests décoratifs sans signal produit.

---

## 8. Synthèse exécutive (10 lignes max)

La suite de tests est globalement **mature** pour un MVP Rails orienté réservation.  
Le cœur métier booking (créneaux, pending, confirmation, conflits, expiration) est **fortement sécurisé**.  
La séparation par couche est claire et cohérente avec la philosophie annoncée.  
Les tests d’intégration garantissent le flow principal utilisateur de bout en bout.  
La fiabilité est **élevée** sur les régressions fonctionnelles critiques.  
Le contrat HTTP est bien couvert (redirect/status/flash), sans sur-mocker.  
La maintenabilité est bonne grâce à des scénarios lisibles et `travel_to`.  
Risques restants: concurrence réelle, couverture partielle de modèles hors booking, certains services annexes non isolés.  
La suite peut évoluer proprement si la discipline “comportement réel d’abord” est maintenue.  
Priorité future: compléter les zones non booking et ajouter des tests de contention/concurrence.