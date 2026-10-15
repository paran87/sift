import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/app.dart';
import 'package:flutter_application_1/services/mock_photo_library_service.dart';

void main() {
  testWidgets('splash shows brand and moves to onboarding', (tester) async {
    await tester.pumpWidget(SiftApp(service: MockPhotoLibraryService(latency: Duration.zero)));
    expect(find.text('Sift'), findsOneWidget);

    // Onboarding has looping animations, so step frames instead of settling.
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Get Started'), findsOneWidget);
  });
}
