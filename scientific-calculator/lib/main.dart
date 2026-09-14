import 'package:flutter/material.dart';

import 'app.dart';
import 'services/settings_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await SettingsController.create();
  runApp(CalculatorApp(settings: settings));
}
