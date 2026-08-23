# 🤝 Contributing to Proxmox Optimizer

First off, thank you for considering contributing to Proxmox Optimizer! It's people like you that make this project such a great tool for the Proxmox community.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
  - [Reporting Bugs](#-reporting-bugs)
  - [Suggesting Enhancements](#-suggesting-enhancements)
  - [Pull Requests](#-pull-requests)
- [Style Guidelines](#-style-guidelines)
- [Testing](#-testing)

---

## Code of Conduct

See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md). Short version: be decent to people.

---

## How Can I Contribute?

### 🐛 Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates.

Found a security problem instead? Do not open an issue. See
[SECURITY.md](SECURITY.md) for how to report it privately.

**When reporting a bug, include:**

- **Proxmox Version:** (e.g., PVE 8.1, PBS 3.0)
- **Debian Version:** (e.g., Bookworm 12.x)
- **Script Name:** Which script is affected?
- **Expected Behavior:** What should happen?
- **Actual Behavior:** What actually happened?
- **Steps to Reproduce:** How can we replicate the issue?
- **Error Messages:** Include relevant log output

**Template:**
```markdown
## Bug Report

**Environment:**
- Proxmox Version: 
- Debian Version: 
- Script: 

**Description:**
[Clear description of the bug]

**Steps to Reproduce:**
1. 
2. 
3. 

**Expected Result:**
[What should happen]

**Actual Result:**
[What actually happened]

**Logs/Error Messages:**
```
[paste relevant logs here]
```
```

### 💡 Suggesting Enhancements

Enhancement suggestions are welcome! Please include:

- **Clear Description:** What do you want to achieve?
- **Use Case:** Why is this needed?
- **Proposed Solution:** How would you implement it?
- **Alternatives:** Other approaches you've considered

### 🔀 Pull Requests

1. **Fork** the repository
2. **Create** your feature branch:
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. **Commit** your changes:
   ```bash
   git commit -m 'Add amazing feature'
   ```
4. **Push** to the branch:
   ```bash
   git push origin feature/amazing-feature
   ```
5. **Open** a Pull Request

**PR Guidelines:**

- Keep changes focused and atomic
- Update documentation if needed
- Test on relevant Proxmox versions
- Follow existing code style
- Reference related issues

---

## 📝 Style Guidelines

### Bash Scripts

```bash
#!/usr/bin/env bash
################################################################################
# This is property of ashimov.com
# You are free to use, modify and distribute, however you may not remove this notice.
# Copyright (c) Berik Ashimov :: berik@ashimov.com
################################################################################

# Set locale
export LANG="en_US.UTF-8"
export LC_ALL="C"

# Use meaningful variable names
MY_VARIABLE="value"

# Quote variables
echo "$MY_VARIABLE"

# Use [[ ]] for conditionals
if [[ "$condition" == "true" ]]; then
    # code
fi

# Add comments for complex logic
# This section handles XYZ because...

# Use DEBIAN_FRONTEND for apt operations
/usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' install package
```

### Ansible

- Roles carry their own defaults. Putting a variable only in
  `group_vars/all.yml` means the role breaks the moment someone uses their own
  inventory.
- `meta: end_role` needs ansible-core 2.18. This project supports 2.16, so guard
  a role with `when:` on the role entry in the playbook instead.
- One source of truth per behaviour. If a shell script and a role do the same
  thing, change both in the same commit.
- Validate anything from inventory before templating it into a config file or
  passing it to a command. Use `argv:` rather than a shell string.
- Watch the quoting on regexes. In single-quoted YAML a doubled backslash stays
  doubled, so `\\s` reaches Python as backslash-backslash-s and the pattern
  matches nothing at all, quietly. Use double quotes or single backslashes.

### Documentation

- Use Markdown for all documentation
- Include code examples with proper syntax highlighting
- Keep instructions clear and step-by-step
- Update README and CHANGELOG when adding new features

---

## 🧪 Testing

Before submitting, please test your changes:

### Test Environments

- [ ] Proxmox VE 8.x (Debian 12 Bookworm)
- [ ] Proxmox VE 9.x (Debian 13 Trixie)
- [ ] Proxmox Backup Server 3.x

### Test Checklist

- [ ] Script runs without errors
- [ ] shellcheck is clean (the repo is clean at `severity=style`)
- [ ] Works on a fresh installation
- [ ] Doesn't break existing functionality
- [ ] Documentation and CHANGELOG updated

### What CI runs

```bash
# shellcheck: *.sh plus the two extensionless Hetzner scripts
find . -path ./.git -prune -o -name '*.sh' -type f -print0 | xargs -0 shellcheck
shellcheck hetzner/pve hetzner/pbs

# yaml
yamllint -c .yamllint.yml ansible/ .github/workflows/

# ansible
pip install -r ansible/requirements.txt
cd ansible
ansible-lint -c ../.ansible-lint playbooks/ roles/
molecule test --scenario-name default
```

Molecule syntax-checks every playbook, resolves each one against
`inventory/hosts.ini.example` and fails if a play matches no hosts. If you add a
playbook, add it to `molecule/default/verify.yml` too.

The fixture job runs the playbooks against a fake Proxmox host, which is the
only way most task logic gets exercised at all:

```bash
docker run --rm -v "$PWD:/repo" -w /repo debian:12 bash -c '
  apt-get update -qq && apt-get install -y -qq python3-venv python3-apt iproute2 procps >/dev/null
  python3 -m venv --system-site-packages /venv
  /venv/bin/pip -q install -r ansible/requirements.txt
  export PATH=/venv/bin:$PATH
  ansible-galaxy collection install -r ansible/collections/requirements.yml
  tests/fixture/setup.sh && tests/fixture/run.sh'
```

See `tests/fixture/README.md`. If you add something that renders a template or
parses command output, add an assertion to `tests/fixture/assert-render.yml`:
those are the failures that otherwise report ok and do nothing.

### Destructive scripts

Anything that touches disks or `/etc/network/interfaces` needs a confirmation
variable and a preflight report. Follow what `zfs/createzfs.sh` and
`playbooks/zfs-create.yml` do: refuse to run without the flag, print what is
about to happen, and validate the device list before destroying anything.

---

## 📞 Questions?

If you have questions, feel free to:

- Open an issue with the **question** label
- Check existing issues and documentation

---

<div align="center">

**Thank you for contributing! 🎉**

</div>
