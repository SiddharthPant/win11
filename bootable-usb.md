# Create a Windows 11 Bootable USB From the Official ISO

This guide starts from the official Windows 11 ISO downloaded from Microsoft and creates a
UEFI-bootable USB installer. The macOS flow is the one intended for this repo.

Microsoft download page:

<https://www.microsoft.com/en-us/software-download/windows11>

Microsoft USB/DISM reference:

<https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/install-windows-from-a-usb-flash-drive?view=windows-11>

## Requirements

- A blank USB drive. Microsoft says at least 8 GB; use 16 GB or larger to avoid space surprises.
- The official Windows 11 x64 ISO from Microsoft.
- For this repo's unattended install: `autounattend.xml` copied to the USB root.
- On macOS: Homebrew and `wimlib`.

```zsh
brew install wimlib
```

## Why the WIM Must Be Split

UEFI firmware reliably boots Windows setup from a FAT32 USB drive. FAT32 cannot store files larger
than 4 GB, and recent Windows 11 ISOs commonly contain `sources/install.wim` larger than that.

The fix is to copy everything except `install.wim`, then split `install.wim` into `.swm` chunks.
Windows Setup reads `install.swm`, `install2.swm`, and the rest automatically.

Avoid using `dd` directly on the ISO. The Windows ISO is not the same shape as a USB installer, and
the result is often not UEFI-bootable on real PCs.

## macOS: Create the USB

Run these commands from the repo root.

1. Identify the USB disk:

   ```zsh
   diskutil list
   ```

   Look for the external USB device, for example `/dev/disk4`. Be very careful with this value; the
   erase command below destroys the selected disk.

2. Erase the USB as FAT32:

   ```zsh
   diskutil eraseDisk MS-DOS WIN11 MBR /dev/diskN
   ```

   Replace `/dev/diskN` with the real USB disk, such as `/dev/disk4`.

3. Mount the Windows 11 ISO:

   ```zsh
   hdiutil attach ~/Downloads/Win11_*.iso
   ls /Volumes
   ```

   Set variables for the mounted ISO and USB. Adjust the ISO volume name to match what `ls /Volumes`
   shows.

   ```zsh
   ISO="/Volumes/CCCOMA_X64FRE_EN-US_DV9"
   USB="/Volumes/WIN11"
   ```

4. Copy the ISO contents except the oversized WIM:

   ```zsh
   rsync -avh --exclude sources/install.wim "$ISO/" "$USB/"
   ```

5. Split `install.wim` into FAT32-safe chunks:

   ```zsh
   wimlib-imagex split "$ISO/sources/install.wim" "$USB/sources/install.swm" 3800
   ```

6. Add the unattended answer file:

   ```zsh
   cp ./autounattend.xml "$USB/autounattend.xml"
   ```

   For a mostly vanilla install, copy `autounattend.minimal.xml` instead and rename it on the USB:

   ```zsh
   cp ./autounattend.minimal.xml "$USB/autounattend.xml"
   ```

7. Flush writes and eject:

   ```zsh
   sync
   diskutil eject /dev/diskN
   hdiutil detach "$ISO"
   ```

## Windows: Create the USB With DISM

Use this if you already have a Windows machine available. It uses built-in Microsoft tools.

1. Mount the ISO in File Explorer. Note the mounted ISO drive letter, for example `D:`.
2. Open Terminal or PowerShell as Administrator.
3. Prepare the USB with DiskPart:

   ```text
   diskpart
   list disk
   select disk N
   clean
   convert mbr
   create partition primary
   format fs=fat32 quick label=WIN11
   assign letter=U
   exit
   ```

   Replace `N` with the USB disk number. The example assigns the USB as `U:`.

4. Copy all ISO files except `install.wim`:

   ```powershell
   robocopy D:\ U:\ /S /MAX:3800000000
   ```

5. Split the image with DISM:

   ```powershell
   Dism /Split-Image /ImageFile:D:\sources\install.wim /SWMFile:U:\sources\install.swm /FileSize:3800
   ```

6. Copy the answer file to the USB root if using this repo:

   ```powershell
   Copy-Item .\autounattend.xml U:\autounattend.xml
   ```

## Boot the Installer

1. Insert the USB into the target PC.
2. Enter firmware boot menu.
3. Choose the `UEFI:` entry for the USB drive.
4. Keep CSM/Legacy boot disabled.
5. If using this repo's full answer file, still choose the target disk manually during Windows Setup.

## Troubleshooting

- `File too large`: `install.wim` was copied directly to FAT32. Delete it from the USB and run the
  split command.
- USB does not appear as UEFI-bootable: confirm the USB has a FAT32 partition and boot the `UEFI:`
  entry, not a legacy entry.
- Setup ignores `autounattend.xml`: confirm the file is named exactly `autounattend.xml` and is at
  the USB root, not inside a folder.
- Windows Setup cannot see your storage device: add the motherboard/storage driver to the USB and
  load it during setup, or switch the storage controller to a standard AHCI/NVMe mode in firmware.
