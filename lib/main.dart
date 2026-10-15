import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'services/ads/ads_controller.dart';
import 'services/device_photo_library_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(SiftApp(service: DevicePhotoLibraryService(), ads: AdsController(enabled: true)));
}
