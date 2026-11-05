# `main` branch protection

To make the security gate and the commit convention mandatory before merging, set up a
*ruleset* (or branch protection rule) under
`Settings → Rules → Rulesets → New branch ruleset`:

* **Target**: `main` (default branch)
* **Restrict deletions** and **Block force pushes**
* **Require a pull request before merging**
  * Allowed merge methods: **Squash**. The PR title becomes the commit message, which
    is what release-please reads.
* **Require status checks to pass**
  * `gate` (`images` workflow): summarizes the whole build + Trivy matrix. Do not add
    the `build (<image>)` jobs, because their names change depending on what the PR
    touches.
  * `check-pr-title` (`Validate PR Title` workflow)
  * Check **Require branches to be up to date before merging**.
* **Require conversation resolution before merging**

## How it works

1. You open a PR that changes `images/<image>/` with the title `fix(<image>): ...`.
2. `images` builds, tests and scans only the affected images. If there are fixable
   HIGH/CRITICAL CVEs, `gate` fails and the merge is blocked.
3. On merge, release-please opens `chore(<image>): release X.Y.Z`.
4. When that PR is merged, `images` scans again and publishes `X.Y.Z` to Docker Hub.

Release PRs need the `RELEASE_PLEASE_TOKEN` secret. With the default `GITHUB_TOKEN`,
GitHub does not run workflows on those PRs and `gate` stays pending.
