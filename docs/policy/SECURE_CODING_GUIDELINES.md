# Secure Coding Guidelines (Node.js)

> **Audience** : développeurs front et back de l'organisation.
> **Statut** : guide d'application des [Security Standards](./SECURITY_STANDARDS.md).
> **Mode** : recommandations pratiques — toute exception suit la procédure §9 du standard.

Ce document complète le standard. Là où le standard dit *quoi*, ce guide dit *comment*.

---

## 1. Cycle de vie sécurisé d'une feature

```
1. Threat modeling rapide (STRIDE, 15-30 min) si la feature touche : auth, données sensibles, paiement, intégrations externes.
2. Conception : choix d'architecture sécurisé (chiffrement, segregation, principe least privilege).
3. Implémentation : code conforme aux patterns ci-dessous.
4. Tests : unit + integration + tests de sécurité (cas négatifs).
5. Review : checklist sécurité + code review par un pair.
6. Pipeline : Quality Gate (Lint + Gitleaks + Semgrep + Trivy) bloquant.
7. Déploiement : feature flag, rollback plan, monitoring.
8. Post-mortem : mesure du MTTR si incident, retours dans le backlog.
```

---

## 2. Patterns Node.js sécurisés

### 2.1. Lecture de fichier avec path traversal protégé

```js
const path = require('path');
const fs = require('fs/promises');

const UPLOAD_DIR = path.resolve('/var/app/uploads');

async function readUserFile(filename) {
  const resolved = path.resolve(UPLOAD_DIR, filename);
  if (!resolved.startsWith(UPLOAD_DIR + path.sep)) {
    throw new Error('Path traversal attempt');
  }
  return fs.readFile(resolved);
}
```

### 2.2. Exécution de commande externe (jamais `exec`)

```js
const { execFile } = require('child_process');

execFile('/usr/bin/convert', [inputPath, outputPath], (err, stdout, stderr) => {
  // ...
});
// PAS exec(`convert ${inputPath} ${outputPath}`) - injection de commande
```

### 2.3. Requête SQL paramétrée

```js
// pg (node-postgres)
await client.query('SELECT * FROM users WHERE email = $1 AND tenant_id = $2', [email, tenantId]);

// mysql2
await conn.execute('SELECT * FROM users WHERE id = ?', [userId]);
```

### 2.4. Génération d'aléa cryptographique

```js
const crypto = require('crypto');
const token = crypto.randomBytes(32).toString('hex');
// PAS Math.random() pour des usages sécurité
```

### 2.5. Hash de mot de passe (Argon2id préféré)

```js
const argon2 = require('argon2');
const hash = await argon2.hash(password, {
  type: argon2.argon2id,
  memoryCost: 65536, // 64 MB
  timeCost: 3,
  parallelism: 4,
});
const ok = await argon2.verify(hash, password);
```

### 2.6. JWT — vérification stricte

```js
const jwt = require('jsonwebtoken');

const payload = jwt.verify(token, PUBLIC_KEY, {
  algorithms: ['RS256'],         // forcer l'algo, ne JAMAIS accepter 'none'
  issuer: 'https://auth.org',
  audience: 'api.org',
  clockTolerance: 5,
});
```

### 2.7. Headers HTTP de sécurité

```js
const helmet = require('helmet');
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'"],
      styleSrc: ["'self'"],
      objectSrc: ["'none'"],
      frameAncestors: ["'none'"],
    },
  },
  hsts: { maxAge: 31536000, includeSubDomains: true, preload: true },
}));
```

### 2.8. Validation d'entrée avec Zod

```js
const { z } = require('zod');

const CreateUserSchema = z.object({
  email: z.string().email().max(255),
  age: z.number().int().min(13).max(120),
  role: z.enum(['user', 'admin']),
});

app.post('/users', (req, res) => {
  const parsed = CreateUserSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ errors: parsed.error.issues });
  // parsed.data est désormais typé et validé
});
```

### 2.9. Désérialisation prudente

- Ne **jamais** désérialiser de YAML / pickle / objets binaires venant d'utilisateurs sans contrôle strict.
- En JSON : limiter la taille (`express.json({ limit: '100kb' })`).
- En XML : désactiver les entités externes (XXE).

---

## 3. Frontend — règles spécifiques

| Règle                                                         | Pourquoi                                              |
|--------------------------------------------------------------|-------------------------------------------------------|
| Pas de `dangerouslySetInnerHTML` sans DOMPurify.             | XSS                                                   |
| `target="_blank"` accompagné de `rel="noopener noreferrer"`. | Tabnabbing                                            |
| Cookies de session `HttpOnly`, jamais lisibles depuis JS.    | XSS → vol de session                                  |
| CSP stricte, pas de `unsafe-inline` ni `unsafe-eval`.        | Mitigation XSS                                        |
| Pas de stockage de tokens sensibles en `localStorage`.       | Lecture par tout JS sur la page                       |
| Validation côté client = UX, **pas** de la sécurité.         | La sécurité est côté serveur                          |

---

## 4. API REST — checklist

- [ ] Authentification sur tous les endpoints sauf endpoints publics explicites.
- [ ] Autorisation au niveau **objet** (pas seulement au niveau endpoint) — éviter IDOR.
- [ ] Rate limiting (par IP **et** par token).
- [ ] Versioning (`/v1/...`) pour permettre la dépréciation contrôlée.
- [ ] Pagination obligatoire pour les listes (limite max forcée côté serveur).
- [ ] Pas d'objets internes exposés (mass assignment) — mapper explicitement `req.body` → DTO.
- [ ] Réponses d'erreur génériques (pas de stack trace, pas de SQL error en clair).

---

## 5. Tests de sécurité

### 5.1. Tests unitaires obligatoires

Pour chaque fonction de validation / sanitization / autorisation :

- Cas nominal (allow).
- Cas refus explicite (deny).
- Cas limites (longueur max, charset, valeurs nulles/undefined).
- Cas malicieux : XSS, SQLi, path traversal, prototype pollution.

### 5.2. Exemple

```js
test('sanitizeInput refuses script tags', () => {
  expect(sanitizeInput('<script>alert(1)</script>')).not.toContain('<script>');
});

test('authorize rejects cross-tenant access', () => {
  const req = mockRequest({ user: { tenantId: 'A' }, params: { resourceTenant: 'B' } });
  expect(() => authorize(req)).toThrow(ForbiddenError);
});
```

---

## 6. Quand demander de l'aide à la Security Team

Toujours, en amont, pour :

- Conception d'un nouveau mécanisme d'authentification ou de chiffrement.
- Intégration d'un fournisseur tiers traitant de la donnée sensible.
- Modification du modèle de permissions / multi-tenancy.
- Toute fonctionnalité touchant à des données régulées (PII, santé, paiement).
- Avant un pentest externe.

Canal : `#security` sur Slack, ou ticket Jira `SEC-`.

---

## 7. Anti-patterns fréquemment vus en review (à éviter)

| Anti-pattern                                              | Correction                                            |
|-----------------------------------------------------------|-------------------------------------------------------|
| Logger l'objet `req` complet                              | Logger explicitement les champs nécessaires           |
| `try/catch` qui swallow l'erreur silencieusement          | Logger + remonter ou re-throw                         |
| `console.log` laissé en production                        | Logger structuré (winston/pino)                       |
| Comparaison de hash avec `===`                            | `crypto.timingSafeEqual` (timing attack)              |
| Concaténation de requête SQL                              | Toujours paramétrer                                   |
| `Math.random()` pour un token                             | `crypto.randomBytes`                                  |
| Désactiver TLS verify (`rejectUnauthorized: false`)       | Configurer une CA de confiance                        |
| Variables d'env lues sans validation                      | Schéma Zod/Joi de validation au boot                  |

---

**En résumé** : le code sécurisé n'est pas plus long ni plus lent. Il est *différent*. En cas de doute, demandez avant de commiter.
