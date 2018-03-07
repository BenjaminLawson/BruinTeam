import UIKit
import AVFoundation

class HomeViewController: UIViewController {

    var audioPlayer:AVAudioPlayer!
    override func viewDidLoad() {
        super.viewDidLoad()

        let audioFilePath = Bundle.main.path(forResource: "argsound_alpha-bit", ofType: "mp3")
        
        if audioFilePath != nil{
            let audioFileUrl = NSURL.fileURL(withPath: audioFilePath!)
            audioPlayer = try! AVAudioPlayer(contentsOf: audioFileUrl)
            audioPlayer.play()
        }
        else{
            print("couldn't load audio player :/")
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
}


