# Bauwerk-Tor-Steuerung fuer CC:Tweaked

Rednet-basierte Torsteuerung fuer Create/ComputerCraft:

- `Tor-Steuercomputer`: steuert genau ein Tor ueber eine Sequenced Gearshift.
- `Taschencomputer`: zeigt zuerst Gebaeude, dann die Tore des Gebaeudes, und schaltet ein Tor per Nummernauswahl um.

## Installation

Voraussetzung: HTTP muss in der ComputerCraft/CC:Tweaked-Konfiguration aktiviert sein.

Auf dem Computer oder Taschencomputer in CC:Tweaked den Initialiser herunterladen und ausfuehren:

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
- Winkel zum Oeffnen
- Initialer Zustand (`auf` oder `zu`)

Nach einem Neustart startet die Torsteuerung automatisch ueber `startup.lua`.

Das Modem wird automatisch gefunden und fuer Rednet geoeffnet. Eine feste Modem-Seite ist nicht noetig.

Die Sequenced Gearshift wird automatisch gesucht. Akzeptiert wird ein Peripheral, das die Methoden `rotate()` und `isRunning()` besitzt. Eine feste Seite ist nicht noetig.

Voraussetzungen:

- Mindestens ein Modem am Computer oder im Wired Network.
- Genau eine passende Sequenced Gearshift.

Beispiel fuer `cfg.lua`:

```lua
return {
    gebaeude = "Zugfabrik1",
    tor = "VR",
    winkel_auf = 90,
    initZustand = "zu",
}
```

Zum Schliessen wird automatisch `-winkel_auf` verwendet. Es gibt keinen separaten Schliesswinkel.

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

Optional kann der Taschencomputer feste Gebaeude und Tore aus `Bauwerk/tor_cfg.lua` laden:

```lua
return {
    protokoll = "torsteuerung",

    gebaeude = {
        {
            id = "rathaus",
            name = "Rathaus",
            tore = {
                { id = "rathaus_nord", name = "Eingang Nord" },
                { id = "rathaus_sued", name = "Eingang Sued" },
                { id = "rathaus_keller", name = "Kellerzugang" },
            },
        },
        {
            id = "bahnhof_sued",
            name = "Bahnhof Sued",
            tore = {
                { id = "bahnhof_sued_tor_1", name = "Tor 1" },
                { id = "bahnhof_sued_tor_2", name = "Tor 2" },
            },
        },
    },
}
```

Falls Rednet-IDs fest bekannt sind:

```lua
return {
    protokoll = "torsteuerung",

    gebaeude = {
        {
            id = "rathaus",
            name = "Rathaus",
            tore = {
                { id = "rathaus_nord", name = "Eingang Nord", rednet_id = 12 },
                { id = "rathaus_sued", name = "Eingang Sued", rednet_id = 15 },
            },
        },
    },
}
```

## Dateien

- `init.lua`: Installer
- `startup.lua`: Programm fuer den Tor-Steuercomputer
- `cfg.lua`: Beispiel-Konfiguration fuer einen Tor-Steuercomputer
- `tor.lua`: Programm fuer den Taschencomputer
