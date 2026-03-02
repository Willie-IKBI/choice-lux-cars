/// Web implementation: reads Supabase config from window.__SUPABASE_CONFIG__
/// (injected at build time by inject-firebase-config.js when dart-define fails).

import 'dart:js' as js;

(String? url, String? anonKey) getSupabaseRuntimeConfig() {
  try {
    final c = js.context['__SUPABASE_CONFIG__'];
    if (c != null) {
      final obj = c as js.JsObject;
      final url = obj['url']?.toString();
      final anonKey = obj['anonKey']?.toString();
      if (url != null && url.isNotEmpty && anonKey != null && anonKey.isNotEmpty) {
        return (url, anonKey);
      }
    }
  } catch (_) {}
  return (null, null);
}
