import UIKit
import MultipeerConnectivity

class ClientViewController: UIViewController {
    @IBOutlet weak var statusLabel: UILabel!
    let serviceManager = DiscoveryServiceManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        serviceManager.advertiserDelegate = self
        serviceManager.startAdvertising()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ClientViewController: DiscoveryServiceManagerAdvertiserDelegate {
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
