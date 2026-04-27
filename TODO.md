# TODO - Issue 109: What needs to be done to push v2 out?

## Testing
- [ ] Test for local

## Documentation
- [ ] Document multiple prefixes supplied in one call (e.g. `-p 'hourly- daily- weekly-'`)
- [ ] Document periodic files

## Output & Verbosity
- [ ] Make output similar to ZFS style: "would" vs "will"
- [ ] Be verbose on failure, don't be silent
- [ ] Double verbosity will output actual ZFS commands

## Periodic Scripts
- [ ] Periodic scripts, test

## Handle Pools/FS/Snapshots with Spaces
- [ ] Handle pools/fs/snapshots with spaces in names
- [ ] Add tests for all `TrimTo*` and `Valid*` functions
- [ ] Handle IFS issues (can't have space as default)
  - Consider set/unset approach (bad idea: people source core.sh, don't want to mess with IFS silently)
- [ ] Building lists, don't use space
- [ ] Make sure quoting passes through to actual ZFS commands: destroy, snapshot, recurseback, etc
- [ ] Test for all allowed ZFS special characters

## API Changes
- [ ] Rename `SkipPool` (would be an API change)
- [ ] Rename `ValidSnapshot` to `IsZFSNAPSnapshot`

## Code Style
- [ ] Use semi-colons where appropriate, rather than `&&`

## Other
- [ ] Use depth to limit destroy's snapshot list creation
- [ ] Generate new HTML

## Design Concerns (from @aqq)
- [ ] IFS issues with datasets with spaces (especially dangerous with "destroy")
- [ ] Language consistency ("would" and "will")
- [ ] Consider changing default behavior: no-op by default, prompt to delete, add `-y` to force yes (breaking change)
- [ ] Improve tests further
