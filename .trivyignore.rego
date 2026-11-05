# Trivy ignore policy (https://trivy.dev/latest/docs/configuration/filtering/#by-rego),
# loaded by .github/scripts/scan.sh with --ignore-policy.
#
# Only for whole classes of findings that can never be exploitable inside a container.
# Individual CVEs go in .trivyignore.yaml, with a statement and an expiry date.
# Changes here require explicit approval from the repository owner.

package trivy

import rego.v1

default ignore := false

# linux-libc-dev only ships the kernel's userspace API headers (used to compile against
# libc). Containers run on the host kernel, so kernel CVEs reported against this package
# are not exploitable from the image. It is pulled in as a build dependency (e.g. by
# netexec in the pentesting image).
ignore if {
	input.PkgName == "linux-libc-dev"
}
