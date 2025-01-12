import SwiftUI

struct CommandField: NSViewControllerRepresentable {
    
    @Binding var commandText: String
    
    func makeNSViewController(context: Context) -> some CommandFieldViewController {
        return CommandFieldViewController(text: $commandText)
    }
    
    func updateNSViewController(_ nsViewController: NSViewControllerType, context: Context) {
        guard let textField = nsViewController.textField else {
            Log.error("update command bar - fail: get textField = nil")
            return
        }
        textField.stringValue = CommandManager.update(commandText)
        CommandManager.commandText = textField.stringValue
        NotificationCenter.default.post(name: .CommandTextChanged, object: nil, userInfo: ["commandText":textField.stringValue])
    }
    
}

class CommandFieldViewController: NSViewController, NSTextFieldDelegate {
    
    @Binding var text: String
    
    init(text: Binding<String>) {
        _text = text
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }

    var textField: NSTextField!
    
    override func loadView() {
        textField = NSTextField()
        textField.cell = NSTextFieldCell()
        textField.isEditable = true
        textField.usesSingleLineMode = true
        textField.cell?.isScrollable = true
        textField.delegate = self
        textField.stringValue = text
        textField.backgroundColor = .white
        textField.textColor = Constant.mainTextColor.nsColor
        textField.font = NSFont(name: "Menlo", size: 22)
        textField.isBordered = false
        textField.focusRingType = .none
        view = textField
    }
    
    lazy var fieldEditor: NSTextView = {
        return textField.window?.fieldEditor(true, for: textField) as! NSTextView
    }()
    
    override func viewDidAppear() {
        view.window?.makeFirstResponder(view)
        fieldEditor.insertionPointColor = .gray
        if let textView = textField.currentEditor() as? NSTextView {
            let textLength = (textField.stringValue as NSString).length
            textView.setSelectedRange(NSMakeRange(textLength, 0))
        }
    }
    
    func controlTextDidChange(_ obj: Notification) {
        text = textField.stringValue
    }
    
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(insertNewline(_:)) {
            return true
        }
        return false
    }
    
}
