import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'
    show CupertinoIcons, CupertinoPageRoute, CupertinoSliverRefreshControl;
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../constants/app_constants.dart';
import '../design/design.dart';
import '../models/donation.dart';
import '../providers/auth_provider.dart';
import '../services/donation_service.dart';
import '../widgets/common/main_tab_bar.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'settings_screen.dart';

class MyDonationsScreen extends StatefulWidget {
  final bool forceRefresh;

  const MyDonationsScreen({super.key, this.forceRefresh = false});

  @override
  State<MyDonationsScreen> createState() => _MyDonationsScreenState();
}

class _MyDonationsScreenState extends State<MyDonationsScreen> {
  static const List<String> _filters = [
    'all',
    'this_month',
    'this_year',
    'completed',
    'pending',
    'cancelled',
    'failed',
  ];

  String _selectedFilter = 'all';

  final DonationService _donationService = DonationService();
  List<Donation> _donations = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isLoginRequired = false;

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadDonations();
  }

  @override
  void didUpdateWidget(MyDonationsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.forceRefresh != oldWidget.forceRefresh || widget.forceRefresh) {
      _checkAuthAndLoadDonations();
    }
  }

  Future<void> _checkAuthAndLoadDonations() async {
    try {
      final isAuthenticated =
          await _donationService.apiClient.isAuthenticated();
      if (!mounted) return;

      if (!isAuthenticated) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'must_login_first_to_view_donations'.tr();
          _isLoginRequired = true;
        });
        return;
      }

      await _loadDonations();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = '${'error_checking_login'.tr()}: $e';
        _isLoginRequired = false;
      });
    }
  }

  Future<void> _loadDonations() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final donations = await _donationService.getAllUserDonations();
      if (!mounted) return;

      setState(() {
        _donations = donations;
        _isLoading = false;
        _errorMessage = null;
        _isLoginRequired = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  // --- Debug-only developer tools (hidden in release builds) -------------

  Future<void> _createTestDonation() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      await _donationService.createDonationWithPayment(
        itemId: '1',
        itemType: 'campaign',
        amount: 10.0,
        donorName: 'Test User',
        message: 'test_donation_for_testing'.tr(),
        isAnonymous: false,
        returnOrigin: Uri.base.origin,
      );

      await _loadDonations();
      if (mounted) {
        AppToast.show(context, 'test_donation_created'.tr(),
            kind: AppToastKind.success);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = '${'error_creating_test_donation'.tr()}: $e';
      });
    }
  }

  Future<void> _testAllEndpoints() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      await _donationService.testAllEndpoints();
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppToast.show(context, 'all_apis_tested'.tr());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'error_occurred'.tr();
      });
    }
  }

  Future<void> _checkLastDonation() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final donations = await _donationService.getUserDonations();
      if (donations.isNotEmpty) {
        final last = donations.first;
        await _donationService.checkDonationStatus(last.id);
        if (!mounted) return;
        setState(() => _isLoading = false);
        AppToast.show(context, '${'last_donation'.tr()}: ${last.status}');
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
        AppToast.show(context, 'no_data'.tr());
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = '${'error_checking_last_donation'.tr()}: $e';
      });
    }
  }

  // --- Derived data -------------------------------------------------------

  List<Donation> get _filteredDonations {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'this_month':
        final start = DateTime(now.year, now.month, 1);
        return _donations.where((d) => d.date.isAfter(start)).toList();
      case 'this_year':
        final start = DateTime(now.year, 1, 1);
        return _donations.where((d) => d.date.isAfter(start)).toList();
      case 'completed':
        return _donations.where((d) => d.isPaid || d.isCompleted).toList();
      case 'pending':
        return _donations.where((d) => d.isPending).toList();
      case 'cancelled':
        return _donations.where((d) => d.isCancelled).toList();
      case 'failed':
        return _donations.where((d) => d.isFailed).toList();
      default:
        return _donations;
    }
  }

  /// Total of successful donations in the current filter.
  double get _totalAmount => _filteredDonations
      .where((d) => d.isPaid || d.isCompleted)
      .fold(0.0, (sum, d) => sum + d.amount);

  int get _successfulDonationsCount =>
      _filteredDonations.where((d) => d.isPaid || d.isCompleted).length;

  String _formatDate(DateTime date) {
    final difference = DateTime.now().difference(date).inDays;

    if (difference == 0) return 'today_date'.tr();
    if (difference == 1) return 'yesterday_date'.tr();
    if (difference < 7) {
      return '$difference ${difference == 1 ? 'day_ago'.tr() : 'days_ago'.tr()}';
    }
    if (difference < 30) {
      final weeks = (difference / 7).floor();
      return '$weeks ${weeks == 1 ? 'week_ago'.tr() : 'weeks_ago'.tr()}';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  String _filterLabel(String filter) =>
      _filters.contains(filter) ? filter.tr() : filter;

  void _onBottomNavigationTap(int index, bool isAuthenticated) {
    if (index == 1) {
      _checkAuthAndLoadDonations();
      return;
    }

    if (index == 0) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).popUntil((route) =>
            route.isFirst || route.settings.name == AppConstants.homeRoute);
      } else {
        Navigator.of(context).pushReplacement(
          CupertinoPageRoute(builder: (context) => const HomeScreen()),
        );
      }
      return;
    }

    if (index == 2) {
      Navigator.push(
        context,
        CupertinoPageRoute(builder: (context) => const SettingsScreen()),
      );
    }
  }

  ({Color color, IconData icon, String text}) _statusInfo(Donation donation) {
    final p = AppPalette.of(context);
    if (donation.isPaid || donation.isCompleted) {
      return (
        color: p.success,
        icon: CupertinoIcons.checkmark_circle_fill,
        text: 'completed_status'.tr(),
      );
    }
    if (donation.isPending) {
      return (
        color: p.warning,
        icon: CupertinoIcons.clock_fill,
        text: 'pending_status'.tr(),
      );
    }
    if (donation.isCancelled) {
      return (
        color: p.secondaryLabel,
        icon: CupertinoIcons.xmark_circle_fill,
        text: 'cancelled'.tr(),
      );
    }
    if (donation.isFailed) {
      return (
        color: p.destructive,
        icon: CupertinoIcons.exclamationmark_circle_fill,
        text: 'failed'.tr(),
      );
    }
    if (donation.isExpired) {
      return (
        color: p.tertiaryLabel,
        icon: CupertinoIcons.timer,
        text: 'expired'.tr(),
      );
    }
    return (
      color: p.secondaryLabel,
      icon: CupertinoIcons.question_circle_fill,
      text: donation.status,
    );
  }

  // --- UI -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final isAuthenticated = authProvider.isAuthenticated;
        final bottom = MediaQuery.paddingOf(context).bottom;

        return Scaffold(
          extendBody: true,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              AppNavBar(title: 'my_donations'.tr()),
              CupertinoSliverRefreshControl(
                onRefresh: _checkAuthAndLoadDonations,
              ),
              ..._buildBody(bottom),
            ],
          ),
          bottomNavigationBar: MainTabBar(
            currentIndex: 1,
            onTap: (index) => _onBottomNavigationTap(index, isAuthenticated),
          ),
        );
      },
    );
  }

  List<Widget> _buildBody(double bottomInset) {
    final listBottom = AppTabBar.barHeight + bottomInset + AppSpace.xl;

    if (_isLoading && _donations.isEmpty) {
      return [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
              AppSpace.screen, AppSpace.xs, AppSpace.screen, listBottom),
          sliver: SliverList.list(
            children: const [
              AppSkeleton(height: 96, radius: AppRadius.lg),
              SizedBox(height: AppSpace.md),
              AppSkeleton(height: 44, radius: 100),
              SizedBox(height: AppSpace.md),
              AppSkeleton(height: 72, radius: AppRadius.md),
              SizedBox(height: AppSpace.xs),
              AppSkeleton(height: 72, radius: AppRadius.md),
              SizedBox(height: AppSpace.xs),
              AppSkeleton(height: 72, radius: AppRadius.md),
            ],
          ),
        ),
      ];
    }

    if (_errorMessage != null) return [_buildErrorState(listBottom)];

    if (_donations.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.only(bottom: listBottom),
            child: AppEmptyState(
              icon: CupertinoIcons.heart,
              message: 'when_you_donate_will_appear_here'.tr(),
              title: 'no_donations_yet'.tr(),
            ),
          ),
        ),
      ];
    }

    final donations = _filteredDonations;

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
        sliver: SliverToBoxAdapter(
          child: AppReveal(child: _buildSummaryCard()),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
            AppSpace.screen, AppSpace.md, AppSpace.screen, AppSpace.md),
        sliver: SliverToBoxAdapter(
          child: AppChipBar(
            labels: [for (final f in _filters) _filterLabel(f)],
            selectedIndex: _filters.indexOf(_selectedFilter),
            onSelected: (i) => setState(() => _selectedFilter = _filters[i]),
          ),
        ),
      ),
      if (donations.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.only(bottom: listBottom),
            child: AppEmptyState(
              icon: CupertinoIcons.search,
              title: 'no_donations_found_for_filter'.tr(),
              message: 'try_different_filter_or_check_back_later'.tr(),
            ),
          ),
        )
      else
        SliverPadding(
          padding: EdgeInsets.only(bottom: listBottom),
          sliver: SliverToBoxAdapter(
            child: AppListSection(
              children: [
                for (final donation in donations) _buildDonationRow(donation),
              ],
            ),
          ),
        ),
    ];
  }

  Widget _buildErrorState(double listBottom) {
    final loginRequired = _isLoginRequired;

    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: listBottom),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppEmptyState(
              icon: loginRequired
                  ? CupertinoIcons.lock_fill
                  : CupertinoIcons.exclamationmark_circle,
              title: loginRequired
                  ? 'login_required'.tr()
                  : 'error_occurred'.tr(),
              message: _errorMessage!,
              actionLabel: loginRequired ? 'login'.tr() : 'retry'.tr(),
              onAction: loginRequired
                  ? () => Navigator.pushReplacement(
                        context,
                        CupertinoPageRoute(
                            builder: (context) => const LoginScreen()),
                      )
                  : _checkAuthAndLoadDonations,
            ),
            if (kDebugMode && !loginRequired) _buildDebugTools(),
          ],
        ),
      ),
    );
  }

  /// Developer-only actions; never compiled into the visible UI of release
  /// builds.
  Widget _buildDebugTools() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
      child: Wrap(
        spacing: AppSpace.xs,
        children: [
          AppButton(
            label: 'create_test_donation'.tr(),
            style: AppButtonStyle.tinted,
            expand: false,
            onPressed: _createTestDonation,
          ),
          AppButton(
            label: 'test_apis'.tr(),
            style: AppButtonStyle.tinted,
            expand: false,
            onPressed: _testAllEndpoints,
          ),
          AppButton(
            label: 'check_last_donation'.tr(),
            style: AppButtonStyle.tinted,
            expand: false,
            onPressed: _checkLastDonation,
          ),
        ],
      ),
    );
  }

  /// Total given and number of successful donations for the current filter.
  Widget _buildSummaryCard() {
    final p = AppPalette.of(context);

    Widget stat(String value, String label, {bool large = false}) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppType.footnote.copyWith(color: p.secondaryLabel),
              ),
              const SizedBox(height: AppSpace.xxs),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: (large ? AppType.title1 : AppType.title2)
                    .copyWith(color: p.label),
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
      child: Row(
        children: [
          stat(
            '${AppFormat.amount(_totalAmount)} ${'riyal'.tr()}',
            'total_donations'.tr(),
            large: true,
          ),
          Container(width: 0.5, height: 44, color: p.separator),
          const SizedBox(width: AppSpace.md),
          stat(
            _successfulDonationsCount.toString(),
            'number_of_donations'.tr(),
          ),
        ],
      ),
    );
  }

  Widget _buildDonationRow(Donation donation) {
    final p = AppPalette.of(context);
    final status = _statusInfo(donation);
    final title = donation
            .getLocalizedCampaignName(context.locale.languageCode) ??
        donation.programName ??
        'charity_donation'.tr();

    return AppListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: status.color.withValues(alpha: 0.14),
        ),
        child: Icon(status.icon, color: status.color, size: 20),
      ),
      title: title,
      subtitle: '${_formatDate(donation.date)} · ${status.text}',
      trailing: Text(
        '${AppFormat.amount(donation.amount)} ${'riyal'.tr()}',
        style: AppType.headline.copyWith(color: p.label),
      ),
      showChevron: false,
      onTap: () => _showDonationDetails(donation),
    );
  }

  void _showDonationDetails(Donation donation) {
    final status = _statusInfo(donation);
    final lang = context.locale.languageCode;
    final isGift = donation.message?.contains('هدية') == true ||
        donation.message?.contains('إهداء') == true ||
        donation.message?.contains('gift') == true;

    final isProgram = donation.programId != null;
    final isCampaign = donation.campaignId != null;
    final targetName = donation.programName ??
        donation.getLocalizedCampaignName(lang) ??
        '';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (sheetContext) {
        final p = AppPalette.of(sheetContext);

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSpace.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'donation_amount_label'.tr(),
                  textAlign: TextAlign.center,
                  style: AppType.footnote.copyWith(color: p.secondaryLabel),
                ),
                Text(
                  '${AppFormat.amount(donation.amount)} ${'omani_riyal'.tr()}',
                  textAlign: TextAlign.center,
                  style: AppType.largeTitle.copyWith(color: p.label),
                ),
                if (donation.paidAmount != null &&
                    donation.paidAmount != donation.amount)
                  Text(
                    '${'paid_amount'.tr()}: ${donation.paidAmount!.toStringAsFixed(0)} ${'riyal'.tr()}',
                    textAlign: TextAlign.center,
                    style: AppType.footnote.copyWith(color: p.secondaryLabel),
                  ),
                const SizedBox(height: AppSpace.sm),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.sm,
                      vertical: AppSpace.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: status.color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(status.icon, size: 14, color: status.color),
                        const SizedBox(width: 6),
                        Text(
                          status.text,
                          style: AppType.footnote.copyWith(
                            color: status.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
                AppListSection(
                  children: [
                    AppListTile(
                      title: 'donation_date_label'.tr(),
                      value:
                          '${donation.date.day}/${donation.date.month}/${donation.date.year}',
                    ),
                    if (isProgram || isCampaign)
                      AppListTile(
                        title: 'type_label'.tr(),
                        value: isProgram ? 'program'.tr() : 'campaign'.tr(),
                      ),
                    if (targetName.isNotEmpty)
                      AppListTile(
                        title: isProgram ? 'program'.tr() : 'campaign'.tr(),
                        subtitle: targetName,
                      ),
                    if (donation.donorName != null && !donation.isAnonymous)
                      AppListTile(
                        title: 'donor_name_required'.tr(),
                        value: donation.donorName!,
                      ),
                    if (isGift)
                      AppListTile(
                        icon: CupertinoIcons.gift_fill,
                        iconColor: p.tint,
                        title: 'gift_donation_badge'.tr(),
                      ),
                    if (donation.isAnonymous)
                      AppListTile(
                        icon: CupertinoIcons.eye_slash_fill,
                        iconColor: p.secondary,
                        title: 'anonymous_donation_badge'.tr(),
                      ),
                    AppListTile(
                      title: 'donation_id_label'.tr(),
                      value: donation.id,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
