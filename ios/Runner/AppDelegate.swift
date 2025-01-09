import UIKit
import Firebase
import UserNotifications
import Flutter
import flutter_background_service_ios
import AVFoundation
import CoreLocation
import SocketIO

@main
@objc class AppDelegate: FlutterAppDelegate, MessagingDelegate, CLLocationManagerDelegate {

    private let channel = "com.yourapp/fcm"
    private var foregroundNotificationOptions: UNNotificationPresentationOptions = []
    private let speechSynthesizer = AVSpeechSynthesizer()

    // Class-level variable to track notification call count
    private static var notificationCount = 0
    private static var resetTimer: Timer?

    // Configure the Socket.IO manager
    let socketManager = SocketManager(socketURL: URL(string: "https://yoururl.com")!, config: [.log(true), .connectParams([:]), .forceWebsockets(true)])
    private var locationManager: CLLocationManager?
    private var socket: SocketIOClient?  // Socket.IO client

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Error setting up audio session: \(error)")
        }

        // Configure Firebase
        FirebaseApp.configure()

        // Background service setup
        SwiftFlutterBackgroundServicePlugin.taskIdentifier = "dev.flutter.background.refresh"

        // Request Notification Permission
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
        }

        // Set the delegate for UNUserNotificationCenter and Firebase Messaging
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        // Configure Flutter Method Channel
        configureFlutterEngine()

        // Handle app launch from notification
        if let userInfo = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            handleRemoteNotification(userInfo)
        }

        // Start socket connection (using Socket.IO)
        startSocketConnection()


        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // Start Socket.IO connection
    func startSocketConnection() {

        socket = socketManager.defaultSocket

        // Set up event listeners
        socket?.on(clientEvent: .connect) {data, ack in
            print("Socket connected")
        }

        socket?.on(clientEvent: .disconnect) {data, ack in
            print("Socket disconnected")
        }

        socket?.on("someEvent") {data, ack in
            print("Received from server: \(data)")
        }
        
        // Listen for errors during the connection
        socket?.on(clientEvent: .error) { data, ack in
            // The error data is usually an array containing the error message or object
            if let errorMessage = data.first as? String {
                print("Socket connection failed with error: \(errorMessage)")
            } else {
                print("Socket connection failed with unknown error")
            }
        }

        // Connect to the server
        socket?.connect()
    }


    // Handle remote notification registration (Background)
    override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    // Handle receiving remote notification (Foreground)
    override func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        handleRemoteNotification(userInfo)
        completionHandler(.newData)
    }

    // Method to handle received remote notification
    func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) {

        // If notification count is not zero, return immediately
        if Self.notificationCount > 0 {
            return
        }

        // Set a timer to reset count after 2 seconds
        if let existingTimer = Self.resetTimer {
            existingTimer.invalidate() // Cancel the previous timer if the method was called again within 2 seconds
        }

        Self.resetTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
            Self.notificationCount = 0  // Reset the count after 2 seconds
        }

        // Extract notification data from userInfo (FCM payload)
        // Directly handle the notification title and body using UNNotification
        guard let aps = userInfo["aps"] as? [String: AnyObject],
              let alert = aps["alert"] as? [String: AnyObject] else {
            return
        }

        // Retrieve the title and body directly from the notification alert payload
        let title = alert["title"] as? String ?? ""
        let body = alert["body"] as? String ?? ""

        // Speak the notification title using Text-to-Speech
        speakNotificationTitle(body)

        // Create and show a local notification
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        // Create a notification request
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)

        // Add the request to the notification center
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error showing notification: \(error.localizedDescription)")
            }
        }

        // Send the notification data to Flutter
        guard let flutterViewController = window?.rootViewController as? FlutterViewController else { return }
        let methodChannel = FlutterMethodChannel(name: channel, binaryMessenger: flutterViewController.binaryMessenger)

        methodChannel.invokeMethod("onMessageReceived", arguments: userInfo) { result in
            if let error = result as? FlutterError {
                print("Error sending data to Flutter: \(error.message ?? "")")
            } else {
                print("Notification data sent to Flutter successfully.")
            }
        }

        // Increment notification count
        Self.notificationCount += 1
    }

    // Handle notification when the app is opened (foreground or tapped)
    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Apply the configured options for foreground notifications
        completionHandler(foregroundNotificationOptions)
    }

    // Function to speak the notification title
    func speakNotificationTitle(_ title: String) {
        let utterance = AVSpeechUtterance(string: title)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5 // Adjust the speaking rate if needed
        speechSynthesizer.speak(utterance)
    }

    // Configure MethodChannel
    func configureFlutterEngine() {
        guard let flutterViewController = window?.rootViewController as? FlutterViewController else { return }

        let methodChannel = FlutterMethodChannel(name: channel, binaryMessenger: flutterViewController.binaryMessenger)
        methodChannel.setMethodCallHandler { [weak self] (call, result) in
            switch call.method {
            case "initializeFCM":
                // Perform FCM initialization or any other setup
                result(nil)

            case "getToken":
                // Get the FCM token and return it to Flutter
                Messaging.messaging().token { token, error in
                    if let error = error {
                        result(FlutterError(code: "UNAVAILABLE", message: "FCM token not available", details: error.localizedDescription))
                    } else if let token = token {
                        result(token)
                    }
                }

            case "onMessageReceived":
                // Handle the message received
                result(nil)

            case "setForegroundNotificationPresentationOptions":
                // Set the foreground notification presentation options
                if let options = call.arguments as? [String] {
                    self?.setForegroundNotificationOptions(options)
                }
                result(nil)

            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    // Set the foreground notification options (defaults to banner, sound, badge)
    func setForegroundNotificationOptions(_ options: [String]) {
        var presentationOptions: UNNotificationPresentationOptions = []

        if options.contains("banner") {
            presentationOptions.insert(.banner)
        }
        if options.contains("sound") {
            presentationOptions.insert(.sound)
        }
        if options.contains("badge") {
            presentationOptions.insert(.badge)
        }

        self.foregroundNotificationOptions = presentationOptions
    }
}
