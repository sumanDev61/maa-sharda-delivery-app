import 'package:flutter/material.dart';

import 'app/rider_app.dart';
import 'core/api/api_client.dart';
import 'core/push/push_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient().init();
  await PushService.initAndSync();
  runApp(const RiderApp());
}
