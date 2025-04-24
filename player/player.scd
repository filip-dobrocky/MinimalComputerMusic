(
SynthDef(\perc, { |freq = 440, amp = 1, attack = 0.01, decay = 1, out = 0|
	var env, sig;
	env = EnvGen.ar(Env.perc(attack, decay), doneAction: 2);
	sig = amp * env * 0.3 * SinOsc.ar(freq);
	Out.ar(out, sig ! 2);
}).add;

Pdefn(\scale, Scale.major);
Pdefn(\root, 0);
~recvPort = 55555;
)


(
~seq = [0, 5, 7, Rest(1), 2];

~pattern = Pbind(
	\instrument, \perc,
	\scale, Pdefn(\scale),
	\root, Pdefn(\root),
	\octave, 4,
	\amp, 1,
	\degree, Pseq(~seq, inf)
);

~stream = ~pattern.asStream;

OSCdef(\degrees, { |msg, time|
	Pdefn(\scale, Scale(msg[1..]));
	~stream = ~pattern.asStream;
}, "/scale/degrees", recvPort: ~recvPort);

OSCdef(\root, { |msg, time|
	Pdefn(\root, msg[1]);
	msg[1].postln;
	~stream = ~pattern.asStream;
}, "/scale/root", recvPort: ~recvPort);

OSCdef(\clock, { |msg, time|
	var beat = msg[2];
	var event;
	if (beat == 0) {
		event = ~stream.next(()).play;
	};

}, "/tempo/pulse", recvPort: ~recvPort);

)


