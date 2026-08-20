-- MCM boot file for TidalCycles.
--
-- Tidal plays as a member of the MCM ensemble: it takes clock, scale and root from
-- whoever is conducting, and plays through its own SuperDirt as usual.
--
--   MCMLink (SuperCollider)  --Ableton Link-->  tempo and phase
--   MCMLink  --/ctrl mcmscale, mcmroot-->  the `mcm` function below
--   mcmPlay / mcmSetScale / ... --/mcm/conduct-->  MCMLink -> MCMConductor -> ensemble
--
-- Start order that works most reliably: SuperDirt, then Tidal, then MCMLink.
--
-- Multi-line definitions are wrapped in :{ ... :} because editors feed this file to
-- ghci a line at a time.

:set -fno-warn-orphans -Wno-type-defaults -XMultiParamTypeClasses -XOverloadedStrings
:set prompt ""

import Sound.Tidal.Boot

-- Tidal defines its own <* and *> (structure from the left / right operand), and
-- `all` (apply a function to every pattern).
import Prelude hiding (all, (<*), (*>))

-- hosc >= 0.20. On older hosc these are Sound.OSC.FD / Sound.OSC.Transport.FD.UDP.
import qualified Sound.Osc.Fd as O
import qualified Sound.Osc.Transport.Fd.Udp as O

default (Rational, Integer, Double, Pattern String)

-- Link on. cQuantum and cBeatsPerCycle must match MCMLink's `quantum` (4).
:{
tidalInst <- mkTidalWith
  [(superdirtTarget { oLatency = 0.05 }, [superdirtShape])]
  (defaultConfig { cEnableLink = True, cQuantum = 4, cBeatsPerCycle = 4 })
:}

instance Tidally where tidal = tidalInst


-- Ensemble harmony -----------------------------------------------------------
-- MCMLink forwards the conductor's scale and root here as /ctrl messages, so
-- `mcm` reads whatever the ensemble is currently in.
--
--   d1 $ note (mcm "0 [2 4] <7 9>*2 ~") # s "superpiano"

:{
let mcmDegrees = (map read . words) <$> cS "0 2 4 5 7 9 11" "mcmscale" :: Pattern [Double]
    mcmRoot = cF 0 "mcmroot"
    -- An octave is always 12 semitones; the degree list gives the steps per octave.
    -- Mirrors pd/player.pd's degree2note and SuperCollider's Scale, and keeps
    -- micro-intervals (a 24-entry quartertone list still spans 12 semitones).
    mcmDeg ds d = (ds !! (d `mod` length ds)) + fromIntegral (12 * (d `div` length ds))
    -- <* keeps the structure coming from the note pattern, not from the controls
    mcm p = (\d ds r -> realToFrac (mcmDeg ds d + r)) <$> p <* mcmDegrees <* mcmRoot
:}


-- Ensemble transport ---------------------------------------------------------
-- Link carries tempo and phase but no transport, so the conductor's start/stop
-- arrives as a control instead, and gates every pattern. Defaults to playing, so
-- Tidal on its own (no MCMLink) behaves as usual.

:{
let mcmPlaying = (> 0) <$> cF 1 "mcmplaying"
    mcmGate = mask mcmPlaying
:}

all mcmGate


-- Conducting -----------------------------------------------------------------
-- MCM is non-hierarchical, so a Tidal player can conduct too. These reach
-- MCMLink's OSCdef on sclang's own port, which calls MCMConductor.

mcmAddr <- O.openUdp "127.0.0.1" 57120

:{
let conduct k vs = O.sendMessage mcmAddr (O.Message "/mcm/conduct" (O.string k : vs))
    mcmPlay = conduct "playing" [O.int32 1]
    mcmStop = conduct "playing" [O.int32 0]
    mcmSetRoot r = conduct "root" [O.float r]
    mcmSetScale ds = conduct "degrees" (map O.float ds)
:}

-- Tempo rides Link: this sets the local session tempo, MCMLink forwards it to the
-- ensemble, and it comes back via the shared clock. The round trip is the
-- confirmation that the bridge is working. `setcps` does the same thing.
let mcmBpm b = setcps (b / 60 / 4)

:set prompt "tidal> "
:set prompt-cont ""
