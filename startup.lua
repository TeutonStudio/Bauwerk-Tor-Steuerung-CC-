-- Torsteuerung: laeuft auf JEDEM Computer, der ein einzelnes Tor steuert.
-- Reagiert auf Nachrichten vom Taschencomputer-Skript ueber Rednet und
-- prueft dabei immer zuerst, ob die Nachricht ueberhaupt fuer DIESES
-- Tor (gebaeude + tor aus der cfg.lua) bestimmt ist.
--
-- Ansteuerung erfolgt direkt ueber die Sequenced-Gearshift-Peripherie
-- (Create-CC:Tweaked-Integration): gangschaltung.rotate(winkel, [modifier]).

local cfg = dofile("cfg.lua")

local PROTOKOLL = "torsteuerung"
local TOR_ID = tostring(cfg.tor_id or cfg.tor or "tor")
local ZUSTAND_DATEI = cfg.zustand_datei or ".tor_zustand"
local WINKEL = tonumber(cfg.winkel)

if not WINKEL then
    error("cfg.lua: Winkel fehlt oder ist keine Zahl!")
end

peripheral.find("modem", rednet.open)

local function istRednetOffen()
    for _, name in ipairs(peripheral.getNames()) do
        if peripheral.getType(name) == "modem" and rednet.isOpen(name) then
            return true
        end
    end
    return false
end

if not istRednetOffen() then
    error("Kein Modem gefunden! Bitte ein Modem direkt am Computer oder im Wired Network anschliessen.")
end

local function istGangschaltung(peripherie)
    return type(peripherie) == "table"
        and type(peripherie.rotate) == "function"
        and type(peripherie.isRunning) == "function"
end

local function findeGangschaltung()
    if cfg.gangschaltung_name and cfg.gangschaltung_name ~= "" then
        local peripherie = peripheral.wrap(cfg.gangschaltung_name)
        if not peripherie then
            error("Konfigurierte Sequenced Gearshift '" .. tostring(cfg.gangschaltung_name) .. "' wurde nicht gefunden!")
        end
        if not istGangschaltung(peripherie) then
            error("Konfigurierte Sequenced Gearshift '" .. tostring(cfg.gangschaltung_name) .. "' besitzt nicht rotate() und isRunning()!")
        end
        return peripherie, cfg.gangschaltung_name
    end

    local gefundene = {}
    for _, name in ipairs(peripheral.getNames()) do
        local peripherie = peripheral.wrap(name)
        if istGangschaltung(peripherie) then
            table.insert(gefundene, { name = name, peripherie = peripherie })
        end
    end

    if #gefundene == 0 then
        error("Keine Sequenced Gearshift gefunden! Erwartet Peripheral mit rotate() und isRunning().")
    elseif #gefundene > 1 then
        print("Mehrere passende Sequenced Gearshifts gefunden:")
        for _, eintrag in ipairs(gefundene) do
            print("- " .. tostring(eintrag.name))
        end
        error("Bitte gangschaltung_name in cfg.lua auf den gewuenschten Peripheral-Namen setzen.")
    end

    return gefundene[1].peripherie, gefundene[1].name
end

local gangschaltung, gangschaltungName = findeGangschaltung()

local function istGueltigerZustand(wert)
    return wert == "auf" or wert == "zu"
end

local function ladeZustand()
    if fs.exists(ZUSTAND_DATEI) then
        local datei = fs.open(ZUSTAND_DATEI, "r")
        if datei then
            local wert = datei.readAll()
            datei.close()
            if istGueltigerZustand(wert) then
                return wert
            end
        end
    end
    local initZustand = cfg.initZustand or cfg.init_zustand
    if istGueltigerZustand(initZustand) then
        return initZustand
    end
    return "zu"
end

local function speichereZustand(neuerZustand)
    if not istGueltigerZustand(neuerZustand) then
        return
    end

    local datei = fs.open(ZUSTAND_DATEI, "w")
    if not datei then
        error("Konnte Zustand nicht speichern: " .. tostring(ZUSTAND_DATEI))
    end
    datei.write(neuerZustand)
    datei.close()
end

local zustand = ladeZustand()
speichereZustand(zustand)

-- Wartet, bis die Gangschaltung ihre aktuelle Drehung abgeschlossen hat
local function wartenAufAbschluss(maxSekunden)
    local ende = os.clock() + (maxSekunden or 10)
    while gangschaltung.isRunning() and os.clock() < ende do
        sleep(0.1)
    end
end

local function oeffnen()
    gangschaltung.rotate(WINKEL, cfg.richtungsKorrektur and -1 or 1)           -- vorwaerts um WINKEL Grad
    wartenAufAbschluss()
    zustand = "auf"
    speichereZustand(zustand)
    print("Tor " .. tostring(cfg.tor) .. " geoeffnet (" .. tostring(WINKEL) .. " Grad)")
end

local function schliessen()
    gangschaltung.rotate(WINKEL, cfg.richtungsKorrektur and 1 or -1)        -- rueckwaerts um WINKEL Grad
    wartenAufAbschluss()
    zustand = "zu"
    speichereZustand(zustand)
    print("Tor " .. tostring(cfg.tor) .. " geschlossen (-" .. tostring(WINKEL) .. " Grad)")
end

local function wechseln()
    local vorher = zustand
    if zustand == "auf" then
        schliessen()
    else
        oeffnen()
    end
    return vorher, zustand
end

local function sendeStatus(anId)
    rednet.send(anId, {
        typ = "status",
        gebaeude = cfg.gebaeude,
        tor = cfg.tor,
        tor_id = TOR_ID,
        zustand = zustand,
    }, PROTOKOLL)
end

local function sendeTorStatusAntwort(anId, ok, fehler)
    rednet.send(anId, {
        typ = "tor_status_antwort",
        tor_id = TOR_ID,
        ok = ok,
        zustand = ok and zustand or nil,
        fehler = fehler,
    }, PROTOKOLL)
end

local function sendeTorWechselAntwort(anId, ok, vorher, nachher, fehler)
    rednet.send(anId, {
        typ = "tor_wechsel_antwort",
        tor_id = TOR_ID,
        ok = ok,
        vorher = vorher,
        nachher = nachher,
        fehler = fehler,
    }, PROTOKOLL)
end

local function istFuerDiesesTor(nachricht)
    if nachricht.tor_id ~= nil then
        return tostring(nachricht.tor_id) == tostring(TOR_ID)
    end

    return nachricht.gebaeude == cfg.gebaeude and nachricht.tor == cfg.tor
end

print("Gangschaltung gefunden: " .. tostring(gangschaltungName))
print("Torsteuerung bereit: " .. tostring(cfg.gebaeude) .. " / " .. tostring(cfg.tor) .. " (" .. tostring(TOR_ID) .. ")")

while true do
    local absenderId, nachricht = rednet.receive(PROTOKOLL)

    if type(nachricht) == "table" then
        if nachricht.typ == "ping" then
            -- Taschencomputer sucht erreichbare Gebaeude/Tore -> immer antworten
            rednet.send(absenderId, {
                typ = "pong",
                gebaeude = cfg.gebaeude,
                tor = cfg.tor,
                tor_id = TOR_ID,
                zustand = zustand,
            }, PROTOKOLL)

        elseif istFuerDiesesTor(nachricht) then
            -- Nachricht ist eindeutig an DIESES Tor gerichtet
            if nachricht.typ == "tor_status_anfrage" then
                sendeTorStatusAntwort(absenderId, true)

            elseif nachricht.typ == "tor_wechsel" then
                local ok, vorher, nachher = pcall(wechseln)
                if ok then
                    sendeTorWechselAntwort(absenderId, true, vorher, nachher)
                else
                    sendeTorWechselAntwort(absenderId, false, nil, nil, vorher)
                end

            elseif nachricht.typ == "status_abfrage" then
                sendeStatus(absenderId)
            end
        end
        -- Passen gebaeude/tor NICHT: Nachricht war fuer einen anderen
        -- Computer bestimmt -> wird ignoriert.
    end
end
