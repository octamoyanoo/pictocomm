import 'package:flutter/material.dart';
import 'package:pictocomm/l10n/app_localizations.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_theme.dart';

final class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

final class _SignUpScreenState extends State<SignUpScreen> {
  static final RegExp _emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) {
      return l10n.passwordRequired;
    }
    if (value.length < 8) {
      return l10n.passwordTooShort;
    }
    return null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.childSelector, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _LogoSection(),
                            const SizedBox(height: 32),
                            _FieldLabel(l10n.nameLabel),
                            TextFormField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              autofillHints: const [AutofillHints.name],
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(hintText: l10n.nameExampleHint),
                              key: const Key('signup_name'),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return l10n.nameRequired;
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                            ),
                            const SizedBox(height: 16),
                            _FieldLabel(l10n.emailLabel),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(hintText: l10n.emailHint),
                              key: const Key('signup_email'),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return l10n.emailRequired;
                                }
                                if (!_emailRegExp.hasMatch(value.trim())) {
                                  return l10n.emailInvalid;
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                            ),
                            const SizedBox(height: 16),
                            _FieldLabel(l10n.passwordLabel),
                            TextFormField(
                              controller: _passwordController,
                              keyboardType: TextInputType.visiblePassword,
                              autofillHints: const [AutofillHints.newPassword],
                              textInputAction: TextInputAction.next,
                              key: const Key('signup_password'),
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                hintText: l10n.passwordHint,
                                suffixIcon: IconButton(
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                              validator: (value) => _validatePassword(value, l10n),
                              onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                            ),
                            const SizedBox(height: 16),
                            _FieldLabel(l10n.confirmPasswordLabel),
                            TextFormField(
                              controller: _confirmController,
                              keyboardType: TextInputType.visiblePassword,
                              autofillHints: const [AutofillHints.newPassword],
                              key: const Key('signup_confirm_password'),
                              obscureText: _obscureConfirmPassword,
                              decoration: InputDecoration(
                                hintText: l10n.passwordHint,
                                suffixIcon: IconButton(
                                  onPressed:
                                      () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                final passwordError = _validatePassword(value, l10n);
                                if (passwordError != null) {
                                  return passwordError;
                                }
                                if (value != _passwordController.text) {
                                  return l10n.passwordsMismatch;
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) => _submit(),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(onPressed: _submit, child: Text(l10n.createAccountButton)),
                            const SizedBox(height: 24),
                            const Divider(color: AppColors.surfaceSecondary, thickness: 1),
                            const SizedBox(height: 16),
                            const _LoginLink(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

final class _LogoSection extends StatelessWidget {
  const _LogoSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.auto_awesome, color: AppColors.surface, size: 40),
        ),
        const SizedBox(height: 12),
        const Text('PictoComm', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        Text(
          AppLocalizations.of(context)!.signupTagline,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

final class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
      ),
    );
  }
}

final class _LoginLink extends StatelessWidget {
  const _LoginLink();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      },
      behavior: HitTestBehavior.opaque,
      child: Text.rich(
        TextSpan(
          text: l10n.haveAccount,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          children: [
            TextSpan(
              text: l10n.loginLinkHere,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.accent),
            ),
          ],
        ),
        textAlign: TextAlign.center,
        key: const Key('signup_login_link'),
      ),
    );
  }
}
