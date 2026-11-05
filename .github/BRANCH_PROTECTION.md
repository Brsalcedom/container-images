# Protección de `main`

Para que el security gate y la convención de commits sean obligatorios antes del merge,
configura un *ruleset* (o branch protection rule) en
`Settings → Rules → Rulesets → New branch ruleset`:

* **Target**: `main` (default branch)
* **Restrict deletions** y **Block force pushes**
* **Require a pull request before merging**
  * Allowed merge methods: **Squash**. El título del PR queda como mensaje de commit,
    que es lo que lee release-please.
* **Require status checks to pass**
  * `gate` (workflow `images`): resume toda la matrix de build + Trivy. No agregues
    los jobs `build (<imagen>)`, porque su nombre cambia según lo que modifique el PR.
  * `check-pr-title` (workflow `Validate PR Title`)
  * Marca **Require branches to be up to date before merging**.
* **Require conversation resolution before merging**

## Cómo funciona

1. Abres un PR que modifica `images/<imagen>/` con título `fix(<imagen>): ...`.
2. `images` construye, prueba y escanea solo las imágenes afectadas. Si hay CVEs
   HIGH/CRITICAL con fix, `gate` falla y el merge queda bloqueado.
3. Al hacer merge, release-please abre `chore(<imagen>): release X.Y.Z`.
4. Al hacer merge de ese PR, `images` vuelve a escanear y publica `X.Y.Z` en Docker Hub.

Los PRs de release necesitan el secret `RELEASE_PLEASE_TOKEN`. Con el `GITHUB_TOKEN`
por defecto, GitHub no ejecuta workflows en esos PRs y `gate` queda pendiente.
