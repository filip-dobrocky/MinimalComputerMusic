MCM - Minimal Computer Music
----------------------------
MCM is a set of tools for Pd (vanilla) and SuperCollider which enables a non-hierarchichal computer ensemble to play pattern-based minimalism-like music.

It makes use of [AOO](https://git.iem.at/aoo/aoo) (Audio Over OSC) for group communication in a network, broadcasting information influencing global musical parameters and also a shared clock with timecode information. AOO is used because of its ability to reliably send and receive OSC messages, minimizing the effects of packet loss and timing differences. The audio streaming capabilities are not used, although the network group could be utilized also for this purpose.

Clock - `clock.pd`
-----------------
This is the patch that hosts the AOO server and also creates a client called `clock` which broadcasts timing messages of the following format:
- `/clock/pulse [beat] [subdiv]`,  
 where `beat` is the number of beats (quarter notes) elapsed since the start of the clock and `subdiv` is the number of clock ticks since the start of the current beat, going from `0` to `ppqn - 1` (`ppqn` = Pulses Per Quarter Note),

 - `/clock/ppqn [ppqn]`,  
 which is a variable parameter inside the `clock` patch with the default value of `24`.

 The clock listens to the following messages:

 - `/tempo/playing [0/1]` - starts or stops the clock,

 - `/tempo/bpm [bpm]` - beats per minute.

 There should be only one instance of the `clock.pd` patch running on the network, and every client connects to the server, which hosts this patch.

 Conductor - `conductor.pd`
 -------------------------
 The word conductor is not used in the traditional sense, where one conductor directs the whole ensemble. On the other hand, everyone in the ensemble can also be a conductor (hence "non-hierarchichal") and control global musical parameters like tempo and mode.

 A conductor can:

 - start and stop the clock: `/tempo/playing [0/1]`
 - change the tempo:  `/tempo/bpm [bpm]`
 - change the musical mode: `/scale/degrees [degrees]`,
 where `degrees` is a variable-sized list of `float`s which indicate the relative intervals in semitones from the root of the scale (micro-intervals allowed)
 - change the root note of the scale: `/scale/root [root]`.

 Player (Pd and SC)
 ------------------
 A player receives the clock (and tempo + scale information) and plays their own patterns on their own instruments. Both the Pure Data and SuperCollider versions employ a custom pattern notation in the following format:
 ```
 degree:duration, x = rest
degrees separated by dashes = chord
e.g. 0-2-5:3 -> chord [0,2,5] with duration 3 beats

example:
0:1 4:3 x:1 7:2 8-13:1
- number of events (notes): 5
- number of beats: 8
 ```

There is also a possibility to *stretch* and *shift* the pattern, which are techniques often employed in minimal music. These are basically manipulations of the incoming clock:
 - `stretch` - factor which speeds up or slows down the pattern (augmentation / diminishment)
 - `shift` - phase shift, shifts the pattern along the clock by the given value of `ppqn`.

 The SuperCollider version is somewhat more powerful, because it makes use of Patterns (in a hacky way, because they do not allow for external clocks and have to be converted to streams to get events on demand).

 You can give it your own instrument(s) (SynthDef) via the `\instrument` key. The SynthDef should have an an envelope with `doneAction: 2`. If you have a sustained instrument, it should have a gated envelope (eg. ADSR) and an argument called `gate`.

 The Pd version outputs MIDI `NoteOn / NoteOff` data via the send `mcm-midinote` (so you can receive it in another patch with your synth) and also `noteout` to the output MIDI port.

 Dependencies
 ------------
 The only dependency is **AOO**. You can install it in Pd via Deken (`Help -> Find Externals`) and in SuperCollider by downloading the latest [release](https://git.iem.at/aoo/aoo/-/releases) for your system and copying the SC version to your `Extensions` folder.