/*
 
 * keep track of controls used in current game
 * keep track of states of all controls
 * generate new instructions that change value of controls
 * process control state changes
 * maintain pending instructions, check them off if completed
 
 */



import MultipeerConnectivity
import GameKit

class ControlState {
    var ownedBy: MCPeerID
    var state: Int
    var pendingInstruction: (value: Int, peer: MCPeerID)? // state : peer
    
    init(state: Int, ownedBy owner: MCPeerID) {
        self.state = state
        self.ownedBy = owner
        self.pendingInstruction = nil
    }
}


class InstructionManager {
    let gameControls: [Control]
    let nPlayers: Int
    let nControlsPerPlayer: Int
    
    //var controlOwners: [Int: MCPeerID]
    //var controlStates: [Int: Int] // uid : current known state value
    //var pendingCommands = [Int: Int]() // uid : desired state value
    
    //var pendingInstructons = [Int: [(value: Int, peer: MCPeerID)]]()
    var controlStates = [Int: ControlState]()
    
    init(session: MCSession, controlsPerPlayer: Int = 3) {
        self.nPlayers = session.connectedPeers.count + 1
        self.nControlsPerPlayer = controlsPerPlayer
        
        // GameKit has built in shuffling method, how convenient!
        let shuffled: [Control] = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: Controls.controls) as! [Control]
        
        let numControlsUsed = controlsPerPlayer * nPlayers
        self.gameControls = Array(shuffled[0..<numControlsUsed])

        // assign & init all control states to 0
        self.controlStates = [Int: ControlState]()
        for (i, peer) in session.connectedPeers.enumerated() {
            let start = i * nControlsPerPlayer
            let end = start + nControlsPerPlayer
            for j in start..<end {
                let uid = gameControls[j].uid
                controlStates[uid] = ControlState(state: 0, ownedBy: peer)
            }
        }
        let hostStart = session.connectedPeers.count * nControlsPerPlayer
        let hostEnd = hostStart + nControlsPerPlayer
        for i in hostStart..<hostEnd {
            let uid = gameControls[i].uid
            controlStates[uid] = ControlState(state: 0, ownedBy: session.myPeerID)
        }
    }
    
    func controls(forPeer peer: MCPeerID) -> [Int] {
        return controlStates.filter({ $0.value.ownedBy == peer }).map({ $0.key })
    }
    
    func registerInstruction(uid: Int, value: Int, peer: MCPeerID) {
        controlStates[uid]?.pendingInstruction = (value: value, peer: peer)
    }
    
    // generate instruction string & register instruction
    func generateInstruction(forPeer peer: MCPeerID) -> String {
        // only pick from controls without pending instructions
        let unusedControls = controlStates.filter({ $0.value.pendingInstruction == nil })
        let randomIndex = Int(arc4random_uniform(UInt32(unusedControls.count)))
        let control: Control = Controls.controls[Array(unusedControls.keys)[randomIndex]]
        let state = controlStates[control.uid]!.state
        
        var instruction = "Error"
        var value = 0
        
        switch control.controlType {
        case .toggle:
            let newState = !(state != 0) // convert to Bool and invert it
            if newState {
                instruction = "Enable \(control.title)"
                value = 1
            }
            else {
                instruction = "Disable \(control.title)"
                value = 0
            }
            
        case .segmentedControl:
            // TODO: randomly pick any state other than current
            instruction = "TODO: segmented \(control.title)" // TODO
        case .button:
            instruction = "\(control.possibleValues as! String) \(control.title)"
        case .slider:
            instruction = "TODO: slider \(control.title)" // TODO
        }
        
        registerInstruction(uid: control.uid, value: value, peer: peer)
        return instruction
    }
    
    // applies state change and returns peer of pending instruction if exists, nil otherwise
    func applyStateDict(dict: [String: Int], fromPeer peer: MCPeerID) -> MCPeerID? {
        let uid = dict["uid"]!
        let newValue = dict["value"]!
        
        guard let controlState = controlStates[uid] else {
            print("error getting control state in applyStateDict")
            return nil
        }
        
        controlState.state = newValue
        
        if let pendingInstruction = controlState.pendingInstruction {
            let instructionOwner = pendingInstruction.peer
            controlState.pendingInstruction = nil
            return instructionOwner
        }
        
        return nil
    }
    
    static func stateDictFromUIControl(control: UIControl) -> [String: Int] {
        var value = -1
        
        if let control = control as? UISwitch {
            //print("switch control")
            value = control.isOn ? 1 : 0
        }
        else if let control = control as? UISegmentedControl {
            print("segmented control")
            value = control.selectedSegmentIndex
        }
        else if let control = control as? UISlider {
            print("slider control")
            value = Int(control.value)
        }
        
        return ["uid": control.tag, "value": value]
    }
}
