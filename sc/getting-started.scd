// run line / code block by Ctrl+Enter / Cmd+Enter

// ======= DEPENDENCIES =======

// Download AOO at
"https://git.iem.at/aoo/aoo/-/releases"
// move the contents of the sc folder to:
Platform.userExtensionDir

// define working directory (path to MinimalComputerMusic)
// (you can drag and drop a directory from a file explorer)
~dir = "E:/Projects/MinimalComputerMusic"

// install MCM-SC Quark
// Option 1 - install from local directory:
Quarks.install(~dir +/+ "MCM-SC")
// Option 2 - install from GitHub (requires git installed)
// Quarks.install("https://github.com/filip-dobrocky/MCM-SC")

// After installing the Quark, recompile the class library
// Language -> Recompile Class Library
// (Ctrl + Shift + L)


// BOOT SC SERVER
s.boot


// ======= CLOCK =======


c = MCMClock.new(groupName: "ensemble")

// start the server
c.start

// start clock
c.playing = true


// ======= PLAYER =======

// simple example SynthDefs - you can use them as a template to create your own
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

// or use ready-made synths from SCLOrkSynths (or modify them)
this.executeFile(~dir +/+ "sc/SCLOrkSynths/SynthDefs/percussion/marimba1.scd")
this.executeFile(~dir +/+ "sc/SCLOrkSynths/SynthDefs/percussion/kalimba.scd")
this.executeFile(~dir +/+ "sc/SCLOrkSynths/SynthDefs/misc/beating.scd")
this.executeFile(~dir +/+ "sc/SCLOrkSynths/SynthDefs/guitar/distortedGuitar.scd")
this.executeFile(~dir +/+ "sc/SCLOrkSynths/SynthDefs/guitar/modalElectricGuitar.scd")

// Initialize MCMPlayer
(
p = MCMPlayer.new(
	playerID: "filip", // can be replaced by username - e.g. "MyName"
	serverAddress: "192.168.0.45",
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

p.setSequence("1")
p.setSequence("0-5-7")
p.setSequence("1:2 2:1 3:1")
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
p.instrument = \marimba1
p.instrument = \distortedGuitar
p.instrument = \modalElectricGuitar
p.instrument = \
p.instrument = Prand([\marimba1, \kalimba, \beating], inf)
p.instrument = Pseq([\marimba1, \kalimba, \beating], inf)

// change pattern, utlize generative Pattern classes
p.instrument =  Prand([\perc, \sustain], inf);
p.amp = Pn(Pgeom(0.05, 1.5, 16).clip(0, 1), inf);


// instead of setSequence, change the degrees / durations
p.degrees =  Pwhite(0, 14, inf)
p.durations = Prand([1, 2], inf)

p.setParam(\dec, 0.1)


// ======= MIDI MAPPING =======
MIDIIn.connectAll

// post incoming MIDI messages
MIDIFunc.trace(true)
MIDIFunc.trace(false)

(
MIDIdef.cc(\stretch, { |val, num|
	// exponential mapping, use .linlin for linear
	p.stretch = val.linexp(0, 127, 0.1, 3);
	"stretch: %".format(p.stretch).postln;
}, 77); // map to MIDI CC 77
)

// other interesting things to map could be:
// p.shift, p.amp...
// ...or any synth parameters - p.setParam(\attack, val.linlin(0, 127, 0.0, 1.0))

(
MIDIdef.cc(\amp, { |val, num|
	// exponential mapping, use .linlin for linear
	p.amp = val.linexp(0, 127, 0.0005, 1).thresh(0.00051);
	"amp: %".format(p.amp).postln;
}, 78); // map to MIDI CC 77
)


// ... or use GUI
(
// A 2D slider (joystick) example
w = Window("XY Pad - Shift / Amp", Rect(100, 100, 300, 300));
w.background = Color.red;
s = Slider2D(w, Rect(20, 20, 260, 260))
.action_({ |sl|
	p.shift = sl.x.linlin(0.0, 1.0, -24, 24);
	p.amp = sl.y ** 2;
	("x - shift:" + p.shift + " y - amp:" + p.amp).postln;
});
w.front;
)

// ======= CONDUCTOR =======
k = MCMConductor.new("filip1", "localhost", "ensemble")
k.connect

k.stopClock
k.startClock

Scale.directory // see available scales
k.setScale(Scale.ionian) // set scale
// or build your own - e.g. 24T equal temperament
k.setScale(Scale([ 0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0, 5.5, 6.0, 6.5, 7.0, 7.5, 8.0, 8.5, 9.0, 9.5, 10.0, 10.5, 11.0, 11.5 ]))
// equivalent of
k.setScale(Scale(Array.series(24, 0, 0.5)))

k.setRoot(-7) // shift global root note by semitones

k.setTempo(120) // set global tempo in BPM

