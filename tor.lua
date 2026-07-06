-- Taschencomputer-Steuerung fuer alle Tore.
-- Zeigt alle bekannten oder erreichbaren Tore direkt als Liste an.
-- Eine Nummernauswahl loest sofort einen Zustandswechsel aus.

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
local tore = {}

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
        return { id = eintrag }
    elseif type(eintrag) == "table" and eintrag.id then
        return {
            id = tostring(eintrag.id),
            rednet_id = eintrag.rednet_id,
        }
    end
    return nil
end

local function ladeBekannteTore()
    local bekannte = {}

    if type(config.tore) == "table" then
        for _, eintrag in ipairs(config.tore) do
            local tor = normalisiereTor(eintrag)
            if tor then
                table.insert(bekannte, tor)
            end
        end
    end

    return bekannte
end

local function findeTorIndex(liste, id)
    for i, tor in ipairs(liste) do
        if tor.id == id then
            return i
        end
    end
    return nil
end

local function sucheTore()
    rednet.broadcast({ typ = "ping" }, PROTOKOLL)

    local gefundene = {}
    local ende = os.clock() + SUCH_TIMEOUT

    while true do
        local restzeit = ende - os.clock()
        if restzeit <= 0 then break end

        local senderId, nachricht = rednet.receive(PROTOKOLL, restzeit)
        if type(nachricht) == "table" and nachricht.typ == "pong" then
            local id = nachricht.tor_id or nachricht.tor
            if id then
                id = tostring(id)
                local index = findeTorIndex(gefundene, id)
                if index then
                    gefundene[index].rednet_id = senderId
                else
                    table.insert(gefundene, {
                        id = id,
                        rednet_id = senderId,
                    })
                end
            end
        end
    end

    table.sort(gefundene, function(a, b)
        return a.id < b.id
    end)

    return gefundene
end

local function ladeOderSucheTore()
    local bekannte = ladeBekannteTore()
    if #bekannte > 0 then
        return bekannte
    end
    return sucheTore()
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

local function aktualisiereZustaende()
    tore = ladeOderSucheTore()

    for _, tor in ipairs(tore) do
        tor.zustand = frageZustand(tor)
    end
end

local function zeichneListe()
    term.clear()
    term.setCursorPos(1, 1)

    print("=== Torsteuerung ===")
    print("")

    if #tore == 0 then
        print("Keine Tore gefunden.")
    else
        for i, tor in ipairs(tore) do
            print(i .. ") " .. tostring(tor.id) .. " [" .. tostring(tor.zustand or "unbekannt") .. "]")
        end
    end

    print("")
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
    if not antwort then
        print("Keine Antwort von Tor " .. tostring(tor.id))
        sleep(1.5)
        return
    end

    if not antwort.ok then
        print("Tor " .. tostring(tor.id) .. ": Wechsel fehlgeschlagen: " .. tostring(antwort.fehler))
        sleep(2)
        return
    end

    local vorher = pruefeZustand(antwort.vorher)
    local nachher = pruefeZustand(antwort.nachher)
    print("Tor " .. tostring(tor.id) .. ": " .. vorher .. " -> " .. nachher)
    tor.zustand = nachher
    sleep(1.5)
end

local function loop()
    aktualisiereZustaende()

    while true do
        zeichneListe()

        local eingabe = read()
        if eingabe == "q" then
            return
        elseif eingabe == "r" or eingabe == "a" then
            aktualisiereZustaende()
        else
            local index = tonumber(eingabe)
            if index and tore[index] then
                wechsleTor(tore[index])
                aktualisiereZustaende()
            else
                print("Ungueltige Auswahl")
                sleep(1)
            end
        end
    end
end

oeffneModem()
loop()
