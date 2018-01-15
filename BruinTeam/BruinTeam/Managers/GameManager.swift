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
    var controls: [Control]? {
        didSet {
            if let controls = self.controls {
                self.delegate?.receivedControls(controls: controls)
            }
        }
    }
    
    var delegate: GameManagerDelegate?
    
    // Host vars
    var allGameControlStates: [(control: Control, state: Any?)]?
    var outstandingInstructions: [(controlID: Control, state: Any?)]?
    
    init(serviceManager: DiscoveryServiceManager, isHost: Bool) {
        self.serviceManager = serviceManager
        self.isHost = isHost
        gpa = 4.0
        
        self.serviceManager.delegate = self
    }
    
    
    
    func setControlToState() {
        
    }
    
    func controlStateChanged() {
        
    }
    
    // MARK: Host Functions
    func startGame() {
        // GameKit has built in shuffling method, how convenient!
        let shuffled: [Control] = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: Controls.controls) as! [Control]
        
        // send peers starting controls
        let numControlsPerPlayer = 3
         for index in 0..<serviceManager.session.connectedPeers.count {
            let peer: MCPeerID = serviceManager.session.connectedPeers[index]
            let start = index * numControlsPerPlayer
            let end = start + numControlsPerPlayer
            let peerControls: [Int] = shuffled[start..<end].map({ $0.uid }) // temp
            serviceManager.send(event: .startGame, withObject: peerControls as AnyObject, toPeers: [peer])
         }
        
        
        // give host starting controls
        let start = serviceManager.session.connectedPeers.count * numControlsPerPlayer
        let end = start + numControlsPerPlayer
        self.controls = Array(shuffled[start..<end]) // temp
        
        // save current game controls
        let numControlsUsed = numControlsPerPlayer * (1 + self.serviceManager.session.connectedPeers.count)
        let allGameControls = Array(shuffled[0..<numControlsUsed])
        self.allGameControlStates = allGameControls.map({ control in
            switch control.controlType {
            case .toggle:
                return (control, false)
            case .segmentedControl:
                return (control, 0)
            case .button:
                return (control, nil)
            case .slider:
                // TODO
                return (control, 0)
            }
        })
        
        // TODO: save instructions
        // give peers commands
        for peer in self.serviceManager.session.connectedPeers {
            let instruction = self.generateInstruction()
            print("generated peer instruction: \(instruction)")
            self.serviceManager.send(event: .newInstruction, withObject: instruction as AnyObject, toPeers: [peer])
        }
        
        // give host a command
        let hostInstruction = self.generateInstruction()
        print("generated host instruction: \(hostInstruction)")
        self.delegate?.commandChanged(command: hostInstruction)
        
    }
    
    func generateInstruction() -> String {
        if let controlPairs = self.allGameControlStates {
            let randomIndex = Int(arc4random_uniform(UInt32(controlPairs.count)))
            let randomPair = controlPairs[randomIndex]
            let control = randomPair.control
            switch control.controlType {
            case .toggle:
                let newState = !(randomPair.state as! Bool)
                if newState {
                    return "Enable \(control.title)"
                }
                return "Disable \(control.title)"
            case .segmentedControl:
                return "TODO: segmented \(control.title)" // TODO
            case .button:
                return "\(control.possibleValues as! String) \(control.title)"
            case .slider:
                return "TODO: slider \(control.title)" // TODO
            }
        }
        return "Error" // temp
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
