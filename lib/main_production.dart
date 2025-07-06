import 'package:flutter/material.dart';
import 'package:utmmart/core/depandancy_injection/service_locator.dart';
import 'package:utmmart/core/utils/service_locator/service_locator.dart';
import 'package:utmmart/t_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupServiceLocator();
  setupOldServiceLocator();

  runApp(const TStore());
}
