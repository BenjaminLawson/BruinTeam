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
    
}

extension GameManager: DiscoveryServiceManagerDelegate {
    
    func receivedData(data: Data, fromPeer peer: MCPeerID) {
        print("game manager recieved data")
        
        guard let dict = NSKeyedUnarchiver.unarchiveObject(with: data) as? [String: AnyObject],
            let event = dict["event"] as? String else {
                print("game manager data guard failed")
                return
        }
        
        switch event  {
        case "NewInstruction":
            if let object = dict["object"] as? String {
                self.currentInstruction = object
            } else {
                print("object downcast failed")
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
