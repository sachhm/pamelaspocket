import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  // The storyboard controller loads before the engine has a shell. On a
  // 120Hz phone that empty task runner crashes release builds at launch.
  // Run the engine first, then give that engine to the view controller.
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScene = scene as? UIWindowScene else {
      return
    }

    let engine = FlutterEngine(name: "pocket")
    engine.run()
    GeneratedPluginRegistrant.register(with: engine)

    let controller = FlutterViewController(engine: engine, nibName: nil, bundle: nil)
    let window = UIWindow(windowScene: windowScene)
    window.rootViewController = controller
    self.window = window
    window.makeKeyAndVisible()

    super.scene(scene, willConnectTo: session, options: connectionOptions)
  }
}
