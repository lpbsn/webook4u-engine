# Plan de refonte de la suite de tests — webook4u-engine

**Basé sur** : `doc/AuditTests.md`  
**Objectif** : plan actionnable par lots, avec décisions explicites fichier par fichier.

---

## 1. Analyse structurée des fichiers de test

Pour chaque fichier : type, couverture, valeur, confiance, **décision obligatoire**.

| # | Fichier | Type | Couverture réelle | Valeur | Confiance | Décision |
|---|---------|------|-------------------|--------|-----------|----------|
| 1 | `test/models/booking_test.rb` | model | Validations (présence, conditionnelles, end > start, service même client), `expired?`, `confirmable?`, scopes `active_pending` / `blocking_slot`, cohérence `BookingRules.booking_expired?`, `slot_blocked?` (Availability). | Élevée | Fragile (assertions sur messages "can't be blank", etc.) | **Améliorer** : garder les scénarios ; plus tard, remplacer les assert sur le texte des erreurs par assert sur les clés d’erreur (`booking.errors[:attr].any?`). |
| 2 | `test/models/client_test.rb` | model | Aucune (fichier vide, commentaire "the truth"). | Faible | — | **Supprimer** : supprimer le fichier ou vider la classe et laisser un commentaire "No tests yet; add when validations or behavior exist." Pour un MVP, **supprimer le fichier** est recommandé. |
| 3 | `test/models/service_test.rb` | model | Aucune (fichier vide). | Faible | — | **Supprimer** : même règle que `client_test.rb`. |
| 4 | `test/services/bookings/rate_limit_test.rb` | service | (1) Fallback quand `Rails.cache.increment` retourne nil (mock). (2) ENV parsing (nil, empty, non-numeric) → valeurs par défaut. | (1) Faible (2) Moyenne | (1) Trompeur (2) Fiable | **Améliorer** : **supprimer** le test (1). **Garder** le test (2). Voir encadré "Décision rate_limit_test" ci-dessous. |
| 5 | `test/services/bookings/booking_rules_test.rb` | service | Constantes (slot_duration, day_start/end, min_notice, max_future_days, pending_expiration), `minimum_bookable_time`, `pending_expires_at`, `bookable_day?`, `booking_expired?`. | Élevée | Fiable | **Garder tel quel**. |
| 6 | `test/services/bookings/available_slots_test.rb` | service | Weekend vide, jour ouvré avec créneaux, min bookable time, exclusion confirmed/pending actif, réintégration pending expiré, blocage avant premier slot, overlap jour précédent. | Élevée | Fiable | **Garder tel quel**. |
| 7 | `test/services/bookings/create_pending_test.rb` | service | Slot valide, nil, slot non bookable, slot occupé (confirmed / pending actif), overlap partiel, bordure (fin = début), pending expiré autorise. | Élevée | Fiable | **Améliorer** : ajouter des messages d’assertion (3e argument) sur les assertions critiques (`result.success?`, `result.error_code`, `assert_includes` sur slots/booking). Aucun changement de scénario. |
| 8 | `test/services/bookings/confirm_test.rb` | service | Confirm OK, déjà confirmed, expiré, slot pris par un autre, overlap, bordure, formulaire invalide. | Élevée | Fiable | **Garder tel quel**. |
| 9 | `test/services/bookings/blocking_bookings_test.rb` | service | `overlapping` et `intervals_for_range` pour créneaux bloquants. | Élevée | Fiable | **Garder tel quel**. |
| 10 | `test/services/bookings/input_test.rb` | service | `safe_date` / `safe_time` : blank, format valide, passé, au-delà de max_future_days, format invalide. | Élevée | Fiable | **Garder tel quel**. |
| 11 | `test/services/bookings/bookings_flow_test.rb` | integration (ActionDispatch) | new crée pending, new redirect (invalid, not bookable, beyond max_future_days), create confirme, create redirect (expiré, déjà confirmé). | Moyenne | Fiable | **Fusionner** : les scénarios sont en doublon avec `BookingsControllerTest` et `test/integration/booking_flow_test.rb`. Décision : **supprimer ce fichier** après avoir vérifié que chaque scénario est couvert soit par `test/integration/booking_flow_test.rb`, soit par `test/controllers/bookings_controller_test.rb`. Les cas manquants éventuels seront ajoutés dans le fichier d’intégration ou le contrôleur, pas ici. |
| 12 | `test/controllers/bookings_controller_test.rb` | controller (integration) | GET #new (slot valide, start_time invalide, slot indisponible), POST #create (valide, formulaire invalide, non confirmable), GET #success (OK, 404 autre client). | Moyenne | Fiable | **Améliorer** : garder le fichier ; après consolidation (Lot 3), supprimer uniquement les tests qui sont des doublons **stricts** du flow d’intégration. Conserver les cas spécifiques contrôleur : 404 success, 422 form invalid, messages flash. Ne pas tout supprimer. |
| 13 | `test/controllers/public_clients_controller_test.rb` | controller | (1) show retourne 200 pour un slug valide. (2) date au-delà de max_future_days → pas de créneaux (assert sur "Date :" et "—"). | Moyenne | Fragile (2) | **Améliorer** : (1) **Renommer** "should get show" en "GET show returns success for valid client slug". (2) Plus tard : remplacer les assert sur "Date :" / "—" par un critère stable (ex. absence de liste de créneaux ou variable d’instance). |
| 14 | `test/integration/booking_flow_test.rb` | integration | Flow complet : page publique → slots → GET new (pending) → POST confirm → success ; vérification état en base et contenu page success. | Élevée | Fiable | **Garder tel quel** + **Améliorer** : ajouter des messages d’assertion sur 2–3 assertions critiques (ex. `assert result.success?`, `assert_includes response.body, ...`). Ce fichier est la **référence** du flow ; ne pas le fusionner avec un autre. |
| 15 | `test/integration/booking_rate_limit_test.rb` | integration | GET new avec quota pending = 0 → pas de création, redirect + message. POST create avec quota confirm = 0 → 429 + message, booking reste pending. | Élevée | Fiable | **Garder tel quel**. |
| 16 | `test/services/bookings/booking_duplicates_flow_test.rb` | integration | new refuse créneau confirmé / pending actif ; new autorise si pending expiré ; create refuse si slot pris entre-temps ; contrainte unique DB ; autre client peut prendre le même créneau. | Élevée | Fiable | **Garder tel quel**. |

**Récapitulatif des décisions** :
- **Garder tel quel** : 6 fichiers (booking_rules, available_slots, confirm, blocking_bookings, input, booking_rate_limit_test integration).
- **Améliorer** : 6 fichiers (booking_test, rate_limit_test, create_pending_test, bookings_controller_test, public_clients_controller_test, booking_flow_test integration).
- **Supprimer** : 2 fichiers (client_test, service_test).
- **Fusionner / Supprimer** : 1 fichier (bookings_flow_test → supprimer après vérification de couverture).

---

#### Décision explicite : `rate_limit_test.rb` (test "falls back when cache increment returns nil")

- **Décision** : **Supprimer** ce test. **Ne pas le remplacer** par un autre test unitaire.
- **Pourquoi il n’a pas de valeur** :
  - Il mocke `Rails.cache.increment` pour forcer le chemin "fallback" (read/write). Il ne vérifie pas un comportement utilisateur : l’utilisateur ne voit jamais "le cache a retourné nil".
  - Il est **trop couplé à l’implémentation** : si vous changez la stratégie de fallback (ex. refuser au lieu d’accepter quand increment échoue), le test peut rester vert alors que le comportement réel change, ou casser alors que le comportement utilisateur reste correct.
  - Il n’est **pas représentatif du comportement réel** : en conditions réelles, le comportement "trop de tentatives → pas de création / 429" est déjà couvert par `test/integration/booking_rate_limit_test.rb` (quota à 0, pas de mock). Ce test unitaire ne protège donc pas l’utilisateur.
- **Remplacement** : Aucun. Le comportement "rate limit actif" est déjà garanti par les tests d’intégration. Aucun nouveau test à ajouter.

---

## 2. Regroupement en lots de refonte

### Lot 1 — Suppression du test trompeur + améliorations secondaires

| Élément | Détail |
|--------|--------|
| **Objectif** | Supprimer le seul test trompeur (impact fiabilité), puis améliorations de lisibilité ciblées. |
| **Fichiers concernés** | `test/services/bookings/rate_limit_test.rb`, `test/controllers/public_clients_controller_test.rb`, `test/services/bookings/create_pending_test.rb`, `test/integration/booking_flow_test.rb` |
| **Risque** | Faible |
| **Gain attendu** | Élevé pour la suppression du trompeur ; moyen pour le reste. |

**Priorisation des actions au sein du Lot 1** :

| Priorité | Action | Fichier | Justification |
|----------|--------|---------|---------------|
| **Critique** | Supprimer le test "falls back when cache increment returns nil" | `rate_limit_test.rb` | Impact direct sur la fiabilité : ce test donne une fausse confiance et est couplé à l’implémentation. |
| **Important** | Ajouter messages d’assertion (3e argument) sur 3 assertions | `create_pending_test.rb` | Améliore la lisibilité des échecs sur un fichier métier clé. |
| **Important** | Ajouter messages d’assertion sur 2 assertions | `booking_flow_test.rb` (integration) | Même raison sur le flow de référence. |
| **Cosmétique** | Renommer "should get show" en "GET show returns success for valid client slug" | `public_clients_controller_test.rb` | Améliore la clarté du nom uniquement ; aucun impact sur la fiabilité. |

**Actions concrètes** (dans l’ordre ci‑dessus) :
1. **Critique** — Dans `rate_limit_test.rb` : supprimer entièrement le bloc `test "falls back when cache increment returns nil" do ... end`. Ne pas modifier le test "env parsing is safe...". Puis lancer `rails test` → 105 tests verts.
2. **Important** — Dans `create_pending_test.rb` : ajouter un message (3e argument) à au moins 3 assertions : (a) le premier `assert result.success?` du test "creates a pending booking for a valid slot", (b) un `assert_not result.success?` ou `assert_equal ... result.error_code` dans un test d’échec, (c) une assertion sur le booking. Ex. : `assert result.success?, "CreatePending should succeed for valid slot; error=#{result.error_code}"`.
3. **Important** — Dans `booking_flow_test.rb` : ajouter un message à 2 assertions (ex. après création pending et après confirmation).
4. **Cosmétique** — Dans `public_clients_controller_test.rb` : renommer le test `"should get show"` en `"GET show returns success for valid client slug"`. Aucun autre changement.

---

### Lot 2 — Suppression des fichiers sans valeur

| Élément | Détail |
|--------|--------|
| **Objectif** | Supprimer les fichiers de test vides qui n’apportent aucune couverture. |
| **Fichiers concernés** | `test/models/client_test.rb`, `test/models/service_test.rb` |
| **Actions concrètes** | 1) Supprimer le fichier `test/models/client_test.rb`. 2) Supprimer le fichier `test/models/service_test.rb`. 3) Lancer la suite : `rails test`. Vérifier qu’aucun autre fichier ne requiert ces classes (grep ou chargement explicite). Si des références existent (ex. `require` ou chargement par nom), les retirer. |
| **Risque** | Faible |
| **Gain attendu** | Moyen (suite plus claire, moins de faux fichiers) |

---

### Lot 3 — Consolidation des tests d’intégration / contrôleur

| Élément | Détail |
|--------|--------|
| **Objectif** | Un scénario métier = un seul niveau de test ; supprimer les doublons et appliquer la règle de répartition intégration vs contrôleur. |
| **Fichiers concernés** | `test/services/bookings/bookings_flow_test.rb`, `test/controllers/bookings_controller_test.rb`, `test/integration/booking_flow_test.rb` |
| **Risque** | Moyen (inventaire à faire soigneusement) |
| **Gain attendu** | Élevé (maintenance simplifiée, plus de fausse couverture). |

**Règle obligatoire : répartition intégration vs contrôleur**

- **Tests d’intégration** (`test/integration/*`) : **source de vérité** des flows utilisateur complets (parcours HTTP de bout en bout : page publique → choix → new → confirm → success). Ils valident le comportement réel perçu par l’utilisateur.
- **Tests contrôleur** (`test/controllers/*`) : **uniquement** :
  - statuts HTTP spécifiques (404, 422, 429),
  - redirections et URLs cibles,
  - gestion d’erreurs (flash, message d’erreur),
  - cas techniques non couverts par l’intégration (ex. GET #success retourne 404 quand le booking n’appartient pas au client).
- **Règle** : **Un scénario métier ne doit exister que dans un seul niveau de test.** Si le même scénario (ex. "new avec slot invalide → redirect + message") existe en intégration et en contrôleur, c’est un doublon. **On conserve l’intégration** (comportement réel) et **on supprime le doublon côté contrôleur**, sauf si le test contrôleur apporte un élément technique non couvert (ex. assertion explicite sur le status 302 ou sur l’URL exacte). Si le doublon est dans `bookings_flow_test.rb` et déjà couvert par `booking_flow_test.rb` ou `bookings_controller_test.rb` : **on supprime le test dans `bookings_flow_test.rb`** (et à terme le fichier entier), car ce fichier est redondant avec les deux autres.

**En cas de doublon : lequel supprimer ?**

| Situation | Fichier / test à supprimer | Raison |
|-----------|----------------------------|--------|
| Même scénario dans `bookings_flow_test.rb` et dans `booking_flow_test.rb` (integration) | Supprimer celui dans `bookings_flow_test.rb` | L’intégration dans `test/integration/` est la source de vérité du flow ; le fichier "bookings_flow" dans services est mal placé et duplique. |
| Même scénario dans `bookings_flow_test.rb` et dans `bookings_controller_test.rb` | Supprimer celui dans `bookings_flow_test.rb` | Le contrôleur garde les cas techniques (status, redirect) ; le flow métier complet reste dans l’intégration. |
| Même scénario "flow métier" dans `bookings_controller_test.rb` et dans `booking_flow_test.rb` | Supprimer le doublon dans `bookings_controller_test.rb` (garder l’intégration) | Un scénario métier complet = intégration. Le contrôleur ne garde que ce qui est spécifique (ex. "GET #success returns 404 when booking does not belong to client"). |

**Actions concrètes** :
1. **Inventaire** : lister chaque test de `bookings_flow_test.rb` et noter s’il est couvert par `booking_flow_test.rb` ou `bookings_controller_test.rb` (même comportement).
2. Pour chaque test de `bookings_flow_test.rb` : si couvert → rien à ajouter ailleurs. Si non couvert → ajouter le cas manquant dans `test/integration/booking_flow_test.rb` (si flow complet) ou dans `test/controllers/bookings_controller_test.rb` (si cas technique uniquement).
3. **Supprimer** le fichier `test/services/bookings/bookings_flow_test.rb`.
4. Dans `bookings_controller_test.rb` : supprimer **uniquement** les tests qui sont des doublons **stricts** d’un scénario déjà couvert par `booking_flow_test.rb` (integration). Conserver tous les tests qui apportent un élément technique (404, 422, redirect, flash).
5. Relancer `rails test` et vérifier le nombre de tests (cohérent avec les suppressions).

---

### Lot 4 — Amélioration lisibilité / nommage (ciblée)

| Élément | Détail |
|--------|--------|
| **Objectif** | Améliorer noms et messages d’assertion **uniquement** sur les tests déjà modifiés (dans un lot, un bugfix ou un nouveau test) ou sur les tests critiques. **Pas de refonte cosmétique globale.** |
| **Fichiers concernés** | Uniquement les fichiers **déjà touchés** pour une autre raison (lot 1–3, bugfix, nouveau test) ou les tests **critiques** (ex. flow complet, rate limit). Pas de passe sur l’ensemble des fichiers. |
| **Risque** | Faible (incrémental) |
| **Gain attendu** | Moyen (lisibilité là où c’est utile). |

**Règle explicite : pas de refonte cosmétique globale**

- Ne **pas** appliquer renommage ou messages d’assertion sur **tous** les tests du projet en une seule fois.
- **Appliquer** les améliorations de lisibilité **uniquement** dans les cas suivants :
  1. **Tests modifiés dans le cadre d’un lot** (ex. dans Lot 1 on touche à `create_pending_test.rb` et `booking_flow_test.rb` → on peut y ajouter des messages d’assertion).
  2. **Nouveaux tests** : pour chaque nouveau test, utiliser un nom explicite et un message sur les assertions critiques.
  3. **Tests critiques** : si vous travaillez sur un fichier contenant des tests critiques (flow complet, rate limit, doublons), vous pouvez ajouter des messages d’assertion aux assertions clés de **ce fichier** uniquement.
- Ne **pas** ouvrir un fichier **uniquement** pour renommer des tests ou ajouter des messages sans autre modification.

**Actions concrètes** (au fil de l’eau) :
1. Lors d’une modification dans un fichier de test : pour chaque **nouveau** test, nom explicite (ex. "when X then Y"). Pour chaque assertion critique **ajoutée ou modifiée**, message en 3e argument.
2. Ne **pas** lancer une passe dédiée de renommage ou de messages sur l’ensemble des fichiers existants.

---

### Lot 5 — Découpler le modèle Booking des messages d’erreur exacts

| Élément | Détail |
|--------|--------|
| **Objectif** | Rendre les tests du modèle Booking insensibles à l’I18n et aux changements de libellé. |
| **Fichiers concernés** | `test/models/booking_test.rb` |
| **Actions concrètes** | 1) Remplacer chaque `assert_includes booking.errors[:attr], "can't be blank"` par `assert_not booking.valid?` + `assert booking.errors[:attr].any?` (ou équivalent selon l’API Minitest). 2) Remplacer les assert sur "must be after booking_start_time" et "must belong to the same client" par une assertion sur la présence d’erreur sur l’attribut : `assert booking.errors[:booking_end_time].any?` et `assert booking.errors[:service].any?`. 3) Pour "confirmed booking requires valid email format" : garder `assert_not booking.valid?` et `assert booking.errors[:customer_email].any?`. 4) Relancer les tests du modèle : `rails test test/models/booking_test.rb`. |
| **Risque** | Moyen (changement d’assertions ; vérifier que le comportement reste le même) |
| **Gain attendu** | Moyen (stabilité à l’introduction de l’I18n, moins de couplage au texte) |

---

### Lot 6 — Assertion stable pour "date rejetée" (page publique)

| Élément | Détail |
|--------|--------|
| **Objectif** | Ne plus dépendre du libellé HTML "Date :" et "—" pour vérifier qu’une date au-delà de max_future_days est rejetée. |
| **Fichiers concernés** | `test/controllers/public_clients_controller_test.rb` |
| **Actions concrètes** | 1) Analyser la page publique : quand la date est rejetée (`Bookings::Input.safe_date` nil), quel élément du DOM ou quelle variable d’instance indique qu’aucun créneau n’est affiché ? (ex. absence d’une liste de créneaux, ou présence d’un message générique.) 2) Remplacer `assert_includes response.body, "Date :"` et `assert_includes response.body, "—"` par une assertion sur ce critère stable (ex. `assert_select` sans créneaux, ou `assert_not_includes response.body, "10:00"` si les créneaux ne doivent pas apparaître). Documenter le choix dans un commentaire au-dessus du test. 3) Relancer `rails test test/controllers/public_clients_controller_test.rb`. |
| **Risque** | Faible |
| **Gain attendu** | Moyen (test moins fragile aux changements de copy) |

---

## 3. Priorisation globale

**Distinction des priorités** :
- **Critique** = impact direct sur la fiabilité (ex. suppression d’un test trompeur). À faire en premier.
- **Important** = gain réel (lisibilité des échecs, consolidation) mais pas de test trompeur en jeu.
- **Cosmétique** = clarté ou cohérence uniquement (ex. renommage "should get show") ; aucun impact sur la fiabilité. À faire si on touche déjà au fichier.

| Ordre | Lot | Nature | Justification |
|-------|-----|--------|---------------|
| **1** | Lot 1 (dont action critique : supprimer test RateLimit) | Critique + important + cosmétique | La seule action **critique** du plan : supprimer le test trompeur. Le reste du Lot 1 (messages d’assertion, renommage) est important ou cosmétique. |
| **2** | Lot 2 — Suppression fichiers vides | Important | Nettoyage ; pas de fausse couverture. Risque faible. |
| **3** | Lot 3 — Consolidation | Important | Un scénario = un niveau ; moins de duplication. Risque moyen (inventaire). |
| **4** | Lot 4 — Lisibilité / nommage | Règle continue (pas un lot "à faire avant les autres") | À appliquer **uniquement** sur les tests modifiés ou critiques ; pas de refonte cosmétique globale. |
| **5** | Lot 5 — Découpler Booking | Optionnel à court terme | Utile à l’I18n ou à la modification des messages. |
| **6** | Lot 6 — Assertion stable date | Optionnel | Quand vous retravaillez la page publique. |

**Résumé** : exécuter dans l’ordre **Lot 1 → Lot 2 → Lot 3**. Dans Lot 1, faire **d’abord** l’action critique (suppression du test trompeur). Lots 4 (règle continue), 5 et 6 selon besoin.

---

## 4. Stratégie cible (rappel synthétique)

- **Intégration** : Garantir le comportement réel perçu par l’utilisateur. Peu de tests, mais qui parcourent le flow HTTP (public → new → confirm → success) et les cas d’erreur clés (slot invalide, expiré, rate limit). Référence = `test/integration/booking_flow_test.rb` (+ rate limit + doublons).
- **Services** : Tester les entrées/sorties et l’état en base ; pas de mock d’implémentation (ex. cache). Règles et sanitization (BookingRules, Input) en unitaire pur ; CreatePending, Confirm, AvailableSlots, BlockingBookings avec DB réelle.
- **Modèle** : Validations et méthodes métier (expired?, confirmable?, scopes). Préférer assert sur **présence d’erreur sur un attribut** plutôt que sur le texte du message.
- **Contrôleur** : Cas spécifiques (status 404, 422, 429, flash). Éviter de dupliquer les scénarios déjà couverts par l’intégration.

**Nommage** : Une convention (ex. "when X then Y") dans une seule langue ; noms explicites, pas "should get show".

**Structure** : Sections par groupe logique (GET #new, POST #create, Validations, etc.) ; setup partagé.

**Éviter les tests trompeurs** : Ne pas tester un chemin d’implémentation sans lien avec le comportement utilisateur. Si en cassant le comportement sur localhost le test reste vert → revoir ou supprimer le test.

**Messages d’erreur lisibles** : Message en 3e argument sur les assertions critiques (contexte + comportement attendu). Pas d’excès : pas de message sur chaque `assert_equal` trivial. À appliquer **uniquement** sur les tests modifiés ou critiques (pas de passe globale).

**Anti-dérives** : Voir section 5 (règles d’exécution) : pas de couverture artificielle, supprimer les tests inutiles plutôt que les corriger, pas de couplage à l’implémentation, privilégier le comportement réel, ne pas modifier l’app uniquement pour un test.

---

## 5. Règles d’exécution et anti-dérives

**Règles obligatoires** (pour éviter les dérives) :

1. **Ne pas augmenter la couverture artificiellement** : pas de tests ajoutés "pour faire du vert" ou pour gonfler un pourcentage. Privilégier la valeur métier ; peu de tests, mais les bons.
2. **Supprimer les tests inutiles plutôt que les corriger** : si un test n’a pas de valeur (trompeur, vide, redondant), le supprimer. Ne pas le "réparer" pour le garder.
3. **Éviter les tests trop couplés à l’implémentation** : ne pas mocker des détails internes (cache, méthodes privées) pour tester un chemin ; préférer l’intégration ou le comportement observable.
4. **Privilégier les tests qui reflètent le comportement réel utilisateur** : intégration (flow HTTP) et services avec DB réelle ; un test doit échouer si on casse le comportement sur localhost.
5. **Ne pas modifier le code applicatif uniquement pour satisfaire un test** : la refonte porte sur les **tests**. Modifier l’app uniquement si c’est justifié par un besoin métier ou un bug (ex. exposer un indicateur stable pour Lot 6 si vraiment nécessaire).
6. **Un scénario métier = un seul niveau de test** : pas de doublon entre intégration et contrôleur pour le même scénario (voir Lot 3).
7. **Ne pas renommer tous les tests d’un coup** : renommage et messages d’assertion uniquement sur les fichiers déjà modifiés (lot, bugfix, nouveau test) ou sur les tests critiques ; pas de refonte cosmétique globale.
8. **Lots petits et vérifiables** : après chaque lot, lancer `rails test` et vérifier que tout est vert.

---

**Règles stratégiques globales** (sécuriser l’exécution dans le temps) :

- **Tests techniques (mécanismes internes)**  
  Les tests ne doivent **pas** valider des mécanismes internes (cache, fallback, implémentation privée) **sauf si** ces mécanismes ont un **impact observable côté utilisateur**.  
  *Pourquoi* : éviter les tests trompeurs (un test vert alors que le comportement utilisateur est cassé) et le couplage à l’implémentation (refacto interne fait casser un test sans changement de comportement). Si l’impact est observable (ex. rate limit actif → pas de création, 429), le tester au niveau intégration, pas en mockant le cache.

- **Sécurisation des suppressions (Lot 3 et toute suppression de test)**  
  **Avant** de supprimer un test : (1) vérifier qu’un test **équivalent** existe ailleurs, et (2) qu’il couvre le **même comportement observable** (même résultat utilisateur ou même effet en base / HTTP).  
  Si aucun test équivalent n’existe : **ne pas supprimer** ; **ajouter d’abord** le test manquant au bon niveau (intégration ou contrôleur selon la règle du Lot 3), puis supprimer le doublon.

- **Règle de validation ultime**  
  **Un test doit échouer si on casse le comportement réel sur localhost.**  
  Si ce n’est pas le cas (ex. on casse l’affichage ou le flow et le test reste vert), le test est **trompeur** : il doit être **supprimé** ou **réécrit** pour qu’il reflète ce comportement réel. Cette règle s’applique à tout nouveau test et à tout test modifié ; en cas de doute sur un test existant, l’utiliser comme critère de décision (garder / réécrire / supprimer).

---

## 6. Première itération recommandée (100 % exécutable)

**Objectif** : Réaliser la **seule action critique** du plan (suppression du test trompeur), vérifiable immédiatement. Limite : **2 fichiers maximum** pour cette itération.

---

### Itération 1a — Action critique (1 fichier, obligatoire)

| Élément | Détail |
|--------|--------|
| **Fichier** | `test/services/bookings/rate_limit_test.rb` |
| **Action** | Supprimer **uniquement** le bloc suivant (du `test` jusqu’au `end` inclus) : le test dont le nom est exactement `"falls back when cache increment returns nil"`. Ne pas toucher au test `"env parsing is safe for nil, empty and non-numeric values"`. |
| **Résultat attendu** | Suite inchangée pour le reste : `rails test` → **105 tests**, **0 failures**, **0 errors**. (Aujourd’hui : 106 tests ; après suppression d’un test → 105.) |
| **Vérification** | `cd /Users/leobsn/Desktop/webook4u-engine && bundle exec rails test` (ou `rails test`). Tous verts, 105 tests. |

**Contenu à supprimer** (extrait du fichier) : tout le bloc qui commence par `test "falls back when cache increment returns nil" do` et se termine par le `end` correspondant (inclut les lignes avec `ip`, `slug`, `Rails.cache.write`, `cache.define_singleton_method`, `assert Bookings::RateLimit.allow_pending_creation?`, `ensure`, etc.).

---

### Itération 1b — Optionnelle (1 fichier, cosmétique)

Si vous souhaitez poursuivre dans la même session **sans** toucher aux autres lots :

| Élément | Détail |
|--------|--------|
| **Fichier** | `test/controllers/public_clients_controller_test.rb` |
| **Action** | Remplacer la chaîne du nom du test : `"should get show"` → `"GET show returns success for valid client slug"`. Aucune autre modification. |
| **Résultat attendu** | `rails test` → 105 tests (inchangé par rapport à 1a), tous verts. |

---

**Résumé première itération** :
- **Minimum exécutable** : 1 fichier (`rate_limit_test.rb`), 1 suppression. Résultat : 105 tests verts.
- **Optionnel** : + 1 fichier (`public_clients_controller_test.rb`), 1 renommage. Résultat : 105 tests verts.
- **Pas dans cette itération** : `create_pending_test.rb`, `booking_flow_test.rb` (messages d’assertion), `client_test`/`service_test`, Lot 3.
