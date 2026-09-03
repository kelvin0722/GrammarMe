---
name: create-grammarme-release
description: Prepare, validate, package, notarize, and publish versioned GrammarMe macOS releases. Use for release planning, version bumps, release candidates, tags, GitHub Releases, or release troubleshooting.
---

# Create a GrammarMe Release

Use SemVer tags such as `v1.0.0`. `MARKETING_VERSION` is the user-visible SemVer value without the `v` prefix; `CURRENT_PROJECT_VERSION` is an independently increasing positive integer build number.

Before changing versions or producing artifacts, read [references/apple-versioning.md](references/apple-versioning.md). Run `scripts/validate_release.sh <version>` after the version change and again immediately before tagging.

## Release invariants

- Release only a clean commit reachable from `origin/main`. Never release directly from a feature or `develop` branch.
- Fetch tags and fail if either the version tag or GitHub Release already exists.
- Require explicit user authorization immediately before pushing a tag or creating/updating a GitHub Release.
- Never overwrite or move an existing release tag. Correct mistakes with a new version.
- Run all unit tests using a disposable DerivedData path.
- Archive the `GrammarMe` scheme in Release configuration for `generic/platform=macOS`.
- For a public downloadable app, require a `Developer ID Application` identity, hardened runtime, successful notarization, stapling, `codesign --verify --deep --strict`, and `spctl --assess --type execute`. An Apple Development signature is not a distribution signature.
- Package the stapled app with `ditto -c -k --sequesterRsrc --keepParent` as `GrammarMe-<version>.zip`.
- Generate release notes from the previous SemVer tag, focusing on user-visible changes and known limitations. Do not include credentials, internal paths, or unverifiable claims.

## Publish

Create an annotated `v<version>` tag on the verified main commit and push that exact tag. Create the GitHub Release with `gh release create`, attach the verified ZIP, and mark prerelease versions according to their SemVer suffix. Verify the release URL and asset checksum after upload.

If signing credentials, notarization credentials, a merged main commit, or explicit publishing authorization is missing, stop after producing a precise preflight report. Do not substitute an unsigned or development-signed artifact for a public release.
