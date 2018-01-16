import MultipeerConnectivity
import GameKit

protocol GameManagerDelegate {
    func receivedControls(controls: [Control])
    func commandChanged(command: String)
}

class GameManager {
    let serviceManager: DiscoveryServiceManager
    var gpa: Float
    var isHost = false
    // this player's controls
    var controls: [Control]? {
        didSet {
            if let controls = self.controls {
                self.delegate?.receivedControls(controls: controls)
            }
        }
    }
    
    var delegate: GameManagerDelegate?
    
    var instructionManager: InstructionManager
    
    // Host vars
    var allGameControlStates: [(control: Control, state: Any?)]?
    var outstandingInstructions: [(controlID: Control, state: Any?)]?
    
    init(serviceManager: DiscoveryServiceManager, isHost: Bool) {
        self.serviceManager = serviceManager
        self.isHost = isHost
        self.gpa = 3.0
        
        self.instructionManager = InstructionManager(nPlayers: serviceManager.session.connectedPeers.count + 1)
        
        self.serviceManager.delegate = self
    }
    
    
    
    func setControlToState() {
        
    }
    
    func controlStateChanged() {
        
    }
    
    // MARK: Host Functions
    
    func startGame() {
        // send peers starting controls
         for index in 0..<serviceManager.session.connectedPeers.count {
            let peer: MCPeerID = serviceManager.session.connectedPeers[index]
            let peerControls: [Int] = instructionManager.controls(forPeerNumber: index)
            serviceManager.send(event: .startGame, withObject: peerControls as AnyObject, toPeers: [peer])
         }
        
        // give host starting controls
        self.controls = instructionManager.controls(forPeerNumber: serviceManager.session.connectedPeers.count).map({ Controls.controls[$0] })
        
        
        // TODO: save instructions
        // give peers commands
        for peer in serviceManager.session.connectedPeers {
            let instruction = instructionManager.generateInstruction()
            print("generated peer instruction: \(instruction)")
            serviceManager.send(event: .newInstruction, withObject: instruction as AnyObject, toPeers: [peer])
        }
        
        // give host a command
        let hostInstruction = instructionManager.generateInstruction()
        
        print("generated host instruction: \(hostInstruction)")
        self.delegate?.commandChanged(command: hostInstruction)
        
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
                DispatchQueue.main.async { self.delegate?.commandChanged(command: object) }
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
