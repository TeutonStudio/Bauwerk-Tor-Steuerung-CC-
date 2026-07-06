# Bauwerk-Tor-Steuerung fuer CC:Tweaked

Rednet-basierte Torsteuerung fuer Create/ComputerCraft:

- `Tor-Steuercomputer`: steuert genau ein Tor ueber eine Sequenced Gearshift.
- `Taschencomputer`: sucht erreichbare Tore und kann sie oeffnen, schliessen und abfragen.

## Installation

Voraussetzung: HTTP muss in der ComputerCraft/CC:Tweaked-Konfiguration aktiviert sein.

Auf dem Computer oder Taschencomputer in CC:Tweaked den Initialiser herunterladen und ausfuehren:

```lua
wget https://raw.githubusercontent.com/TeutonStudio/Bauwerk-Tor-Steuerung-CC-/master/init.lua init.lua
init.lua
```

Der Installer fragt, was installiert werden soll:

```text
1) Tor-Steuercomputer
2) Taschencomputer-Steuerung
0) Abbrechen
```

Nach der Installation loescht sich `init.lua` automatisch.

## Tor-Steuercomputer

Waehle im Installer:

```text
1) Tor-Steuercomputer
```

Dabei wird `startup.lua` installiert und die lokale `cfg.lua` direkt abgefragt und gespeichert:

- Gebaeude
- Tor-Name/Kuerzel
- Winkel zum Oeffnen
- Winkel zum Schliessen
- Optionaler Name der Sequenced Gearshift

Nach einem Neustart startet die Torsteuerung automatisch ueber `startup.lua`.

Das Modem wird automatisch gefunden und fuer Rednet geoeffnet. Eine feste Modem-Seite ist nicht noetig.

Die Sequenced Gearshift wird automatisch gesucht. Akzeptiert wird ein Peripheral, das die Methoden `rotate()` und `isRunning()` besitzt. Eine feste Seite ist nicht noetig.

Voraussetzungen:

- Mindestens ein Modem am Computer oder im Wired Network.
- Genau eine passende Sequenced Gearshift oder optional `gangschaltung_name` in `cfg.lua` bei mehreren passenden Peripherals.

Optionale Gearshift-Auswahl in `cfg.lua`:

```lua
return {
    gebaeude = "Zugfabrik1",
    tor = "VR",
    winkel_auf = 90,
    winkel_zu = 90,
    gangschaltung_name = "right",
}
```

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

Der Taschencomputer sucht per Rednet nach erreichbaren Tor-Steuercomputern und zeigt die gefundenen Gebaeude und Tore als Menue an.

## Dateien

- `init.lua`: Installer
- `startup.lua`: Programm fuer den Tor-Steuercomputer
- `cfg.lua`: Beispiel-Konfiguration fuer einen Tor-Steuercomputer
- `tor.lua`: Programm fuer den Taschencomputer
