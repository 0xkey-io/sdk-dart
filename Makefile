test:
	dart run melos exec --dir-exists=test -- dart test

.PHONY: fmt
fmt:
	dart format .

.PHONY: changeset
changeset:
	dart run tool/changeset.dart

.PHONY: version
version:
	dart run tool/changeset_version.dart

.PHONY: changelog
changelog:
	dart run tool/changeset_changelog.dart

# Prepare release by updating versions and changelogs. Does not publish.
.PHONY: prepare-release
prepare-release:
	dart run tool/changeset_version.dart
	dart run tool/changeset_changelog.dart

# Generate the pubspec snippet for consuming the SDK as a Git dependency
# (integration "方案 1"). Override the ref via REF (defaults to main):
#   make git-overrides REF=prod-20260624
REF ?= main
.PHONY: git-overrides
git-overrides:
	dart run tool/gen_git_overrides.dart --ref $(REF)