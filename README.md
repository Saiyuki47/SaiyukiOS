> [!CAUTION]
> **Vibe-coded:** SaiyukiOS wurde vollständig mit KI erstellt – Code, Konfiguration
> und Grafiken. Nichts davon wurde von Menschen geprüft, getestet wurde nur in einer
> virtuellen Maschine. Nutzung auf eigene Gefahr.

```
                                ,
                           ,##/#P
                      ,#####//##P       SaiyukiOS 1.0 „sprout“
                  d########//##P        ──────────────────────
               d#########//###P         Basis:    Debian 13 (trixie)
             d#########//####P          Desktop:  KDE Plasma 6 · Wayland
           d#########//#####P           Dateien:  Dolphin
          d########//######P            Grafik:   NVIDIA bis RTX 50
         d########//######P
         #######//######P
         #####//######P
          Y##//####P
           //###"
         //
       //
     //
```

## Was macht SaiyukiOS einzigartig?

- **NVIDIA ohne Handarbeit:** Erkennt die Grafikkarte und richtet den passenden
  Treiber ein, für Wayland vorbereitet. RTX 20 bis RTX 50 bekommen NVIDIAs aktuellen
  Treiber, GTX 750 bis 1080 Debians Treiber 550, auch ohne Internet. Mit Secure Boot
  wird der Schlüssel bei der Installation angemeldet, beim Neustart nur bestätigen.
- **Nur, was die Hardware braucht:** Unnötige Grafiktreiber fliegen bei der
  Installation raus. In Hyper-V, VMware oder QEMU bleiben die passenden
  Gast-Werkzeuge, auf echter Hardware keine.
- **Zurück per Bootmenü:** Vor jedem Update entsteht ein Btrfs-Schnappschuss. Geht
  etwas schief, startest du den alten Stand direkt aus dem Bootmenü.
- **Stabil und trotzdem aktuell:** Debian 13 als Fundament, dazu Flathub in Discover
  für aktuelle Programme.
- **Eigenes Gesicht:** Das Blatt zieht sich durch alles, von Bootmenü, Startbildschirm
  und Anmeldung bis zum Terminal.
- **Deutsch ab Werk:** Englisch gibt es per Eintrag im Bootmenü.

Bauen, Testen und Anpassen: [Anleitung](docs/ANLEITUNG.md)
