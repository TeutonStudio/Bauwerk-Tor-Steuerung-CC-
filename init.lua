-- Installer fuer die Bauwerk-Torsteuerung.
-- Diese Datei liegt zusammen mit startup.lua, cfg.lua und tor.lua im Repo.

local INSTALLER = shell.getRunningProgram()
local INSTALLER_DIR = fs.getDir(INSTALLER)
local RAW_URL = "https://raw.githubusercontent.com/TeutonStudio/Bauwerk-Tor-Steuerung-CC-/master/"

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

local function ladeRepoDatei(name)
    local lokal = quellpfad(name)
    if fs.exists(lokal) then
        return leseDatei(lokal)
    end

    if not http then
        error("HTTP ist deaktiviert. Bitte http in der ComputerCraft-Konfiguration aktivieren.")
    end

    local antwort = http.get(RAW_URL .. name)
    if not antwort then
        error("Konnte " .. name .. " nicht von GitHub laden")
    end

    local inhalt = antwort.readAll()
    antwort.close()
    return inhalt
end

local function installiereRepoDatei(name, ziel)
    if fs.exists(quellpfad(name)) and quellpfad(name) == ziel then
        return
    end
    schreibeDatei(ziel, ladeRepoDatei(name))
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

local function frageZustand(label, standard)
    while true do
        local eingabe = frageText(label, standard)
        if eingabe == "auf" or eingabe == "zu" then
            return eingabe
        end
        print("Bitte 'auf' oder 'zu' eingeben.")
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
        winkel_auf = frageZahl("Winkel zum Oeffnen", 90),
        initZustand = frageZustand("Initialer Zustand (auf/zu)", "zu"),
    }

    local inhalt = "-- Automatisch durch init.lua erzeugte Konfiguration fuer diesen Tor-Computer.\n\n"
        .. "return " .. textutils.serialize(cfg) .. "\n"
    schreibeDatei("cfg.lua", inhalt)
end

local function installiereTorSteuercomputer()
    installiereRepoDatei("startup.lua", "startup.lua")
    schreibeConfig()

    print()
    print("Tor-Steuercomputer installiert.")
    print("Beim naechsten Start laeuft startup.lua automatisch.")
end

local function installiereTaschencomputer()
    installiereRepoDatei("tor.lua", fs.combine("Bauwerk", "tor.lua"))

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
