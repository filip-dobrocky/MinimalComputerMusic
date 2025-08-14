MCMPlayer {
    var <playerID, <serverAddress, <groupName, <serverPort, <clientPort;
    var <client, <isConnected = false, <isListening = false;
    var <scale, <root, <octave, <amp, <instrument;
    var <stretch, <shift, <ppqn, <bpm, <beatTimeDur;
    var <pattern, <stream, <beatCounter, <currentDuration;
    var <notesPdefn, <durationsPdefn;

    *new { |playerID, serverAddress, groupName, serverPort, clientPort|
        ^super.new.init(
            playerID, 
            serverAddress ? MCMConfig.defaultServerAddress,
            groupName ? MCMConfig.defaultGroupName,
            serverPort ? MCMConfig.defaultServerPort,
            clientPort ? MCMConfig.defaultPlayerPort
        );
    }

    init { |playerIDArg, serverAddr, groupNm, serverPrt, clientPrt|
        playerID = playerIDArg;
        serverAddress = serverAddr;
        groupName = groupNm;
        serverPort = serverPrt;
        clientPort = clientPrt;
        
        // Initialize musical defaults
        scale = Scale.major;
        root = 0;
        octave = 5;
        amp = 1;
        instrument = \default;
        stretch = 1.0;
        shift = 0;
        ppqn = MCMConfig.defaultPPQN;
        bpm = MCMConfig.defaultBPM;
        beatTimeDur = 60 / bpm;
        beatCounter = 0;
        currentDuration = 1;
        
        // Initialize pattern system
        notesPdefn = Pdefn((playerID ++ "_notes").asSymbol, 0);
        durationsPdefn = Pdefn((playerID ++ "_durations").asSymbol, 1);
        this.prUpdatePattern();
    }

    // Connection methods
    connect { |action|
        // Handle AOO connection and group joining
    }
    
    disconnect {
        // Clean disconnect
    }
    
    // Pattern methods
    setSequence { |sequenceString|
        // Parse your custom notation and update Pdefns
    }
    
    setDegrees { |pattern|
        // Set degrees using SC Pattern objects (Pwhite, Pseq, etc.)
    }
    
    setDurations { |pattern|
        // Set durations using SC Pattern objects
    }
    
    // Musical parameter setters
    instrument_ { |synthDef| ... }
    stretch_ { |value| ... }
    shift_ { |value| ... }
    octave_ { |value| ... }
    amp_ { |value| ... }
    
    // Control methods
    start { /* start listening to clock */ }
    stop { /* stop listening */ }
    
    // Internal methods
    prClockEvent { |beat, subdiv| ... }
    prUpdatePattern { ... }
    prParseSequence { |seq| ... }
}