s.boot

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


// connect to AOO server and join group
(
fork {
	~playerID = 10000.rand; // can be your own name
	~serverAddress = "localhost"; // replace by server IP
	~groupName = "ensemble";
	~serverPort = 8000;
	~clientPort = 9014;
	~client = AooClient(~clientPort);

	s.sync;

	~client.connect(~serverAddress, ~serverPort, "_", action: { |err|
        if (err.isNil) {
            // now join a group
			~client.joinGroup(~groupName, "player-" ++ ~playerID, "_", "_", action: {
                |err, group, user|
                if (err.isNil) {
                    "successfully joined group % as user %".format(group.name, user.name).postln;
                }
            });
        }
    });
}
)


// initialize
(
~scale =  Scale.major;
~root = 0;
~amp = 1;
~octave = 5;
~instrument = \perc;

Pdefn(\notes, 0);
Pdefn(\durations, 1);

// initial pattern
// params wrapped inside Pfunc, so they can be updated on the fly
// and potentially mapped to a controller
// alternatively, you can replace them by generative Pattern classes
// e.g. Pwhite, Prand etc.

~pat = Pdefn(\pat, Pbind(
	\instrument, Pfunc({ ~instrument }),
	\scale, Pfunc({ ~scale }),
	\root, Pfunc({ ~root }),
	\octave, Pfunc({ ~octave }),
	\amp, Pfunc({ ~amp }),
	\degree, Pdefn(\notes),
	\dur, Pdefn(\durations),
	\sustain, Pfunc({ |ev| ~beatTimeDur * ~stretch * ev[\dur]}) // don't change this
));

~updatePat = { ~stream = ~pat.asStream };
~updatePat.();

~shift = 0; // shift in ticks
~stretch = 1.0; // relative pattern time stretch
~ppqn = 24;
~bpm = 120;
~beatTimeDur = 60 / ~bpm;

~beatCounter = 0;
~currentDuration = 1;

// function to process clock ticks
~clockEvent = { |beat, subdiv|
	var event;
	var clockVal = (beat * ~ppqn) + subdiv;
	var beatDur = (~ppqn * ~stretch).round;

	if ((clockVal - (~shift.ceil)) % beatDur == 0) {
		~beatCounter = ~beatCounter + 1;

		if (~beatCounter == ~currentDuration) {
			event = ~stream.next(());
			~currentDuration = event['dur'];
			event.play;
			~beatCounter = 0;
		};
	};
};

// function to parse custom pattern notation
~setSeq = { |seq|
	var split = seq.split($ );
	var arr = split.collect( { |x| x.split($:)});
	var notes = arr.collect( { |x|
		var chord = x[0].split($-);
		chord = chord.collect( { |note|
			if (note.interpret.isNumber) {note.asInteger} {Rest()}
		});
		if (chord.size == 1) { chord[0] } { chord }
	});
	var durations = arr.collect( { |x| if (x[1] == nil) {1} {x[1].asInteger.max(1)} });
	Pdefn(\notes, Pseq(notes, inf));
	Pdefn(\durations, Pseq(durations, inf));
	~updatePat.();
	notes.postln;
};

)


// start listening to clock and conductor
(
~client.addListener(\msg, { |msg, time, peer|
	switch (msg.data[0])
	{ '/clock/pulse' } { ~clockEvent.(msg.data[1], msg.data[2]); }
	{ '/clock/ppqn' } { ~ppqn = msg.data[1] }
	{ '/tempo/bpm' } { ~bpm = msg.data[1]; ~beatTimeDur = 60 / ~bpm; }
	{ '/scale/root' } { ~root = msg.data[1] }
	{ '/scale/degrees' } { ~scale = Scale(msg.data[1..]) }
	{ };
});
)

// stop listening
~client.removeListener(\msg)


// pattern stretch
// (augment (stretch > 1) / diminish (stretch < 1))
// (slow down / speed up)
~stretch = 2

// pattern phase shift in clock ticks
~shift = 0

// custom pattern notation
// set sequence (format: degree:duration, x = rest)
// degrees separated by dashes = chord
// e.g. 0-2-5:3 -> chord [0,2,5] with duration 3 beats
~setSeq.("1:1 2:1 3:1")
~setSeq.("0:1 4:3 x:1 7:2 8-13:1")
~setSeq.("1-3-2 x:3 3:1 x:1")
~setSeq.("x")
~setSeq.("0")
~setSeq.("0-2-5:4 3:4 2:1 4:2 0:1 7:4")

// change octave
~octave = 6

// change instrument (any SynthDef)
~instrument = \sustain

// change pattern, utlize generative Pattern classes
// note that by replacing the params wrapped in Pfunc,
// global variables like ~instrument, ~amp will no longer update the stream
// and you have to reinitialize
(
~pat = Pdefn(\pat, Pbind(
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
~pat = Pdefn(\pat, Pbind(
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