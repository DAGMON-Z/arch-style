# 17. SSH: control another computer from this one

SSH lets you open a terminal on another computer over the network, for example
to fix your desktop PC from your laptop. This setup makes it short and
password-free: `ssh pc`.

## On the computer you connect TO (for example the PC)

SSH is off by default, so nobody can connect. Turn it on only when needed:

```bash
sshon       # start SSH (prints this computer's address)
sshoff      # stop it again
sshstatus   # "active" or "inactive"
```

These are shortcuts in `~/.zshrc` for `sudo systemctl start sshd` and
`sudo systemctl stop sshd`. `sshd` is the SSH server. `start` only runs it
until the next restart, so after a restart it's off again.

## On the computer you connect FROM (for example the laptop)

**1. A key** (once). An SSH key is a pair of files: a private one that stays on
this computer, and a public one you give to the other computer.

```bash
[ -f ~/.ssh/id_ed25519 ] || ssh-keygen -t ed25519
```

- `[ -f ~/.ssh/id_ed25519 ] ||` only creates a key if you don't have one.
- `ssh-keygen -t ed25519` creates a modern key. Press Enter at the questions.

**2. A short name** (once). Create `~/.ssh/config` with your other computer's
address and user name:

```text
Host pc
    HostName 192.168.1.20
    User yourname
    IdentityFile ~/.ssh/id_ed25519
```

Now `ssh pc` means `ssh yourname@192.168.1.20`. Find the address with `sshon`
on the other computer.

**3. No more passwords** (once, while SSH is on there):

```bash
ssh-copy-id pc
```

It asks for the other computer's password one last time and copies your public
key there. From then on, `ssh pc` logs in with the key.

**Connect:**

```bash
ssh pc
```

Type `exit` to leave.

## Tips

- **The address can change** when the router gives out a new one. Reserve a
  fixed address for the PC in your router's settings (often called "DHCP
  reservation" or "static lease"), or update `HostName` in `~/.ssh/config`.
- **Copy files:** `scp file.txt pc:~/` copies to the PC's home folder, and
  `scp pc:~/file.txt .` copies back.
- `REMOTE HOST IDENTIFICATION HAS CHANGED` after reinstalling the other
  computer is expected. Remove the old entry with `ssh-keygen -R 192.168.1.20`.
