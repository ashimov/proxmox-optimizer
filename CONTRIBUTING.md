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

This project and everyone participating in it is governed by our commitment to providing a welcoming and inclusive environment. Please be respectful and constructive in all interactions.

---

## How Can I Contribute?

### 🐛 Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates.

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

### Documentation

- Use Markdown for all documentation
- Include code examples with proper syntax highlighting
- Keep instructions clear and step-by-step
- Update README when adding new features

---

## 🧪 Testing

Before submitting, please test your changes:

### Test Environments

- [ ] Proxmox VE 8.x (Debian 12 Bookworm)
- [ ] Proxmox VE 9.x (Debian 13 Trixie)
- [ ] Proxmox Backup Server 3.x

### Test Checklist

- [ ] Script runs without errors
- [ ] No shellcheck warnings (if applicable)
- [ ] Works on fresh installation
- [ ] Doesn't break existing functionality
- [ ] Documentation updated

### Running ShellCheck

```bash
# Install shellcheck
apt-get install shellcheck

# Check a script
shellcheck your-script.sh
```

---

## 📞 Questions?

If you have questions, feel free to:

- Open an issue with the **question** label
- Check existing issues and documentation

---

<div align="center">

**Thank you for contributing! 🎉**

</div>
