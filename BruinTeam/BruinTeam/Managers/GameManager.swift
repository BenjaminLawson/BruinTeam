import MultipeerConnectivity
import GameKit

enum GameStatus {
    case InProgress
    case GameOver
}

protocol GameManagerDelegate {
    func controlsChanged(to controls: [Control])
    func instructionChanged(to instruction: String)
    func gpaChanged(to gpa: Float)
    func gameEnded(withResult won: Bool)
}

class GameManager {
    let serviceManager: DiscoveryServiceManager
    var delegate: GameManagerDelegate?
    var instructionManager: InstructionManager?
    var isHost = false
    var status: GameStatus = .InProgress
    
    /// this player's controls
    var controls: [Control]? {
        didSet {
            if let controls = self.controls {
                self.delegate?.controlsChanged(to: controls)
            }
        }
    }
 
    /// this player's current instruction
    var currentInstruction: String? {
        didSet {
            if let instruction = self.currentInstruction {
                self.delegate?.instructionChanged(to: instruction)
            }
        }
    }
    
    /// the team's GPA, should be synchronized across all players
    var gpa: Float {
        didSet {
            self.delegate?.gpaChanged(to: gpa)
        }
    }

    init(serviceManager: DiscoveryServiceManager, isHost: Bool) {
        self.isHost = isHost
        self.gpa = 2.0 // starting GPA
        
        self.serviceManager = serviceManager
        self.serviceManager.delegate = self
        
        if isHost {
            self.instructionManager = InstructionManager(session: self.serviceManager.session)
        }
    }
    
    /**
     Call when all players have connected to host to initiate the game.
     1. Send all peers starting controls
     2. Give host its controls
     3. Assign a starting instruction to all peers
     4. Assign a starting instruction to the host
     - Warning: Only host should call.
     */
    func startGame() {
        guard let instructionManager = self.instructionManager else {
            print("start game guard failed")
            return
        }
        
        // send peers starting controls
         for peer in serviceManager.session.connectedPeers {
            //let peer: MCPeerID = serviceManager.session.connectedPeers[index]
            let peerControls: [Int] = instructionManager.controls(forPeer: peer)
            print("sending \(peerControls.count) controls to peer \(peer.displayName)")
            serviceManager.send(event: .startGame, withObject: peerControls as AnyObject, toPeers: [peer])
         }
        
        // give host starting controls
        let hostPeer = serviceManager.session.myPeerID
        self.controls = instructionManager.controls(forPeer: hostPeer).map({ Controls.controls[$0] })
        
        // give peers commands
        for peer in serviceManager.session.connectedPeers {
            let instruction = instructionManager.generateInstruction(forPeer: peer)
            print("generated peer instruction: \(instruction)")
            serviceManager.send(event: .newInstruction, withObject: instruction as AnyObject, toPeers: [peer])
        }
        
        // give host a command
        let hostInstruction = instructionManager.generateInstruction(forPeer: hostPeer)
        print("generated host instruction: \(hostInstruction)")
        self.currentInstruction = hostInstruction
    }
    
    
    /**
     Call whenever a control changes value on either client or host.
     If host, apply the change.
     If client, send state change message to host.
     - Parameter control: The UIControl that changed state.
     */
    func handleStateChange(of control: UIControl) {
        let stateDict = InstructionManager.stateDictFromUIControl(control: control)
        if isHost {
            // apply change as if it were sent from a client, for sweet sweet code reusability!
            processControlStateDict(dict: stateDict)
        } else {
            // this player is a client, so send state change to host
            serviceManager.send(event: Event.controlState, withObject: stateDict as AnyObject, toPeers: serviceManager.session.connectedPeers)
        }
    }
    
    /**
     Apply the received control state change message.
     If it completed a pending instruction, notify the owner.
     Update the GPA accordingly.
     - Warning: Only host should call.
     - Parameter dict: Dictionary generated from InstructionManager.stateDictFromUIControl, representing the uid
        of the control and the value it is set to.
     */
    func processControlStateDict(dict: [String: Int]) {
        if let instructionOwner = instructionManager?.applyStateDict(dict: dict) {
            print("control state change resolved valid instruction")
            if !updateGPA(success: true) {
                // game didn't end
                notifyInstructionOwner(peer: instructionOwner)
            }
        }
        else {
            print("control state change did not resolve valid instruction")
            _ = self.updateGPA(success: false)
        }
    }
    
    /**
     Called when host processes a control change.
     - Warning: Only host should call.
     - Returns: true if gpa caused game to end
     */
    func updateGPA(success: Bool) -> Bool {
        gpa += success ? 0.1 : -0.1
        
        if gpa <= 0.0 {
            endGame(won: false)
            return true
        }
        else if gpa >= 4.0 {
            endGame(won: true)
            return true
        }
        else {
            serviceManager.send(event: .gpaUpdate, withObject: gpa as AnyObject, toPeers: serviceManager.peers)
            return false
        }
    }
    
    /**
        Notify owner that their instruction was completed & send new instruction.
     
     TODO: send different event for instruction completed/failed vs just a new instruction event?
     - Warning: Only host should call.
     - Parameter peer: The peer object of the instruction owner.
     */
    func notifyInstructionOwner(peer: MCPeerID) {
        guard let instructionManager = self.instructionManager else { return }
        
        // generate new instruction
        let instruction = instructionManager.generateInstruction(forPeer: peer)
        if peer == serviceManager.session.myPeerID {
            // instruction owner is host, no need to send message
            self.currentInstruction = instruction
        }
        else {
            // send new instruction to the client that owned the completed instruction
            serviceManager.send(event: .newInstruction, withObject: instruction as AnyObject, toPeers: [peer])
        }
    }
    
    func processTimerExpired() {
        if isHost {
            if updateGPA(success: false) { return }
            
            guard let instructionManager = self.instructionManager else { return }
            // delete pendingInstruction for the control
            instructionManager.deletePendingInstructions(for: serviceManager.session.myPeerID)
            // generate new instruction for self
            currentInstruction = instructionManager.generateInstruction(forPeer: serviceManager.session.myPeerID)
        }
        else { // client
            // send timer expired message to host
            serviceManager.send(event: .instructionExpired, withObject: nil, toPeers: serviceManager.session.connectedPeers)
        }
    }
    
    func endGame(won: Bool) {
        if isHost {
            serviceManager.send(event: .gameOver, withObject: ["won": won] as AnyObject, toPeers: serviceManager.peers)
        }
        status = .GameOver
        delegate?.gameEnded(withResult: won)
    }
}

// MARK: DiscoveryServiceManagerDelegate

extension GameManager: DiscoveryServiceManagerDelegate {
    func lostPeer(peerID: MCPeerID) {}
    
    func receivedData(data: Data, fromPeer peer: MCPeerID) {
        print("game manager recieved data")
        
        guard let dict = NSKeyedUnarchiver.unarchiveObject(with: data) as? [String: AnyObject],
            let eventRawValue = dict["event"] as? String,
            let event = Event(rawValue: eventRawValue) else {
                print("game manager data guard failed")
                return
        }
        
        print("[EVENT] \(event.rawValue)")
        
        DispatchQueue.main.async {
            switch event  {
            case .newInstruction:
                if let object = dict["object"] as? String {
                        self.currentInstruction = object
                }
            case .controlState:
                guard let stateDict = dict["object"] as? [String: Int] else { return }
                
                if self.isHost {
                        self.processControlStateDict(dict: stateDict)
                }
            case .instructionExpired:
                print("received instructionExpired event")
                if self.isHost {
                    if self.updateGPA(success: false) { return } // check for game end
                    
                    guard let instructionManager = self.instructionManager else { return }
                    
                    instructionManager.deletePendingInstructions(for: peer)
                    let instruction = instructionManager.generateInstruction(forPeer: peer)
                    
                    // send new instruction to the client that owned the expired instruction
                    self.serviceManager.send(event: .newInstruction, withObject: instruction as AnyObject, toPeers: [peer])
                }
            case .gpaUpdate:
                guard let newGPA = dict["object"] as? Float else { return }
                
                    self.gpa = newGPA
            case .gameOver:
                guard let resultDict = dict["object"] as? [String: Bool],
                    let result = resultDict["won"],
                    !self.isHost
                    else { return }
                
                self.endGame(won: result)
            default:
                print("unrecognized event \(event)")
            }
        }
    }
    
    func foundPeer(peerID: MCPeerID) {
        
    }
    
    func receivedInvite(peerID: MCPeerID, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        
    }
    
    func peerChangedState(peerID: MCPeerID, state: MCSessionState) {
        
    }
}
