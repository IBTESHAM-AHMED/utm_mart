import 'package:flutter/material.dart';
import 'package:utmmart/core/depandancy_injection/service_locator.dart';
import 'package:utmmart/core/utils/service_locator/service_locator.dart';
import 'package:utmmart/core/services/firebase_service.dart';
import 'package:utmmart/t_store.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:utmmart/firebase_options.dart'; // Add this import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase first
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Setup dependency injection
  await setupServiceLocator();
  setupOldServiceLocator(); // Note: No await here since it's synchronous

  // Initialize Firebase services
  await sl<FirebaseService>().initialize();

  runApp(const TStore());
}
