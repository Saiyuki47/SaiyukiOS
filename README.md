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
  Treiber ein. RTX 20 bis RTX 50 bekommen NVIDIAs aktuellen Treiber, GTX 750 bis
  1080 Debians Treiber 550, auch ohne Internet. Unnötige Treiber werden bei der
  Installation automatisch entfernt.
- **Wayland von Anfang an:** KDE Plasma 6 und der Anmeldebildschirm laufen unter
  Wayland. NVIDIA ist dafür vorbereitet: Modesetting, Standby ohne schwarzen
  Bildschirm, `prime-run` für Laptops mit zwei Grafikchips.
- **Debian als Fundament:** Stabil, mit Sicherheitsupdates und über 60.000 Paketen.
- **Eigenes Gesicht:** Das Blatt zieht sich durch alles, von Bootmenü, Startbildschirm
  und Anmeldung bis zum Terminal.
- **Deutsch ab Werk:** Sprache, Tastatur und Zeitzone sind vorbelegt.

Bauen, Testen und Anpassen: [Anleitung](docs/ANLEITUNG.md)
