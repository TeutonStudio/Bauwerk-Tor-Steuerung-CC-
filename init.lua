-- Installer fuer die Bauwerk-Torsteuerung.
-- Diese Datei liegt zusammen mit startup.lua, cfg.lua und tor.lua im Repo.

local INSTALLER = shell.getRunningProgram()
local INSTALLER_DIR = fs.getDir(INSTALLER)

local function quellpfad(name)
    if INSTALLER_DIR == "" then
        return name
    end
    return fs.combine(INSTALLER_DIR, name)
end

local function schreibeDatei(pfad, inhalt)
    local dir = fs.getDir(pfad)
    if dir ~= "" and not fs.exists(dir) then
        fs.makeDir(dir)
    end

    local datei = fs.open(pfad, "w")
    if not datei then
        error("Konnte " .. pfad .. " nicht schreiben")
    end
    datei.write(inhalt)
    datei.close()
end

local function leseDatei(pfad)
    local datei = fs.open(pfad, "r")
    if not datei then
        error("Konnte " .. pfad .. " nicht lesen")
    end
    local inhalt = datei.readAll()
    datei.close()
    return inhalt
end

local function kopiereDatei(von, nach)
    if von == nach then
        return
    end
    schreibeDatei(nach, leseDatei(von))
end

local function frageText(label, standard)
    while true do
        if standard and standard ~= "" then
            write(label .. " [" .. standard .. "]: ")
        else
            write(label .. ": ")
        end

        local eingabe = read()
        if eingabe == "" and standard then
            return standard
        elseif eingabe ~= "" then
            return eingabe
        end
    end
end

local function frageZahl(label, standard)
    while true do
        local wert = tonumber(frageText(label, tostring(standard)))
        if wert then
            return wert
        end
        print("Bitte eine Zahl eingeben.")
    end
end

local function schreibeConfig()
    term.clear()
    term.setCursorPos(1, 1)
    print("Konfiguration fuer diesen Tor-Steuercomputer")
    print("---------------------------------------------")

    local cfg = {
        gebaeude = frageText("Gebaeude", "Zugfabrik1"),
        tor = frageText("Tor-Name/Kuerzel", "VR"),
        gangschaltung_seite = frageText("Seite/Name der Sequenced Gearshift", "front"),
        winkel_auf = frageZahl("Winkel zum Oeffnen", 90),
        winkel_zu = frageZahl("Winkel zum Schliessen", 90),
    }

    local inhalt = "-- Automatisch durch init.lua erzeugte Konfiguration fuer diesen Tor-Computer.\n\n"
        .. "return " .. textutils.serialize(cfg) .. "\n"
    schreibeDatei("cfg.lua", inhalt)
end

local function installiereTorSteuercomputer()
    kopiereDatei(quellpfad("startup.lua"), "startup.lua")
    schreibeConfig()

    print()
    print("Tor-Steuercomputer installiert.")
    print("Beim naechsten Start laeuft startup.lua automatisch.")
end

local function installiereTaschencomputer()
    kopiereDatei(quellpfad("tor.lua"), fs.combine("Bauwerk", "tor.lua"))

    print()
    print("Taschencomputer-Steuerung installiert.")
    print("Start mit: Bauwerk/tor.lua")
end

local function loescheInstaller()
    if INSTALLER and INSTALLER ~= "" and fs.exists(INSTALLER) then
        fs.delete(INSTALLER)
    end
end

local function menu()
    while true do
        term.clear()
        term.setCursorPos(1, 1)
        print("Bauwerk-Torsteuerung installieren")
        print("---------------------------------")
        print("1) Tor-Steuercomputer")
        print("2) Taschencomputer-Steuerung")
        print("0) Abbrechen")
        write("> ")

        local auswahl = read()
        if auswahl == "1" then
            installiereTorSteuercomputer()
            break
        elseif auswahl == "2" then
            installiereTaschencomputer()
            break
        elseif auswahl == "0" then
            print("Abgebrochen.")
            return
        end
    end

    loescheInstaller()
    print("init.lua wurde geloescht.")
end

menu()
