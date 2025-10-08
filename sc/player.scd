s.boot

// dependencies:
// Download AOO at
"https://git.iem.at/aoo/aoo/-/releases"
// move the contents of the sc folder to:
Platform.userExtensionDir



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
~player = MCMPlayer.new(
    playerID: 10000.rand,
    serverAddress: "localhost",
    groupName: "ensemble"
);
)


// Connect to the server
~player.connect;

// Start listening
~player.start;


// pattern stretch
// (augment (stretch > 1) / diminish (stretch < 1))
// (slow down / speed up)
~player.stretch = 2

// pattern phase shift in clock ticks
~shift = 0

// custom pattern notation
// set sequence (format: degree:duration, x = rest)
// degrees separated by dashes = chord
// e.g. 0-2-5:3 -> chord [0,2,5] with duration 3 beats

~player.setSequence("0")
~player.setSequence("0-7")
~player.setSequence("1:1 2:1 3:1")
~player.setSequence("0:2 3:1 2:1 5:2 7:1")
~player.setSequence("0:1 4:3 x:1 7:2 8-13:1")
~player.setSequence("0:1 0:1 0:1 0:1 0:1 0:1 0:1 3-6:1")
~player.setSequence("0-3 x:3 3:1 x:1 2:1 2:1 3:2 6:3 6:1")
~player.setSequence("0-3-7:3 3:3 2:1 3:2 6:1 6:1 7:3 5:1")
~player.setSequence("1-3-2 x:3 3:1 x:1")
~player.setSequence("x")
~player.setSequence("0-2-5:4 3:4 2:1 4:2 0:1 7:4")


// change octave
~player.octave = 6

// change instrument (any SynthDef)
~player.instrument = \sustain

// change pattern, utlize generative Pattern classes
// note that by replacing the params wrapped in Pfunc,
// global variables like ~instrument, ~amp will no longer update the stream
// and you have to reinitialize
(
~pat = Pdef(\pat, Pbind(
	// random instrument (SynthDef)
	\instrument, Prand([\perc, \sustain], inf),

	\scale, Pfunc({ ~scale }),
	\root, Pfunc({ ~root }),
	\octave, Pfunc({ ~octave }),

	// repeating crescendo
	\amp, Pn(Pgeom(0.05, 1.5, 16).clip(0, 1), inf),

	// keep these, if you want to use the ~setSeq function
	// or replace, if you want to use generative patterns
	\degree, Pdefn(\notes),
	\dur, Pdefn(\durations),
	\sustain, Pfunc({ |ev| ~beatTimeDur * ~stretch * ev[\dur]}), // don't change this

	/* you can add custom parameters for your own synth */
));

// this function has to be called to update the stream
~updatePat.();
)

// alternatively, just change e.g. the degrees (Pdefn allows this)
(
Pdefn(\notes, Pwhite(0, 14, inf));
~updatePat.();
)
(
Pdefn(\durations, Prand([1, 2], inf));
~updatePat.();
)

// reinitialize pattern
(
~pat = Pdef(\pat, Pbind(
	\instrument, Pfunc({ ~instrument }),
	\scale, Pfunc({ ~scale }),
	\root, Pfunc({ ~root }),
	\octave, Pfunc({ ~octave }),
	\amp, Pfunc({ ~amp }),
	\degree, Pdefn(\notes),
	\dur, Pdefn(\durations),
	\sustain, Pfunc({ |ev| ~beatTimeDur * ~stretch * ev[\dur]}) // don't change this
));
)

/* example of MIDI mapping */
MIDIIn.connectAll

// post incoming MIDI messages
MIDIFunc.trace(true)
MIDIFunc.trace(false)

(
MIDIdef.cc(\stretch, { |val, num|
	// exponential mapping, use .linlin for linear
	~stretch = val.linexp(0, 127, 0.1, 3);
	"stretch: %".format(~stretch).postln;
}, 77); // map to MIDI CC 77
)

// other interesting things to map could be:
// ~shift, ~amp... or any synth parameters