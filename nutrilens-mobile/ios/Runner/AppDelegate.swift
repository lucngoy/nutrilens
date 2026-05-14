import UIKit
import Flutter
import UniformTypeIdentifiers

// MARK: - Document Picker Plugin

class DocumentPickerPlugin: NSObject, FlutterPlugin, UIDocumentPickerDelegate {

  private var pendingResult: FlutterResult?

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.nutrilens/document_picker",
      binaryMessenger: registrar.messenger()
    )
    let instance = DocumentPickerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "pickDocument" {
      pendingResult = result
      openPicker()
    } else {
      result(FlutterMethodNotImplemented)
    }
  }

  private func openPicker() {
    var types: [UTType] = [.pdf, .image, .plainText]
    if #available(iOS 14.0, *) {
      if let doc  = UTType(filenameExtension: "doc")  { types.append(doc) }
      if let docx = UTType(filenameExtension: "docx") { types.append(docx) }
    }

    let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
    picker.delegate = self
    picker.allowsMultipleSelection = false

    DispatchQueue.main.async {
      let root = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController
      root?.present(picker, animated: true)
    }
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    pendingResult?(urls.first?.path as Any)
    pendingResult = nil
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    pendingResult?(nil)
    pendingResult = nil
  }
}

// MARK: - App Delegate

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }

    GeneratedPluginRegistrant.register(with: self)

    DocumentPickerPlugin.register(
      with: self.registrar(forPlugin: "DocumentPickerPlugin")!
    )

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
