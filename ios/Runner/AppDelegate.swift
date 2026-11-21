import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "DivisionRegionsPlugin") {
      DivisionRegionsPlugin.register(with: registrar)
    }
  }
}

/// Reports UIKit division regions (the fold of an unfolded iPhone Duo) to
/// Flutter. Active regions, while the device is partially open, become
/// display features; inactive ones, while it is fully open, only guide
/// layouts that split around the fold.
///
/// The iOS 27.1 reserved-region API is looked up at runtime, so the app still
/// builds with older SDKs and reports nothing on older systems.
final class DivisionRegionsPlugin: NSObject, FlutterPlugin {
  private let channel: FlutterMethodChannel
  private weak var registrar: FlutterPluginRegistrar?
  private var observer: DivisionRegionObserverView?

  private init(channel: FlutterMethodChannel, registrar: FlutterPluginRegistrar) {
    self.channel = channel
    self.registrar = registrar
  }

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "nekokolpa/division_regions",
      binaryMessenger: registrar.messenger()
    )
    let instance = DivisionRegionsPlugin(channel: channel, registrar: registrar)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "start":
      if let observer {
        // A restarted Dart isolate starts without regions.
        observer.resend()
      } else {
        attach(attempt: 0)
      }
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func attach(attempt: Int) {
    guard observer == nil, DivisionRegionObserverView.isSupported else { return }
    // The view controller is attached shortly after the implicit engine.
    guard let view = registrar?.viewController?.view else {
      if attempt < 20 {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
          self?.attach(attempt: attempt + 1)
        }
      }
      return
    }
    let observer = DivisionRegionObserverView(frame: view.bounds)
    observer.onChange = { [weak self] regions in
      self?.channel.invokeMethod("update", arguments: regions)
    }
    view.addSubview(observer)
    self.observer = observer
  }
}

/// An invisible view that tracks its superview's bounds and re-reads the
/// division regions on layout, and when UIKit reports that they changed.
private final class DivisionRegionObserverView: UIView {
  private static let querySelector = NSSelectorFromString("reservedRegionsOfKind:options:")
  /// `UIViewReservedRegionQueryOptionsIncludeInactive`.
  private static let includeInactive: UInt = 1 << 0

  private typealias Query = @convention(c) (AnyObject, Selector, AnyObject, UInt) -> Unmanaged<NSArray>

  static var isSupported: Bool {
    UIView.instancesRespond(to: querySelector) && divisionKind != nil
  }

  private static var divisionKind: AnyObject? {
    guard let kindClass = NSClassFromString("UIViewReservedRegionKind") as? NSObject.Type else {
      return nil
    }
    let selector = NSSelectorFromString("divisionRegionKind")
    guard kindClass.responds(to: selector) else { return nil }
    return kindClass.perform(selector)?.takeUnretainedValue()
  }

  // UIKit tracks the regions read here and runs this again when they change.
  override class var requiresConstraintBasedLayout: Bool { true }

  var onChange: (([[String: AnyHashable]]) -> Void)?
  private var lastRegions: [[String: AnyHashable]] = []

  override init(frame: CGRect) {
    super.init(frame: frame)
    isUserInteractionEnabled = false
    alpha = 0
    autoresizingMask = [.flexibleWidth, .flexibleHeight]
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    reportIfChanged()
  }

  override func updateConstraints() {
    reportIfChanged()
    super.updateConstraints()
  }

  override func didMoveToWindow() {
    super.didMoveToWindow()
    reportIfChanged()
  }

  func resend() {
    lastRegions = currentRegions()
    if !lastRegions.isEmpty {
      onChange?(lastRegions)
    }
  }

  private func currentRegions() -> [[String: AnyHashable]] {
    guard let kind = Self.divisionKind, responds(to: Self.querySelector) else { return [] }
    let query = unsafeBitCast(method(for: Self.querySelector), to: Query.self)
    let regions = query(self, Self.querySelector, kind, Self.includeInactive)
      .takeUnretainedValue() as? [NSObject] ?? []
    return regions.compactMap { region in
      guard let frame = (region.value(forKey: "frame") as? NSValue)?.cgRectValue,
        frame.width > 0 || frame.height > 0
      else {
        return nil
      }
      return [
        "left": Double(frame.minX),
        "top": Double(frame.minY),
        "width": Double(frame.width),
        "height": Double(frame.height),
        "active": (region.value(forKey: "active") as? NSNumber)?.boolValue ?? true,
      ]
    }
  }

  private func reportIfChanged() {
    guard window != nil else { return }
    let regions = currentRegions()
    guard regions != lastRegions else { return }
    lastRegions = regions
    onChange?(regions)
  }
}

