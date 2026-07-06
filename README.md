# Bauwerk-Tor-Steuerung fuer CC:Tweaked

Rednet-basierte Torsteuerung fuer Create/ComputerCraft:

- `Tor-Steuercomputer`: steuert genau ein Tor ueber eine Sequenced Gearshift.
- `Taschencomputer`: sucht erreichbare Tore und kann sie oeffnen, schliessen und abfragen.

## Installation

Voraussetzung: HTTP muss in der ComputerCraft/CC:Tweaked-Konfiguration aktiviert sein.

Auf dem Computer oder Taschencomputer in CC:Tweaked den Initialiser herunterladen und ausführen:

```lua
wget https://raw.githubusercontent.com/TeutonStudio/Bauwerk-Tor-Steuerung-CC-/master/init.lua
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
- Seite oder Name der Sequenced Gearshift
- Winkel zum Oeffnen
- Winkel zum Schliessen

Nach einem Neustart startet die Torsteuerung automatisch ueber `startup.lua`.

Voraussetzungen:

- Wireless Modem auf Seite `top`
- Sequenced Gearshift an der angegebenen Seite oder mit dem angegebenen Peripherie-Namen

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
