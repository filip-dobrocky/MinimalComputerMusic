Quarks.install("/run/media/filip/data/Projects/MinimalComputerMusic/sc-quark")

Quarks.gui

c = MCMClock.new

c.start
c.stop

c.playing = true
c.isPlaying
c.subdivCounter

p = MCMPlayer.new('hp', '192.168.0.130', 'ensemble', 8080, 9016)

p.connect

p.start


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


d = MCMConductor.new

d.connect

d.setTempo(240)

