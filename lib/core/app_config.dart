class AppConfig {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://bsbfjvwvdaisnoxvfrqx.supabase.co',
  );

  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_6g2BPDA9bnDAGubJmiy10g_QWZ4CQXQ',
  );

  static const storageBucket = 'animal-media';
}
