Release workflow
----------------

We keep a tracked `dist/` tree for distribution packaging, but `src/` is the authoritative
development workspace. Update `dist/` and commit its contents only when performing a release.

Typical release steps:

1. Create a release branch: `git checkout -b release/vX.Y.Z`
2. Update `src/NEWS` (first line should contain the version `vX.Y.Z`) if needed.
3. Run `make build` (this populates `dist/`).
4. Run tests against the built tree:
   `ZFSNAP_PREFIX=$(pwd)/dist ./tests/run.sh`
5. Commit `dist/` and the generated tarball(s):
   `git add dist zfsnap-*.tar.gz zfsnap-*.tar.gz.sha256`
   `git commit -m "release: vX.Y.Z — build distributable"`
6. Push and tag: `git push origin release/vX.Y.Z` and `git tag vX.Y.Z && git push origin vX.Y.Z`

Local development
-----------------

Work in `src/`. To test the distributable locally:

1. `make build`
2. `ZFSNAP_PREFIX=$(pwd)/dist ./tests/run.sh`
