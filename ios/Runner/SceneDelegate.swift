import Flutter
import UIKit

@available(iOS 13.0, *)
class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    // FlutterSceneDelegate sets up the Flutter window/engine integration.
    super.scene(scene, willConnectTo: session, options: connectionOptions)

    guard
      let appDelegate = UIApplication.shared.delegate as? AppDelegate,
      let controller = window?.rootViewController as? FlutterViewController
    else {
      return
    }

    appDelegate.configureChannelsIfNeeded(controller: controller)
  }

  override func sceneDidBecomeActive(_ scene: UIScene) {
    // Do not call super here: FlutterSceneDelegate does not implement this selector.
    // Calling super caused runtime crash ("unrecognized selector").
    (UIApplication.shared.delegate as? AppDelegate)?.handleSceneDidBecomeActive()
  }
}
