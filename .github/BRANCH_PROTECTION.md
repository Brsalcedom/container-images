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
- `Security Gate Check` (from `Security :: Gate` workflow) - **REQUIRED**
- `Generate Security Report` (from `Security :: Report` workflow) - Optional but recommended

#### ✅ Require conversation resolution before merging
- [x] All conversations on code must be resolved

#### ✅ Do not allow bypassing the above settings
- [x] Include administrators

---

## How it works

1. Developer creates PR with Dockerfile changes
2. Two workflows run automatically:
   - **Security Report**: Scans and uploads results to Security tab (always succeeds)
   - **Security Gate**: Checks for CRITICAL vulnerabilities and blocks if found
3. If CRITICAL vulnerabilities found → Security Gate fails, PR is blocked ❌
4. If scan passes → Both workflows succeed, PR can be merged ✅
5. After merge, manually trigger `docker-homelab-ci-publish.yml` to publish

---

## Manual Configuration Steps

1. Go to: `https://github.com/<your-username>/container-images/settings/branches`
2. Click "Add rule"
3. Enter `main` as branch name pattern
4. Enable the checkboxes listed above
5. In "Status checks that are required", search for and add: `Security Gate Check`
6. Optionally add: `Generate Security Report` (informational only)
6. Click "Create" or "Save changes"

---

## Testing the Protection

To verify it's working:

1. Create a test PR with a Dockerfile change
2. Wait for the security scan to complete
3. Try to merge before the scan finishes → Should be blocked
4. After scan completes successfully → Merge should be allowed
