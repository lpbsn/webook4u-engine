# Webook4u

Moteur de reservation Ruby on Rails en cours de construction, oriente MVP.

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

## Tests

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
