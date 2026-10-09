# nixos-vm-config

NixOS for a QEMU VM: sway + foot + kakoune, with two accounts:

- `user`: daily use, the only admin (`wheel`). Builds the system.
- `pentest`: pentesting tools, deliberately **not** an admin. Can only change
  its own home (`users/pentest/`) and apply it with `hms`.

## What a fresh install needs

1. **The VM boots in UEFI mode.** The config uses systemd-boot, which can't
   install on a legacy-BIOS VM (VirtualBox: "Enable EFI"; virt-manager/QEMU:
   UEFI/OVMF firmware).
2. **x86_64** and network access during the install.
3. **With the graphical installer, name the account `user`.** It then keeps
   the password you set there. Otherwise accounts start with `changeme`.
4. **`/etc/nixos/hardware-configuration.nix` exists.** `nixos-generate-config`
   (or the graphical installer) creates it; the config imports it, which is
   why builds use `--impure`.

## Fresh install

Either way, the system clones this repo into `/srv/nixos-vm-config` by itself on
first boot (`nixos-vm-config-checkout` service), so there's no manual clone.

**Option A: straight from the installer ISO with `nixos-install`.** Partition
for UEFI (an EFI partition and a root partition), mount them under `/mnt`,
then:

```sh
sudo nixos-generate-config --root /mnt
# The config imports /etc/nixos/hardware-configuration.nix, and nixos-install
# evaluates it on the live system, so put a copy where it will look:
sudo cp /mnt/etc/nixos/hardware-configuration.nix /etc/nixos/
sudo nixos-install --flake github:ViliLuosujarvi/nixos-vm-config#nixos-vm --impure
reboot
```

`nixos-install` asks for a root password at the end. `user` and `pentest`
both start with the password `changeme`.

**Option B: after the graphical installer** (account named `user`), one
rebuild:

```sh
sudo env NIX_CONFIG="experimental-features = nix-command flakes" \
  nixos-rebuild switch --flake github:ViliLuosujarvi/nixos-vm-config#nixos-vm --impure
reboot
```

Then, **on a text console** (Ctrl+Alt+F2 at the login screen). Until `hms` has
run there's no terminal app or window-manager config, so a graphical session
would leave you with nothing to type into:

1. Log in as `user`. If zsh shows a "new user" menu, press `q`. Run `passwd`
   if you still have `changeme`, then `hms`.
2. Log in as `pentest` (password `changeme`). Run `passwd`, then `hms`.
3. Back on the login screen (Ctrl+Alt+F1), log in normally; sway is the
   only session.

If `hms` says `/srv/nixos-vm-config` has no flake, the first-boot clone hadn't
finished (it needs the network): wait a moment, or run
`sudo systemctl start nixos-vm-config-checkout`.

## Day to day

| Alias | Does |
|---|---|
| `nrs` | rebuild and switch the system (`user` only) |
| `nrt` / `nrb` | try a rebuild without a boot entry / only build it |
| `hms` | apply your own home (either account, no sudo) |
| `nfu` / `nup` | update pinned inputs / update and rebuild everything |
| `ngc 7d` | delete generations older than 7 days, then garbage-collect |

## VM host settings (CPU usage)

The VM is meant to run **without 3D acceleration** (smaller attack surface on
the host), so the guest draws everything on the CPU. To keep that cheap:

- **Sway draws with pixman** (plain 2D, set in `system/configuration.nix`).
  Compositors that only draw through OpenGL, like Hyprland, get it emulated
  on the CPU (llvmpipe), which is far more expensive.
- **Video device: virtio-vga, 3D off** (`-device virtio-vga`, or virt-manager
  Video model "Virtio" without "3D acceleration"). VGA/Bochs/QXL have no
  hardware mouse cursor, so every mouse move makes the guest redraw.
- **Moderate resolution, no scaling** (e.g. 1920×1080). Software rendering
  cost grows with the number of pixels.
- **Prefer a local display window** (`-display gtk` or `-display sdl`) over
  SPICE/VNC. Remote viewers make the host compress every changed frame.

An idle desktop should then sit near 0% CPU. If it doesn't, `pkill waybar`
and watch `btop`: anything that redraws constantly shows up immediately.
