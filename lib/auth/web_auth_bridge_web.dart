import 'dart:js_interop';
import 'package:web/web.dart' as web;

void listenForWebGoogleToken(void Function(String idToken) onToken) {
  web.window.addEventListener(
    'speecheasy_google_token',
    ((web.CustomEvent event) {
      final token = (event.detail as JSString?)?.toDart;
      if (token != null && token.isNotEmpty) {
        onToken(token);
      }
    }).toJS,
  );
}
