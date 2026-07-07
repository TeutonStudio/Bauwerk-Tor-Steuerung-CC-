# Bauwerk-Tor-Steuerung fuer CC:Tweaked

Rednet-basierte Torsteuerung fuer Create/ComputerCraft:

- `Tor-Steuercomputer`: steuert genau ein Tor über eine Sequentielle Gangschaltung.
- `Taschencomputer`: zeigt zuerst Gebäude, dann die Tore des Gebäudes, und schaltet ein Tor per Nummernauswahl um.

## Installation

Voraussetzung: HTTP muss in der ComputerCraft/CC:Tweaked-Konfiguration aktiviert sein.

Auf dem Taschencomputer den Initialiser herunterladen und ausführen:

```lua
wget https://raw.githubusercontent.com/TeutonStudio/Bauwerk-Tor-Steuerung-CC-/master/init.lua

Der Installer fragt, was installiert werden soll:

```text
1) Tor-Steuercomputer
2) Taschencomputer-Steuerung
0) Abbrechen
```

Nach der Installation löscht sich `init.lua` automatisch.

## Tor-Steuercomputer

Waehle im Installer:

```text
1) Tor-Steuercomputer
```

Dabei wird `startup.lua` installiert und die lokale `cfg.lua` direkt abgefragt und gespeichert:

- Gebäude
- Tor-Name/Kuerzel
- Winkel zum Oeffnen
- Initialer Zustand (`auf` oder `zu`)

Nach einem Neustart startet die Torsteuerung automatisch über `startup.lua`.

Das Modem wird automatisch gefunden und für Rednet geoeffnet. Eine feste Modem-Seite ist nicht nötig.

Die Sequentielle Gangschaltung wird automatisch gesucht. Akzeptiert wird ein Peripheral, das die Methoden `rotate()` und `isRunning()` besitzt. Eine feste Seite ist nicht nötig.

Voraussetzungen:

- Mindestens ein Modem am Computer oder im Wired Network.
- Genau eine passende Sequentielle Gangschaltung.

Beispiel fuer `cfg.lua`:

```lua
return {
    gebaeude = "Zugfabrik1",
    tor = "VR",
    winkel = 90,
    initZustand = "zu",
}
```

Zum Schliessen wird derselbe positive `winkel` mit negativem Sequenced-Gearshift-Modifier verwendet: `rotate(winkel, -1)`. Es gibt keinen separaten Schliesswinkel.

Der Zustand des Tores wird auf dem Tor-Steuercomputer verwaltet und lokal gespeichert. Der Taschencomputer zeigt nur den Zustand an, den der Tor-Steuercomputer meldet.

## Taschencomputer

Waehle im Installer:

```text
2) Taschencomputer-Steuerung
```

Dabei wird die Steuerung nach `Bauwerk/tor.lua` installiert.

Start:

```lua
Bauwerk/tor.lua
```

Der Taschencomputer sucht per Rednet nach erreichbaren Tor-Steuercomputern und zeigt zuerst die Gebaeudeauswahl:

```text
=== Gebaeudeauswahl ===

1) Rathaus
2) Bahnhof Sued

r) aktualisieren
q) beenden

Auswahl:
```

Nach Auswahl eines Gebaeudes werden dessen Tore mit Zustand angezeigt:

```text
=== Rathaus ===

1) Eingang Nord [zu]
2) Eingang Sued [auf]
3) Kellerzugang [unbekannt]

b) zurueck zu Gebaeuden
r) aktualisieren
q) beenden

Auswahl:
```

Befehle:

- Gebaeudeauswahl: Nummer oeffnet das Gebaeude
- Torauswahl: Nummer wechselt das Tor direkt
- `b`: zurueck zur Gebaeudeauswahl
- `r`: aktuelle Ansicht aktualisieren
- `q`: Programm beenden

Es gibt kein Untermenue pro Tor. Der Taschencomputer sendet keine Zielzustaende, keine Winkel und keine freien `auf`-/`zu`-Befehle.

Der Taschencomputer nutzt keine lokale Config. Gebaeude und Tore werden ausschliesslich per Rednet-Discovery gefunden.

## Dateien

- `init.lua`: Installer
- `startup.lua`: Programm fuer den Tor-Steuercomputer
- `cfg.lua`: Beispiel-Konfiguration fuer einen Tor-Steuercomputer
- `tor.lua`: Programm fuer den Taschencomputer
