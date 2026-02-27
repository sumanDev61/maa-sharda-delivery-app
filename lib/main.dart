import 'package:flutter/material.dart';

import 'app/rider_app.dart';
import 'core/api/api_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient().init();
  runApp(const RiderApp());
}
