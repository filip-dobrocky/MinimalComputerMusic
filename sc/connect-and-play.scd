(
~dir = "E:/Projects/MinimalComputerMusic";
// ~dir = "/run/media/data/Projects/MinimalComputerMusic";

s.waitForBoot({
	MCMConfig.serverAddress = "127.0.0.1";
	MCMConfig.username = "filip";
});
)

c = MCMClock.new
c.start
c.playing = true