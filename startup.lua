-- Torsteuerung: laeuft auf JEDEM Computer, der ein einzelnes Tor steuert.
-- Reagiert auf Nachrichten vom Taschencomputer-Skript ueber Rednet und
-- prueft dabei immer zuerst, ob die Nachricht ueberhaupt fuer DIESES
-- Tor (gebaeude + tor aus der cfg.lua) bestimmt ist.
--
-- Ansteuerung erfolgt direkt ueber die Sequenced-Gearshift-Peripherie
-- (Create-CC:Tweaked-Integration): gangschaltung.rotate(winkel, [modifier]).

local cfg = dofile("cfg.lua")

local MODEM_SEITE = "top"
local PROTOKOLL = "torsteuerung"

if peripheral.getType(MODEM_SEITE) ~= "modem" then
    error("Auf Seite '" .. MODEM_SEITE .. "' wurde kein Modem gefunden!")
end

if not rednet.isOpen(MODEM_SEITE) then
    rednet.open(MODEM_SEITE)
end

local gangschaltung = peripheral.wrap(cfg.gangschaltung_seite)
if not gangschaltung then
    error("Auf '" .. cfg.gangschaltung_seite .. "' wurde keine Sequenced Gearshift gefunden!")
end

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
    print("Tor " .. cfg.tor .. " geoeffnet (" .. cfg.winkel_auf .. " Grad)")
end

local function schliessen()
    gangschaltung.rotate(cfg.winkel_zu, -1)    -- rueckwaerts um winkel_zu Grad
    wartenAufAbschluss()
    zustand = "zu"
    print("Tor " .. cfg.tor .. " geschlossen (" .. cfg.winkel_zu .. " Grad)")
end

local function sendeStatus(anId)
    rednet.send(anId, {
        typ = "status",
        gebaeude = cfg.gebaeude,
        tor = cfg.tor,
        zustand = zustand,
    }, PROTOKOLL)
end

print("Torsteuerung bereit: " .. cfg.gebaeude .. " / " .. cfg.tor)

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
