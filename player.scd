// example SynthDefs
(
SynthDef(\perc, { |freq = 440, amp = 1, attack = 0.01, decay = 1, out = 0|
	var env, sig;
	env = EnvGen.ar(Env.perc(attack, decay), doneAction: 2);
	sig = amp * env * 0.3 * SinOsc.ar(freq);
	Out.ar(out, sig ! 2);
}).add;

SynthDef(\sustain, { |freq = 440, amp = 1, attack = 0.1, decay = 1, out = 0, timeDur = 1|
	var env, sig;
	env = EnvGen.ar(Env.linen(attack, timeDur - attack - decay, decay), doneAction: 2);
	sig = amp * env * 0.3 * SinOsc.ar(freq);
	Out.ar(out, sig ! 2);
}).add;
)


// connect to AOO server and join group
(
fork {
	~playerID = 10000.rand;
	~serverAddress = "localhost";
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

Pdefn(\notes, Pseq([0, 5, 7, Rest(1), 2], inf));
Pdefn(\durations, Pseq([1, 2, 1, 2, 2], inf));

~pat = Pdefn(\pat, Pbind(
	\instrument, Pfunc({ ~instrument }),
	\scale, Pfunc({ ~scale }),
	\root, Pfunc({ ~root }),
	\octave, Pfunc({ ~octave }),
	\amp, Pfunc({ ~amp }),
	\degree, Pdefn(\notes),
	\dur, Pdefn(\durations),
	\timeDur, Pfunc({ |ev| ~beatTimeDur * ~stretch * ev[\dur]})
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


~setSeq = { |seq|
	var split = seq.split($ );
	var arr = split.collect( { |x| x.split($:)});
	var notes = arr.collect( { |x|
		var chord = x[0].split($,);
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


// pattern stretch (augment / diminish - slow down / speed up)
~stretch = 1

// pattern phase shift
~shift = 14

// set sequence (format: degree:duration, x = rest)
// notes separated by commas = chord, e.g. 0,2,5:3
~setSeq.("1:1 2:1 3:1")
~setSeq.("0:1 4:3 x:1 7:2 8,13:1")
~setSeq.("1,3:2 x:3 3:1 x:1")
~setSeq.("x")
~setSeq.("0")
~setSeq.("0,2,5:4 3:4 2:1 4:2 0:1 7:4")

~octave = 4

~instrument = \sustain
