# Test fixture

The roles refuse to run on anything that is not Proxmox, which is correct on a
real host and useless in CI: the very first task aborts and nothing else is ever
evaluated. That is how a playbook targeting a non-existent inventory group, a
regex that matches nothing and a role building a 404 URL all reached main.

`setup.sh` fakes just enough of a Proxmox host for a check-mode run to walk
through every task: `/etc/pve/.version` and stub `pve*` binaries that print
plausible output. Nothing here talks to real storage.

```bash
sudo tests/fixture/setup.sh
cd ansible
ansible-playbook -i ../tests/fixture/inventory.ini playbooks/proxmox.yml --check --diff
ansible-playbook -i ../tests/fixture/inventory.ini ../tests/fixture/assert-render.yml
```

In a container, which is what CI does:

```bash
docker run --rm -v "$PWD:/repo" -w /repo debian:12 bash -c '
  apt-get update -qq && apt-get install -y -qq python3-venv python3-apt iproute2 >/dev/null
  python3 -m venv --system-site-packages /venv          # --system-site-packages: the apt module needs python3-apt
  /venv/bin/pip -q install "ansible>=9,<11"
  export PATH=/venv/bin:$PATH
  ansible-galaxy collection install -r ansible/collections/requirements.yml
  tests/fixture/setup.sh && tests/fixture/run.sh'
```

`assert-render.yml` checks the things that are easy to get wrong and impossible
to notice: the signed-by regexes, the mdstat parsing, ARC min against max, and
the tinc and firewall templates.
