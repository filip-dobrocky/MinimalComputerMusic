// Playing MCM from TidalCycles.
//
// This script runs the SuperCollider side: it joins the ensemble and mirrors the
// shared clock into an Ableton Link session that Tidal follows. Point Tidal at
// tidal/BootTidal.hs in this repo.
//
// Start order: SuperDirt, then Tidal, then evaluate the block below.


// init, connect
(
s.waitForBoot({
    MCMConfig.serverAddress = "localhost";
    MCMConfig.username = "filip";

    s.sync;

    // A conductor is optional - pass one to MCMLink and you can also conduct from Tidal
    k = MCMConductor.new;
    s.sync;
    k.connect;
    s.sync;

    l = MCMLink.new(k);
    s.sync;
    l.connect;

    3.wait;
    l.start;

    "Link peers: %".format(l.link.numPeers).postln; // should be > 0 once Tidal is up
});
)


// In Tidal, degrees go through `mcm` so the ensemble's scale and root apply:
//
//   d1 $ note (mcm "0 [2 4] <7 9>*2 ~") # s "superpiano"
//   d2 $ note (mcm "0 ~ 7 ~") # s "superpiano"


// Conduct from SuperCollider...
k.startClock
k.setTempo(66)
k.setScale(Scale.aeolian)
k.setRoot(5)
k.setScale(Scale(Array.series(48, 0, 0.25))) // 24T - Tidal gets fractional notes
k.stopClock

// ...or from Tidal, which reaches MCMConductor through MCMLink:
//
//   mcmPlay
//   mcmBpm 90
//   mcmSetScale [0,2,3,5,7,8,10]
//   mcmSetRoot 5
//   mcmStop


// ===================================
// An MCM player can run alongside, on the same clock and scale

(
p = MCMPlayer.new;
p.connect({ p.start });
)

p.setMini("0 [2 4] <7 9>*2 ~")  // mini-notation, 4 beats per cycle
p.setSequence("0:1 4:3 x:1 7:2") // MCM notation, durations in beats
p.setSequence("0:0.5 4:1.5 x:1") // fractional durations also work now

l.free
