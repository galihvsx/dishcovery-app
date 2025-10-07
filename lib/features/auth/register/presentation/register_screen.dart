import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:dishcovery_app/core/widgets/app_logo.dart';
import 'package:dishcovery_app/providers/auth_provider.dart';
import 'package:dishcovery_app/utils/routes/app_routes.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('register.validation.termsRequired'.tr()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();

    try {
      final success = await authProvider.registerWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );

      if (success && mounted) {
        // Show success message and navigate to main screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('register.success'.tr()),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        Navigator.of(context).pushReplacementNamed(AppRoutes.main);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    debugPrint('🎯 RegisterScreen: Google Sign-In button pressed');
    final authProvider = context.read<AuthProvider>();
    debugPrint(
      '🎯 RegisterScreen: AuthProvider obtained, current loading state: ${authProvider.isLoading}',
    );
    debugPrint(
      '🎯 RegisterScreen: AuthProvider current user: ${authProvider.user?.email ?? 'null'}',
    );

    try {
      debugPrint('🎯 RegisterScreen: Calling authProvider.signInWithGoogle()');
      final success = await authProvider.signInWithGoogle();
      debugPrint(
        '🎯 RegisterScreen: authProvider.signInWithGoogle() returned: $success',
      );

      if (success && mounted) {
        debugPrint(
          '✅ RegisterScreen: Sign-in successful, navigating to main screen',
        );
        Navigator.of(context).pushReplacementNamed(AppRoutes.main);
      } else if (!success) {
        debugPrint('❌ RegisterScreen: Sign-in failed (success = false)');
      } else if (!mounted) {
        debugPrint(
          '⚠️ RegisterScreen: Widget not mounted, skipping navigation',
        );
      }
    } catch (e) {
      debugPrint('❌ RegisterScreen: Exception caught during Google Sign-In');
      debugPrint('❌ RegisterScreen: Exception type: ${e.runtimeType}');
      debugPrint('❌ RegisterScreen: Exception message: ${e.toString()}');
      debugPrint(
        '❌ RegisterScreen: Is cancellation error: ${e.toString().contains('cancelled')}',
      );
      debugPrint('❌ RegisterScreen: Widget mounted: $mounted');

      if (mounted && !e.toString().contains('cancelled')) {
        debugPrint('🎯 RegisterScreen: Showing error SnackBar to user');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      } else if (e.toString().contains('cancelled')) {
        debugPrint(
          '🎯 RegisterScreen: User cancelled sign-in, not showing error message',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo and Title
                const Center(child: AppLogo(size: 60)),
                const SizedBox(height: 24),

                Text(
                  'register.title'.tr(),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'register.subtitle'.tr(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Name Field
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'register.fullName'.tr(),
                    hintText: 'register.fullNameHint'.tr(),
                    prefixIcon: Icon(
                      Icons.person_outlined,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'register.validation.nameRequired'.tr();
                    }
                    if (value.trim().length < 2) {
                      return 'register.validation.nameMinLength'.tr();
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'register.email'.tr(),
                    hintText: 'register.emailHint'.tr(),
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'register.validation.emailRequired'.tr();
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'register.validation.emailInvalid'.tr();
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'register.password'.tr(),
                    hintText: 'register.passwordHint'.tr(),
                    prefixIcon: Icon(
                      Icons.lock_outlined,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'register.validation.passwordRequired'.tr();
                    }
                    if (value.length < 6) {
                      return 'register.validation.passwordMinLength'.tr();
                    }
                    if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)').hasMatch(value)) {
                      return 'register.validation.passwordFormat'.tr();
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Confirm Password Field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'register.confirmPassword'.tr(),
                    hintText: 'register.confirmPasswordHint'.tr(),
                    prefixIcon: Icon(
                      Icons.lock_outlined,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'register.validation.confirmPasswordRequired'.tr();
                    }
                    if (value != _passwordController.text) {
                      return 'register.validation.passwordMismatch'.tr();
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _handleRegister(),
                ),

                const SizedBox(height: 16),

                // Terms and Conditions
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _acceptTerms,
                      onChanged: (value) {
                        setState(() {
                          _acceptTerms = value ?? false;
                        });
                      },
                      activeColor: colorScheme.primary,
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _acceptTerms = !_acceptTerms;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: RichText(
                            text: TextSpan(
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              children: [
                                TextSpan(text: 'register.termsPrefix'.tr()),
                                TextSpan(
                                  text: 'register.termsOfService'.tr(),
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(text: 'register.termsAnd'.tr()),
                                TextSpan(
                                  text: 'register.privacyPolicy'.tr(),
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Register Button
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return FilledButton(
                      onPressed: authProvider.isLoading
                          ? null
                          : _handleRegister,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: authProvider.isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : Text(
                              'register.signUpButton'.tr(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: colorScheme.outlineVariant)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'register.orSignUpWith'.tr(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: colorScheme.outlineVariant)),
                  ],
                ),

                const SizedBox(height: 24),

                // Google Sign-In Button
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return SizedBox(
                      height: 48,
                      child: authProvider.isLoading
                          ? Container(
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: colorScheme.outlineVariant,
                                ),
                              ),
                              child: Center(
                                child: SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            )
                          : SignInButton(
                              Buttons.google,
                              onPressed: _handleGoogleSignIn,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Sign In Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'register.alreadyHaveAccount'.tr(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'register.login'.tr(),
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
