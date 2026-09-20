import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import 'farm_gate.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    return StreamBuilder<AuthState>(
      stream: auth.changes,
      builder: (context, snapshot) {
        final signedIn = Supabase.instance.client.auth.currentSession != null;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: signedIn ? const FarmGate() : const LoginScreen(),
        );
      },
    );
  }
}
