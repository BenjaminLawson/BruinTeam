struct Controls {
    static let controls: [Control] = [
        Control(controlType: .segmentedControl, title: "Best editor", possibleValues: ["Emacs", "Vim", "Sublime Text"]),
        Control(controlType: .toggle, title: "Caffeine", possibleValues: nil),
        Control(controlType: .button, title: "Bruin bear paw", possibleValues: "Rub"),
        Control(controlType: .button, title: "Boelter 3400", possibleValues: "Find")
    ]
}
