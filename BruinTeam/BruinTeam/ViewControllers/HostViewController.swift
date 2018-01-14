import UIKit
import MultipeerConnectivity

class HostViewController: UIViewController {
    
    @IBOutlet weak var connectionsTableView: UITableView!
    
    let serviceManager = DiscoveryServiceManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        connectionsTableView.dataSource = self
        connectionsTableView.delegate = self

        serviceManager.browserDelegate = self
        serviceManager.startBrowsing()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

// MARK: DiscoveryServiceManagerBrowserDelegate

extension HostViewController: DiscoveryServiceManagerBrowserDelegate {
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
