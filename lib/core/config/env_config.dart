class EnvConfig {
  EnvConfig._();

  /// Default Supabase URL (Can be overridden via --dart-define=SUPABASE_URL=...)
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://placeholder.supabase.co',
  );

  /// Default Supabase Anon Key (Can be overridden via --dart-define=SUPABASE_ANON_KEY=...)
  /// NEVER place service-role key or private secrets in client code.
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'placeholder_anon_key',
  );

  /// Feature Flag: Phone OTP Auth (requires Twilio or SMS provider in Supabase)
  static const bool enablePhoneOtp = bool.fromEnvironment(
    'ENABLE_PHONE_OTP',
    defaultValue: true,
  );

  /// Feature Flag: Location tracking for exposure places
  static const bool enableLocationTracking = bool.fromEnvironment(
    'ENABLE_LOCATION',
    defaultValue: true,
  );

  /// Default Demo Mode toggle flag
  static const bool defaultDemoMode = bool.fromEnvironment(
    'DEMO_MODE',
    defaultValue: true,
  );
}
