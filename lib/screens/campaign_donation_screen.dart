import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons, CupertinoPageRoute;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import '../design/design.dart';

import '../models/campaign.dart';
import '../providers/auth_provider.dart';
import '../providers/payment_provider.dart';
import 'payment_webview.dart';
import 'donation_success_screen.dart';
import 'payment_failed_screen.dart';

class CampaignDonationScreen extends StatefulWidget {
  final Campaign campaign;

  const CampaignDonationScreen({
    super.key,
    required this.campaign,
  });

  @override
  State<CampaignDonationScreen> createState() => _CampaignDonationScreenState();
}

class _CampaignPaymentResult {
  final PaymentState? state;
  final double? amount;
  final String? campaignTitle;
  final String? donationId;
  final String? sessionId;

  const _CampaignPaymentResult({
    this.state,
    this.amount,
    this.campaignTitle,
    this.donationId,
    this.sessionId,
  });

  factory _CampaignPaymentResult.fromNavigatorResult(dynamic result) {
    if (result is Map) {
      final map = Map<String, dynamic>.from(result);
      return _CampaignPaymentResult(
        state: _parseState(map['state']),
        amount: _parseAmount(map['amount']),
        campaignTitle: _asString(map['campaignTitle']) ?? _asString(map['campaign_title']),
        donationId: _asString(map['donationId']) ?? _asString(map['donation_id']),
        sessionId: _asString(map['sessionId']) ?? _asString(map['session_id']),
      );
    }

    if (result is PaymentState) {
      return _CampaignPaymentResult(state: result);
    }

    return const _CampaignPaymentResult();
  }

  static PaymentState? _parseState(dynamic value) {
    if (value is PaymentState) return value;
    if (value is String) {
      for (final state in PaymentState.values) {
        if (state.name == value) return state;
      }
    }
    return null;
  }

  static double? _parseAmount(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      final normalized = value.replaceAll(RegExp(r'[^0-9\.\-]'), '');
      return double.tryParse(normalized);
    }
    return null;
  }

  static String? _asString(dynamic value) {
    return value?.toString();
  }
}
class _CampaignDonationScreenState extends State<CampaignDonationScreen> {
  double _selectedAmount = 0;
  final List<double> _quickAmounts = [50, 100, 200, 500, 1000];
  final TextEditingController _customAmountController = TextEditingController();
  final TextEditingController _donorPhoneController = TextEditingController();

  @override
  void dispose() {
    _customAmountController.dispose();
    _donorPhoneController.dispose();
    super.dispose();
  }

  void _selectAmount(double amount) {
    setState(() {
      _selectedAmount = amount;
      _customAmountController.clear();
    });
  }

  bool _validateAmount() {
    if (_selectedAmount <= 0) {
      AppToast.show(context, 'please_choose_donation_amount'.tr(), kind: AppToastKind.error);
      return false;
    }
    return true;
  }

  Future<void> _proceedToDonation() async {
    if (kDebugMode) {
      debugPrint('[DONATION_LOG] بداية التبرع: amount=$_selectedAmount, campaignId=${widget.campaign.id}, type=${widget.campaign.type}');
    }
    // Check if campaign is completed
    if (widget.campaign.isCompleted) {
      AppToast.show(context, 'campaign_completed_no_donations'.tr(), kind: AppToastKind.success);
      return;
    }

    if (!_validateAmount()) return;

    final provider = context.read<PaymentProvider>();
    final auth = context.read<AuthProvider>();
    final isLoggedIn = auth.isAuthenticated && auth.userProfile != null;
    String? donorPhone = isLoggedIn
        ? (auth.userProfile!['phone']?.toString() ?? auth.userProfile!['user']?['phone']?.toString())
        : _donorPhoneController.text.trim();

    if (!isLoggedIn) {
      if (donorPhone == null || donorPhone.isEmpty) {
        AppToast.show(context, 'please_enter_donor_phone'.tr(), kind: AppToastKind.error);
        return;
      }
      final cleanPhone = donorPhone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
      if (!RegExp(r'^[0-9]+$').hasMatch(cleanPhone)) {
        AppToast.show(context, 'please_enter_valid_phone'.tr(), kind: AppToastKind.error);
        return;
      }
      if (cleanPhone.length < 8 || cleanPhone.length > 15) {
        AppToast.show(context, 'phone_must_be_between_8_and_15_digits'.tr(), kind: AppToastKind.error);
        return;
      }
    }

    // ابدأ دورة الدفع
    provider.initializePayment(_selectedAmount);

    // استنتاج نوع الهدف (برنامج/حملة) وتحويل المعرف إلى int
    final rawId = widget.campaign.id.toString();
    final parsedId = int.tryParse(rawId);
    int? programId;
    int? campaignId;

    final isProgram = (widget.campaign.type == 'student_program' || widget.campaign.type == 'program');
    if (parsedId != null) {
      if (isProgram) {
        programId = parsedId;
      } else {
        campaignId = parsedId;
      }
    }

    // إنشاء التبرع مع الدفع مباشرة (مع donor_phone للمسجلين)
    if (kDebugMode) {
      debugPrint('[DONATION_LOG] استدعاء initiateDonationWithPayment: programId=$programId, campaignId=$campaignId');
    }
    await provider.initiateDonationWithPayment(
      amount: _selectedAmount,
      donorName: 'generous_donor'.tr(),
      donorPhone: donorPhone,
      message: 'donation_for_campaign'.tr().replaceAll('{title}', widget.campaign.getLocalizedTitle(context.locale.languageCode)),
      programId: programId,
      campaignId: campaignId,
      note: 'donation_message'.tr(),
    );

    if (!mounted) return;

    if (kDebugMode) {
      debugPrint('[DONATION_LOG] بعد initiateDonationWithPayment: state=${provider.state}, paymentUrl=${provider.paymentUrl != null ? "موجود" : "null"}, errorMessage=${provider.displayErrorMessage}');
    }
    if (provider.state == PaymentState.sessionCreated && provider.paymentUrl != null) {
      // افتح الـ WebView داخل التطبيق
      provider.startPayment();

      final result = await Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (_) => PaymentWebView(
            paymentUrl: provider.paymentUrl!,
            sessionId: provider.currentSessionId!,
          ),
        ),
      );

      final paymentResult = _CampaignPaymentResult.fromNavigatorResult(result);
      final PaymentState? resultState = paymentResult.state;

      // التعامل مع نتيجة الـ WebView
      if (resultState == PaymentState.paymentSuccess || provider.isPaymentSuccessful) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(
            builder: (_) => DonationSuccessScreen(
              amount: _selectedAmount,
              campaignTitle: paymentResult.campaignTitle ?? widget.campaign.getLocalizedTitle(context.locale.languageCode),
              campaignCategory: widget.campaign.getLocalizedCategory(context.locale.languageCode),
              donationId: paymentResult.donationId,
              sessionId: paymentResult.sessionId ?? provider.currentSessionId,
            ),
          ),
        );
      } else if (resultState == PaymentState.paymentFailed ||
          resultState == PaymentState.paymentCancelled ||
          resultState == PaymentState.paymentExpired ||
          provider.isPaymentFailed) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(
            builder: (_) => PaymentFailedScreen(
              errorMessage: provider.displayErrorMessage,
              campaignTitle: widget.campaign.getLocalizedTitle(context.locale.languageCode),
              amount: _selectedAmount,
              donationId: provider.currentDonationId,
              sessionId: provider.currentSessionId,
            ),
          ),
        );
      } else if (result != null) {
        await provider.checkPaymentStatus();
        if (provider.isPaymentSuccessful) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            CupertinoPageRoute(
            builder: (_) => DonationSuccessScreen(
              amount: _selectedAmount,
              campaignTitle: widget.campaign.getLocalizedTitle(context.locale.languageCode),
              campaignCategory: widget.campaign.getLocalizedCategory(context.locale.languageCode),
            ),
            ),
          );
        } else if (provider.isPaymentFailed) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            CupertinoPageRoute(
              builder: (_) => PaymentFailedScreen(
                errorMessage: provider.displayErrorMessage,
                campaignTitle: widget.campaign.title,
                amount: _selectedAmount,
                donationId: provider.currentDonationId,
                sessionId: provider.currentSessionId,
              ),
            ),
          );
        }
      } else {
        provider.cancelPayment();
      }
    } else {
      // فشل إنشاء الجلسة
      if (kDebugMode) {
        debugPrint('[DONATION_LOG] ⚠ الانتقال لصفحة الفشل: السبب = إنشاء الجلسة فشل (state != sessionCreated أو paymentUrl null)');
        debugPrint('[DONATION_LOG] state=${provider.state}, hasPaymentUrl=${provider.paymentUrl != null}, displayErrorMessage=${provider.displayErrorMessage}');
      }
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(
          builder: (_) => PaymentFailedScreen(
            errorMessage: provider.displayErrorMessage,
            campaignTitle: widget.campaign.title,
            amount: _selectedAmount,
            donationId: provider.currentDonationId,
            sessionId: provider.currentSessionId,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final isLoading = context.watch<PaymentProvider>().isLoading;
    final campaign = widget.campaign;
    final lang = context.locale.languageCode;
    final done = campaign.isCompleted;
    final accent = done ? p.success : p.tint;
    final category = campaign.getLocalizedCategory(lang);
    final riyal = 'riyal'.tr();

    return Scaffold(
      bottomNavigationBar: done ? null : _buildDonateBar(isLoading),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 260,
            backgroundColor: p.background,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: false,
            leadingWidth: 60,
            leading: Center(
              child: Semantics(
                button: true,
                label: MaterialLocalizations.of(context).backButtonTooltip,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.maybePop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.surface.withValues(alpha: 0.9),
                    ),
                    child: Icon(AppIcons.chevronBack, color: p.tint, size: 20),
                  ),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: _buildCampaignImage(260),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.screen),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (category.isNotEmpty)
                    Text(
                      category,
                      style: AppType.footnote.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  Text(
                    campaign.getLocalizedTitle(lang),
                    style: AppType.title1.copyWith(color: p.label),
                  ),
                  const SizedBox(height: AppSpace.md),
                  _buildSummaryCard(accent, riyal),
                  const SizedBox(height: AppSpace.lg),
                  _buildSectionTitle('program'.tr()),
                  Text(
                    campaign.getLocalizedDescription(lang),
                    style: AppType.body.copyWith(
                      color: p.secondaryLabel,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  if (done)
                    _buildCompletedCard()
                  else ...[
                    _buildSectionTitle('select_amount'.tr()),
                    _buildAmountTiles(riyal),
                    const SizedBox(height: AppSpace.md),
                    AppTextField(
                      controller: _customAmountController,
                      label: 'or_enter_custom_amount'.tr(),
                      hint: 'enter_amount'.tr(),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      suffix: Padding(
                        padding: const EdgeInsetsDirectional.only(
                            end: AppSpace.md),
                        child: Center(
                          widthFactor: 1,
                          child: Text(
                            riyal,
                            style: AppType.body
                                .copyWith(color: p.secondaryLabel),
                          ),
                        ),
                      ),
                      onChanged: (value) =>
                          setState(() => _selectedAmount = double.tryParse(value) ?? 0),
                    ),
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        if (auth.isAuthenticated && auth.userProfile != null) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: AppSpace.md),
                          child: AppTextField(
                            controller: _donorPhoneController,
                            label: 'donor_phone_label'.tr(),
                            hint: 'enter_your_phone'.tr(),
                            keyboardType: TextInputType.phone,
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.xs),
      child: Text(text, style: AppType.title3.copyWith(color: p.label)),
    );
  }

  /// Raised amount, progress bar and key figures on one flat card.
  Widget _buildSummaryCard(Color accent, String riyal) {
    final p = AppPalette.of(context);
    final campaign = widget.campaign;
    final done = campaign.isCompleted;
    final percent = campaign.progressPercentage;

    Widget stat(String value, String label) => Expanded(
          child: Column(
            children: [
              Text(value, style: AppType.title3.copyWith(color: p.label)),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppType.caption1.copyWith(color: p.secondaryLabel),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${campaign.currentAmount.toStringAsFixed(0)} $riyal',
            style: AppType.title2.copyWith(color: p.label),
          ),
          Text(
            done
                ? 'campaign_goal_achieved'.tr()
                : '${'target_amount'.tr()}: ${campaign.targetAmount.toStringAsFixed(0)} $riyal',
            style: AppType.footnote.copyWith(color: p.secondaryLabel),
          ),
          const SizedBox(height: AppSpace.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: percent.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: p.fill,
              valueColor: AlwaysStoppedAnimation(accent),
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            done
                ? '${(percent * 100).toStringAsFixed(0)}% ${'completed'.tr()}'
                : '${(percent * 100).toStringAsFixed(1)}%',
            style: AppType.footnote.copyWith(
              color: accent,
              fontWeight: FontWeight.w600,
            ),
          ),
          Divider(height: AppSpace.lg * 2, color: p.separator),
          Row(
            children: [
              stat('${campaign.donorCount}', 'donors_count'.tr()),
              SizedBox(
                height: 32,
                child: VerticalDivider(width: 1, color: p.separator),
              ),
              stat('${campaign.remainingDays}', 'days_remaining'.tr()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountTiles(String riyal) {
    final p = AppPalette.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpace.xs;
        final tileWidth = (constraints.maxWidth - gap * 2) / 3;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final amount in _quickAmounts)
              Builder(builder: (context) {
                final selected = _selectedAmount == amount;
                return Semantics(
                  button: true,
                  selected: selected,
                  label: '${amount.toStringAsFixed(0)} $riyal',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _selectAmount(amount);
                    },
                    child: AnimatedContainer(
                      duration: AppMotion.fast,
                      width: tileWidth,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? p.tint : p.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Text(
                        '${amount.toStringAsFixed(0)} $riyal',
                        style: AppType.headline.copyWith(
                          color: selected ? Colors.white : p.label,
                        ),
                      ),
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  Widget _buildCompletedCard() {
    final p = AppPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: p.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          Icon(CupertinoIcons.checkmark_circle_fill,
              color: p.success, size: 40),
          const SizedBox(height: AppSpace.sm),
          Text(
            'campaign_completed'.tr(),
            style: AppType.title3.copyWith(color: p.label),
          ),
          const SizedBox(height: AppSpace.xxs),
          Text(
            'campaign_completed_message'.tr(),
            textAlign: TextAlign.center,
            style: AppType.subheadline.copyWith(color: p.secondaryLabel),
          ),
        ],
      ),
    );
  }

  /// Sticky primary action with the security note beneath it.
  Widget _buildDonateBar(bool isLoading) {
    final p = AppPalette.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final amountSuffix = _selectedAmount > 0
        ? ' · ${_selectedAmount.toStringAsFixed(_selectedAmount % 1 == 0 ? 0 : 2)} ${'riyal'.tr()}'
        : '';

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpace.screen,
        AppSpace.sm,
        AppSpace.screen,
        AppSpace.xs + bottom,
      ),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.separator, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppButton(
            label: isLoading
                ? 'processing_payment'.tr()
                : '${'donate_now'.tr()}$amountSuffix',
            icon: isLoading ? null : CupertinoIcons.heart_fill,
            loading: isLoading,
            onPressed: _proceedToDonation,
          ),
          const SizedBox(height: AppSpace.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.lock_fill,
                  size: 12, color: p.secondaryLabel),
              const SizedBox(width: AppSpace.xxs),
              Flexible(
                child: Text(
                  'donation_security_notice'.tr(),
                  textAlign: TextAlign.center,
                  style: AppType.caption1.copyWith(color: p.secondaryLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignImage(double height) {
    final p = AppPalette.of(context);
    final imageUrl = widget.campaign.imageUrl.trim();

    Widget placeholder([Widget? child]) => Container(
          width: double.infinity,
          height: height,
          color: p.fill,
          alignment: Alignment.center,
          child: child ??
              Icon(CupertinoIcons.photo, color: p.tertiaryLabel, size: 40),
        );

    if (imageUrl.isEmpty) return placeholder();

    return Image.network(
      imageUrl,
      width: double.infinity,
      height: height,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : placeholder(const AppActivityIndicator()),
      errorBuilder: (context, error, stackTrace) => placeholder(),
    );
  }
}
