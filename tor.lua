-- Taschencomputer-Steuerung fuer Tore.
-- Erst Gebaeude auswaehlen, dann ein Tor im Gebaeude direkt wechseln.

local STANDARD_PROTOKOLL = "torsteuerung"
local SUCH_TIMEOUT = 1.5
local ANTWORT_TIMEOUT = 2
local WECHSEL_TIMEOUT = 5

local function ladeConfig()
    local pfade = {
        "Bauwerk/tor_cfg.lua",
        "tor_cfg.lua",
    }

    for _, pfad in ipairs(pfade) do
        if fs.exists(pfad) then
            return dofile(pfad)
        end
    end

    return {}
end

local config = ladeConfig()
local PROTOKOLL = config.protokoll or STANDARD_PROTOKOLL
local gebaeudeListe = {}

local function oeffneModem()
    peripheral.find("modem", rednet.open)

    for _, name in ipairs(peripheral.getNames()) do
        if peripheral.getType(name) == "modem" and rednet.isOpen(name) then
            return
        end
    end

    error("Kein Modem gefunden! Bitte ein Modem direkt am Taschencomputer oder im Wired Network anschliessen.")
end

local function normalisiereTor(eintrag)
    if type(eintrag) == "string" then
        return {
            id = eintrag,
            name = eintrag,
        }
    elseif type(eintrag) == "table" and eintrag.id then
        return {
            id = tostring(eintrag.id),
            name = eintrag.name and tostring(eintrag.name) or tostring(eintrag.id),
            rednet_id = eintrag.rednet_id,
        }
    end
    return nil
end

local function normalisiereGebaeude(eintrag)
    if type(eintrag) ~= "table" then
        return nil
    end

    local id = tostring(eintrag.id or eintrag.name or "gebaeude")
    local gebaeude = {
        id = id,
        name = eintrag.name and tostring(eintrag.name) or id,
        tore = {},
    }

    if type(eintrag.tore) == "table" then
        for _, torEintrag in ipairs(eintrag.tore) do
            local tor = normalisiereTor(torEintrag)
            if tor then
                table.insert(gebaeude.tore, tor)
            end
        end
    end

    return gebaeude
end

local function ladeKonfigurierteGebaeude()
    local liste = {}

    if type(config.gebaeude) == "table" then
        for _, eintrag in ipairs(config.gebaeude) do
            local gebaeude = normalisiereGebaeude(eintrag)
            if gebaeude then
                table.insert(liste, gebaeude)
            end
        end
    end

    return liste
end

local function ladeAlteTorConfigAlsGebaeude()
    local tore = {}

    if type(config.tore) == "table" then
        for _, eintrag in ipairs(config.tore) do
            local tor = normalisiereTor(eintrag)
            if tor then
                table.insert(tore, tor)
            end
        end
    end

    if #tore == 0 then
        return {}
    end

    return {
        {
            id = "alle",
            name = "Alle Tore",
            tore = tore,
        },
    }
end

local function findeGebaeudeIndex(liste, id)
    for i, gebaeude in ipairs(liste) do
        if gebaeude.id == id then
            return i
        end
    end
    return nil
end

local function findeGebaeudeNachId(id)
    for _, gebaeude in ipairs(gebaeudeListe) do
        if gebaeude.id == id then
            return gebaeude
        end
    end
    return nil
end

local function findeTorIndex(liste, id)
    for i, tor in ipairs(liste) do
        if tor.id == id then
            return i
        end
    end
    return nil
end

local function fuegeGefundenesTorEin(liste, gebaeudeId, gebaeudeName, torId, torName, rednetId)
    local gebIndex = findeGebaeudeIndex(liste, gebaeudeId)
    if not gebIndex then
        table.insert(liste, {
            id = gebaeudeId,
            name = gebaeudeName,
            tore = {},
        })
        gebIndex = #liste
    end

    local tore = liste[gebIndex].tore
    local torIndex = findeTorIndex(tore, torId)
    if torIndex then
        tore[torIndex].rednet_id = rednetId
    else
        table.insert(tore, {
            id = torId,
            name = torName,
            rednet_id = rednetId,
        })
    end
end

local function sucheGebaeude()
    rednet.broadcast({ typ = "ping" }, PROTOKOLL)

    local gefundene = {}
    local ende = os.clock() + SUCH_TIMEOUT

    while true do
        local restzeit = ende - os.clock()
        if restzeit <= 0 then break end

        local senderId, nachricht = rednet.receive(PROTOKOLL, restzeit)
        if type(nachricht) == "table" and nachricht.typ == "pong" then
            local torId = nachricht.tor_id or nachricht.tor
            if torId then
                torId = tostring(torId)
                local gebaeudeId = tostring(nachricht.gebaeude_id or nachricht.gebaeude or "unbekannt")
                local gebaeudeName = tostring(nachricht.gebaeude_name or nachricht.gebaeude or gebaeudeId)
                local torName = tostring(nachricht.tor_name or nachricht.tor or torId)
                fuegeGefundenesTorEin(gefundene, gebaeudeId, gebaeudeName, torId, torName, senderId)
            end
        end
    end

    table.sort(gefundene, function(a, b)
        return tostring(a.name or a.id) < tostring(b.name or b.id)
    end)

    for _, gebaeude in ipairs(gefundene) do
        table.sort(gebaeude.tore, function(a, b)
            return tostring(a.name or a.id) < tostring(b.name or b.id)
        end)
    end

    return gefundene
end

local function ladeOderSucheGebaeude()
    local konfigurierte = ladeKonfigurierteGebaeude()
    if #konfigurierte > 0 then
        return konfigurierte
    end

    local alteConfig = ladeAlteTorConfigAlsGebaeude()
    if #alteConfig > 0 then
        return alteConfig
    end

    return sucheGebaeude()
end

local function sendeAnTor(tor, nachricht)
    if tor.rednet_id then
        rednet.send(tor.rednet_id, nachricht, PROTOKOLL)
    else
        rednet.broadcast(nachricht, PROTOKOLL)
    end
end

local function empfangeAntwort(tor, typ, timeout)
    local ende = os.clock() + timeout

    while true do
        local restzeit = ende - os.clock()
        if restzeit <= 0 then break end

        local senderId, nachricht = rednet.receive(PROTOKOLL, restzeit)
        if type(nachricht) == "table"
            and nachricht.typ == typ
            and tostring(nachricht.tor_id or "") == tor.id then
            if not tor.rednet_id then
                tor.rednet_id = senderId
            end
            return nachricht
        end
    end

    return nil
end

local function pruefeZustand(zustand)
    if zustand == "auf" or zustand == "zu" then
        return zustand
    elseif zustand == nil then
        return "unbekannt"
    end
    return "ungueltig"
end

local function frageZustand(tor)
    sendeAnTor(tor, {
        typ = "tor_status_anfrage",
        tor_id = tor.id,
    })

    local antwort = empfangeAntwort(tor, "tor_status_antwort", ANTWORT_TIMEOUT)
    if not antwort or not antwort.ok then
        return "unbekannt"
    end

    return pruefeZustand(antwort.zustand)
end

local function aktualisiereGebaeude(gebaeude)
    for _, tor in ipairs(gebaeude.tore or {}) do
        tor.zustand = frageZustand(tor)
    end
end

local function aktualisiereAlleGebaeude()
    gebaeudeListe = ladeOderSucheGebaeude()

    for _, gebaeude in ipairs(gebaeudeListe) do
        aktualisiereGebaeude(gebaeude)
    end
end

local function zeichneGebaeudeAuswahl()
    term.clear()
    term.setCursorPos(1, 1)

    print("=== Gebaeudeauswahl ===")
    print("")

    if #gebaeudeListe == 0 then
        print("Keine Gebaeude gefunden.")
    else
        for i, gebaeude in ipairs(gebaeudeListe) do
            print(i .. ") " .. tostring(gebaeude.name or gebaeude.id))
        end
    end

    print("")
    print("r) aktualisieren")
    print("q) beenden")
    print("")
    write("Auswahl: ")
end

local function zeichneTorAuswahl(gebaeude)
    term.clear()
    term.setCursorPos(1, 1)

    print("=== " .. tostring(gebaeude.name or gebaeude.id) .. " ===")
    print("")

    if not gebaeude.tore or #gebaeude.tore == 0 then
        print("Keine Tore gefunden.")
    else
        for i, tor in ipairs(gebaeude.tore) do
            print(i .. ") " .. tostring(tor.name or tor.id) .. " [" .. tostring(tor.zustand or "unbekannt") .. "]")
        end
    end

    print("")
    print("b) zurueck zu Gebaeuden")
    print("r) aktualisieren")
    print("q) beenden")
    print("")
    write("Auswahl: ")
end

local function wechsleTor(tor)
    sendeAnTor(tor, {
        typ = "tor_wechsel",
        tor_id = tor.id,
    })

    local antwort = empfangeAntwort(tor, "tor_wechsel_antwort", WECHSEL_TIMEOUT)
    local torName = tostring(tor.name or tor.id)

    if not antwort then
        print("Keine Antwort von Tor " .. torName)
        sleep(1.5)
        return
    end

    if not antwort.ok then
        print("Tor " .. torName .. ": Wechsel fehlgeschlagen: " .. tostring(antwort.fehler))
        sleep(2)
        return
    end

    local vorher = pruefeZustand(antwort.vorher)
    local nachher = pruefeZustand(antwort.nachher)
    print("Tor " .. torName .. ": " .. vorher .. " -> " .. nachher)
    tor.zustand = nachher
    sleep(1.5)
end

local function torAuswahlLoop(gebaeude)
    aktualisiereGebaeude(gebaeude)

    while true do
        zeichneTorAuswahl(gebaeude)

        local eingabe = read()
        if eingabe == "q" then
            return "quit"
        elseif eingabe == "b" then
            return "back"
        elseif eingabe == "r" then
            aktualisiereGebaeude(gebaeude)
        elseif eingabe == "a" then
            local gebaeudeId = gebaeude.id
            aktualisiereAlleGebaeude()
            gebaeude = findeGebaeudeNachId(gebaeudeId) or gebaeude
        else
            local index = tonumber(eingabe)
            if index and gebaeude.tore and gebaeude.tore[index] then
                wechsleTor(gebaeude.tore[index])
                aktualisiereGebaeude(gebaeude)
            else
                print("Ungueltige Auswahl")
                sleep(1)
            end
        end
    end
end

local function gebaeudeAuswahlLoop()
    aktualisiereAlleGebaeude()

    while true do
        zeichneGebaeudeAuswahl()

        local eingabe = read()
        if eingabe == "q" then
            return
        elseif eingabe == "r" or eingabe == "a" then
            aktualisiereAlleGebaeude()
        else
            local index = tonumber(eingabe)
            if index and gebaeudeListe[index] then
                local ergebnis = torAuswahlLoop(gebaeudeListe[index])
                if ergebnis == "quit" then
                    return
                end
            else
                print("Ungueltige Auswahl")
                sleep(1)
            end
        end
    end
end

oeffneModem()
gebaeudeAuswahlLoop()
