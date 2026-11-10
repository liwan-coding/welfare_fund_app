import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'
    show CupertinoActivityIndicator, CupertinoIcons, CupertinoPageRoute;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../constants/app_constants.dart';
import '../design/design.dart';
import '../providers/auth_provider.dart';
import '../widgets/common/main_tab_bar.dart';
import 'login_screen.dart' as login;
import 'edit_profile_screen.dart';
import 'my_donations_screen.dart';
import 'settings/setting_page_screen.dart';
import 'fund_partners_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _instagramUrl =
      'https://www.instagram.com/welfarefund4stu?igsh=M212OGhhejB5azFs';

  void _push(Widget screen) {
    Navigator.push(context, CupertinoPageRoute(builder: (_) => screen));
  }

  void _onBottomNavigationTap(int index, bool isAuthenticated) {
    if (index == 2) {
      setState(() {});
      return;
    }

    if (index == 0) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      return;
    }

    if (index == 1) {
      _push(isAuthenticated
          ? const MyDonationsScreen()
          : const login.LoginScreen());
    }
  }

  Future<void> _editProfile(Map<String, dynamic>? userProfile) async {
    final result = await Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => EditProfileScreen(userProfile: userProfile),
      ),
    );

    if (result == true && mounted) {
      await Provider.of<AuthProvider>(context, listen: false)
          .refreshProfile();
    }
  }

  Future<void> _chooseLanguage() async {
    final locale = await showAppActionSheet<Locale>(
      context,
      title: 'choose_language'.tr(),
      cancelLabel: 'cancel'.tr(),
      actions: [
        AppSheetAction('arabic'.tr(), const Locale('ar')),
        AppSheetAction('english'.tr(), const Locale('en')),
      ],
    );
    if (locale == null || !mounted) return;
    if (locale.languageCode == context.locale.languageCode) return;

    await context.setLocale(locale);
    // Rebuild the whole app tree in the new language.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    });
  }

  Future<void> _confirmLogout() async {
    final ok = await showAppAlert(
      context,
      title: 'logout'.tr(),
      message: 'logout_confirmation'.tr(),
      confirmLabel: 'confirm'.tr(),
      cancelLabel: 'cancel'.tr(),
      destructive: true,
    );
    if (ok && mounted) await _performLogout();
  }

  Future<void> _performLogout() async {
    final navigator = Navigator.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    NavigatorState? dialogNavigator;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        dialogNavigator ??= Navigator.of(dialogContext);
        final p = AppPalette.of(dialogContext);
        return Center(
          child: Container(
            padding: const EdgeInsets.all(AppSpace.xl),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CupertinoActivityIndicator(radius: 14),
                const SizedBox(height: AppSpace.md),
                Text(
                  'logging_out'.tr(),
                  style: AppType.subheadline.copyWith(
                    color: p.label,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      await authProvider.logout();
      dialogNavigator?.pop();
      dialogNavigator = null;
      if (!mounted) return;

      AppToast.show(context, 'logout_successful'.tr(),
          kind: AppToastKind.success);
      navigator.pushNamedAndRemoveUntil(
        AppConstants.homeRoute,
        (route) => false,
      );
    } catch (error) {
      dialogNavigator?.pop();
      dialogNavigator = null;
      if (!mounted) return;
      AppToast.show(
        context,
        '${'logout_error'.tr()}: $error',
        kind: AppToastKind.error,
      );
    }
  }

  Future<void> _openInstagramLink() async {
    HapticFeedback.lightImpact();
    try {
      if (await canLaunchUrlString(_instagramUrl)) {
        await launchUrlString(
          _instagramUrl,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (!mounted) return;
        AppToast.show(context, 'cannot_open_link'.tr(),
            kind: AppToastKind.error);
      }
    } catch (_) {
      if (!mounted) return;
      AppToast.show(context, 'error_opening_link'.tr(),
          kind: AppToastKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final isAuthenticated = authProvider.isAuthenticated;
        final userProfile = authProvider.userProfile;
        final bottom = MediaQuery.paddingOf(context).bottom;

        return Scaffold(
          extendBody: true,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              AppNavBar(title: 'settings'.tr()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: AppTabBar.barHeight + bottom + AppSpace.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppReveal(
                        child: isAuthenticated
                            ? _buildProfileCard(userProfile)
                            : _buildGuestCard(),
                      ),
                      AppReveal.staggered(
                        index: 1,
                        child: _buildMainSections(isAuthenticated, userProfile),
                      ),
                      if (isAuthenticated)
                        AppReveal.staggered(
                          index: 2,
                          child: AppListSection(
                            children: [
                              AppListTile(
                                title: 'logout'.tr(),
                                destructive: true,
                                showChevron: false,
                                onTap: _confirmLogout,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: MainTabBar(
            currentIndex: 2,
            onTap: (index) => _onBottomNavigationTap(index, isAuthenticated),
          ),
        );
      },
    );
  }

  Widget _buildMainSections(
    bool isAuthenticated,
    Map<String, dynamic>? userProfile,
  ) {
    final p = AppPalette.of(context);
    final languageName =
        context.locale.languageCode == 'ar' ? 'arabic'.tr() : 'english'.tr();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isAuthenticated)
          AppListSection(
            header: 'account_settings'.tr(),
            children: [
              AppListTile(
                icon: CupertinoIcons.person_fill,
                iconColor: p.tint,
                title: 'edit_profile'.tr(),
                onTap: () => _editProfile(userProfile),
              ),
              AppListTile(
                icon: CupertinoIcons.lock_fill,
                iconColor: p.secondary,
                title: 'security_privacy'.tr(),
                onTap: () =>
                    _push(const SettingPageScreen(pageKey: 'security')),
              ),
              AppListTile(
                icon: CupertinoIcons.heart_fill,
                iconColor: p.tint,
                title: 'my_donations'.tr(),
                onTap: () => _push(const MyDonationsScreen()),
              ),
            ],
          ),
        AppListSection(
          header: 'language_settings'.tr(),
          children: [
            AppListTile(
              icon: CupertinoIcons.globe,
              iconColor: p.secondary,
              title: 'choose_language'.tr(),
              value: languageName,
              onTap: _chooseLanguage,
            ),
          ],
        ),
        AppListSection(
          header: 'support_help'.tr(),
          children: [
            AppListTile(
              icon: CupertinoIcons.chat_bubble_2_fill,
              iconColor: p.secondary,
              title: 'contact_us'.tr(),
              subtitle: 'message_support_team'.tr(),
              onTap: () =>
                  _push(const SettingPageScreen(pageKey: 'contact_us')),
            ),
            AppListTile(
              icon: CupertinoIcons.person_2_fill,
              iconColor: p.tint,
              title: 'fund_partners'.tr(),
              subtitle: 'fund_partners_tile_subtitle'.tr(),
              onTap: () => _push(const FundPartnersScreen()),
            ),
            AppListTile(
              icon: CupertinoIcons.info_circle_fill,
              iconColor: p.tertiaryLabel,
              title: 'about_app'.tr(),
              subtitle: 'app_info_version'.tr(),
              onTap: () =>
                  _push(const SettingPageScreen(pageKey: 'about_app')),
            ),
            AppListTile(
              icon: CupertinoIcons.hand_raised_fill,
              iconColor: p.secondary,
              title: 'privacy_policy'.tr(),
              subtitle: 'read_privacy_policy'.tr(),
              onTap: () =>
                  _push(const SettingPageScreen(pageKey: 'privacy_policy')),
            ),
          ],
        ),
        AppListSection(
          header: 'follow_us'.tr(),
          footer: 'stay_connected'.tr(),
          children: [
            AppListTile(
              leading: Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFE4405F),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.instagram,
                  size: 17,
                  color: Colors.white,
                ),
              ),
              title: 'Instagram',
              onTap: _openInstagramLink,
            ),
          ],
        ),
      ],
    );
  }

  /// Signed-in header: avatar, name and contact line; taps through to
  /// Edit profile.
  Widget _buildProfileCard(Map<String, dynamic>? userProfile) {
    final p = AppPalette.of(context);
    final name = (userProfile?['name'] ??
            userProfile?['user']?['name'] ??
            'user'.tr())
        .toString();
    final phone =
        (userProfile?['phone'] ?? userProfile?['user']?['phone'] ?? '')
            .toString();
    final email =
        (userProfile?['email'] ?? userProfile?['user']?['email'] ?? '')
            .toString();
    final contact = phone.isNotEmpty ? phone : email;

    return AppListSection(
      children: [
        AppListTile(
          leading: Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: p.tint.withValues(alpha: 0.14),
            ),
            child: Text(
              name.isEmpty ? '?' : name.characters.first,
              style: AppType.title2.copyWith(color: p.tint),
            ),
          ),
          title: name,
          subtitle: contact.isEmpty ? null : contact,
          onTap: () => _editProfile(userProfile),
        ),
      ],
    );
  }

  Widget _buildGuestCard() {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpace.screen,
        0,
        AppSpace.screen,
        AppSpace.lg,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpace.lg),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: p.tint.withValues(alpha: 0.14),
              ),
              child: Icon(CupertinoIcons.heart_fill, color: p.tint, size: 26),
            ),
            const SizedBox(height: AppSpace.sm),
            Text(
              'make_difference'.tr(),
              textAlign: TextAlign.center,
              style: AppType.title3.copyWith(color: p.label),
            ),
            const SizedBox(height: AppSpace.xxs),
            Text(
              'login_to_view_donations'.tr(),
              textAlign: TextAlign.center,
              style: AppType.subheadline.copyWith(color: p.secondaryLabel),
            ),
            const SizedBox(height: AppSpace.md),
            AppButton(
              label: 'login'.tr(),
              onPressed: () => _push(const login.LoginScreen()),
            ),
          ],
        ),
      ),
    );
  }
}
