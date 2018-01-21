import MultipeerConnectivity
import GameKit

protocol GameManagerDelegate {
    func controlsChanged(to controls: [Control])
    func instructionChanged(to instruction: String)
}

class GameManager {
    let serviceManager: DiscoveryServiceManager
    var delegate: GameManagerDelegate?
    var instructionManager: InstructionManager?
    var gpa: Float
    var isHost = false
    
    // this player's controls
    var controls: [Control]? {
        didSet {
            if let controls = self.controls {
                self.delegate?.controlsChanged(to: controls)
            }
        }
    }
 
    var currentInstruction: String? {
        didSet {
            if let instruction = self.currentInstruction {
                self.delegate?.instructionChanged(to: instruction)
            }
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
    
    
    
    func setControlToState() {
        
    }
    
    func controlStateChanged() {
        
    }
    
    // MARK: Host Functions
    
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
    
    func handleStateChange(of control: UIControl) {
        let stateDict = InstructionManager.stateDictFromUIControl(control: control)
        if isHost {
            processControlStateDict(dict: stateDict)
        } else {
            // send state change to host
            serviceManager.send(event: Event.controlState, withObject: stateDict as AnyObject, toPeers: serviceManager.session.connectedPeers)
        }
    }
    
    func processControlStateDict(dict: [String: Int]) {
        if let instructionOwner = instructionManager?.applyStateDict(dict: dict) {
            print("control state change resolved valid instruction")
            notifyInstructionOwnerOfSuccess(peer: instructionOwner)
        }
        else {
            print("control state change did not resolve valid instruction")
            // TODO: penalty?
        }
    }
    
    // notify owner & send new instruction
    // host function
    func notifyInstructionOwnerOfSuccess(peer: MCPeerID) {
        // generate new instruction
        guard let instructionManager = self.instructionManager else { return }
        
        let instruction = instructionManager.generateInstruction(forPeer: peer)
        if peer == serviceManager.session.myPeerID {
            // peer is self, no need to send message
            self.currentInstruction = instruction
        }
        else {
            serviceManager.send(event: Event.newInstruction, withObject: instruction as AnyObject, toPeers: [peer])
        }
    }
    
}

// MARK: DiscoveryServiceManagerDelegate

extension GameManager: DiscoveryServiceManagerDelegate {
    
    func receivedData(data: Data, fromPeer peer: MCPeerID) {
        print("game manager recieved data")
        
        guard let dict = NSKeyedUnarchiver.unarchiveObject(with: data) as? [String: AnyObject],
            let eventRawValue = dict["event"] as? String,
            let event = Event(rawValue: eventRawValue) else {
                print("game manager data guard failed")
                return
        }
        
        switch event  {
        case Event.newInstruction:
            if let object = dict["object"] as? String {
                DispatchQueue.main.async {
                    self.currentInstruction = object
                }
            }
        case Event.controlState:
            // TODO: handle host's own control state changes
            guard let stateDict = dict["object"] as? [String: Int] else {
                print("Event.controlState guard failed")
                return
            }
            
            if isHost {
                DispatchQueue.main.async {
                    self.processControlStateDict(dict: stateDict)
                }
            }
            
        default:
            print("unrecognized event \(event)")
        }
    }
    
    func foundPeer(peerID: MCPeerID) {
        
    }
    
    func receivedInvite(peerID: MCPeerID, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        
    }
    
    func peerChangedState(peerID: MCPeerID, state: MCSessionState) {
        
    }
}
