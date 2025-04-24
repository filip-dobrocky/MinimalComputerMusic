(
s.boot; // boot the Server
~aooPort = 7000; // pick any free port
)

// A: AOO source with 2 channels
(
SynthDef(\aoo_send, { |id=1, bus=0|
    AooSend.ar(~aooPort, id, In.ar(bus, 2))
}).add;
)

// B: AOO sink with 2 channels
(
SynthDef(\aoo_recv, { |id=1, bus=0|
    Out.ar(bus, AooReceive.ar(~aooPort, id))
}).add;
)

// A:
(
// Create the destination adddress:

// Note: hostnames must be resolved with AooAddr.resolve!
~destAddr = AooAddr.resolve("255:255:255:255", ~aooPort);

~aooBus = Bus.audio(s, 2);

fork {
    ~source = AooSendCtl(Synth(\aoo_send, [bus: ~aooBus]));

    // AOO sources are created asynchronously, so we have to
    // synchronize with the Server before we can call methods!
    s.sync;

    "AOO source is ready!".postln;
    // add the sink that should receive our stream
    ~source.addSink(~destAddr, 1);
}
)

// B:
(
fork {
    ~sink = AooReceiveCtl(Synth(\aoo_recv));

    // AOO sinks are created asynchronously, so we have to
    // synchronize with the Server before we can call methods!
    // (Here it wouldn't be necessary as we don't call any methods.)
    s.sync;

    "AOO sink is ready!".postln;
}
)

// A:
(
// Play two sine tones *before* the AOO source Synth.
{
    Out.ar(~aooBus, SinOsc.ar([440, 220]) * 0.1)
}.play(target: ~source.synth, addAction: \addBefore);
)

// Finally, start the stream.
~source.start;

// You can pause the stream
~source.stop;

