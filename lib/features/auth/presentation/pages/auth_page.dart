import 'package:flutter/material.dart';

import '../../../../core/services/auth_service.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.onAuthenticated});

  final VoidCallback onAuthenticated;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService.instance;
  final Set<String> _selectedWantedPets = <String>{};

  bool _isSignUp = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final success = _isSignUp
        ? await _authService.signUp(
            name: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
            preferences: UserProfile.serializePreferenceSelections(
              _selectedWantedPets.toList(),
            ),
          )
        : await _authService.signIn(
                email: _emailController.text,
                password: _passwordController.text,
              ) !=
              null;

    if (!mounted) {
      return;
    }

    if (success) {
      widget.onAuthenticated();
    } else {
      setState(() {
        _errorMessage = _isSignUp
            ? 'Já existe uma conta com este e-mail.'
            : 'E-mail ou senha inválidos.';
      });
    }

    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _isSignUp ? 'Criar conta' : 'Entrar',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isSignUp
                          ? 'Cadastre-se para salvar suas preferências e acompanhar adoções.'
                          : 'Entre na sua conta para continuar.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    if (_isSignUp)
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Nome'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Informe seu nome'
                            : null,
                      ),
                    if (_isSignUp) const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'E-mail'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe seu e-mail';
                        }
                        if (!value.contains('@')) {
                          return 'E-mail inválido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Senha'),
                      validator: (value) => value == null || value.length < 6
                          ? 'Use pelo menos 6 caracteres'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    if (_isSignUp) ...[
                      Text(
                        'Que tipo de pet você quer?',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: UserProfile.petPreferenceOptions.map((
                          option,
                        ) {
                          final isSelected = _selectedWantedPets.contains(
                            option,
                          );
                          return FilterChip(
                            label: Text(UserProfile.labelForPreference(option)),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedWantedPets.add(option);
                                } else {
                                  _selectedWantedPets.remove(option);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isSignUp ? 'Criar conta' : 'Entrar'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => setState(() => _isSignUp = !_isSignUp),
                      child: Text(
                        _isSignUp ? 'Já tenho conta' : 'Criar uma conta',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}