import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:async';

/// This class provides dummy implementations for plugins that aren't
/// fully supported on macOS yet.
class PlatformChannelFixes {
  // Create a dummy controller for the uni_links stream
  static final StreamController<Uri?> _uniLinksStreamController =
      StreamController<Uri?>.broadcast();

  // Make the stream available for subscription
  static Stream<Uri?> get uniLinksStream => _uniLinksStreamController.stream;

  /// Initialize dummy implementations for missing plugins on macOS
  static void init() {
    if (Platform.isMacOS) {
      print("Setting up platform channel fixes for macOS");

      // Handle uni_links messages channel
      const MethodChannel uniLinksChannel = MethodChannel('uni_links/messages');
      uniLinksChannel.setMethodCallHandler((MethodCall call) async {
        print("Handling uni_links method call: ${call.method}");
        if (call.method == 'getInitialLink') {
          print("Returning null for getInitialLink on macOS");
          return null;
        }
        return null;
      });

      // Handle uni_links events channel
      const EventChannel uniLinksEventChannel = EventChannel(
        'uni_links/events',
      );

      // Set up a message handler for the uni_links events channel
      ServicesBinding.instance.defaultBinaryMessenger.setMessageHandler(
        uniLinksEventChannel.name,
        (ByteData? message) async {
          print("Handling uni_links event channel message");
          return null; // Return null to indicate successful setup
        },
      );
    }
  }

  /// Manually trigger a deep link in the stream (for testing on macOS)
  static void triggerDeepLink(String url) {
    if (Platform.isMacOS) {
      _uniLinksStreamController.add(Uri.parse(url));
    }
  }

  /// Clean up resources
  static void dispose() {
    if (Platform.isMacOS) {
      _uniLinksStreamController.close();
    }
  }
}
