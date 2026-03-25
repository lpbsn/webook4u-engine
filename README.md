# Webook4u

Moteur de reservation Ruby on Rails en cours de construction.

## Versions figees

- Ruby `3.4.9`
- Rails `8.1.2`
- Bundler `2.7.2`
- PostgreSQL `17`

Verification rapide :

```bash
ruby -v
bundle -v
psql --version
```

## Documentation

- [README.md](/Users/leobsn/Desktop/webook4u-engine/README.md) : point d'entree setup, base locale, tests et perimetre courant
- [docs/BookingRules.md](/Users/leobsn/Desktop/webook4u-engine/docs/BookingRules.md) : point d'entree technique vers la documentation de reservation
- [docs/BookingFlow.md](/Users/leobsn/Desktop/webook4u-engine/docs/BookingFlow.md) : reference du flux de reservation et du cycle de vie courant
- [docs/BookingInvariants.md](/Users/leobsn/Desktop/webook4u-engine/docs/BookingInvariants.md) : reference des invariants de domaine, DB et concurrence
- [docs/DatabaseArchitecture.md](/Users/leobsn/Desktop/webook4u-engine/docs/DatabaseArchitecture.md) : architecture de la base, tables, relations et garde-fous PostgreSQL
- [docs/ProductScope.md](/Users/leobsn/Desktop/webook4u-engine/docs/ProductScope.md) : cadrage produit/strategie en anglais
- [docs/ProductScope.fr.md](/Users/leobsn/Desktop/webook4u-engine/docs/ProductScope.fr.md) : cadrage produit/strategie en francais
- [docs/FutureInvariantsChecklist.md](/Users/leobsn/Desktop/webook4u-engine/docs/FutureInvariantsChecklist.md) : checklist des invariants a revisiter lors des futures evolutions
- [docs/BookingCrossTableAudit.md](/Users/leobsn/Desktop/webook4u-engine/docs/BookingCrossTableAudit.md) : audit historique de coherence cross-table avant ajout du trigger DB

## Bootstrap local

Le chemin de reference pour preparer le projet en local est :

```bash
bin/setup --skip-server
```

Ce script :

- installe les dependances Ruby si necessaire
- prepare la base de donnees avec `bin/rails db:prepare`
- nettoie les logs et fichiers temporaires

Pour lancer directement l'application apres le setup :

```bash
bin/setup
```

Application disponible sur :

[http://localhost:3000](http://localhost:3000)

Healthcheck :

[http://localhost:3000/up](http://localhost:3000/up)

## Base de donnees locale

Le projet utilise PostgreSQL.

Configuration locale par defaut :

- base de developpement : `webook4u_development`
- base de test : `webook4u_test`

Par defaut, `config/database.yml` utilise PostgreSQL local avec l'utilisateur systeme courant si aucun `username` n'est renseigne.

PostgreSQL doit donc etre demarre et accessible en local, sauf configuration specifique via `DATABASE_URL`.

Le projet utilise `db/structure.sql` pour porter certains invariants PostgreSQL avancés qui ne tiennent pas correctement dans `schema.rb`, notamment le trigger de coherence cross-table sur `bookings`.

## Tests

Avant de lancer les tests, preparer la base avec le workflow standard du projet :

```bash
bin/rails db:prepare
```

La base de test est preparee avec le meme schema SQL PostgreSQL que le projet, y compris les invariants avances portes par `db/structure.sql`.

Commande de reference :

```bash
bin/rails test
```

Commande equivalente :

```bash
bundle exec rails test
```

Lancer un fichier de test precis :

```bash
bin/rails test test/integration/booking_flow_test.rb
```

## Verification rapide

Une installation est consideree valide si :

- `bin/setup --skip-server` se termine sans erreur
- `bin/rails server` demarre sans erreur
- [http://localhost:3000/up](http://localhost:3000/up) repond
- une page publique seedee s'affiche en local
- `bin/rails test` passe au vert

## Perimetre actuel

Le projet couvre aujourd'hui :

- page publique de reservation par `slug`
- selection d'une enseigne
- selection d'une prestation
- selection d'une date
- affichage des creneaux disponibles
- creation d'une reservation temporaire (`pending`)
- confirmation de reservation
- page de succes

Hors perimetre actuel :

- paiement
- gestion metier liee aux echecs de paiement
- exploitation reelle du statut `failed`
- fonctionnement 100% base sur les horaires par enseigne

Regles metier actuelles :

- les prestations sont partagees entre toutes les enseignes d'un meme client
- les horaires au niveau `client` sont un fallback transitoire avant un fonctionnement 100% par `enseigne`
