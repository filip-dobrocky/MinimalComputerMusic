// ======= DEPENDENCIES =======

// Download AOO at
"https://git.iem.at/aoo/aoo/-/releases"
// move the contents of the sc folder to:
Platform.userExtensionDir

// define working directory (path to MinimalComputerMusic)
~dir = "/run/media/filip/data/Projects/MinimalComputerMusic"

// install MCM-SC Quark
// Option 1 - install from local directory:
Quarks.install(~dir +/+ "sc-quark")
// Option 2 - install from GitHub (requires git installed)
Quarks.install("https://github.com/filip-dobrocky/MCM-SC")



// BOOT SC SERVER
s.boot


// ======= CLOCK =======

c = MCMClock.new(groupName: "ensemble")
// start/stop server
c.start
c.stop

// start clock
c.playing = true


// ======= PLAYER =======

// example SynthDefs
(
SynthDef(\perc, { |freq = 440, amp = 1, attackTime = 0.01, decayTime = 1, out = 0|
	var env, sig;
	env = EnvGen.ar(Env.perc(attackTime, decayTime), doneAction: 2);
	sig = amp * env * 0.2 * SinOsc.ar(freq);
	Out.ar(out, sig ! 2);
}).add;

SynthDef(\sustain, { |freq = 440, amp = 1, attackTime = 0.1, decayTime = 0.2, sustainLevel = 0.7, releaseTime = 0.5, gate = 1, out = 0, timeDur = 1|
	var env, sig;
	env = EnvGen.ar(Env.adsr(attackTime, decayTime, sustainLevel, releaseTime), gate, doneAction: 2);
	sig = amp * env * 0.2 * LFTri.ar(freq);
	Out.ar(out, sig ! 2);
}).add;
)


// Initialize MCMPlayer
(
p = MCMPlayer.new(
	playerID: 10000.rand, // can be replaced by username - e.g. "MyName"
    serverAddress: "localhost",
    groupName: "ensemble"
);
)


// Connect to the server
p.connect

// Start listening
p.start


// pattern stretch
// (augment (stretch > 1) / diminish (stretch < 1))
// (slow down / speed up)
p.stretch = 0.5

// pattern phase shift in clock ticks
p.shift = 0

// custom pattern notation
// set sequence (format: degree:duration, x = rest)
// degrees separated by dashes = chord
// e.g. 0-2-5:3 -> chord [0,2,5] with duration 3 beats

p.setSequence("0")
p.setSequence("0-7")
p.setSequence("1:1 2:1 3:1")
p.setSequence("0:2 3:1 2:1 5:2 7:1")
p.setSequence("0:1 4:3 x:1 7:2 8-13:1")
p.setSequence("0:1 0:1 0:1 0:1 0:1 0:1 0:1 3-6:1")
p.setSequence("0-3 x:3 3:1 x:1 2:1 2:1 3:2 6:3 6:1")
p.setSequence("0-3-7:3 3:3 2:1 3:2 6:1 6:1 7:3 5:1")
p.setSequence("1-3-2 x:3 3:1 x:1")
p.setSequence("x")
p.setSequence("0-2-5:4 3:4 2:1 4:2 0:1 7:4")


// change octave
p.octave = 6

// change instrument (any SynthDef)
p.instrument = \perc

// change pattern, utlize generative Pattern classes
p.instrument =  Prand([\perc, \sustain], inf);
p.amp = Pn(Pgeom(0.05, 1.5, 16).clip(0, 1), inf);


// instead of setSequence, change the degrees / durations
p.degrees =  Pwhite(0, 14, inf)
p.durations = Prand([1, 2], inf)



// ======= MIDI MAPPING =======
MIDIIn.connectAll

// post incoming MIDI messages
MIDIFunc.trace(true)
MIDIFunc.trace(false)

(
MIDIdef.cc(\stretch, { |val, num|
	// exponential mapping, use .linlin for linear
	p.stretch = val.linexp(0, 127, 0.1, 3);
	"stretch: %".format(~stretch).postln;
}, 77); // map to MIDI CC 77
)

// other interesting things to map could be:
// ~shift, ~amp... or any synth parameters


// ======= CONDUCTOR =======
k = MCMConductor.new("filip", "localhost", "ensemble")
k.connect
k.stopClock
k.startClock
k.setScale(Scale.partch_o6)
k.setRoot(-12)
