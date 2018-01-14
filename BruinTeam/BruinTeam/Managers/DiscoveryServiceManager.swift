import Foundation
import MultipeerConnectivity

protocol DiscoveryServiceManagerAdvertiserDelegate {
    func receivedInvite(peerID: MCPeerID, invitationHandler: @escaping (Bool, MCSession?) -> Void)
    func peerChangedState(peerID: MCPeerID, state: MCSessionState)
}

protocol DiscoveryServiceManagerBrowserDelegate {
    func foundPeer(peerID: MCPeerID)
    func peerChangedState(peerID: MCPeerID, state: MCSessionState)
}

class DiscoveryServiceManager: NSObject {
    let bruinTeamServiceType = "bruin-team"
    let myPeerID = MCPeerID(displayName: UIDevice.current.name)
    
    let serviceAdvertiser: MCNearbyServiceAdvertiser
    let serviceBrowser: MCNearbyServiceBrowser
    
    var advertiserDelegate: DiscoveryServiceManagerAdvertiserDelegate?
    var browserDelegate: DiscoveryServiceManagerBrowserDelegate?
    
    lazy var session: MCSession = {
        let session = MCSession(peer: self.myPeerID, securityIdentity: nil, encryptionPreference: .optional)
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
        NSLog("%@", "invitePeer: \(peerID)")
        serviceBrowser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }
    
    
}

// MARK: MCNearbyServiceAdvertiserDelegate

extension DiscoveryServiceManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("didNotStartAdvertisingPeer: \(error)")
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("didReceiveInvitationFromPeer: \(peerID)")
        
        self.advertiserDelegate?.receivedInvite(peerID: peerID, invitationHandler: invitationHandler)
    }
}

// MARK: MCNearbyServiceBrowserDelegate

extension DiscoveryServiceManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("didNotStartBrowsingForPeers: \(error)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("foundPeer: \(peerID)")
        
        self.browserDelegate?.foundPeer(peerID: peerID)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("lostPeer: \(peerID)")
    }
}

// MARK: MCSessionDelegate

extension DiscoveryServiceManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        print("peer \(peerID) didChangeState: \(state.rawValue)")
        
        browserDelegate?.peerChangedState(peerID: peerID, state: state)
        advertiserDelegate?.peerChangedState(peerID: peerID, state: state)
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("didReceiveData: \(data)")
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        NSLog("%@", "didReceiveStream")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        NSLog("%@", "didStartReceivingResourceWithName")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        NSLog("%@", "didFinishReceivingResourceWithName")
    }
}

