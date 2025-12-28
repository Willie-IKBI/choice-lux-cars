/// Central place for environment flags.
/// Keep secrets in runtime config (Firebase/Vercel/etc) — not in git.
class Env {
  static const bool isProd = bool.fromEnvironment('PROD', defaultValue: false);
}
