import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import '../design/design.dart';
import '../providers/auth_provider.dart';

class PhoneOtpVerifyScreen extends StatefulWidget {
  final String verifyId;
  final String phone;
  final String? maskedPhone;
  /// في بيئة التطوير: إذا الباكند أرسل الرمز في الاستجابة (otp / dev_otp / debug_otp) نعرضه هنا للاختبار
  final String? devOtp;

  const PhoneOtpVerifyScreen({
    super.key,
    required this.verifyId,
    required this.phone,
    this.maskedPhone,
    this.devOtp,
  });

  @override
  State<PhoneOtpVerifyScreen> createState() => _PhoneOtpVerifyScreenState();
}

class _PhoneOtpVerifyScreenState extends State<PhoneOtpVerifyScreen> {
  final _otpController = TextEditingController();

  bool _isLoading = false;
  bool _isResending = false;
  String _currentVerifyId = '';
  String? _fetchedDevOtp;
  String? _otpError;

  @override
  void initState() {
    super.initState();
    _currentVerifyId = widget.verifyId;
    // Try to fetch dev OTP whenever backend might return it (local or production support)
    if (widget.devOtp == null || widget.devOtp!.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchDevOtp());
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  /// Masks phone so only last 4 digits show, e.g. ****9633
  static String _maskPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '****';
    if (digits.length <= 4) return '****' + digits;
    return '****' + digits.substring(digits.length - 4);
  }

  /// Always show phone as ****XXXX (last 4 digits only)
  String get _displayPhone => _maskPhone(widget.phone);

  Future<void> _fetchDevOtp() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final otp = await authProvider.getDevOtp(_currentVerifyId);
      if (mounted && otp != null && otp.isNotEmpty) {
        setState(() => _fetchedDevOtp = otp);
      }
    } catch (_) {
      // Dev hint is optional; ignore failures.
    }
  }

  String? get _effectiveDevOtp => _fetchedDevOtp ?? widget.devOtp;

  Widget _buildDevOtpHint() {
    final p = AppPalette.of(context);
    final code = _effectiveDevOtp;
    final hasDevOtp = code != null && code.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: p.fill,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.hammer, size: 16, color: p.secondaryLabel),
              const SizedBox(width: AppSpace.xs),
              Text(
                'otp_dev_mode'.tr(),
                style: AppType.footnote.copyWith(
                  color: p.secondaryLabel,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          if (hasDevOtp) ...[
            Text(
              'otp_dev_code_label'.tr(),
              style: AppType.footnote.copyWith(color: p.secondaryLabel),
            ),
            const SizedBox(height: AppSpace.xs),
            Row(
              children: [
                Text(
                  code,
                  style: AppType.title3.copyWith(
                    color: p.label,
                    letterSpacing: 4,
                  ),
                ),
                const Spacer(),
                AppButton(
                  label: 'otp_use_this_code'.tr(),
                  style: AppButtonStyle.tinted,
                  expand: false,
                  onPressed: () {
                    _otpController.text = code;
                    setState(() => _otpError = null);
                  },
                ),
              ],
            ),
          ] else
            Text(
              'otp_dev_check_logs'.tr(),
              style: AppType.footnote.copyWith(color: p.secondaryLabel),
            ),
        ],
      ),
    );
  }

  String _errorMessage(Object e) {
    final message = e.toString().replaceFirst('Exception: ', '').trim();
    return message.contains(' ') ? message : message.tr();
  }

  Future<void> _handleVerify() async {
    if (_isLoading) return;
    final code = _otpController.text.trim();
    if (code.length != 6) {
      setState(() => _otpError = 'otp_must_be_6_digits'.tr());
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.verifyPhoneOtp(_currentVerifyId, code);
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        AppToast.show(context, 'phone_verified_successfully'.tr(),
            kind: AppToastKind.success);
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        AppToast.show(context, 'invalid_verification_code'.tr(),
            kind: AppToastKind.error);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppToast.show(context, _errorMessage(e), kind: AppToastKind.error);
    }
  }

  Future<void> _handleResend() async {
    if (_isResending) return;
    setState(() => _isResending = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final result = await authProvider.resendOtp(widget.phone);
      if (!mounted) return;
      setState(() {
        _isResending = false;
        _currentVerifyId = result['verifyId'] as String;
      });
      AppToast.show(context, 'otp_resent'.tr(), kind: AppToastKind.success);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isResending = false);
      AppToast.show(context, _errorMessage(e), kind: AppToastKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final hasDevOtp =
        _effectiveDevOtp != null && _effectiveDevOtp!.isNotEmpty;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          AppNavBar(title: 'verify_phone'.tr()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.screen),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'otp_enter_code'.tr(),
                    style: AppType.title2.copyWith(color: p.label),
                  ),
                  const SizedBox(height: AppSpace.xxs),
                  Text(
                    'otp_sent_to'.tr().replaceAll(
                          '{0}',
                          // LTR isolate keeps the number as ****9633 in RTL.
                          '⁨$_displayPhone⁩',
                        ),
                    style: AppType.subheadline.copyWith(color: p.secondaryLabel),
                  ),
                  if (hasDevOtp) ...[
                    const SizedBox(height: AppSpace.md),
                    _buildDevOtpHint(),
                  ],
                  const SizedBox(height: AppSpace.xl),
                  AppTextField(
                    controller: _otpController,
                    hint: '••••••',
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    errorText: _otpError,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    onChanged: (_) {
                      if (_otpError != null) setState(() => _otpError = null);
                    },
                    onSubmitted: (_) => _handleVerify(),
                  ),
                  const SizedBox(height: AppSpace.xl),
                  AppButton(
                    label: 'verify'.tr(),
                    loading: _isLoading,
                    onPressed: _handleVerify,
                  ),
                  const SizedBox(height: AppSpace.lg),
                  Text(
                    'otp_didnt_receive'.tr(),
                    textAlign: TextAlign.center,
                    style: AppType.footnote.copyWith(color: p.secondaryLabel),
                  ),
                  AppButton(
                    label: 'resend_code'.tr(),
                    style: AppButtonStyle.plain,
                    loading: _isResending,
                    onPressed: _handleResend,
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
