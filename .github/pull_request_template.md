## What this changes

<!-- One or two sentences. Link the issue if there is one. -->

## Why

<!-- What was wrong, or what was missing. -->

## Checklist

- [ ] shellcheck is clean (`severity=style`, the whole tree passes today)
- [ ] `yamllint -c .yamllint.yml ansible/ .github/workflows/ tests/`
- [ ] `ansible-lint -c ../.ansible-lint playbooks/ roles/` from `ansible/`
- [ ] Ran the fixture: `tests/fixture/setup.sh && tests/fixture/run.sh` (see `tests/fixture/README.md`)
- [ ] Both implementations changed if the behaviour exists as a script and a role
- [ ] CHANGELOG entry added
- [ ] Documentation updated

## Anything destructive?

<!-- If this touches disks, networking or authentication: what is the
confirmation flag, and what happens on a host where the assumption is wrong? -->
