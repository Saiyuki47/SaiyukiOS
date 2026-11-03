# SaiyukiOS

```
                                ,
                           ,##/#P
                      ,#####//##P
                  d########//##P          SaiyukiOS 1.0 „sprout“
               d########//###P            ────────────────────────
             d#########//####P            Basis:    Debian 13 (trixie)
           d#########//#####P             Desktop:  KDE Plasma 6 · Wayland
          d########//######P              Dateien:  Dolphin
         d########//######P               Grafik:   NVIDIA-Treiber vorinstalliert
         #######//######P
         #####//######P
          Y##//####P
           //###"
         //
       //
     //
```

Eine eigene Desktop-Linux-Distribution auf Basis von **Debian 13 „trixie“** mit
**KDE Plasma unter Wayland**, **Dolphin** als Dateimanager und besonderem
Augenmerk auf **NVIDIA-Grafikkarten**.

Name, Version, Farben und Sprache stehen zentral in [`distro.conf`](distro.conf).
Logo, Hintergrundbild und Bootbild werden daraus automatisch erzeugt.

## Was drin ist

| Bereich       | Inhalt                                                                         |
|---------------|--------------------------------------------------------------------------------|
| Basis         | Debian 13 stable, inkl. Sicherheitsupdates, `non-free` und `non-free-firmware` |
| Desktop       | KDE Plasma 6, Wayland-Sitzung als Standard, auch der Anmeldebildschirm (SDDM) |
| Design        | Eigenes globales Design „SaiyukiOS“ (Breeze Dunkel, grüner Akzent), Blatt-Logo |
| Dateimanager  | Dolphin mit Vorschaubildern für Videos, PDFs, Bilder usw.                     |
| Programme     | Firefox ESR, LibreOffice, VLC, Kate, Okular, Gwenview, Spectacle, Discover …  |
| NVIDIA        | Treiber 595 inkl. RTX 50, 550 für GTX 750–1080, automatische Wahl, Unnötiges wird entfernt |
| Terminal      | Konsole begrüßt mit `fastfetch` und dem ASCII-Blatt                           |
| Installer     | Calamares mit eigenem Logo, Farben und Diashow                                |
| Sprache       | Deutsch vorkonfiguriert (Tastatur, Zeitzone, Übersetzungen)                    |
| Booten        | Hybrid-ISO für USB-Stick und DVD, BIOS **und** UEFI                            |

## NVIDIA

Für aktuelle Karten kommt der Treiber direkt aus **NVIDIAs offizieller
Debian-13-Paketquelle**, festgelegt auf die Treiberreihe **595** (einstellbar
in `distro.conf`). Diese Reihe unterstützt die **RTX 50**.

Ab Treiberreihe 590 unterstützt NVIDIA ältere Karten (GTX 750 bis GTX 1080)
nicht mehr. Dafür setzt SaiyukiOS automatisch **Debians NVIDIA-Treiber 550**
ein. Die nötigen Pakete stecken schon im Image.

### Automatische Treiberwahl

| Grafikkarte                          | Live-System              | Nach der Installation                            |
|--------------------------------------|--------------------------|--------------------------------------------------|
| RTX 20 / GTX 16 bis **RTX 50**       | NVIDIA 595 (offene Module) | NVIDIA 595 (offene Module)                       |
| GTX 750 bis GTX 1080, Titan V        | nouveau (frei)           | Debians NVIDIA 550, auch ohne Internet           |
| ältere NVIDIA-Karten                 | nouveau                  | nouveau, NVIDIA-Treiber werden **entfernt**      |
| keine NVIDIA-Karte (Intel/AMD)       | Mesa                     | Mesa, NVIDIA-Treiber werden **entfernt**         |

- **Bei der Installation** erkennt ein eigener Installer-Schritt die
  Grafikkarte. Er behält nur den passenden Treiber und entfernt alles
  Unnötige: andere NVIDIA-Pakete, den Zwischenspeicher mit dem 550er-Treiber,
  und wenn gar kein NVIDIA-Treiber gebraucht wird, auch DKMS, die
  Kernel-Header und die NVIDIA-Paketquelle.
- **Später**, z. B. nach dem Einbau einer anderen Grafikkarte:
  `sudo saiyukios-driver-setup`. Mit `--dry-run` zeigt es nur an, was es tun würde.
- **Notfall:** Im Bootmenü „Open-Source-Grafiktreiber (nouveau)“ wählen.

### Einstellungen für Wayland und Laptops

- **Wayland:** `nvidia-drm.modeset=1` und `fbdev=1` sind gesetzt.
- **Standby und Ruhezustand:** Der Grafikspeicher wird gesichert
  (`NVreg_PreserveVideoMemoryAllocations`), dazu laufen die NVIDIA-Dienste.
  So bleibt der Bildschirm nach dem Aufwachen nicht schwarz.
- **Videobeschleunigung:** `nvidia-vaapi-driver` stellt den Videodecoder per
  VA-API bereit. Das wird automatisch aktiviert, wenn NVIDIA die einzige
  Grafikkarte ist.
- **Laptops mit zwei Grafikchips (Optimus):** In Plasma per Rechtsklick
  „Mit dedizierter Grafikkarte starten“ wählen oder im Terminal
  `prime-run programm` eingeben.
- **Secure Boot:** Selbst kompilierte Module müssen signiert sein. Nach der
  Installation einmal `sudo saiyukios-nvidia-secureboot` ausführen und beim
  Neustart den Schlüssel bestätigen. Alternativ Secure Boot abschalten.
- **Diagnose:** `nvidia-smi`, `nvtop`, `vulkaninfo --summary`.

## Bauen

Rechne mit 30–90 Minuten und etwa 20 GB freiem Speicher.

**1. Auf einem Debian-Rechner**

```bash
sudo ./build.sh
```

**2. Auf jedem anderen Linux (Ubuntu, Fedora, Arch …) mit Docker**

```bash
./build-in-docker.sh
```

**3. Ohne eigenen Rechner – mit GitHub Actions**

Projekt auf GitHub hochladen, dann *Actions → ISO bauen → Run workflow*.
Das fertige ISO liegt anschließend unter *Artifacts* zum Download bereit.

Ergebnis: `saiyukios-1.0-amd64.hybrid.iso` samt `.sha256`-Prüfsumme.

## Testen

```bash
./test-vm.sh              # Live-System in einer VM starten (BIOS)
./test-vm.sh --uefi       # im UEFI-Modus
./test-vm.sh --disk       # mit virtueller Festplatte, um den Installer zu testen
./test-vm.sh --boot-disk  # das installierte System von der virtuellen Platte starten
```

Benötigt `qemu-system-x86` und `ovmf`. Im Live-System ist der Benutzer `live`
mit dem Passwort `live` automatisch angemeldet. Den Installer startest du
über **„SaiyukiOS installieren“**.

In der VM gibt es keine NVIDIA-Karte. Den NVIDIA-Teil testest du am besten
direkt per USB-Stick auf echter Hardware.

**Auf einen USB-Stick schreiben:** Das löscht den Stick! Prüfe `/dev/sdX`
vorher mit `lsblk`.

```bash
sudo dd if=saiyukios-1.0-amd64.hybrid.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

Unter Windows geht das z. B. mit Rufus oder balenaEtcher.

## Anpassen

| Was möchtest du ändern?          | Wo?                                                                   |
|----------------------------------|-----------------------------------------------------------------------|
| Name, Version, Farben, Sprache   | `distro.conf`                                                         |
| Programme hinzufügen/entfernen   | `config/package-lists/*.list.chroot` (ein Paketname pro Zeile)        |
| Logo, Hintergrund, Bootbild      | `branding/*.svg.in` (SVG mit Platzhaltern wie `@NAME@`, `@PRIMARY@`)  |
| ASCII-Logo (fastfetch, Login)    | `branding/ascii-logo.txt` (`$1` = grün, `$2` = weiß)                  |
| Plasma-Design, SDDM, Dolphin     | `config/hooks/live/0300-desktop-defaults.hook.chroot`                 |
| NVIDIA-Treiberreihe              | `distro.conf` (`NVIDIA_BRANCH`)                                       |
| NVIDIA-Pakete und Treiberwahl    | `nvidia/` und `config/hooks/live/0250-nvidia.hook.chroot`             |
| Installer                        | `config/hooks/live/0400-installer.hook.chroot`                        |
| Eigene Dateien ins System legen  | `config/includes.chroot_after_packages/` (Pfad wie im Zielsystem)     |

Paketnamen findest du auf <https://packages.debian.org> oder mit `apt search`.
Nach jeder Änderung einfach `sudo ./build.sh` erneut ausführen.

## So funktioniert's

```
distro.conf ──┬──> auto/config ──> lb config   (live-build konfigurieren)
              └──> branding/render.sh          (SVG → PNG: Logo, Wallpaper, Bootbild)

lb build
 ├─ bootstrap   Debian-Grundsystem herunterladen (debootstrap)
 ├─ chroot      Pakete aus config/package-lists installieren (NVIDIA-Modul via DKMS),
 │              dann die Hooks ausführen:
 │                0100 os-release   → System heißt jetzt "SaiyukiOS"
 │                0200 artwork      → Logo, Wallpaper, ASCII-Logo, Plymouth, GRUB
 │                0250 nvidia       → Treiberwahl, Modesetting, Standby, prime-run
 │                0300 desktop      → Plasma-Design, SDDM (Wayland), Dolphin, Konsole
 │                0400 installer    → Calamares-Branding
 │                9900 cleanup      → Build-Reste und Signaturschlüssel entfernen
 └─ binary      SquashFS + Kernel + Bootloader → ISO-Image
```

Werkzeug ist [live-build](https://live-team.pages.debian.net/live-manual/),
mit dem Debian auch die offiziellen Live-Images baut.

Das installierte System bleibt ein vollwertiges Debian. Updates kommen per
Discover oder `sudo apt update && sudo apt full-upgrade` direkt von Debian.
Das Branding bleibt dabei erhalten, `os-release` ist per `dpkg-divert` geschützt.

## Mögliche nächste Schritte

- **Gaming:** 32-Bit-Unterstützung (`dpkg --add-architecture i386`) mit Steam,
  Lutris und GameMode.
- **Eigene Paketquelle:** Branding und Einstellungen als `.deb`-Paket
  (z. B. `saiyukios-desktop`) über ein eigenes APT-Repository verteilen. Dann
  bekommen auch installierte Systeme Design-Updates.

## Rechtliches

Die Distribution besteht aus Debian-Paketen unter ihren jeweiligen freien
Lizenzen. Der NVIDIA-Treiber stammt aus NVIDIAs Paketquelle und steht unter NVIDIAs
Lizenz. Sie erlaubt die Weitergabe als Teil einer Linux-Distribution, solange
der Treiber unverändert bleibt. „Basiert auf Debian“ darfst du
sagen. Verwende aber nicht das Debian-Logo als dein eigenes. Details stehen
in der [Debian-Markenrichtlinie](https://www.debian.org/trademark).
