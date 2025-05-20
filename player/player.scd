(
SynthDef(\perc, { |freq = 440, amp = 1, attack = 0.01, decay = 1, out = 0|
	var env, sig;
	env = EnvGen.ar(Env.perc(attack, decay), doneAction: 2);
	sig = amp * env * 0.3 * SinOsc.ar(freq);
	Out.ar(out, sig ! 2);
}).add;

)

(
fork {
	~playerID = 2;
	~aooPort = 9014;
	~client = AooClient(~aooPort);

	s.sync;

	~client.connect("localhost", 8000, "_", action: { |err|
        if (err.isNil) {
            // now join a group
			~client.joinGroup("ensemble", "player" ++ ~playerID, "_", "_", action: {
                |err, group, user|
                if (err.isNil) {
                    "successfully joined group % as user %".format(group.name, user.name).postln;
                }
            });
        }
    });
}
)

(
~scale =  Scale.major;
~root = 0;

~seq = [0, 5, 7, Rest(1), 2];

~pat1 = Pdefn(\pat1, Pbind(
	\instrument, \perc,
	\scale, Pfunc({ ~scale }),
	\root, Pfunc({ ~root }),
	\octave, 4,
	\amp, 1,
	\degree, Pseq(~seq, inf)
));

~stream = ~pat1.asStream;

/*OSCdef(\degrees, { |msg, time|
	Pdefn(\scale, Scale(msg[1..]));
	~stream = ~pattern.asStream;
}, "/scale/degrees", recvPort: ~recvPort);

OSCdef(\root, { |msg, time|
	Pdefn(\root, msg[1]);
	msg[1].postln;
	~stream = ~pattern.asStream;
}, "/scale/root", recvPort: ~recvPort);*/


~clockEvent = { |beat, subdiv|
	var event;
	if (subdiv == 0) {
		event = ~stream.next(()).play;
	};
};

)

(
~client.addListener(\msg, { |msg, time, peer|
	// msg.data[0].postln;
	switch (msg.data[0])
	{ '/clock/pulse' } { ~clockEvent.(msg.data[1], msg.data[2]); }
	{ '/scale/root' } { ~root = msg.data[1] }
	{ '/scale/degrees' } { ~scale = Scale(msg.data[1..]) }
	{ };
});
)
AooData
~client.removeListener(\msg)


