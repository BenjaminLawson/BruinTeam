import UIKit
import MultipeerConnectivity
import GameKit

class HostViewController: UIViewController {
    
    @IBOutlet weak var connectionsTableView: UITableView!
    
    let serviceManager = DiscoveryServiceManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        connectionsTableView.dataSource = self
        connectionsTableView.delegate = self

        serviceManager.delegate = self
        serviceManager.startAdvertising()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        serviceManager.stopAdvertising()
    }

    @IBAction func startButtonTouched(_ sender: Any) {
        let gameViewController: GameViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "gameViewController") as! GameViewController
        let gameManager = GameManager(serviceManager: serviceManager, isHost: true)
        gameViewController.gameManager = gameManager
        gameManager.delegate = gameViewController
        
        
        navigationController?.setNavigationBarHidden(true, animated: true)
        navigationController?.pushViewController(gameViewController, animated: true)
        
        gameManager.startGame()
        
    }
}

// MARK: DiscoveryServiceManagerBrowserDelegate

extension HostViewController: DiscoveryServiceManagerDelegate {
    func receivedInvite(peerID: MCPeerID, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // accept all invitations to connect
        invitationHandler(true, serviceManager.session)
    }
    
    func peerChangedState(peerID: MCPeerID, state: MCSessionState) {
        print("peerChangedState")
        DispatchQueue.main.async {
            self.connectionsTableView.reloadData()
        }
    }
    
    func lostPeer(peerID: MCPeerID) {}
    func receivedData(data: Data, fromPeer peer: MCPeerID) {}
    func foundPeer(peerID: MCPeerID) {}
}

extension HostViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return serviceManager.session.connectedPeers.count
    }
}

extension HostViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "connectionCell", for: indexPath)
        cell.textLabel?.text = "Name: \(serviceManager.session.connectedPeers[indexPath.row].displayName)"
        return cell
    }
}
