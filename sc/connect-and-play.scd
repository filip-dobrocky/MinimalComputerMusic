
// init, connect
(
~dir = "E:/Projects/MinimalComputerMusic";
// ~dir = "/run/media/data/Projects/MinimalComputerMusic";

s.waitForBoot({
	MCMConfig.serverAddress = "192.168.1.102";
	MCMConfig.username = "filip";

	s.sync;

	p = MCMPlayer.new;

	s.sync;
	p.connect;
	s.sync;

	k = MCMConductor.new;
	s.sync;
	k.connect;
	s.sync;
	k.startClock;

	3.wait;
	p.start;
});

)


// set midi output
(
MIDIClient.init;
~midiOut = MIDIOut.newByName("loopMIDI Port", "loopMIDI Port").latency_(Server.default.latency);
p.setParam(\type, \midi);
p.setParam(\midiout, ~midiOut);
p.setParam(\sustain, 0.8);
)



// mess around...
p.octave = 6

p.setSequence("0")
p.setSequence("0-5-7")
p.setSequence("1:2 2:1 3:1")
p.setSequence("0:2 3:1 2:1 5:2 7:1 0:2 3:1 4:1 5:2 7:1")
p.setSequence("0:1 4:3 x:1 7:2 8-13:1")
p.setSequence("0:1 0:1 0:1 0:1 0:1 0:1 0:1 3-6:1")
p.setSequence("0-3 x:3 3:1 x:1 2:1 2:1 3:2 6:3 6:1")
p.setSequence("0-3-7:3 3:3 2:1 3:2 6:1 6:1 7:3 5:1")
p.setSequence("1-3-2 x:3 3:1 x:1")
p.setSequence("x")
p.setSequence("0-2-5:4 3:4 2:1 4:2 0:1 7:4")

p.instrument = \default


p.amp = Pexprand(0.85, 1.0, inf)


// ===================================


Scale.directory // see available scales
k.setScale(Scale.aeolian) // set scale
k.setScale(Scale.indian) // set scale
// or build your own - e.g. 24T equal temperament
k.setScale(Scale([ 0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0, 5.5, 6.0, 6.5, 7.0, 7.5, 8.0, 8.5, 9.0, 9.5, 10.0, 10.5, 11.0, 11.5 ]))
// equivalent of
k.setScale(Scale(Array.series(48, 0, 0.25)))

k.setRoot(-0) // shift global root note by semitones

k.setTempo(666) // set global tempo in BPM
