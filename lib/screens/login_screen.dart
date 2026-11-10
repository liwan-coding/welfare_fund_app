import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons, CupertinoPageRoute;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import '../design/design.dart';
import '../services/auth_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/common/brand_emblem.dart';
import '../widgets/responsive/responsive_layout.dart';
import '../widgets/web/web_page_wrapper.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _phoneError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _ensureAuthServiceInitialized();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _ensureAuthServiceInitialized() async {
    try {
      await _authService.initialize();
    } catch (_) {
      // Login still works; the provider re-initializes the service on use.
    }
  }

  bool _validate() {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    setState(() {
      _phoneError = phone.isEmpty ? 'required_field'.tr() : null;
      _passwordError = password.isEmpty
          ? 'required_field'.tr()
          : (password.length < 6 ? 'password_too_short'.tr() : null);
    });
    return _phoneError == null && _passwordError == null;
  }

  Future<void> _handleLogin() async {
    if (_isLoading || !_validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.login(
        _phoneController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        AppToast.show(context, 'login_successful'.tr(),
            kind: AppToastKind.success);
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        AppToast.show(context, 'login_failed'.tr(), kind: AppToastKind.error);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppToast.show(context, error.toString(), kind: AppToastKind.error);
    }
  }

  void _openRegister() {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = ResponsiveLayout.getResponsiveInfo(context);
    final useWebHeader = kIsWeb && (info.isDesktop || info.isTablet);

    if (useWebHeader) {
      return WebPageWrapper(
        title: 'login'.tr(),
        showBackButton: true,
        child: _buildForm(),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          AppNavBar(title: 'login'.tr()),
          SliverToBoxAdapter(child: _buildForm()),
        ],
      ),
    );
  }

  Widget _buildForm() {
    final p = AppPalette.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpace.screen,
        AppSpace.screen,
        AppSpace.screen,
        AppSpace.screen + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: BrandEmblem(size: 72)),
          const SizedBox(height: AppSpace.lg),
          const SizedBox(height: AppSpace.sm),
          AppTextField(
            controller: _phoneController,
            label: 'phone_number'.tr(),
            hint: 'phone_number'.tr(),
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            errorText: _phoneError,
            onChanged: (_) {
              if (_phoneError != null) setState(() => _phoneError = null);
            },
          ),
          const SizedBox(height: AppSpace.md),
          AppTextField(
            controller: _passwordController,
            label: 'password'.tr(),
            hint: 'password'.tr(),
            obscureText: !_isPasswordVisible,
            textInputAction: TextInputAction.done,
            errorText: _passwordError,
            onChanged: (_) {
              if (_passwordError != null) setState(() => _passwordError = null);
            },
            onSubmitted: (_) => _handleLogin(),
            suffix: IconButton(
              tooltip: _isPasswordVisible
                  ? 'hide_password'.tr()
                  : 'show_password'.tr(),
              icon: Icon(
                _isPasswordVisible
                    ? CupertinoIcons.eye_slash
                    : CupertinoIcons.eye,
                color: p.secondaryLabel,
                size: 20,
              ),
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() => _isPasswordVisible = !_isPasswordVisible);
              },
            ),
          ),
          const SizedBox(height: AppSpace.xl),
          AppButton(
            label: _isLoading ? 'loading'.tr() : 'login'.tr(),
            loading: _isLoading,
            onPressed: _handleLogin,
          ),
          const SizedBox(height: AppSpace.xs),
          AppButton(
            label: 'create_new_account'.tr(),
            style: AppButtonStyle.plain,
            onPressed: _openRegister,
          ),
        ],
      ),
    );
  }
}
