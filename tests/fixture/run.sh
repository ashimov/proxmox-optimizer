#!/usr/bin/env bash
################################################################################
# This is property of ashimov.com
# You are free to use, modify and distribute, however you may not remove this notice.
# Copyright (c) Berik Ashimov :: berik@ashimov.com
################################################################################
#
# Runs the playbooks against the fixture. Expects tests/fixture/setup.sh to have
# run first. Check mode only, nothing here changes a real system.
#
################################################################################
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/../.."
inventory="tests/fixture/inventory.ini"

cd ansible

echo "== rendering and parsing checks =="
ansible-playbook -i "../${inventory}" ../tests/fixture/assert-render.yml

echo
echo "== proxmox.yml, check mode =="
ansible-playbook -i "../${inventory}" playbooks/proxmox.yml --check --diff

echo
echo "== validate-postinstall.yml, check mode =="
ansible-playbook -i "../${inventory}" playbooks/validate-postinstall.yml --check || \
  echo "NOTE: validation reports drift on the fixture, which is expected"

echo
echo "Fixture run complete"
