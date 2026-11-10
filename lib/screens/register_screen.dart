import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons, CupertinoPageRoute, CupertinoSwitch;
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:provider/provider.dart';
import '../design/design.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'phone_otp_verify_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _acceptedTerms = true;

  /// Inline validation messages keyed by field.
  final Map<String, String?> _errors = {};

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _clearError(String key) {
    if (_errors[key] != null) setState(() => _errors[key] = null);
  }

  bool _validate() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    final digits = phone.replaceAll(RegExp(r'\D'), '');

    final errors = <String, String?>{
      'name': name.length < 2 ? 'required_field'.tr() : null,
      'phone': phone.isEmpty
          ? 'required_field'.tr()
          : (digits.length < 8
              ? 'phone_must_be_between_8_and_15_digits'.tr()
              : null),
      'email': email.isNotEmpty &&
              !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)
          ? 'invalid_email'.tr()
          : null,
      'password': password.isEmpty
          ? 'required_field'.tr()
          : (password.length < 6 ? 'password_too_short'.tr() : null),
      'confirm': confirm.isEmpty
          ? 'required_field'.tr()
          : (confirm != password ? 'passwords_do_not_match'.tr() : null),
    };
    setState(() => _errors
      ..clear()
      ..addAll(errors));
    return errors.values.every((e) => e == null);
  }

  Future<void> _handleRegister() async {
    if (_isLoading) return;
    if (!_acceptedTerms) {
      AppToast.show(context, 'required_field'.tr(), kind: AppToastKind.error);
      return;
    }
    if (!_validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final result = await authProvider.registerWithPhone(
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
        name: _nameController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _isLoading = false);

      AppToast.show(context, 'otp_resent'.tr(), kind: AppToastKind.success);
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => PhoneOtpVerifyScreen(
            verifyId: result['verifyId'] as String,
            phone: _phoneController.text.trim(),
            maskedPhone: result['phone'] as String?,
            devOtp: result['devOtp'] as String?,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppToast.show(context, error.toString(), kind: AppToastKind.error);
    }
  }

  Widget _visibilityToggle(bool visible, VoidCallback onToggle) {
    final p = AppPalette.of(context);
    return IconButton(
      tooltip: visible ? 'hide_password'.tr() : 'show_password'.tr(),
      icon: Icon(
        visible ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
        color: p.secondaryLabel,
        size: 20,
      ),
      onPressed: () {
        HapticFeedback.selectionClick();
        onToggle();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          AppNavBar(title: 'create_new_account'.tr()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.screen),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpace.sm),
                  AppTextField(
                    controller: _nameController,
                    label: 'full_name'.tr(),
                    hint: 'full_name'.tr(),
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                    errorText: _errors['name'],
                    onChanged: (_) => _clearError('name'),
                  ),
                  const SizedBox(height: AppSpace.md),
                  AppTextField(
                    controller: _phoneController,
                    label: 'phone_number'.tr(),
                    hint: 'phone_number'.tr(),
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    errorText: _errors['phone'],
                    onChanged: (_) => _clearError('phone'),
                  ),
                  const SizedBox(height: AppSpace.md),
                  AppTextField(
                    controller: _emailController,
                    label: 'email'.tr(),
                    hint: 'email'.tr(),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    errorText: _errors['email'],
                    onChanged: (_) => _clearError('email'),
                  ),
                  const SizedBox(height: AppSpace.md),
                  AppTextField(
                    controller: _passwordController,
                    label: 'password'.tr(),
                    hint: 'password'.tr(),
                    obscureText: !_isPasswordVisible,
                    textInputAction: TextInputAction.next,
                    errorText: _errors['password'],
                    onChanged: (_) => _clearError('password'),
                    suffix: _visibilityToggle(
                      _isPasswordVisible,
                      () => setState(
                          () => _isPasswordVisible = !_isPasswordVisible),
                    ),
                  ),
                  const SizedBox(height: AppSpace.md),
                  AppTextField(
                    controller: _confirmPasswordController,
                    label: 'confirm_password'.tr(),
                    hint: 'confirm_password'.tr(),
                    obscureText: !_isConfirmPasswordVisible,
                    textInputAction: TextInputAction.done,
                    errorText: _errors['confirm'],
                    onChanged: (_) => _clearError('confirm'),
                    onSubmitted: (_) => _handleRegister(),
                    suffix: _visibilityToggle(
                      _isConfirmPasswordVisible,
                      () => setState(() =>
                          _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                    ),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.md,
                      vertical: AppSpace.xs,
                    ),
                    decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'terms_conditions'.tr(),
                            style: AppType.footnote.copyWith(color: p.label),
                          ),
                        ),
                        const SizedBox(width: AppSpace.sm),
                        CupertinoSwitch(
                          value: _acceptedTerms,
                          activeTrackColor: p.tint,
                          onChanged: (v) => setState(() => _acceptedTerms = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.xl),
                  AppButton(
                    label: _isLoading ? 'loading'.tr() : 'create_new_account'.tr(),
                    loading: _isLoading,
                    onPressed: _handleRegister,
                  ),
                  const SizedBox(height: AppSpace.xs),
                  AppButton(
                    label: 'already_have_account'.tr(),
                    style: AppButtonStyle.plain,
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      CupertinoPageRoute(
                          builder: (context) => const LoginScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
