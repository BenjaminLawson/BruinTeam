import UIKit
import MultipeerConnectivity

class JoiningViewController: UIViewController {
    @IBOutlet weak var statusLabel: UILabel?
    
    var connectionState: MCSessionState = .notConnected
    
    public var serviceManager: DiscoveryServiceManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateLabel(withState: connectionState)
    }

    func updateLabel(withState state: MCSessionState) {
        switch state {
        case .notConnected:
            self.statusLabel?.text = "Searching..."
        case .connecting:
            self.statusLabel?.text = "Connecting..."
        case .connected:
            self.statusLabel?.text = "Connected!"
        }
    }
}

extension JoiningViewController: DiscoveryServiceManagerDelegate {
    func lostPeer(peerID: MCPeerID) {}
    
    func receivedData(data: Data, fromPeer peer: MCPeerID) {
        guard let dict = NSKeyedUnarchiver.unarchiveObject(with: data) as? [String: AnyObject],
            let event = dict["event"] as? String,
            let object = dict["object"],
            let controls = object as? [Int] else {
                print("client received data guard failed")
                return
                
        }
        print("data event: \(event)")
        if event == Event.startGame.rawValue {
            // change serviceManager's delegate to gameManager RIGHT NOW to prevent ClientViewController from getting future game updates (race condition)
            let gameManager = GameManager(serviceManager: serviceManager, isHost: false)
            
            DispatchQueue.main.async {
                let gameViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "gameViewController") as! GameViewController
                gameViewController.gameManager = gameManager
                gameManager.delegate = gameViewController
                gameManager.controls = controls.map({ Controls.controls[$0] })
                
                
                self.navigationController?.setNavigationBarHidden(true, animated: true)
                self.navigationController?.pushViewController(gameViewController, animated: true)
            }
        }
    }
    
    func foundPeer(peerID: MCPeerID) {}
    
    func receivedInvite(peerID: MCPeerID, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("Ignoring MC invitation")
    }
    
    func peerChangedState(peerID: MCPeerID, state: MCSessionState) {
        connectionState = state
        
        DispatchQueue.main.async {
            self.updateLabel(withState: self.connectionState)
        }
    }
}
