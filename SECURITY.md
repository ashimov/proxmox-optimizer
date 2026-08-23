# Security Policy

These scripts run as root on hypervisors and rewrite partition tables, network
configuration and authentication settings. A bug here is not a cosmetic
problem, so please report anything you find.

## Supported versions

| Version | Supported |
|---------|-----------|
| 1.0.4   | yes |
| 1.0.3 and older | no, upgrade first |

Fixes land on `main` and go out in the next tagged release.

## Reporting a vulnerability

Use GitHub's private vulnerability reporting on the
[Security tab](https://github.com/ashimov/proxmox-optimizer/security/advisories/new),
or email <berik@ashimov.com> if you prefer.

Please do not open a public issue for anything that could be used against
someone's host before there is a fix.

Useful things to include:

- which script or role, and which version or commit
- Proxmox and Debian versions
- what an attacker would be able to do, and what they need to already have
- the smallest reproduction you can manage

This is a small project maintained in spare time. Expect a first reply within a
few days rather than a few hours. If something is being actively exploited, say
so in the subject line.

## What is in scope

The classes of problem that matter most here, roughly in order:

- anything that executes code from the network without verifying it
- injection through inventory variables or script arguments into a config file,
  a shell command or a systemd unit
- a destructive operation that runs without its confirmation flag, or that
  destroys data before validating what it is about to destroy
- a hardening step that silently does nothing, so the host looks protected and
  is not
- anything that locks an operator out of a remote machine

Deliberate trade-offs that are documented are not vulnerabilities: running
Docker inside LXC drops container isolation on purpose, and removing the
subscription notice modifies a vendor file. Both say so where they are used.

## Verifying what you downloaded

Every release ships `SHA256SUMS` for the scripts, signed with cosign keyless.
The commands are in the release notes and in the README. Verify before running
anything, especially if you did not clone the repository.
