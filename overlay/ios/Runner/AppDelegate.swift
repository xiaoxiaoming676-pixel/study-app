import Flutter
import UIKit
import AVFoundation
import PDFKit
import Vision
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, AVSpeechSynthesizerDelegate {
  private let studySpeech = AVSpeechSynthesizer()
  private var studyChannel: FlutterMethodChannel?
  private var studyTokens: [ObjectIdentifier: Int] = [:]

  /// Recognize text in scanned PDF pages locally for reading aloud. OCR does
  /// not guess answer regions: scans still require manual cloze selection.
  private static func recognizeScannedPage(_ page: PDFPage, bounds: CGRect) -> String {
    let longest = max(bounds.width, bounds.height)
    guard longest > 0 else { return "" }
    let scale = min(CGFloat(3), CGFloat(2400) / longest)
    let image = page.thumbnail(of: CGSize(width: bounds.width * scale,
      height: bounds.height * scale), for: .cropBox)
    guard let cgImage = image.cgImage else { return "" }
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true
    request.recognitionLanguages = ["zh-Hans", "en-US"]
    do {
      try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
    } catch { return "" }
    let observations = (request.results ?? []).sorted { left, right in
      if abs(left.boundingBox.midY - right.boundingBox.midY) > 0.015 {
        return left.boundingBox.midY > right.boundingBox.midY
      }
      return left.boundingBox.minX < right.boundingBox.minX
    }
    return observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
  }

  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                        willSpeakRangeOfSpeechString characterRange: NSRange,
                        utterance: AVSpeechUtterance) {
    guard let token = studyTokens[ObjectIdentifier(utterance)] else { return }
    studyChannel?.invokeMethod("speechProgress", arguments: ["token": token, "offset": characterRange.location])
  }
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    guard let token = studyTokens.removeValue(forKey: ObjectIdentifier(utterance)) else { return }
    studyChannel?.invokeMethod("speechDone", arguments: ["token": token])
  }
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
    studyTokens.removeValue(forKey: ObjectIdentifier(utterance))
  }

  /// Registers all pubspec-referenced Flutter plugins in the given registry
  static func registerPlugins(with registry: FlutterPluginRegistry) {
    GeneratedPluginRegistrant.register(with: registry)
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      // The following code will be called upon WorkmanagerPlugin's registration.
      AppDelegate.registerPlugins(with: registry)
    }

    // At least 12 hours between background fetches
    UIApplication.shared.setMinimumBackgroundFetchInterval(TimeInterval(12 * 60 * 60))

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    AppDelegate.registerPlugins(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "StudyLocal") else { return }
    let channel = FlutterMethodChannel(name: "study.local/pdf_speech", binaryMessenger: registrar.messenger())
    studyChannel = channel
    studySpeech.delegate = self
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      let args = (call.arguments as? [String: Any]) ?? [:]
      switch call.method {
      case "voices":
        let voices = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix("zh") }
        result(voices.map { voice in
          ["id": voice.identifier, "name": voice.name,
           "gender": voice.gender == .male ? "男声" : voice.gender == .female ? "女声" : "系统声音"]
        })
      case "speak":
        guard let text = args["text"] as? String, !text.isEmpty else {
          result(FlutterError(code: "NO_TEXT", message: "没有可朗读的文字", details: nil)); return
        }
        self.studySpeech.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = (args["voice"] as? String).flatMap { AVSpeechSynthesisVoice(identifier: $0) }
          ?? AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.rate = Float(min(0.65, max(0.25, (args["rate"] as? Double) ?? 0.5)))
        self.studyTokens[ObjectIdentifier(utterance)] = (args["token"] as? Int) ?? 0
        self.studySpeech.speak(utterance)
        result(nil)
      case "pause":
        self.studySpeech.pauseSpeaking(at: .word); result(nil)
      case "resume":
        self.studySpeech.continueSpeaking(); result(nil)
      case "stop":
        self.studySpeech.stopSpeaking(at: .immediate); result(nil)
      case "analyze":
        guard let payload = args["bytes"] as? FlutterStandardTypedData,
              let index = args["page"] as? Int else {
          result(FlutterError(code: "BAD_INPUT", message: "缺少 PDF 页面", details: nil)); return
        }
        let keywords = (args["keywords"] as? [String]) ?? []
        let bold = (args["bold"] as? Bool) ?? false
        let underline = (args["underline"] as? Bool) ?? false
        let highlight = (args["highlight"] as? Bool) ?? false
        let wantedColor = ((args["color"] as? String) ?? "").uppercased()
        DispatchQueue.global(qos: .userInitiated).async {
          guard let document = PDFDocument(data: payload.data), let page = document.page(at: index) else {
            DispatchQueue.main.async { result(FlutterError(code: "BAD_PDF", message: "无法读取 PDF", details: nil)) }; return
          }
          // Refuse unsupported geometry rather than silently mask the wrong content.
          let bounds = page.bounds(for: .cropBox)
          guard page.rotation == 0, bounds.width > 0, bounds.height > 0,
                page.bounds(for: .mediaBox) == bounds else {
            DispatchQueue.main.async { result(FlutterError(code: "GEOMETRY", message: "旋转或裁切 PDF 请使用手动框选，或先规范化页面", details: nil)) }; return
          }
          let extractedText = page.string ?? ""
          let text = extractedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? Self.recognizeScannedPage(page, bounds: bounds) : extractedText
          var masks: [[String: Any]] = []
          var seen = Set<String>()
          func addSelection(_ selection: PDFSelection, answer: String) {
            for line in selection.selectionsByLine() {
              let r = line.bounds(for: page).intersection(bounds)
              guard !r.isNull, r.width > 0, r.height > 0 else { continue }
              let key = String(format: "%.3f:%.3f:%.3f:%.3f", r.minX, r.minY, r.width, r.height)
              guard !seen.contains(key) else { continue }
              seen.insert(key)
              masks.append(["rect": [(r.minX - bounds.minX) / bounds.width,
                (bounds.maxY - r.maxY) / bounds.height, r.width / bounds.width, r.height / bounds.height],
                "answer": answer])
            }
          }
          for keyword in keywords where !keyword.isEmpty {
            let source = text as NSString
            var cursor = 0
            while cursor < source.length {
              let range = source.range(of: keyword, options: [], range: NSRange(location: cursor, length: source.length - cursor))
              if range.location == NSNotFound { break }
              if let selection = page.selection(for: range) { addSelection(selection, answer: keyword) }
              cursor = range.location + range.length
            }
          }
          if let attributed = page.attributedString {
            attributed.enumerateAttributes(in: NSRange(location: 0, length: attributed.length)) { attributes, range, _ in
              let font = attributes[.font] as? UIFont
              let isBold = font?.fontDescriptor.symbolicTraits.contains(.traitBold) ?? false
              let isUnderlined = ((attributes[.underlineStyle] as? NSNumber)?.intValue ?? 0) != 0
              var color = ""
              if let uiColor = attributes[.foregroundColor] as? UIColor {
                var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
                if uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
                  color = String(format: "%02X%02X%02X", Int((red * 255).rounded()),
                    Int((green * 255).rounded()), Int((blue * 255).rounded()))
                }
              }
              if (bold && isBold) || (underline && isUnderlined) || (!wantedColor.isEmpty && color == wantedColor) {
                if let selection = page.selection(for: range) {
                  addSelection(selection, answer: attributed.attributedSubstring(from: range).string)
                }
              }
            }
          }
          if highlight {
            for annotation in page.annotations where annotation.type == "Highlight" {
              if let points = annotation.quadrilateralPoints, points.count >= 4 {
                for offset in stride(from: 0, through: points.count - 4, by: 4) {
                  let quad = points[offset..<(offset + 4)].map { $0.cgPointValue }
                  let xs = quad.map { $0.x + annotation.bounds.minX }
                  let ys = quad.map { $0.y + annotation.bounds.minY }
                  let rect = CGRect(x: xs.min()!, y: ys.min()!, width: xs.max()! - xs.min()!, height: ys.max()! - ys.min()!)
                  if let selection = page.selection(for: rect) { addSelection(selection, answer: selection.string ?? "") }
                }
              } else if let selection = page.selection(for: annotation.bounds) {
                addSelection(selection, answer: selection.string ?? "")
              }
            }
          }
          DispatchQueue.main.async { result(["text": text, "masks": masks]) }
        }
      default: result(FlutterMethodNotImplemented)
      }
    }
  }
}
