# Contributing Guide

Merci de contribuer à ce template DevSecOps. Ce dépôt étant **opposable** (utilisé par toutes les nouvelles applications de l'organisation), toute modification suit un process renforcé.

## 1. Workflow

1. **Fork** ou branche dédiée (préfixe : `feat/`, `fix/`, `chore/`, `sec/`).
2. **Commit signed-off** (`git commit -s`) avec message conventionnel :
   ```
   feat(pipeline): add CodeQL job
   fix(quality-gate): correct severity threshold parsing
   docs(policy): clarify exception procedure
   ```
3. **Vérification locale** (cf. README §7.3) avant push.
4. **Pull request** suivant le template (`.github/PULL_REQUEST_TEMPLATE.md`).
5. **Quality Gate** doit être au statut `success`.
6. **Review** par les CODEOWNERS concernés.

## 2. Modifications du pipeline (`.github/workflows/`)

Toute modification du workflow ou des fichiers de configuration de sécurité (`.gitleaks.toml`, `.semgrepignore`, `.trivyignore`, `.eslintrc.json`) :

- Requiert l'approbation explicite de l'équipe Sécurité (CODEOWNERS).
- Doit être accompagnée d'un commentaire de PR justifiant le changement.
- Ne doit **jamais** affaiblir le Quality Gate sans Risk Acceptance formelle.

## 3. Modifications des standards (`docs/policy/`)

- Soumis pour relecture au CISO Office.
- Communication interne (#security, all-hands) après merge.
- Diff résumé dans le changelog interne.

## 4. Tests

- `npm test` doit passer.
- Tests unitaires obligatoires pour toute nouvelle fonction.
- Tests négatifs (cas refusés) obligatoires pour le code de sécurité.

## 5. Style de code

- ESLint passe sans warning (`npm run lint`).
- Pas de `console.log` en production code.
- Pas de `eslint-disable` sans commentaire de justification.

## 6. License & DCO

En contribuant, vous acceptez que votre contribution soit publiée sous la licence du dépôt (Apache 2.0) et confirmez que vous avez le droit de soumettre ce code (Developer Certificate of Origin — `Signed-off-by`).

## 7. Code of Conduct

Ce projet adhère au Code of Conduct organisationnel. Tout comportement irrespectueux est signalable au CISO Office.
