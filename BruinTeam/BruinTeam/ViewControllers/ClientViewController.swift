import UIKit
import MultipeerConnectivity

class ClientViewController: UIViewController {
    @IBOutlet weak var statusLabel: UILabel!
    let serviceManager = DiscoveryServiceManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        serviceManager.delegate = self
        serviceManager.startAdvertising()
    }
}

extension ClientViewController: DiscoveryServiceManagerDelegate {
    func receivedData(data: Data, fromPeer peer: MCPeerID) {
        guard let dict = NSKeyedUnarchiver.unarchiveObject(with: data) as? [String: AnyObject],
            let event = dict["event"],
            let object = dict["object"],
            let controls = object as? [Int] else {
                print("client received data guard failed")
                return
                
        }
        print("data event: \(event as! String)")
        if event as! String == Event.startGame.rawValue {
            // TODO: fix this race condition
            DispatchQueue.main.async {
                let gameViewController: GameViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "gameViewController") as! GameViewController
                let _ = gameViewController.view // hack to force view hierarchy to load now
                
                gameViewController.serviceManager = self.serviceManager
                let gameManager = GameManager(serviceManager: self.serviceManager, isHost: false)
                gameViewController.gameManager = gameManager
                gameManager.delegate = gameViewController
                gameManager.controls = controls.map({ Controls.controls[$0] })
                
                
                self.navigationController?.setNavigationBarHidden(true, animated: true)
                self.navigationController?.pushViewController(gameViewController, animated: true)
            }
        }
    }
    
    func foundPeer(peerID: MCPeerID) {
        print("ignoring found peer \(peerID)")
    }
    
    func receivedInvite(peerID: MCPeerID, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, serviceManager.session)
    }
    
    func peerChangedState(peerID: MCPeerID, state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .notConnected:
                self.statusLabel.text = "Searching..."
            case .connecting:
                self.statusLabel.text = "Connecting..."
            case .connected:
                self.statusLabel.text = "Connected!"
            }
        }
    }
}
