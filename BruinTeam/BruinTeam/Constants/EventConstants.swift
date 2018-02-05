// compact event strings for Bluetooth transmission
enum Event: String {
    case startGame = "SG"
    case gameOver = "GO"
    case instructionComplete = "IC"
    case instructionExpired = "IE"
    case gpaUpdate = "GPA"
    case controlState = "CS"
    case newInstruction = "NI"
}
