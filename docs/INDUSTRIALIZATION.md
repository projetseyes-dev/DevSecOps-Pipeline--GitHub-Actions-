# Industrialisation GitHub (Enforcement)

Ce document décrit comment transformer ce dépôt en baseline DevSecOps **enforcée** côté plateforme GitHub.

## Prérequis

- Rôle admin sur le repo GitHub.
- PAT GitHub avec scope `repo` (ou fine-grained token avec droits d'administration du dépôt).
- Branche `main` existante.
- Workflow vert au moins une fois (le check required doit exister).

## 1) Activer le mode Template

Le script `scripts/github-hardening.ps1` active `is_template=true` via l'API.

## 2) Activer la Branch Protection (main)

Le script applique :

- PR obligatoire avec au moins 1 approbation.
- CODEOWNERS requis.
- Admins également soumis aux règles.
- Force push interdit.
- Suppression de branche interdite.
- Historique linéaire requis.
- Résolution des conversations requise.
- `strict status checks` activé.
- Check obligatoire : `Quality Gate (Critical/High = FAIL)`.

## 3) Commande d'exécution

```powershell
$env:GITHUB_TOKEN = "<PAT_ADMIN_REPO>"
.\scripts\github-hardening.ps1 -Owner "projetseyes-dev" -Repo "DevSecOps-Pipeline--GitHub-Actions-" -Branch "main"
```

## 4) Vérification post-configuration

1. Repo Settings > General > Template repository = activé.
2. Repo Settings > Branches > `main` rule visible.
3. Required status checks contient `Quality Gate (Critical/High = FAIL)`.
4. Essai de merge d'une PR rouge => refus.

## 5) Déploiement à l'échelle (organisation)

- Créer tous les nouveaux repos via *Use this template*.
- Ajouter une policy interne imposant ce template.
- Auditer trimestriellement :
  - % des repos avec protection `main`
  - % des repos avec check obligatoire Quality Gate
  - nombre d'exceptions actives.
