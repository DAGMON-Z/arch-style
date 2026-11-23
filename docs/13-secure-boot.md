# 13. Secure Boot (optional)

Secure Boot makes the firmware start only boot programs signed by a key it
trusts. Windows 11 and some games want it on: **Valorant's anti-cheat
(Vanguard) requires Secure Boot with the motherboard's factory keys.**

Arch doesn't support Secure Boot out of the box. This guide uses **shim**, the
same method as Ubuntu and Fedora, so the factory keys stay untouched and
Windows, Valorant and Arch all boot with Secure Boot on.

> **Do this last**, after the rest of the setup works. Read it all once first.
> It changes how your computer starts. Done carefully it's safe, and there's a
> way back at every step.

## How it works

```text
firmware (factory keys, includes Microsoft's)
  └─ shim         /boot/EFI/BOOT/BOOTX64.EFI   signed by Microsoft
       └─ GRUB    /boot/EFI/BOOT/grubx64.efi   signed with your own key
            └─ Arch kernel                     signed with your own key
```

1. **shim** is a small boot program signed by Microsoft, so the factory keys
   accept it.
2. You make **your own key** with `sbctl`, and register it with shim once, as a
   **MOK** (Machine Owner Key), in a blue screen called **MokManager**.
3. GRUB and the kernel are signed with your key, so shim accepts them.
4. Windows starts with Microsoft's own signature, unchanged.

> **Why not put your own keys in the firmware?** That works for Windows too,
> but Valorant's anti-cheat refuses Secure Boot with anything but the factory
> keys ("Secure Boot needs to be at factory settings"). With shim, the firmware
> keeps its factory keys.

## What you need

- Arch installed with **GRUB** in the **removable location**
  (`/boot/EFI/BOOT/BOOTX64.EFI`, the archinstall default) and `/boot` as the EFI
  partition.
- The firmware's Secure Boot keys at **factory settings** (the default on a new
  computer).
- If Windows uses **BitLocker**, your recovery key, in case Windows asks for it
  after Secure Boot changes (find it at account.microsoft.com/devices/recoverykey).

Check how your computer boots now:

```bash
sudo find /boot -iname '*.efi'
efibootmgr
```

- `find` should list `/boot/EFI/BOOT/BOOTX64.EFI`.
- `efibootmgr` lists the firmware's boot entries. If an entry points to another
  file, such as `\EFI\GRUB\grubx64.efi`, the firmware would skip shim. Remove
  that entry with `sudo efibootmgr -b XXXX -B`, where `XXXX` is its number, so
  the computer uses the removable location.

## Step 1: Install the tools

```bash
sudo pacman -S --needed sbctl mokutil sbsigntools
yay -S shim-signed-bin
```

- `sbctl` creates your key and signs files with it. Its pacman hook re-signs
  the kernel after every kernel update.
- `mokutil` registers your key with shim.
- `sbsigntools` checks signatures (`sbverify`).
- `shim-signed-bin` (AUR) is Fedora's shim, signed by Microsoft. It installs to
  `/usr/share/shim-signed/`.

## Step 2: Create your key and back up

```bash
sudo sbctl create-keys
sudo cp -a /boot/EFI /boot/EFI.bak-before-shim
```

- `sbctl create-keys` creates your keys in `/var/lib/sbctl/keys`. Never share
  them. Only the `db` key is used here; **don't run `sbctl enroll-keys`**, which
  would replace the firmware's factory keys.
- `cp -a` backs up the boot files exactly as they are.

## Step 3: Install shim, GRUB for shim, and the update hook

From the repository folder:

```bash
cd ~/neon-arch
sudo install -m 755 system/usr/local/bin/grub-shim-install /usr/local/bin/
sudo install -D -m 644 system/etc/pacman.d/hooks/95-grub-shim.hook /etc/pacman.d/hooks/95-grub-shim.hook
sudo install -m 755 system/etc/grub.d/01_gfxmode_secureboot /etc/grub.d/
sudo cp /usr/share/shim-signed/shimx64.efi /boot/EFI/BOOT/BOOTX64.EFI
sudo cp /usr/share/shim-signed/mmx64.efi /boot/EFI/BOOT/mmx64.efi
sudo grub-shim-install
sudo sbctl sign -s /boot/vmlinuz-linux
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

What each part does:

- **`grub-shim-install`** builds GRUB for shim and signs it:
  - GRUB started through shim **can't load modules from the disk**, so it
    builds in every module it needs (including `efibootnext`, used by the
    Windows entry in the boot menu).
  - It adds GRUB's **SBAT** information. shim uses SBAT to block old, insecure
    GRUB versions. Arch's file can declare an older level than GRUB really has,
    so the script uses the level `grub-install` reports.
  - It saves GRUB as `/boot/EFI/BOOT/grubx64.efi`, the file shim starts, and
    signs it with your key.
- **`95-grub-shim.hook`** runs `grub-shim-install` after every GRUB update, so
  updates never leave you with an unsigned or outdated GRUB.
- **`01_gfxmode_secureboot`** makes the boot menu text bigger. GRUB started
  through shim refuses to load fonts ("prohibited by secure boot policy"), so
  the [theme](10-boot-and-login-themes.md) falls back to GRUB's small built-in
  font. This runs the menu at 1280×720, so the screen stretches the text 1.5×.
- The two `cp` commands put **shim** where the firmware looks
  (`BOOTX64.EFI`), with **MokManager** next to it.
- `sbctl sign -s /boot/vmlinuz-linux` signs the kernel. `-s` saves it in
  sbctl's list, so it's re-signed after kernel updates.
- `grub-mkconfig` rebuilds the boot menu.

Check:

```bash
sudo sbctl verify
```

`grubx64.efi` and `vmlinuz-linux` should be ✓. `BOOTX64.EFI` (shim) and
`mmx64.efi` show ✗: they aren't signed with your key, they carry Microsoft's
and Fedora's signatures, which is correct.

## Step 4: Register your key with shim

```bash
sudo openssl x509 -in /var/lib/sbctl/keys/db/db.pem -outform DER -out /var/lib/sbctl/keys/db/db.der
sudo mokutil --import /var/lib/sbctl/keys/db/db.der
```

- `openssl x509 ... -outform DER` converts your key's certificate to the format
  mokutil needs.
- `mokutil --import` asks you to choose a **one-time password**. You type it
  once at the next boot. MokManager uses a US keyboard, so digits are safest.

> If mokutil says the key is **already in db**, your firmware still has custom
> keys (for example from the old method of this guide). See
> [Coming from the old method](#coming-from-the-old-method).

## Step 5: Restart and enroll the key

1. Restart. A **blue MokManager screen** appears instead of the boot menu, once.
   Press a key within 10 seconds.
2. Choose **Enroll MOK** → **Continue** → **Yes**, type your one-time password,
   then **Reboot**.
3. Enter the firmware settings (often `Del` or `F2` while starting) and make sure
   **Secure Boot** is **Enabled**, with the factory (standard) keys. Save and
   restart.

Arch now boots through shim. Check:

```bash
mokutil --sb-state
mokutil --list-enrolled | grep Subject
```

- `SecureBoot enabled`.
- Your key appears as `CN=Database Key`. Fedora's key is listed too: it's built
  into shim.

Windows starts from the **Windows Boot Manager (EFI BootNext)** entry in the
boot menu, or from the firmware's boot menu (`F12` on many boards).

## After updates

- **Kernel updates:** sbctl's hook signs the new kernel automatically.
- **GRUB updates:** the `95-grub-shim` hook runs `grub-shim-install`.

Check anytime:

```bash
sudo sbctl verify
```

If anything you boot from shows ✗, run `sudo grub-shim-install`.

> **Never run plain `grub-install`** (for example with `--removable`) with this
> setup: it would overwrite shim. Always use `sudo grub-shim-install`.

## Coming from the old method

An older version of this guide put your own keys in the firmware
(`sbctl enroll-keys -m`). Valorant refuses that. To switch:

1. Do steps 1 to 3 above (skip `sbctl create-keys`, you already have keys).
   Restart once to check Arch still boots: the current keys trust everything.
2. In the firmware settings, choose **Restore Factory Keys** (sometimes "Install
   default Secure Boot keys") and set **Secure Boot** to **Disabled** for one
   boot.
3. Boot Arch and do step 4. It works now, because your key is no longer in the
   firmware.
4. Do step 5: enroll the key in MokManager, then turn Secure Boot back on.

## If it won't boot

- **A Secure Boot error before the menu:** turn **Secure Boot off** in the
  firmware settings. shim still starts GRUB with Secure Boot off. Boot Arch,
  run `sudo sbctl verify` and `sudo grub-shim-install`, and try again.
- **`prohibited by secure boot policy` in GRUB:** GRUB tried to load a module
  from the disk. Add it to the `MODS` list in `/usr/local/bin/grub-shim-install`
  and run `sudo grub-shim-install`.
- **The blue MokManager screen didn't appear, or you missed it:** run the
  `mokutil --import` command again and restart.
- **To go back to the old boot files:** boot Arch with Secure Boot off and
  restore the backup:

  ```bash
  sudo cp -a /boot/EFI.bak-before-shim/BOOT/BOOTX64.EFI /boot/EFI/BOOT/BOOTX64.EFI
  ```

## Undoing it

1. Turn **Secure Boot** off in the firmware settings.
2. Restore the backup (above), or reinstall GRUB normally:
   `sudo grub-install --target=x86_64-efi --efi-directory=/boot --removable`.
3. Remove the hook and the menu script:
   `sudo rm /etc/pacman.d/hooks/95-grub-shim.hook /etc/grub.d/01_gfxmode_secureboot`,
   then `sudo grub-mkconfig -o /boot/grub/grub.cfg`.

Learn more: the Arch Wiki's
[Secure Boot page](https://wiki.archlinux.org/title/Unified_Extensible_Firmware_Interface/Secure_Boot)
(section "shim") and the [sbctl project](https://github.com/Foxboron/sbctl).
