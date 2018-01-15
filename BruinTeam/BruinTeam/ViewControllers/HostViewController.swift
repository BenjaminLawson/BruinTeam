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
        serviceManager.startBrowsing()
    }

    @IBAction func startButtonTouched(_ sender: Any) {
        let gameManager = GameManager(serviceManager: serviceManager, isHost: true)
        
        let gameViewController: GameViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "gameViewController") as! GameViewController
        gameViewController.serviceManager = serviceManager
        gameViewController.gameManager = gameManager
        
        
        navigationController?.setNavigationBarHidden(true, animated: true)
        navigationController?.pushViewController(gameViewController, animated: true)
        
        gameManager.startGame()
        gameManager.delegate = gameViewController
        
        
        
        // serviceManager.sendToAll(data: <#T##Data#>)
        // pick (# peers) * 5 random controls, send 5 controls to each peer
        //let shuffled = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: Controls.controls)
        //serviceManager.send(event: .startGame, withObject: nil, toPeers: serviceManager.session.connectedPeers)
        
    }
}



// MARK: DiscoveryServiceManagerBrowserDelegate

extension HostViewController: DiscoveryServiceManagerDelegate {
    func receivedData(data: Data, fromPeer peer: MCPeerID) {
        
    }
    
    func receivedInvite(peerID: MCPeerID, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("ignoring invite from \(peerID)")
    }
    
    func foundPeer(peerID: MCPeerID) {
        serviceManager.invitePeer(peerID: peerID)
    }
    
    func peerChangedState(peerID: MCPeerID, state: MCSessionState) {
        DispatchQueue.main.async {
            print("reloading table view")
            self.connectionsTableView.reloadData()
        }
    }
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
