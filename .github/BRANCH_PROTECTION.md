# Branch Protection Configuration

To ensure security scans are enforced before merging to `main`, configure the following branch protection rules in GitHub:

## Settings → Branches → Branch protection rules → Add rule

### Branch name pattern
```
main
```

### Protection Rules

#### ✅ Require a pull request before merging
- [x] Require approvals: 1
- [x] Dismiss stale pull request approvals when new commits are pushed

#### ✅ Require status checks to pass before merging
- [x] Require branches to be up to date before merging

**Required status checks:**
- `scan` (from `Docker :: Security Scan` workflow)

#### ✅ Require conversation resolution before merging
- [x] All conversations on code must be resolved

#### ✅ Do not allow bypassing the above settings
- [x] Include administrators

---

## How it works

1. Developer creates PR with Dockerfile changes
2. `docker-security-scan.yml` workflow runs automatically
3. Trivy scans the image for vulnerabilities
4. If CRITICAL vulnerabilities found → PR is blocked ❌
5. If scan passes → PR can be merged ✅
6. After merge, manually trigger `docker-homelab-ci-publish.yml` to publish

---

## Manual Configuration Steps

1. Go to: `https://github.com/<your-username>/container-images/settings/branches`
2. Click "Add rule"
3. Enter `main` as branch name pattern
4. Enable the checkboxes listed above
5. In "Status checks that are required", search for and add: `scan`
6. Click "Create" or "Save changes"

---

## Testing the Protection

To verify it's working:

1. Create a test PR with a Dockerfile change
2. Wait for the security scan to complete
3. Try to merge before the scan finishes → Should be blocked
4. After scan completes successfully → Merge should be allowed
