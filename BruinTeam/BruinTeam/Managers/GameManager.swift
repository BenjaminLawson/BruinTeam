import MultipeerConnectivity
import GameKit

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
        self.gpa = 3.0
        
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
            self.updateGPA(success: true)
            notifyInstructionOwner(peer: instructionOwner)
        }
        else {
            print("control state change did not resolve valid instruction")
            self.updateGPA(success: false)
        }
    }
    
    /**
     Called when host processes a control change.
     - Warning: Only host should call.
     */
    func updateGPA(success: Bool) {
        gpa += success ? 0.1 : -0.1
        
        if gpa <= 0.0 {
            serviceManager.send(event: .gameOver, withObject: ["won": false] as AnyObject, toPeers: serviceManager.peers)
            delegate?.gameEnded(withResult: false)
        }
        else if gpa >= 4.0 {
            serviceManager.send(event: .gameOver, withObject: ["won": true] as AnyObject, toPeers: serviceManager.peers)
            delegate?.gameEnded(withResult: true)
        }
        else {
            serviceManager.send(event: .gpaUpdate, withObject: gpa as AnyObject, toPeers: serviceManager.peers)
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
        // decrease gpa
        updateGPA(success: false)
        
        if isHost {
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
                if self.isHost {
                        guard let instructionManager = self.instructionManager else { return }
                        print("received instructionExpired event")
                        instructionManager.deletePendingInstructions(for: peer)
                        // generate new instruction
                        let instruction = instructionManager.generateInstruction(forPeer: peer)
                        // send new instruction to the client that owned the expired instruction
                        self.serviceManager.send(event: .newInstruction, withObject: instruction as AnyObject, toPeers: [peer])
                }
            case .gpaUpdate:
                guard let newGPA = dict["object"] as? Float else { return }
                
                    self.gpa = newGPA
            case .gameOver:
                guard let resultDict = dict["object"] as? [String: Bool],
                    let result = resultDict["won"]
                    else { return }
                
                if !self.isHost {
                        self.delegate?.gameEnded(withResult: result)
                }
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
