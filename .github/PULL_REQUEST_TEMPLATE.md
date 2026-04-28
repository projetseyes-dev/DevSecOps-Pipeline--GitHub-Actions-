# Pull Request

## Description

<!-- Décrire brièvement le quoi et le pourquoi. -->

## Type de changement

- [ ] Bug fix (non-breaking)
- [ ] Nouvelle fonctionnalité (non-breaking)
- [ ] Breaking change
- [ ] Refactor / dette technique
- [ ] Documentation / gouvernance
- [ ] Mise à jour de dépendances

## Checklist Sécurité (obligatoire)

- [ ] Aucun secret, clé, token ou credential dans le diff (vérifié localement avec `gitleaks detect`).
- [ ] Toutes les entrées externes sont validées (allow-list, schéma).
- [ ] Pas de concaténation SQL / shell ; requêtes paramétrées.
- [ ] Pas de logging de données sensibles (PII, secrets, tokens).
- [ ] Permissions / autorisation vérifiées côté serveur (pas seulement UI).
- [ ] Dépendances ajoutées : provenance vérifiée, dernière version stable, license compatible.
- [ ] Tests unitaires couvrent les chemins de sécurité (cas refusés / malicieux).
- [ ] Le pipeline `DevSecOps Pipeline` est `success` (Quality Gate PASS).

## Checklist Qualité

- [ ] Lint passe sans warning (`npm run lint`).
- [ ] Tests unitaires verts (`npm test`).
- [ ] Documentation mise à jour si applicable (README, ADR, runbook).

## Tickets liés

<!-- Ex : SEC-1234, JIRA-5678 -->

## Risk Acceptance (si applicable)

Si cette PR introduit une exception sécurité (`.trivyignore`, `.semgrepignore`, `eslint-disable`) :

- [ ] Ticket `SEC-XXXX` créé avec justification, mitigation et date d'expiration.
- [ ] Approbation Security Champion + Engineering Manager.
- [ ] Commentaire d'expiration présent dans le fichier concerné.

## Notes pour les reviewers

<!-- Points d'attention particuliers, choix d'architecture, alternatives évaluées. -->
