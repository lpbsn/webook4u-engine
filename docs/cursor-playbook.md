# Cursor Playbook — Rails MVP (webook4u)

## Objectif

Utiliser Cursor efficacement pour :

* coder rapidement
* garder le contrôle
* éviter les effets de bord
* limiter les bugs

---

# 1. Principe fondamental

> **1 chat = 1 rôle = 1 objectif**

| Chat   | Rôle                              | Modèle     |
| ------ | --------------------------------- | ---------- |
| DOC    | Comprendre & structurer           | GPT 5.4    |
| SEC    | Détecter les risques              | Opus 4.6   |
| REF    | Modifier proprement               | Sonnet 4.6 |
| TEST   | Couvrir intelligemment            | Sonnet 4.6 |
| PROMPT | Structurer les demandes complexes | GPT 5.4    |

---

# ⚡ 2. Règles globales (NON NÉGOCIABLES)

* small changes > big changes
* ne jamais réécrire un fichier entier sans demande explicite
* ne pas modifier plusieurs fichiers sans justification claire
* ne pas changer le comportement sans le signaler
* toujours comprendre avant de modifier
* toujours passer par SEC avant validation
* 1 prompt = 1 objectif
* éviter les prompts vagues

---

# 3. Description des chats

---

## DOC — Audit & Cartographie

### Objectif

* comprendre le code
* analyser les flux
* produire de la documentation claire

### Utilisation

* audit technique
* cartographie architecture
* compréhension d’un module
* analyse de flow

### À ne pas faire

* coder
* refactorer
* proposer des modifications larges

---

## SEC — Sécurisation

### Objectif

* détecter bugs et effets de bord
* identifier régressions

### Utilisation

* review après modification
* validation avant commit

### À ne pas faire

* refactorer
* améliorer le style
* ajouter des features

---

## REF — Refacto & Optimisation

### Objectif

* améliorer le code sans changer le comportement

### Utilisation

* refacto local
* extraction service
* simplification logique

### À ne pas faire

* refonte globale
* modifications multi-fichiers non contrôlées

---

## TEST — Audit & Tests

### Objectif

* couvrir les comportements critiques

### Utilisation

* identifier trous de tests
* générer tests ciblés

### À ne pas faire

* générer masse de tests inutile
* tester l’implémentation au lieu du comportement

---

## PROMPT — Générateur (optionnel)

### Objectif

* structurer les demandes complexes

### Utilisation

* refacto risqué
* audit complexe
* stratégie de test

### À ne pas faire

* utiliser systématiquement
* remplacer la réflexion

---

# 4. Workflows standards

---

## Feature

1. DOC → comprendre
2. REF → implémenter
3. TEST → couvrir
4. SEC → valider

---

## Bug

1. DOC → comprendre
2. TEST → reproduire
3. REF → corriger
4. SEC → vérifier

---

## Refacto

1. DOC → analyser impact
2. REF → modifier
3. SEC → valider
4. TEST → compléter si nécessaire

---

## Audit

1. DOC uniquement
2. éventuellement SEC

---

## Tâche complexe

1. PROMPT → structurer
2. chat cible
3. SEC → validation

---

# 5. Plan Mode (IMPORTANT)

Utiliser Plan Mode si :

* plusieurs fichiers impliqués
* logique métier complexe
* refacto risqué

### Règles

* pas de code en plan
* validation du plan obligatoire
* seulement ensuite implémentation

---

# 6. Anti-patterns critiques (ne surtout pas faire)

un seul chat pour tout
refactor sans comprendre
skip SEC
prompts vagues
modifications massives
tests sans stratégie
laisser Cursor modifier plusieurs fichiers sans contrôle

---

# 7. Règle d’or

> **Plus le prompt est contraint, plus le code est fiable**

---

# 8. Checklist avant validation

* le diff est petit
* le comportement est correct
* aucun refacto caché
* tests pertinents
* SEC validé

---
