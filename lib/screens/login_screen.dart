import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/brand.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = AuthService();
  bool _register = false;
  bool _loading = false;
  bool _hidden = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      if (_register) {
        final response = await _auth.signUp(
          name: _name.text,
          email: _email.text,
          password: _password.text,
        );
        if (!mounted) return;
        if (response.session == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Conta criada. Verifique seu e-mail para confirmar o cadastro.'),
            ),
          );
        }
      } else {
        await _auth.signIn(_email.text, _password.text);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendly(error))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendly(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('invalid login')) return 'E-mail ou senha inválidos.';
    if (text.contains('already registered')) return 'Este e-mail já possui cadastro.';
    if (text.contains('password')) return 'A senha precisa ter pelo menos 6 caracteres.';
    return 'Não foi possível concluir. Verifique os dados e tente novamente.';
  }

  Future<void> _forgot() async {
    if (_email.text.trim().isEmpty || !_email.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe seu e-mail primeiro.')),
      );
      return;
    }
    try {
      await _auth.resetPassword(_email.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enviamos as instruções de recuperação para seu e-mail.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível enviar a recuperação agora.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 470),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: AgroWordmark(height: 82)),
                        const SizedBox(height: 20),
                        Text(
                          _register ? 'Crie sua conta' : 'Bem-vindo de volta',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _register
                              ? 'Um acesso para gerenciar uma ou várias fazendas.'
                              : 'Entre para acessar suas fazendas e o BI do rebanho.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.muted),
                        ),
                        const SizedBox(height: 24),
                        if (_register) ...[
                          TextFormField(
                            key: const Key('nameField'),
                            controller: _name,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Nome completo',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (v) => v == null || v.trim().length < 2 ? 'Informe seu nome.' : null,
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextFormField(
                          key: const Key('emailField'),
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'E-mail',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (v) => v == null || !v.contains('@') ? 'Informe um e-mail válido.' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          key: const Key('passwordField'),
                          controller: _password,
                          obscureText: _hidden,
                          autofillHints: const [AutofillHints.password],
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              key: const Key('togglePassword'),
                              onPressed: () => setState(() => _hidden = !_hidden),
                              icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            ),
                          ),
                          validator: (v) => v == null || v.length < 6 ? 'Use pelo menos 6 caracteres.' : null,
                        ),
                        if (!_register)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              key: const Key('forgotButton'),
                              onPressed: _loading ? null : _forgot,
                              child: const Text('Esqueci minha senha'),
                            ),
                          )
                        else
                          const SizedBox(height: 18),
                        FilledButton(
                          key: const Key('authSubmitButton'),
                          onPressed: _loading ? null : _submit,
                          child: Text(_loading ? 'Aguarde...' : (_register ? 'Criar conta' : 'Entrar')),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          key: const Key('switchAuthModeButton'),
                          onPressed: _loading
                              ? null
                              : () => setState(() => _register = !_register),
                          child: Text(_register ? 'Já tenho uma conta' : 'Criar nova conta'),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'AgroControl • dados seguros por fazenda',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
