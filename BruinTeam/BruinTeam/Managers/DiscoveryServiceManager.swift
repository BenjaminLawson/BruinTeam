import Foundation
import MultipeerConnectivity

protocol DiscoveryServiceManagerDelegate {
    func foundPeer(peerID: MCPeerID)
    func receivedInvite(peerID: MCPeerID, invitationHandler: @escaping (Bool, MCSession?) -> Void)
    func peerChangedState(peerID: MCPeerID, state: MCSessionState)
    func receivedData(data: Data, fromPeer peer: MCPeerID)
}

class DiscoveryServiceManager: NSObject {
    let bruinTeamServiceType = "bruin-team"
    let myPeerID = MCPeerID(displayName: UIDevice.current.name)
    
    let serviceAdvertiser: MCNearbyServiceAdvertiser
    let serviceBrowser: MCNearbyServiceBrowser
    
    var delegate: DiscoveryServiceManagerDelegate?
    
    lazy var session: MCSession = {
        let session = MCSession(peer: self.myPeerID, securityIdentity: nil, encryptionPreference: .none)
        session.delegate = self
        return session
    }()
    
    override init() {
        serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: bruinTeamServiceType)
        serviceBrowser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: bruinTeamServiceType)
        
        super.init()
        
        serviceAdvertiser.delegate = self
        serviceBrowser.delegate = self
    }
    
    deinit {
        serviceAdvertiser.stopAdvertisingPeer()
        serviceBrowser.stopBrowsingForPeers()
    }
    
    public func startAdvertising() {
        serviceAdvertiser.startAdvertisingPeer()
    }
    
    public func startBrowsing() {
        serviceBrowser.startBrowsingForPeers()
    }
    
    public func invitePeer(peerID: MCPeerID) {
        print("invitePeer: \(peerID)")
        serviceBrowser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }
    
    public func send(event: Event, withObject object: AnyObject? = nil, toPeers peers: [MCPeerID]) {
        if peers.count == 0 {
            return
        }
        
        var rootDictionary: [String: Any] = ["event": event.rawValue]
        if let obj = object {
            rootDictionary["object"] = obj
        }
        let data = NSKeyedArchiver.archivedData(withRootObject: rootDictionary)
        do {
            try self.session.send(data, toPeers: peers, with: .reliable)
        }
        catch let error {
            print("Error sending to peers: \(error)")
        }
    }
}

// MARK: MCNearbyServiceAdvertiserDelegate

extension DiscoveryServiceManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("didNotStartAdvertisingPeer: \(error)")
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("didReceiveInvitationFromPeer: \(peerID)")
        
        delegate?.receivedInvite(peerID: peerID, invitationHandler: invitationHandler)
    }
}

// MARK: MCNearbyServiceBrowserDelegate

extension DiscoveryServiceManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("didNotStartBrowsingForPeers: \(error)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("foundPeer: \(peerID)")
        
        delegate?.foundPeer(peerID: peerID)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("lostPeer: \(peerID)")
    }
}

// MARK: MCSessionDelegate

extension DiscoveryServiceManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        print("peer \(peerID) didChangeState: \(state.rawValue)")
        
        delegate?.peerChangedState(peerID: peerID, state: state)
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("didReceiveData: \(data)")
        delegate?.receivedData(data: data, fromPeer: peerID)
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("didReceiveStream")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("didStartReceivingResourceWithName")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        print("didFinishReceivingResourceWithName")
    }
    
    func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        certificateHandler(true)
    }
}

