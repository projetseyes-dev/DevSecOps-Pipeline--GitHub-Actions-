# Security Standards for Developers

> **Version** : 1.0
> **Owner** : CISO Office / Lead DevSecOps
> **Classification** : Internal — Mandatory
> **Review cadence** : Annual (or upon major change)
> **Applies to** : tous les développeurs (internes, prestataires, OSS contributors) intervenant sur les dépôts utilisant ce template.

Ce document définit les **standards de sécurité opposables** aux développeurs. Toute déviation requiert une procédure d'exception formelle (voir §9). Le respect de ces standards est vérifié **automatiquement** par le pipeline CI/CD ; ce qui n'est pas mesurable automatiquement est vérifié en code review.

---

## 1. Principes fondamentaux

| # | Principe                          | Description                                                                            |
|---|-----------------------------------|----------------------------------------------------------------------------------------|
| 1 | **Secure by default**             | Les valeurs par défaut doivent être les plus sécurisées (deny-by-default).             |
| 2 | **Defense in depth**              | Plusieurs couches de contrôle ; aucune ne doit être unique point de défense.           |
| 3 | **Least privilege**               | Permissions minimales : utilisateurs, services, tokens, runners CI.                    |
| 4 | **Fail securely**                 | Une erreur ne doit jamais ouvrir un accès non autorisé.                                |
| 5 | **Don't roll your own crypto**    | Toujours utiliser des bibliothèques éprouvées (libsodium, Web Crypto, etc.).            |
| 6 | **Shift Left**                    | Détecter et corriger en local > en PR > en staging > en production.                    |

---

## 2. Gestion des secrets

### 2.1. Règles obligatoires

- **JAMAIS** de secret en clair dans le code, les commentaires, les logs, les messages de commit, les issues ou les PR.
- **JAMAIS** de secret dans les fichiers de configuration committés (`.env` est dans `.gitignore`, jamais commité).
- Tous les secrets transitent par **GitHub Secrets** (org-level ou repo-level), Vault, AWS Secrets Manager ou équivalent approuvé.
- Rotation obligatoire : tokens applicatifs ≤ 90 jours, clés long-life ≤ 365 jours.
- Tout secret accidentellement committé doit être **considéré comme compromis** : rotation immédiate + ticket d'incident, même si le commit est réécrit.

### 2.2. Contrôle automatique

- **Gitleaks** scanne l'intégralité de l'historique git à chaque push/PR.
- Configuration : [`.gitleaks.toml`](../../.gitleaks.toml).
- Toute détection bloque le merge.

---

## 3. Validation des entrées (Input Validation)

### 3.1. Règles

- **Toute** entrée externe (HTTP, message queue, fichier, env var) est considérée non fiable.
- Validation **par allow-list** (whitelist) plutôt que par deny-list, dès que possible.
- Schéma de validation explicite (JSON Schema, Zod, Joi, Pydantic, etc.).
- Limites strictes : longueur, type, plage de valeurs, charset.
- Encodage à la sortie selon le contexte (HTML, SQL, shell, LDAP, etc.).

### 3.2. Anti-patterns interdits

```js
// INTERDIT - injection SQL
db.query(`SELECT * FROM users WHERE id = ${req.query.id}`);

// INTERDIT - injection commande
exec(`convert ${req.body.filename} output.png`);

// INTERDIT - eval ou équivalent
eval(req.body.expression);
new Function(req.body.code);

// INTERDIT - path traversal
fs.readFile(`./uploads/${req.params.file}`);
```

### 3.3. Patterns approuvés

```js
// OK - paramétrage
db.query('SELECT * FROM users WHERE id = ?', [parseInt(req.query.id, 10)]);

// OK - exécution sans shell
execFile('convert', [sanitizedPath, outputPath]);

// OK - path normalisé + allow-list
const safe = path.normalize(req.params.file);
if (!safe.startsWith('uploads/')) throw new ForbiddenError();
```

---

## 4. Authentification & autorisation

- Aucune **authentification maison** ; utiliser l'IdP organisationnel (OIDC, SAML).
- Mots de passe : hash Argon2id (paramètres minimum : `m=64MB, t=3, p=4`) ou bcrypt cost ≥ 12.
- MFA **obligatoire** pour tous les accès administratifs et tous les comptes ayant accès à de la donnée production.
- Tokens : courte durée de vie (≤ 1h pour access tokens, ≤ 24h pour refresh tokens en SPA).
- Autorisation **côté serveur**, jamais uniquement côté client.
- Modèle RBAC ou ABAC documenté et code-reviewed.

---

## 5. Cryptographie

### 5.1. Algorithmes approuvés

| Usage                      | Algorithme(s) approuvé(s)               | Interdit                          |
|----------------------------|------------------------------------------|-----------------------------------|
| Hash (intégrité)           | SHA-256, SHA-3, BLAKE2/3                | MD5, SHA-1                        |
| Hash de mot de passe       | Argon2id, bcrypt (cost ≥ 12), scrypt    | MD5, SHA-1, SHA-256 sans salt     |
| Chiffrement symétrique     | AES-256-GCM, ChaCha20-Poly1305          | DES, 3DES, RC4, AES-ECB, AES-CBC sans MAC |
| Chiffrement asymétrique    | RSA-2048+, ECDSA P-256+, Ed25519        | RSA < 2048, DSA                   |
| TLS                        | TLS 1.3 (1.2 acceptable en transition)  | TLS ≤ 1.1, SSL                    |
| RNG                        | `crypto.randomBytes`, `getrandom(2)`    | `Math.random`, `rand()`           |

### 5.2. Règles

- Toute communication réseau utilise TLS (HTTPS, mTLS pour service-to-service).
- Les clés privées ne quittent jamais le HSM / KMS.
- Pas de chiffrement « roulé maison » : utiliser libsodium / Web Crypto API.

---

## 6. Gestion des dépendances

### 6.1. Règles

- Dépendances installées uniquement depuis les registres officiels (npmjs.org, pypi.org, Maven Central) ou un registre miroir interne.
- `npm ci` (lockfile strict) en CI ; `npm install` interdit en CI.
- Tout ajout de dépendance > 50 KLOC ou non maintenue (last commit > 12 mois) requiert une revue Sécurité.
- Trivy bloque les CVE Critical/High **non corrigées** (Critical/High avec correctif disponible = fix obligatoire).
- Dependabot/Renovate activé sur tous les repos ; PRs de patch security mergées sous 7 jours.

### 6.2. Inventaire (SBOM)

Le pipeline génère un **SBOM CycloneDX** à chaque build (`reports/sbom.cyclonedx.json`), conservé 90 jours. Cet inventaire est utilisé pour la **réponse rapide aux CVE émergentes**.

---

## 7. Logging & Observabilité

### 7.1. À LOGGER

- Authentification (succès, échec, déconnexion).
- Modifications de droits / privilèges.
- Accès aux ressources sensibles.
- Erreurs serveur (5xx) avec stack trace.
- Modifications de configuration en production.

### 7.2. INTERDIT dans les logs

- Mots de passe, en clair ou hashés.
- Tokens, API keys, secrets.
- Données personnelles (PII) sans pseudonymisation.
- Numéros de carte bancaire complets, CVV, données de santé (HIPAA), données de paiement (PCI).
- Bodies de requête contenant des secrets.

### 7.3. Format

- Logs structurés (JSON) avec `correlation_id` pour le tracing distribué.
- Niveau approprié : `error` réservé aux vraies erreurs (sinon dette d'alerting).
- Rétention conforme à la politique de protection des données.

---

## 8. Configuration sécurisée

- **HTTP headers** : Helmet (Node.js) ou équivalent ; au minimum `Strict-Transport-Security`, `X-Content-Type-Options`, `X-Frame-Options`, `Content-Security-Policy`.
- **CORS** : whitelist explicite, pas de `*` en production.
- **Cookies** : `Secure`, `HttpOnly`, `SameSite=Strict` (ou `Lax` justifié).
- **Rate limiting** sur tous les endpoints publics.
- **Mode debug désactivé** en production (variables d'environnement validées au démarrage).
- **Stack traces** non exposées aux clients (filtrer les réponses d'erreur).

---

## 9. Exceptions & Risk Acceptance

### 9.1. Principe

Le Quality Gate (Critical/High = FAIL) est **par défaut bloquant**. Une exception est possible uniquement :
- Pour un **faux positif documenté**, ou
- Pour une **acceptation formelle du risque** par le management.

### 9.2. Procédure

1. **Création d'un ticket** `SEC-XXXX` (Jira / GitHub Issues) contenant :
   - Identifiant CVE / règle déclencheuse.
   - Justification (faux positif OU mitigation compensatoire).
   - Impact estimé (CVSS, exploitabilité, exposition).
   - Date d'expiration de l'exception (**max 90 jours**, renouvelable une fois).
2. **Approbation** :
   - Sévérité High : Security Champion + Engineering Manager.
   - Sévérité Critical : ajout obligatoire du CISO ou de son délégué.
3. **Implémentation** : ajout dans `.trivyignore` / `.semgrepignore` avec **commentaire obligatoire** :
   ```
   CVE-2024-XXXXX  # Reason: SEC-1234 - false positive in transitive dep, expires 2026-09-30
   ```
4. **Revue trimestrielle** des exceptions actives par l'équipe Sécurité.
5. **Expiration automatique** : un script CI alerte 14 jours avant expiration.

### 9.3. Ce qui n'est jamais accepté

- Désactiver un job du pipeline.
- Commenter une règle ESLint sans justification (`// eslint-disable-line` sans commentaire).
- Modifier `.github/workflows/` sans approbation Sécurité (protégé par CODEOWNERS).
- Ignorer un secret détecté par Gitleaks ; un secret leaké = rotation obligatoire.

---

## 10. Code Review & merge

### 10.1. Règles obligatoires (Branch Protection)

- Au moins **1 reviewer** distinct de l'auteur (≥ 2 pour code de sécurité).
- **Quality Gate** doit être au statut `success`.
- **CODEOWNERS** : toute modification de `.github/workflows/`, `docs/policy/`, fichiers crypto/auth → review obligatoire de l'équipe Sécurité.
- **Force push interdit** sur `main` et `develop`.
- **Linear history** recommandée (squash merge ou rebase).

### 10.2. Checklist du reviewer

- [ ] Pas de secret, clé, token dans le diff.
- [ ] Inputs externes validés.
- [ ] Pas d'introduction de dépendance non revue.
- [ ] Logging conforme (pas de PII, pas de secrets).
- [ ] Permissions/RBAC respectés.
- [ ] Tests unitaires couvrant les chemins de sécurité (auth, autz, validation).

---

## 11. Formation & sensibilisation

- **Onboarding sécurité obligatoire** dans les 30 jours suivant l'arrivée.
- **Mise à jour annuelle** (e-learning ou workshop) — couverture OWASP Top 10, secure coding, threat modeling.
- **Security Champions** : un par squad, formé en profondeur, point de contact sécurité de l'équipe.

---

## 12. Conformité & audit

Ce standard est aligné avec :

- **OWASP ASVS Level 2** (cible) / Level 3 (applications critiques).
- **OWASP Top 10 (2021)**.
- **NIST SSDF (SP 800-218)** — pratiques PW, PO, PS, RV.
- **ISO 27001:2022** Annex A.5, A.8 (notamment A.8.25 à A.8.30).
- **SOC 2** Trust Services Criteria CC6, CC7, CC8.

Voir le mapping détaillé dans le [`README.md`](../../README.md#6-conformité--mapping-soc-2--iso-27001).

---

## 13. Contacts

| Rôle                       | Canal                                  |
|---------------------------|----------------------------------------|
| Security Champion (squad) | Slack `#sec-champions`                 |
| Security Team             | Slack `#security`, mail `secops@org`   |
| CISO Office               | Mail `ciso-office@org`                 |
| Incident Sécurité         | Astreinte 24/7 — voir wiki interne     |

---

**Document opposable** — toute violation peut entraîner un blocage de merge, un audit dédié ou des mesures disciplinaires conformément au règlement interne.
