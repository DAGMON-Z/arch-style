# 13. Secure Boot (optional)

**Secure Boot** is a firmware feature that only starts programs signed with a
trusted key. Some games' anti-cheat, some company laptops, and Windows 11
dual-boot setups want it turned on.

Arch doesn't support Secure Boot out of the box. This guide uses **sbctl** to
create **your own keys**, sign GRUB and the Linux kernel with them, and tell the
firmware to trust those keys.

> **Read the whole page before starting.** You'll change firmware settings and
> reinstall GRUB. If something goes wrong, the fix is usually simple: turn
> Secure Boot off again in the firmware settings. Still, have an Arch USB
> nearby, and back up your files first.

This guide fits the setup from [chapter 1](01-install.md): **GRUB**,
installed to the **removable location**, **no UKI**, and `/boot` as the EFI
partition. Other setups need different steps.

## How it works

1. The firmware holds a list of trusted keys.
2. You add your own key, plus Microsoft's keys (explained below).
3. You sign GRUB and the kernel with your key.
4. With Secure Boot on, the firmware only starts files with a trusted signature.

GRUB itself also gets stricter with Secure Boot on: it refuses to load extra
modules from disk. So the modules it needs are built into GRUB when you
reinstall it (step 4).

## Step 1: Check the current state

```bash
sudo pacman -S --needed sbctl
sbctl status
```

Before you start, it usually shows:

```text
Installed:   ✘ sbctl is not installed
Setup Mode:  ✘ Disabled
Secure Boot: ✘ Disabled
```

## Step 2: Put the firmware in Setup Mode

**Setup Mode** means the firmware has no keys yet, so it accepts new ones.

1. Restart and open the firmware settings. On most laptops you press **F2** or
   **Del** while the logo shows. Some MSI laptops also use **F2**.
2. Find the **Secure Boot** settings, usually under **Security** or **Boot**.
3. Choose the option that clears the keys. Depending on the manufacturer, it's
   called **Delete all Secure Boot keys**, **Clear Secure Boot keys**, **Reset
   to Setup Mode** or **Erase all Secure Boot settings**.
4. Leave **Secure Boot itself turned off** for now.
5. Save and boot into Arch.

Check it worked:

```bash
sbctl status
```

`Setup Mode` should now say **Enabled**.

> Menu names differ between manufacturers and firmware versions. If you can't
> find the option, search the web for your laptop model and "secure boot setup
> mode".

## Step 3: Create and enroll your keys

```bash
sudo sbctl create-keys
sudo sbctl enroll-keys -m
```

- `create-keys` makes your own signing keys. They're stored in
  `/var/lib/sbctl/keys`. Never share them.
- `enroll-keys` puts the keys into the firmware.
- **`-m` also adds Microsoft's keys. Don't leave it out.** Some hardware, such
  as graphics cards and parts of the laptop's own firmware, is signed with
  Microsoft's keys. sbctl's manual warns that if that firmware can't be
  validated, the device can stop working. `-m` also keeps Windows bootable on
  dual-boot systems.

If `enroll-keys` stops with an error about **Option ROMs**, read the
[sbctl FAQ](https://github.com/Foxboron/sbctl/wiki/FAQ#option-rom) before doing
anything else. Don't force it with `--yes-this-might-brick-my-machine`.

## Step 4: Reinstall GRUB with its modules built in

First, find the EFI files on your boot partition:

```bash
sudo find /boot -iname '*.efi'
```

With archinstall's **removable location** choice, GRUB is at
`/boot/EFI/BOOT/BOOTX64.EFI`. You might also have `/boot/EFI/GRUB/grubx64.efi`.

Reinstall GRUB to the removable location, with the modules built in:

```bash
sudo grub-install --target=x86_64-efi --efi-directory=/boot --removable \
  --disable-shim-lock \
  --modules="all_video boot bli cat chain configfile echo efifwsetup efinet ext2 fat font gettext gfxmenu gfxterm gfxterm_background gzio halt help jpeg keystatus loadenv loopback linux ls lsefi lsefimmap lsefisystab memdisk minicmd normal part_gpt part_msdos password_pbkdf2 png probe reboot regexp search search_fs_file search_fs_uuid search_label serial sleep smbios test tpm true video"
```

- `--removable` writes `EFI/BOOT/BOOTX64.EFI`, the path every UEFI firmware checks.
- `--disable-shim-lock` tells GRUB that it's signed with your own key, not
  started through Microsoft's "shim" loader.
- `--modules=...` builds these modules into GRUB. The list covers ext4 and FAT
  disks, the Linux loader, and the graphics, fonts and images used by the
  [boot menu theme](10-boot-and-login-themes.md).

If you also had `/boot/EFI/GRUB/grubx64.efi`, update that copy too:

```bash
sudo grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB \
  --disable-shim-lock --modules="(the same list as above)"
```

Then rebuild the menu:

```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

## Step 5: Sign GRUB and the kernel

```bash
sudo sbctl sign -s /boot/EFI/BOOT/BOOTX64.EFI
sudo sbctl sign -s /boot/vmlinuz-linux
```

If `/boot/EFI/GRUB/grubx64.efi` exists, sign it too:

```bash
sudo sbctl sign -s /boot/EFI/GRUB/grubx64.efi
```

`-s` saves each file in sbctl's list, so `sbctl sign-all` can sign them all
again later.

Check that everything is signed:

```bash
sudo sbctl verify
```

Every file should show a ✔. If one shows ✘, sign it with
`sudo sbctl sign -s <file>`.

## Step 6: Turn Secure Boot on

1. Restart into the firmware settings.
2. Turn **Secure Boot** on.
3. Save and boot.

If Arch starts, check:

```bash
sbctl status
```

`Secure Boot` should say **Enabled**.

## After updates

A kernel update replaces `/boot/vmlinuz-linux`, and a GRUB reinstall replaces
the EFI file. **An unsigned file won't boot with Secure Boot on.**

After a kernel update, or after running `grub-install`, check:

```bash
sudo sbctl verify
```

If anything shows ✘, sign everything in sbctl's list again:

```bash
sudo sbctl sign-all
```

sbctl may re-sign automatically after updates, depending on how the package is
set up. Running `sbctl verify` is how you know for sure.

> **Important:** a `grub` package update doesn't change the installed GRUB by
> itself. If you ever run `grub-install` again, use the same
> `--disable-shim-lock --modules=...` options, then `sudo sbctl sign-all`.

## If it won't boot

- **"Secure Boot violation" or a similar message:** something isn't signed. Go
  into the firmware settings, turn **Secure Boot off**, boot Arch, run
  `sudo sbctl verify`, sign what's missing, and try again.
- **GRUB shows a plain text menu instead of the theme:** the menu still works.
  A module the theme needs is missing from the `--modules` list.
- **Still stuck:** turn Secure Boot off. Your keys stay in the firmware, and
  you can try again later. Some firmware also has a **Restore factory keys**
  option, which puts the original keys back.

## Undoing it

1. Turn **Secure Boot** off in the firmware settings.
2. Optionally, choose **Restore factory keys** there.
3. Optionally, reinstall GRUB normally:

   ```bash
   sudo grub-install --target=x86_64-efi --efi-directory=/boot --removable
   sudo grub-mkconfig -o /boot/grub/grub.cfg
   ```

Learn more: the [sbctl project](https://github.com/Foxboron/sbctl) and the Arch
Wiki page
[UEFI/Secure Boot](https://wiki.archlinux.org/title/Unified_Extensible_Firmware_Interface/Secure_Boot).
