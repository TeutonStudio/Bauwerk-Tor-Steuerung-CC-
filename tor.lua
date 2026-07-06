-- Taschencomputer-Steuerung fuer alle Tore.
-- Sucht per Rednet-Broadcast nach erreichbaren Gebaeuden/Toren und
-- erlaubt es, jedes Tor einzeln zu oeffnen/schliessen.

local PROTOKOLL = "torsteuerung"
local SUCH_TIMEOUT = 1.5
local ANTWORT_TIMEOUT = 2

-- Modem automatisch finden (Taschencomputer haben keine festen Redstone-Seiten)
local modemSeite = nil
for _, name in ipairs(peripheral.getNames()) do
    if peripheral.getType(name) == "modem" then
        modemSeite = name
        break
    end
end

if not modemSeite then
    print("Kein (Wireless-)Modem gefunden. Bitte eines anlegen.")
    return
end

if not rednet.isOpen(modemSeite) then
    rednet.open(modemSeite)
end

-- Sucht alle aktuell erreichbaren Gebaeude/Tore
local function sucheGebaeude()
    rednet.broadcast({ typ = "ping" }, PROTOKOLL)

    local gebaeude = {}
    local ende = os.clock() + SUCH_TIMEOUT

    while true do
        local restzeit = ende - os.clock()
        if restzeit <= 0 then break end

        local _, nachricht = rednet.receive(PROTOKOLL, restzeit)
        if nachricht and type(nachricht) == "table" and nachricht.typ == "pong" then
            gebaeude[nachricht.gebaeude] = gebaeude[nachricht.gebaeude] or {}

            local schonDa = false
            for _, eintrag in ipairs(gebaeude[nachricht.gebaeude]) do
                if eintrag.tor == nachricht.tor then
                    eintrag.zustand = nachricht.zustand
                    schonDa = true
                end
            end
            if not schonDa then
                table.insert(gebaeude[nachricht.gebaeude], {
                    tor = nachricht.tor,
                    zustand = nachricht.zustand,
                })
            end
        end
    end

    return gebaeude
end

-- Sendet einen Befehl (auf/zu) an ein bestimmtes Tor und wartet auf Status
local function sendeBefehl(gebaeudeName, torName, aktion)
    rednet.broadcast({
        typ = "befehl",
        gebaeude = gebaeudeName,
        tor = torName,
        aktion = aktion,
    }, PROTOKOLL)

    local ende = os.clock() + ANTWORT_TIMEOUT
    while true do
        local restzeit = ende - os.clock()
        if restzeit <= 0 then break end

        local _, antwort = rednet.receive(PROTOKOLL, restzeit)
        if antwort and antwort.typ == "status"
           and antwort.gebaeude == gebaeudeName and antwort.tor == torName then
            return antwort.zustand
        end
    end
    return nil
end

-- Fragt den aktuellen Status eines Tores ab
local function frageStatusAb(gebaeudeName, torName)
    rednet.broadcast({ typ = "status_abfrage", gebaeude = gebaeudeName, tor = torName }, PROTOKOLL)

    local ende = os.clock() + ANTWORT_TIMEOUT
    while true do
        local restzeit = ende - os.clock()
        if restzeit <= 0 then break end

        local _, antwort = rednet.receive(PROTOKOLL, restzeit)
        if antwort and antwort.typ == "status"
           and antwort.gebaeude == gebaeudeName and antwort.tor == torName then
            return antwort.zustand
        end
    end
    return nil
end

-- Einfaches Zahlen-Menue
local function menuAuswahl(titel, optionen)
    while true do
        term.clear()
        term.setCursorPos(1, 1)
        print(titel)
        print(string.rep("-", #titel))
        for i, text in ipairs(optionen) do
            print(i .. ") " .. text)
        end
        print("0) Zurueck")
        write("> ")

        local eingabe = tonumber(read())
        if eingabe == 0 then
            return nil
        elseif eingabe and optionen[eingabe] then
            return eingabe
        end
    end
end

local function torMenu(gebaeudeName, tor)
    while true do
        local auswahl = menuAuswahl(
            gebaeudeName .. " - Tor " .. tor.tor .. " (" .. (tor.zustand or "?") .. ")",
            { "Oeffnen", "Schliessen", "Status aktualisieren" }
        )
        if not auswahl then
            return
        elseif auswahl == 1 then
            tor.zustand = sendeBefehl(gebaeudeName, tor.tor, "auf") or tor.zustand
        elseif auswahl == 2 then
            tor.zustand = sendeBefehl(gebaeudeName, tor.tor, "zu") or tor.zustand
        elseif auswahl == 3 then
            tor.zustand = frageStatusAb(gebaeudeName, tor.tor) or tor.zustand
        end
    end
end

local function gebaeudeMenu(name, tore)
    while true do
        local namen = {}
        for _, tor in ipairs(tore) do
            table.insert(namen, tor.tor .. " (" .. (tor.zustand or "?") .. ")")
        end

        local auswahl = menuAuswahl(name, namen)
        if not auswahl then
            return
        end
        torMenu(name, tore[auswahl])
    end
end

-- Hauptschleife: staendig neu suchen und Menue anzeigen
while true do
    term.clear()
    term.setCursorPos(1, 1)
    print("Suche erreichbare Gebaeude ...")

    local gebaeude = sucheGebaeude()

    local namen = {}
    for name, _ in pairs(gebaeude) do
        table.insert(namen, name)
    end
    table.sort(namen)

    if #namen == 0 then
        print("Keine Gebaeude in Reichweite gefunden.")
        print("(Neuer Versuch in 2 Sekunden, Abbruch mit Strg+T)")
        sleep(2)
    else
        local auswahl = menuAuswahl("Erreichbare Gebaeude", namen)
        if auswahl then
            gebaeudeMenu(namen[auswahl], gebaeude[namen[auswahl]])
        end
    end
end
