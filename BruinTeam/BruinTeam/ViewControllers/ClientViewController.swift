import UIKit
import MultipeerConnectivity

// TODO: let client pick which advertiser they want to connect to

class ClientViewController: UIViewController {
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var hostsTableView: UITableView!
    
    let serviceManager = DiscoveryServiceManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("viewDidLoad")
        
        hostsTableView.dataSource = self
        hostsTableView.delegate = self
    }
    
    /**
     called when view first shown, and when going back from JoiningViewController
     */
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("viewDidAppear")
        
        resetView()
    }
    
    func resetView() {
        serviceManager.delegate = self
        
        serviceManager.session.disconnect()
        
        serviceManager.startBrowsing()
        hostsTableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        serviceManager.stopBrowsing()
    }
}

extension ClientViewController: DiscoveryServiceManagerDelegate {
    func lostPeer(peerID: MCPeerID) {
        
    }
    
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
    
    func foundPeer(peerID: MCPeerID) {
        hostsTableView.reloadData()
    }
    
    func receivedInvite(peerID: MCPeerID, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("Ignoring MC invitation")
    }
    
    func peerChangedState(peerID: MCPeerID, state: MCSessionState) {}
}

extension ClientViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return serviceManager.browserPeers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "hostCell") ?? UITableViewCell(style: .default, reuseIdentifier: "hostCell")
        let setIndex = serviceManager.browserPeers.index(serviceManager.browserPeers.startIndex, offsetBy: indexPath.row)
        cell.textLabel?.text = serviceManager.browserPeers[setIndex].displayName
        return cell
    }
}


extension ClientViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let joiningViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "joiningViewController") as! JoiningViewController
        joiningViewController.serviceManager = serviceManager
        serviceManager.delegate = joiningViewController
        
        hostsTableView.deselectRow(at: indexPath, animated: true)
        
        let setIndex = serviceManager.browserPeers.index(serviceManager.browserPeers.startIndex, offsetBy: indexPath.row)
        serviceManager.invitePeer(peerID: serviceManager.browserPeers[setIndex])
        
        self.navigationController?.pushViewController(joiningViewController, animated: true)
        
        
        
    }
}
