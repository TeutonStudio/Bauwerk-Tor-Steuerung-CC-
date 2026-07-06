-- Torsteuerung: laeuft auf JEDEM Computer, der ein einzelnes Tor steuert.
-- Reagiert auf Nachrichten vom Taschencomputer-Skript ueber Rednet und
-- prueft dabei immer zuerst, ob die Nachricht ueberhaupt fuer DIESES
-- Tor (gebaeude + tor aus der cfg.lua) bestimmt ist.
--
-- Ansteuerung erfolgt direkt ueber die Sequenced-Gearshift-Peripherie
-- (Create-CC:Tweaked-Integration): gangschaltung.rotate(winkel, [modifier]).

local cfg = dofile("cfg.lua")

local PROTOKOLL = "torsteuerung"

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
local zustand = "zu" -- Startannahme: Tor ist beim Hochfahren geschlossen

-- Wartet, bis die Gangschaltung ihre aktuelle Drehung abgeschlossen hat
local function wartenAufAbschluss(maxSekunden)
    local ende = os.clock() + (maxSekunden or 10)
    while gangschaltung.isRunning() and os.clock() < ende do
        sleep(0.1)
    end
end

local function oeffnen()
    gangschaltung.rotate(cfg.winkel_auf)       -- vorwaerts um winkel_auf Grad
    wartenAufAbschluss()
    zustand = "auf"
    print("Tor " .. tostring(cfg.tor) .. " geoeffnet (" .. tostring(cfg.winkel_auf) .. " Grad)")
end

local function schliessen()
    gangschaltung.rotate(cfg.winkel_zu, -1)    -- rueckwaerts um winkel_zu Grad
    wartenAufAbschluss()
    zustand = "zu"
    print("Tor " .. tostring(cfg.tor) .. " geschlossen (" .. tostring(cfg.winkel_zu) .. " Grad)")
end

local function sendeStatus(anId)
    rednet.send(anId, {
        typ = "status",
        gebaeude = cfg.gebaeude,
        tor = cfg.tor,
        zustand = zustand,
    }, PROTOKOLL)
end

print("Gangschaltung gefunden: " .. tostring(gangschaltungName))
print("Torsteuerung bereit: " .. tostring(cfg.gebaeude) .. " / " .. tostring(cfg.tor))

while true do
    local absenderId, nachricht = rednet.receive(PROTOKOLL)

    if type(nachricht) == "table" then
        if nachricht.typ == "ping" then
            -- Taschencomputer sucht erreichbare Gebaeude/Tore -> immer antworten
            rednet.send(absenderId, {
                typ = "pong",
                gebaeude = cfg.gebaeude,
                tor = cfg.tor,
                zustand = zustand,
            }, PROTOKOLL)

        elseif nachricht.gebaeude == cfg.gebaeude and nachricht.tor == cfg.tor then
            -- Nachricht ist eindeutig an DIESES Tor gerichtet
            if nachricht.typ == "befehl" then
                if nachricht.aktion == "auf" then
                    oeffnen()
                elseif nachricht.aktion == "zu" then
                    schliessen()
                end
                sendeStatus(absenderId)
            elseif nachricht.typ == "status_abfrage" then
                sendeStatus(absenderId)
            end
        end
        -- Passen gebaeude/tor NICHT: Nachricht war fuer einen anderen
        -- Computer bestimmt -> wird ignoriert.
    end
end
