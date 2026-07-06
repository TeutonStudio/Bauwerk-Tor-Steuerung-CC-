-- Konfiguration fuer DIESEN Tor-Computer.
-- Auf jedem Computer, der ein Tor steuert, liegt eine eigene cfg.lua
-- mit den Werten fuer genau dieses eine Tor.

return {
    gebaeude = "Zugfabrik1", -- Name des Gebaeudes (mehrere Tore koennen sich ein Gebaeude teilen)
    tor = "VR",              -- Name/Kuerzel dieses einzelnen Tores innerhalb des Gebaeudes
    winkel_auf = 90,         -- Grad, um die zum OEFFNEN gedreht wird
    winkel_zu = 90,          -- Grad, um die zum SCHLIESSEN zurueckgedreht wird
    -- gangschaltung_name = "right", -- Optional, falls mehrere passende Gearshifts vorhanden sind
}
