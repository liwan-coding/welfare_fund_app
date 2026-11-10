import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'
    show
        CupertinoButton,
        CupertinoIcons,
        CupertinoPageRoute,
        CupertinoSliverRefreshControl;
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import 'package:flutter/services.dart';
import '../widgets/common/campaign_card.dart';
import 'main_shell.dart';
import '../design/design.dart';
import '../widgets/home/hero_banner.dart';
import '../widgets/home/home_header.dart';
import '../widgets/home/home_quick_actions.dart';
import '../models/campaign.dart';
import '../models/app_banner.dart';
import '../models/donation.dart';
import '../models/student_registration_card.dart';
import '../services/banner_service.dart';
import '../services/campaign_service.dart';
import '../services/donation_service.dart';
import '../services/student_registration_card_service.dart';
import '../services/student_registration_service.dart';
import '../providers/auth_provider.dart';
import 'quick_donate_amount_screen.dart';
// import 'gift_donation_screen.dart'; // Unused for now
import 'fund_news_screen.dart';
import 'campaign_donation_screen.dart';
import 'student_registration_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'all_campaigns_screen.dart';
import '../utils/category_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final StudentRegistrationService _studentService =
      StudentRegistrationService();
  final CampaignService _campaignService = CampaignService();
  final DonationService _donationService = DonationService();
  final BannerService _bannerService = BannerService();
  final PageController _bannerPageController =
      PageController(viewportFraction: 0.92);
  final StudentRegistrationCardService _registrationCardService =
      StudentRegistrationCardService();
  List<Campaign> _campaigns = [];
  List<Campaign> _allCampaigns = []; // جميع الحملات الأصلية
  List<Donation> _recentDonations = []; // التبرعات الأخيرة
  List<AppBanner> _banners = [];
  List<Map<String, dynamic>> _categories = [];
  Map<String, List<String>> _categoryMatchers = {};
  bool _isLoadingCategories = false;
  String _selectedCategoryId = 'all';

  // Application status variables
  Map<String, dynamic>? _applicationData;
  bool _isCheckingApplication = false;
  bool _isLoadingCampaigns = false;
  bool _isLoadingRecentDonations = false;
  bool _isLoadingBanners = false;
  int _activeHeroIndex = 0;
  static const String _defaultRegistrationCardImage =
      'https://images.pexels.com/photos/5905708/pexels-photo-5905708.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1';
  StudentRegistrationCardData? _registrationCardData;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadCampaignsFromAPI(); // Load from API instead of sample data
    _loadRecentDonations(); // Load recent donations from API
    _loadBanners();
    _checkApplicationStatus();
    _loadRegistrationCard();

    // Check application status again after a delay to ensure fresh data
    // This is important after returning from registration screen
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        print('HomeScreen: Re-checking application status after delay...');
        _checkApplicationStatus();
      }
    });

    // Listen to auth changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.addListener(_onAuthStateChanged);
    });
  }

  void _onAuthStateChanged() {
    // Update application status when auth state changes
    print('HomeScreen: Auth state changed, updating application status...');
    _checkApplicationStatus();
  }

  Future<void> _refreshHomeData() async {
    // Reload all data when returning to home screen
    print('HomeScreen: Refreshing home data...');
    _loadCampaignsFromAPI();
    _loadRecentDonations();
    _loadBanners();
    _checkApplicationStatus();
    _loadRegistrationCard();
  }

  String _getRegistrationCardText({
    required BuildContext context,
    required String fallbackKey,
    required String? arabicValue,
    required String? englishValue,
  }) {
    final localeCode = context.locale.languageCode.toLowerCase();
    final String? localizedValue;
    if (localeCode == 'ar') {
      localizedValue = arabicValue ?? englishValue;
    } else {
      localizedValue = englishValue ?? arabicValue;
    }

    if (localizedValue != null && localizedValue.trim().isNotEmpty) {
      return localizedValue.trim();
    }

    return fallbackKey.tr();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      print('HomeScreen: Loading categories from API...');
      final categoriesFromApi = await _campaignService.getCategories();

      if (!mounted) return;

      final bool hasApiCategories = categoriesFromApi.isNotEmpty;
      final normalizedCategories = hasApiCategories
          ? _normalizeCategories(categoriesFromApi)
          : _normalizeCategories(
              CategoryUtils.getLocalizedFallbackCategories());

      if (!hasApiCategories) {
        print(
            'HomeScreen: Categories API returned empty list, using localized fallback categories.');
      } else {
        print(
            'HomeScreen: Loaded ${normalizedCategories.length} categories from API.');
      }

      setState(() {
        _categories = normalizedCategories;
        _categoryMatchers = _createCategoryMatchers(normalizedCategories);
        _isLoadingCategories = false;
      });
    } catch (error) {
      print('HomeScreen: Error loading categories: $error');

      if (!mounted) return;

      final fallbackCategories = _normalizeCategories(
        CategoryUtils.getLocalizedFallbackCategories(),
      );

      setState(() {
        _categories = fallbackCategories;
        _categoryMatchers = _createCategoryMatchers(fallbackCategories);
        _isLoadingCategories = false;
      });
    }

    if (!mounted) return;

    _applyCategoryFilter(_selectedCategoryId);
  }

  Future<void> _loadCampaignsFromAPI() async {
    try {
      print('HomeScreen: Loading campaigns from API...');
      setState(() {
        _isLoadingCampaigns = true;
      });

      List<Campaign> allCampaigns = [];

      // Load only charity campaigns for the home page (for general users)
      try {
        final charityCampaigns = await _campaignService.getCharityCampaigns();
        allCampaigns.addAll(charityCampaigns);
        print(
            'HomeScreen: Successfully loaded ${charityCampaigns.length} charity campaigns from API');
        print(
            'HomeScreen: Charity campaigns are for general users to donate directly');
      } catch (error) {
        print('HomeScreen: Failed to load charity campaigns: $error');
      }

      // Note: Student programs are loaded separately in student registration screens
      // They are for students who want to register for support, not for general donation

      // Only use data from API - no fallback
      if (allCampaigns.isNotEmpty) {
        setState(() {
          _allCampaigns = List.from(allCampaigns);
          _isLoadingCampaigns = false;
        });

        _applyCategoryFilter(_selectedCategoryId);

        print(
            'HomeScreen: Successfully loaded ${allCampaigns.length} total campaigns from API');
        print(
            'HomeScreen: Campaign IDs: ${allCampaigns.map((c) => c.id).toList()}');
        print(
            'HomeScreen: Campaign titles: ${allCampaigns.map((c) => c.title).toList()}');
      } else {
        // No data from API - show empty state
        print('HomeScreen: No data from API, showing empty state');
        setState(() {
          _campaigns = [];
          _allCampaigns = [];
          _isLoadingCampaigns = false;
          _selectedCategoryId = 'all';
        });
      }
    } catch (error) {
      print('HomeScreen: Error loading campaigns from API: $error');
      setState(() {
        _campaigns = [];
        _allCampaigns = [];
        _isLoadingCampaigns = false;
        _selectedCategoryId = 'all';
      });

      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'error_loading_programs'.tr(),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.surface,
              ),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadRecentDonations() async {
    try {
      print('HomeScreen: Loading recent donations from API...');
      setState(() {
        _isLoadingRecentDonations = true;
      });

      final recentDonations =
          await _donationService.getRecentDonations(limit: 5);
      print(
          'HomeScreen: Successfully loaded ${recentDonations.length} recent donations from API');

      setState(() {
        _recentDonations = recentDonations;
        _isLoadingRecentDonations = false;
      });
    } catch (error) {
      print('HomeScreen: Error loading recent donations: $error');
      setState(() {
        _recentDonations = [];
        _isLoadingRecentDonations = false;
      });
    }
  }

  Future<void> _loadBanners() async {
    setState(() {
      _isLoadingBanners = true;
    });

    try {
      final featured = await _bannerService.getFeaturedBanners();
      final active = await _bannerService.getActiveBanners();
      final combined = <AppBanner>[];
      final seenIds = <String>{};

      for (final banner in [...featured, ...active]) {
        if (banner.id.isEmpty || seenIds.contains(banner.id)) continue;
        seenIds.add(banner.id);
        combined.add(banner);
      }
      combined.sort((a, b) => a.priority.compareTo(b.priority));

      if (!mounted) return;
      setState(() {
        _banners = combined;
        _activeHeroIndex = 0;
      });
    } catch (error) {
      print('HomeScreen: Error loading banners: $error');
      if (!mounted) return;
      setState(() {
        _banners = [];
        _activeHeroIndex = 0;
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingBanners = false;
      });
    }
  }

  Future<void> _loadRegistrationCard() async {
    if (!mounted) return;

    try {
      final cardData = await _registrationCardService.fetchCardData();
      if (!mounted) return;
      setState(() {
        _registrationCardData = cardData;
      });
    } catch (error) {
      print('HomeScreen: Error loading registration card data: $error');
    }
  }

  @override
  void dispose() {
    // Remove auth listener
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.removeListener(_onAuthStateChanged);
    } catch (e) {
      // Ignore if provider is not available
    }

    _searchController.dispose();
    _bannerPageController.dispose();
    super.dispose();
  }

  void _onQuickDonate() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => const QuickDonateAmountScreen(),
      ),
    );
  }

  void _onFundNews() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => const FundNewsScreen(),
      ),
    );
  }

  void _showLoginBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final p = AppPalette.of(sheetContext);

        void go(Widget screen) {
          Navigator.pop(sheetContext);
          Navigator.push(
            context,
            CupertinoPageRoute(builder: (_) => screen),
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.screen,
              0,
              AppSpace.screen,
              AppSpace.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.tint.withValues(alpha: 0.14),
                    ),
                    child: Icon(
                      CupertinoIcons.lock_fill,
                      color: p.tint,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.md),
                Text(
                  'login_required'.tr(),
                  textAlign: TextAlign.center,
                  style: AppType.title2.copyWith(color: p.label),
                ),
                const SizedBox(height: AppSpace.xxs),
                Text(
                  'login_to_view_donations'.tr(),
                  textAlign: TextAlign.center,
                  style: AppType.subheadline.copyWith(color: p.secondaryLabel),
                ),
                const SizedBox(height: AppSpace.xl),
                AppButton(
                  label: 'login'.tr(),
                  onPressed: () => go(const LoginScreen()),
                ),
                const SizedBox(height: AppSpace.xs),
                AppButton(
                  label: 'create_new_account'.tr(),
                  style: AppButtonStyle.tinted,
                  onPressed: () => go(const RegisterScreen()),
                ),
                AppButton(
                  label: 'skip'.tr(),
                  style: AppButtonStyle.plain,
                  onPressed: () => Navigator.pop(sheetContext),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _checkApplicationStatus() async {
    print('═══════════════════════════════════════════════════════════');
    print('🔄 [_checkApplicationStatus] Called');
    print('═══════════════════════════════════════════════════════════');

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isAuthenticated = authProvider.isAuthenticated;
      print('🔐 [_checkApplicationStatus] isAuthenticated: $isAuthenticated');

      if (!isAuthenticated) {
        print(
            '❌ [_checkApplicationStatus] User not authenticated, clearing application data');
        setState(() {
          _applicationData = null;
          _isCheckingApplication = false;
        });
        print('📝 [_checkApplicationStatus] _applicationData set to null');
        return;
      }

      print(
          '⏳ [_checkApplicationStatus] Setting _isCheckingApplication = true');
      setState(() {
        _isCheckingApplication = true;
      });

      print(
          '🌐 [_checkApplicationStatus] Fetching latest application data from server...');
      print(
          '📍 [_checkApplicationStatus] Using endpoint: GET /api/v1/students/registration/my-registration');

      // Add a small delay to ensure backend has processed the registration
      await Future.delayed(const Duration(milliseconds: 500));

      print(
          '📡 [_checkApplicationStatus] Calling getCurrentUserRegistration()...');
      final application = await _studentService.getCurrentUserRegistration();

      // Debug: Print application data
      print('═══════════════════════════════════════════════════════════');
      print('📦 [_checkApplicationStatus] API Response Received');
      print('═══════════════════════════════════════════════════════════');
      print('📋 [_checkApplicationStatus] Raw application data: $application');
      print(
          '📋 [_checkApplicationStatus] Application is null: ${application == null}');

      Map<String, dynamic>? normalizedApplication;

      if (application != null) {
        print('✅ [_checkApplicationStatus] Application data is NOT null');
        // Create a copy to avoid modifying the original
        normalizedApplication = Map<String, dynamic>.from(application);

        print(
            '📊 [_checkApplicationStatus] Application keys: ${normalizedApplication.keys.toList()}');
        print(
            '📊 [_checkApplicationStatus] Status before normalization: ${normalizedApplication['status']}');
        print(
            '📊 [_checkApplicationStatus] Status type: ${normalizedApplication['status'].runtimeType}');
        print('📊 [_checkApplicationStatus] Full application data:');
        normalizedApplication.forEach((key, value) {
          print('   - $key: $value (${value.runtimeType})');
        });

        // Normalize status format - ensure it matches expected values
        // Backend status values: under_review, accepted, rejected, completed
        String rawStatus =
            normalizedApplication['status']?.toString() ?? 'under_review';
        String normalizedStatus = rawStatus.toLowerCase().trim();

        print('🔄 [_checkApplicationStatus] Normalizing status...');
        print('   - Raw status: "$rawStatus"');
        print('   - Normalized status: "$normalizedStatus"');

        // Normalize status values to match backend response: under_review, accepted, rejected, completed
        String finalStatus;
        switch (normalizedStatus) {
          case 'under_review':
          case 'قيد المراجعة':
            finalStatus = 'under_review';
            print('   ✅ Matched: under_review');
            break;
          case 'accepted':
          case 'مقبول':
            finalStatus = 'accepted';
            print('   ✅ Matched: accepted');
            break;
          case 'rejected':
          case 'مرفوض':
            finalStatus = 'rejected';
            print('   ✅ Matched: rejected');
            break;
          case 'completed':
          case 'مكتمل':
            finalStatus = 'completed';
            print('   ✅ Matched: completed');
            break;
          default:
            print(
                '   ⚠️ Warning: Unknown status: "$rawStatus", defaulting to under_review');
            finalStatus = 'under_review';
        }

        // Ensure the normalized status is set in the application data
        normalizedApplication['status'] = finalStatus;

        print('✅ [_checkApplicationStatus] Normalized status: "$finalStatus"');
        print(
            '✅ [_checkApplicationStatus] Status after normalization: ${normalizedApplication['status']}');
      } else {
        print('❌ [_checkApplicationStatus] Application data is NULL');
        print(
            '❌ [_checkApplicationStatus] This means user may not have registered yet OR API returned null');
      }

      print('═══════════════════════════════════════════════════════════');

      if (!mounted) {
        print(
            '⚠️ [_checkApplicationStatus] Widget not mounted, skipping setState');
        return;
      }

      print('🔄 [_checkApplicationStatus] Updating state...');
      print('   - Old _applicationData: $_applicationData');
      print('   - New _applicationData: $normalizedApplication');

      setState(() {
        _applicationData = normalizedApplication;
        _isCheckingApplication = false;
      });

      print('✅ [_checkApplicationStatus] State updated successfully');
      print(
          '📋 [_checkApplicationStatus] Current _applicationData: $_applicationData');
      if (normalizedApplication != null) {
        print(
            '📋 [_checkApplicationStatus] Status in _applicationData: ${normalizedApplication['status']}');
      } else {
        print(
            '📋 [_checkApplicationStatus] _applicationData is NULL (will show "سجل الآن")');
      }
      print('═══════════════════════════════════════════════════════════');
    } catch (error) {
      print('❌ [_checkApplicationStatus] Error occurred: $error');
      print('❌ [_checkApplicationStatus] Error type: ${error.runtimeType}');
      print(
          '❌ [_checkApplicationStatus] This error will be caught - _applicationData will remain null');
      print('═══════════════════════════════════════════════════════════');

      // Even if there's an error, set _isCheckingApplication to false
      if (!mounted) return;
      setState(() {
        _isCheckingApplication = false;
        // Keep _applicationData as null on error
        // This means button will show "سجل الآن"
      });

      // Log the full error for debugging
      print('Full error details:');
      print(error.toString());
    }
  }

  void _onRegister() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isAuthenticated = authProvider.isAuthenticated;
      print('Auth check result for student registration: $isAuthenticated');

      if (!isAuthenticated) {
        print('User not authenticated, showing bottom sheet');
        _showLoginBottomSheet();
        return;
      }

      // If user has a registration, show it in read-only mode
      if (_applicationData != null) {
        // Debug: Print data being passed to registration screen
        print('=== Navigation Debug ===');
        print('Passing data to registration screen: $_applicationData');
        print('Status: ${_applicationData!['status']}');
        print('========================');

        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => StudentRegistrationScreen(
              existingData: _applicationData,
              isReadOnly: false, // Allow editing for re-submission
            ),
          ),
        ).then((_) {
          // Refresh application status when returning from registration screen
          print(
              'HomeScreen: Returned from registration screen, refreshing application status...');
          _checkApplicationStatus();
        });
      } else {
        // No registration, navigate to registration screen
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => const StudentRegistrationScreen(),
          ),
        ).then((_) {
          // Refresh application status when returning from registration screen
          print(
              'HomeScreen: Returned from registration screen, refreshing application status...');
          _checkApplicationStatus();
        });
      }
    } catch (error) {
      print('Error checking authentication: $error');
      _showLoginBottomSheet();
    }
  }

  String _getButtonText() {
    print('═══════════════════════════════════════════════════════════');
    print('🔘 [_getButtonText] Called');
    print('═══════════════════════════════════════════════════════════');
    print(
        '📋 [_getButtonText] _isCheckingApplication: $_isCheckingApplication');
    print('📋 [_getButtonText] _applicationData: $_applicationData');
    print(
        '📋 [_getButtonText] _applicationData is null: ${_applicationData == null}');

    if (_isCheckingApplication) {
      print('⏳ [_getButtonText] Currently checking, returning: checking');
      print('═══════════════════════════════════════════════════════════');
      return 'checking'.tr();
    }

    if (_applicationData == null) {
      print(
          '❌ [_getButtonText] _applicationData is NULL, returning: register_now');
      print('❌ [_getButtonText] This is why you see "سجل الآن" button');
      print('═══════════════════════════════════════════════════════════');
      return 'register_now'.tr();
    }

    print('✅ [_getButtonText] _applicationData is NOT null');
    print(
        '📋 [_getButtonText] _applicationData keys: ${_applicationData!.keys.toList()}');

    final status = _applicationData!['status'] ?? 'unknown';

    print('📊 [_getButtonText] Status from _applicationData: "$status"');
    print('📊 [_getButtonText] Status type: ${status.runtimeType}');

    // Normalize status
    String normalizedStatus = status.toString().toLowerCase().trim();
    print('📊 [_getButtonText] Normalized status: "$normalizedStatus"');

    String buttonText;
    switch (normalizedStatus) {
      // Backend status values: under_review, accepted, rejected, completed
      case 'under_review':
      case 'قيد المراجعة':
        buttonText = 'under_review'.tr();
        print('✅ [_getButtonText] Matched: under_review');
        break;
      case 'accepted':
      case 'مقبول':
        buttonText = 'approved'.tr();
        print('✅ [_getButtonText] Matched: accepted');
        break;
      case 'rejected':
      case 'مرفوض':
        buttonText = 'rejected'.tr();
        print('✅ [_getButtonText] Matched: rejected');
        break;
      case 'completed':
      case 'مكتمل':
        buttonText = 'completed'.tr();
        print('✅ [_getButtonText] Matched: completed');
        break;
      default:
        buttonText = 'view_application'.tr();
        print(
            '⚠️ [_getButtonText] Unknown status, using default: view_application');
    }

    print('✅ [_getButtonText] Returning button text: "$buttonText"');
    print('═══════════════════════════════════════════════════════════');
    return buttonText;
  }

  // Backend status values: under_review, accepted, rejected, completed
  Color _getButtonColor() {
    if (_applicationData == null) {
      return AppColors.primary;
    }

    final status = _applicationData!['status'] ?? 'unknown';

    // Normalize status
    String normalizedStatus = status.toLowerCase();

    switch (normalizedStatus) {
      case 'under_review':
      case 'قيد المراجعة':
        return AppColors.warning;
      case 'accepted':
      case 'مقبول':
        return AppColors.success;
      case 'rejected':
      case 'مرفوض':
        return AppColors.error;
      case 'completed':
      case 'مكتمل':
        return AppColors.successDark;
      default:
        return AppColors.primary;
    }
  }

  void _onCampaignTap(Campaign campaign) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => CampaignDonationScreen(campaign: campaign),
      ),
    );
  }

  void _onViewAllCampaigns() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => AllCampaignsScreen(
          initialCampaigns: _allCampaigns,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final isAuthenticated = authProvider.isAuthenticated;
        final userProfile = authProvider.userProfile;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.dark,
          child: Scaffold(
            backgroundColor: AppPalette.of(context).background,
            body: _buildHomeBody(
              isAuthenticated: isAuthenticated,
              userProfile: userProfile,
            ),
          ),
        );
      },
    );
  }

  Widget _buildStudentBannerCarousel() {
    final heroCards = <Widget>[
      _buildStudentRegistrationCard(),
    ];

    if (_isLoadingBanners) {
      heroCards.add(_buildBannerLoadingCard());
    } else if (_banners.isNotEmpty) {
      heroCards.addAll(_banners.map(_buildBannerCard));
    }

    if (heroCards.length == 1) return heroCards.first;

    final showIndicators = heroCards.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: HeroBanner.height,
          child: PageView.builder(
            controller: _bannerPageController,
            padEnds: false,
            itemCount: heroCards.length,
            onPageChanged: (index) {
              setState(() {
                _activeHeroIndex = index;
              });
            },
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpace.xs),
              child: heroCards[index],
            ),
          ),
        ),
        if (showIndicators) ...[
          const SizedBox(height: 12),
          _buildHeroIndicators(heroCards.length),
        ],
      ],
    );
  }

  Widget _buildStudentRegistrationCard() {
    final cardData = _registrationCardData;
    final String imageUrl = (cardData?.backgroundImageUrl?.isNotEmpty ?? false)
        ? cardData!.backgroundImageUrl!
        : _defaultRegistrationCardImage;

    final String headlineText = _getRegistrationCardText(
      context: context,
      fallbackKey: 'start_journey',
      arabicValue: cardData?.headlineAr,
      englishValue: cardData?.headlineEn,
    );

    final String subtitleText = _getRegistrationCardText(
      context: context,
      fallbackKey: 'enable_education',
      arabicValue: cardData?.subtitleAr,
      englishValue: cardData?.subtitleEn,
    );

    return HeroBanner(
      title: headlineText,
      description: subtitleText,
      imageUrl: imageUrl,
      actionLabel: _getButtonText(),
      actionColor: _getButtonColor(),
      onTap: _onRegister,
    );
  }

  Widget _buildBannerLoadingCard() {
    return const AppSkeleton(
        height: HeroBanner.height, radius: AppRadius.lg + 4);
  }

  Widget _buildBannerCard(AppBanner banner) {
    final hasAction = (banner.actionUrl ?? '').isNotEmpty;

    return HeroBanner(
      title: _getBannerTitle(banner),
      eyebrow: _getBannerSubtitle(banner),
      description: _getBannerDescription(banner),
      imageUrl: banner.mobileImageUrl ?? banner.imageUrl,
      actionLabel: hasAction ? (banner.actionLabel ?? 'donate_now'.tr()) : null,
      onTap: hasAction ? () => _handleBannerTap(banner) : null,
    );
  }

  Widget _buildHeroIndicators(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == _activeHeroIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 6,
          width: isActive ? 24 : 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  String _getBannerTitle(AppBanner banner) {
    final locale = context.locale.languageCode;
    if (locale == 'ar') {
      return banner.titleAr?.isNotEmpty == true
          ? banner.titleAr!
          : (banner.title ?? banner.titleEn ?? '');
    }
    return banner.titleEn?.isNotEmpty == true
        ? banner.titleEn!
        : (banner.title ?? banner.titleAr ?? '');
  }

  String _getBannerSubtitle(AppBanner banner) {
    final locale = context.locale.languageCode;
    if (locale == 'ar') {
      return banner.subtitleAr?.isNotEmpty == true
          ? banner.subtitleAr!
          : (banner.subtitle ?? banner.subtitleEn ?? '');
    }
    return banner.subtitleEn?.isNotEmpty == true
        ? banner.subtitleEn!
        : (banner.subtitle ?? banner.subtitleAr ?? '');
  }

  String _getBannerDescription(AppBanner banner) {
    final locale = context.locale.languageCode;
    if (locale == 'ar') {
      return banner.descriptionAr?.isNotEmpty == true
          ? banner.descriptionAr!
          : (banner.description ?? banner.descriptionEn ?? '');
    }
    return banner.descriptionEn?.isNotEmpty == true
        ? banner.descriptionEn!
        : (banner.description ?? banner.descriptionAr ?? '');
  }

  Future<void> _handleBannerTap(AppBanner banner) async {
    final url = banner.actionUrl;
    if (url == null || url.isEmpty) {
      return;
    }
    try {
      final launched = await launchUrlString(
        url,
        webOnlyWindowName: '_self',
      );
      if (!launched) {
        print('HomeScreen: Could not launch banner URL: $url');
      }
    } catch (error) {
      print('HomeScreen: Error launching banner URL ($url): $error');
    }
  }

  Widget _buildCategoryFilterSection() {
    if (_isLoadingCategories && _categories.isEmpty) {
      return const SizedBox(
        height: 50,
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    final chips = <Widget>[
      _buildFilterChip(id: 'all', label: 'all'.tr()),
    ];

    for (final category in _categories) {
      final label = _getLocalizedCategoryLabel(category);
      if (label.isEmpty) continue;
      final categoryKey = _deriveCategoryKey(category);
      chips.add(_buildFilterChip(id: categoryKey, label: label));
    }

    if (chips.isEmpty) {
      chips.add(_buildFilterChip(id: 'all', label: 'all'.tr()));
    }

    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        children: chips,
      ),
    );
  }

  String _getLocalizedCategoryLabel(Map<String, dynamic> category) {
    final locale = context.locale.languageCode;
    if (locale == 'ar') {
      final label = category['name_ar']?.toString() ?? '';
      if (label.isNotEmpty) return label;
    } else {
      final label = category['name_en']?.toString() ?? '';
      if (label.isNotEmpty) return label;
    }

    final fallbackName = category['name']?.toString() ?? '';
    if (fallbackName.isNotEmpty) return fallbackName;

    return category['title']?.toString() ?? '';
  }

  String _deriveCategoryKey(Map<String, dynamic> category) {
    final id = (category['id'] ?? '').toString();
    if (id.isNotEmpty) return id;

    final candidates = [
      category['name'],
      category['name_ar'],
      category['name_en'],
      category['title'],
    ];

    for (final candidate in candidates) {
      if (candidate == null) continue;
      final value = candidate.toString().trim();
      if (value.isNotEmpty) {
        return value;
      }
    }

    return 'all';
  }

  Map<String, List<String>> _createCategoryMatchers(
      List<Map<String, dynamic>> categories) {
    final matchers = <String, List<String>>{};

    for (final category in categories) {
      final key = _deriveCategoryKey(category);
      final names = <String>{};

      for (final candidate in [
        category['name'],
        category['name_ar'],
        category['name_en'],
        category['title'],
      ]) {
        if (candidate == null) continue;
        final value = candidate.toString().trim().toLowerCase();
        if (value.isNotEmpty) {
          names.add(value);
        }
      }

      if (key.isNotEmpty) {
        names.add(key.trim().toLowerCase());
      }

      if (names.isNotEmpty) {
        matchers[key] = names.toList();
      }
    }

    return matchers;
  }

  List<Map<String, dynamic>> _normalizeCategories(
      List<Map<String, dynamic>> categories) {
    return categories.map((category) {
      final normalized = Map<String, dynamic>.from(category);
      normalized['id'] = (normalized['id'] ?? '').toString();
      final fallbackName =
          (normalized['name'] ?? normalized['title'] ?? '').toString();
      normalized['name'] = fallbackName;
      normalized['name_ar'] =
          (normalized['name_ar'] ?? fallbackName).toString();
      normalized['name_en'] =
          (normalized['name_en'] ?? fallbackName).toString();
      normalized['status'] = (normalized['status'] ?? 'active').toString();
      return normalized;
    }).toList();
  }

  void _applyCategoryFilter(String categoryKey) {
    final normalizedKey = categoryKey.isEmpty ? 'all' : categoryKey;
    _selectedCategoryId = normalizedKey;
    _applyFilters();
  }

  void _applyFilters() {
    List<Campaign> filteredCampaigns;

    // Apply category filter
    if (_selectedCategoryId == 'all') {
      filteredCampaigns = List.from(_allCampaigns);
    } else {
      final matcherValues = _categoryMatchers[_selectedCategoryId] ??
          _categoryMatchers.values.firstWhere(
            (names) => names.contains(_selectedCategoryId.toLowerCase()),
            orElse: () => <String>[],
          );

      if (matcherValues.isEmpty) {
        filteredCampaigns = List.from(_allCampaigns);
      } else {
        filteredCampaigns = _allCampaigns.where((campaign) {
          final locale = context.locale.languageCode;
          final campaignCategory =
              campaign.getLocalizedCategory(locale).trim().toLowerCase();
          return matcherValues.contains(campaignCategory);
        }).toList();
      }
    }

    // Apply search filter
    final searchQuery = _searchController.text.trim().toLowerCase();
    if (searchQuery.isNotEmpty) {
      final locale = context.locale.languageCode;
      filteredCampaigns = filteredCampaigns.where((campaign) {
        final title = campaign.getLocalizedTitle(locale).toLowerCase();
        final description =
            campaign.getLocalizedDescription(locale).toLowerCase();
        final category = campaign.getLocalizedCategory(locale).toLowerCase();

        // Also search in all language versions for better search results
        final titleAr = campaign.titleAr.toLowerCase();
        final titleEn = campaign.titleEn.toLowerCase();
        final descriptionAr = campaign.descriptionAr.toLowerCase();
        final descriptionEn = campaign.descriptionEn.toLowerCase();
        final categoryAr = campaign.categoryAr.toLowerCase();
        final categoryEn = campaign.categoryEn.toLowerCase();

        return title.contains(searchQuery) ||
            titleAr.contains(searchQuery) ||
            titleEn.contains(searchQuery) ||
            description.contains(searchQuery) ||
            descriptionAr.contains(searchQuery) ||
            descriptionEn.contains(searchQuery) ||
            category.contains(searchQuery) ||
            categoryAr.contains(searchQuery) ||
            categoryEn.contains(searchQuery);
      }).toList();
    }

    if (!mounted) return;

    setState(() {
      _campaigns = filteredCampaigns;
    });
  }

  Widget? _buildSearchSuffixIcon() {
    if (_searchController.text.isNotEmpty) {
      return IconButton(
        icon: const Icon(
          Icons.clear,
          color: AppColors.textSecondary,
          size: 16,
        ),
        onPressed: () {
          _searchController.clear();
          _applyFilters();
        },
      );
    }
    return null;
  }

  Widget _buildFilterChip({required String id, required String label}) {
    final p = AppPalette.of(context);
    final isSelected = _selectedCategoryId == id;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: AppSpace.xs),
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            _applyCategoryFilter(id);
          },
          child: AnimatedContainer(
            duration: AppMotion.fast,
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? p.tint : p.fill,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              label,
              style: AppType.subheadline.copyWith(
                color: isSelected ? Colors.white : p.label,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeBody({
    required bool isAuthenticated,
    required Map<String, dynamic>? userProfile,
  }) {
    final p = AppPalette.of(context);
    final media = MediaQuery.of(context);
    final userName = userProfile?['name'] ?? userProfile?['user']?['name'];

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: _refreshHomeData),
        SliverToBoxAdapter(
          child: Stack(
            children: [
              // Soft brand wash behind the header; scrolls away with it.
              PositionedDirectional(
                top: 0,
                start: 0,
                end: 0,
                height: 360 + media.padding.top,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        p.tint.withValues(alpha: 0.16),
                        p.secondary.withValues(alpha: 0.07),
                        p.background.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: media.padding.top),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppReveal(
                      child: HomeHeader(
                        displayName:
                            isAuthenticated ? userName?.toString() : null,
                        onAvatarTap: isAuthenticated
                            ? () {
                                if (!MainShell.selectTab(context, 2)) {
                                  Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                      builder: (context) =>
                                          const SettingsScreen(),
                                    ),
                                  );
                                }
                              }
                            : _showLoginBottomSheet,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(
                        AppSpace.screen,
                        0,
                        AppSpace.screen,
                        MainShell.bottomReserve(context) + AppSpace.xl,
                      ),
                      child: _buildSheetContent(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSheetContent() {
    final p = AppPalette.of(context);
    final displayedCampaigns = _campaigns.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppReveal.staggered(
          index: 1,
          child: HomeQuickActions(
            onQuickDonate: _onQuickDonate,
            onCampaigns: _onViewAllCampaigns,
            onNews: _onFundNews,
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        AppReveal.staggered(index: 2, child: _buildSearchField()),
        const SizedBox(height: AppSpace.lg),
        AppReveal.staggered(index: 3, child: _buildStudentBannerCarousel()),
        const SizedBox(height: AppSpace.xl),
        AppReveal.staggered(
          index: 4,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'be_hope'.tr(),
                  style: AppType.title2.copyWith(color: p.label),
                ),
              ),
              if (_campaigns.isNotEmpty) _buildViewAllButton(),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        AppReveal.staggered(index: 5, child: _buildCategoryFilterSection()),
        const SizedBox(height: AppSpace.md),
        if (_isLoadingCampaigns && displayedCampaigns.isEmpty) ...const [
          CampaignCardSkeleton(),
          CampaignCardSkeleton(),
        ] else if (_campaigns.isEmpty)
          AppEmptyState(
            icon: CupertinoIcons.heart,
            message: 'no_active_campaigns'.tr(),
          )
        else
          ...displayedCampaigns.indexed.map(
            (entry) => AppReveal.staggered(
              index: 6 + entry.$1,
              child: CampaignCard(
                campaign: entry.$2,
                onTap: () => _onCampaignTap(entry.$2),
              ),
            ),
          ),
        const SizedBox(height: AppSpace.xl),
        Text(
          'recent_donations'.tr(),
          style: AppType.title2.copyWith(color: p.label),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        const SizedBox(height: AppSpace.sm),
        _buildRecentDonationsList(),
      ],
    );
  }

  Widget _buildSearchField() {
    final p = AppPalette.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      borderSide: BorderSide.none,
    );
    return TextField(
      controller: _searchController,
      style: AppType.body.copyWith(color: p.label),
      cursorColor: p.tint,
      onChanged: (_) => _applyFilters(),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'search'.tr(),
        hintStyle: AppType.body.copyWith(color: p.secondaryLabel),
        prefixIcon: Icon(
          CupertinoIcons.search,
          color: p.secondaryLabel,
          size: 20,
        ),
        suffixIcon: _buildSearchSuffixIcon(),
        isDense: true,
        border: border,
        enabledBorder: border,
        focusedBorder: border,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
      ),
    );
  }

  Widget _buildRecentDonationRow({
    required String title,
    required double amount,
    required String timeAgo,
    required bool isAnonymous,
  }) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: p.tint.withValues(alpha: 0.14),
            ),
            child: Icon(
              isAnonymous
                  ? CupertinoIcons.shield_fill
                  : CupertinoIcons.heart_fill,
              color: p.tint,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.body.copyWith(color: p.label),
                ),
                Text(
                  timeAgo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.footnote.copyWith(color: p.secondaryLabel),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Text(
            '${AppFormat.amount(amount)} ${'riyal'.tr()}',
            style: AppType.headline.copyWith(color: p.success),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentDonationsList() {
    final p = AppPalette.of(context);
    if (_isLoadingRecentDonations) {
      return const SizedBox(
        height: 150,
        child: Center(child: AppActivityIndicator()),
      );
    }

    if (_recentDonations.isEmpty) {
      return SizedBox(
        height: 150,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.heart, size: 44, color: p.tertiaryLabel),
              const SizedBox(height: AppSpace.md),
              Text(
                'no_donations_found'.tr(),
                style: AppType.subheadline.copyWith(color: p.secondaryLabel),
              ),
            ],
          ),
        ),
      );
    }

    final languageCode = context.locale.languageCode;
    final rows = <Widget>[];
    for (var i = 0; i < _recentDonations.length; i++) {
      final donation = _recentDonations[i];
      final campaignName =
          donation.getLocalizedCampaignName(languageCode)?.trim();
      final programName = donation.programName?.trim();
      final title = (campaignName != null && campaignName.isNotEmpty)
          ? campaignName
          : (programName != null && programName.isNotEmpty)
              ? programName
              : 'donor'.tr();

      if (i > 0) {
        rows.add(
          Divider(
            height: 0.5,
            thickness: 0.5,
            indent: AppSpace.md + 40 + AppSpace.sm,
            color: p.separator,
          ),
        );
      }
      rows.add(
        _buildRecentDonationRow(
          title: title,
          amount: donation.amount,
          timeAgo: _formatTimeAgo(donation.date),
          isAnonymous: donation.isAnonymous,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: ColoredBox(
        color: p.surface,
        child: Column(children: rows),
      ),
    );
  }

  Widget _buildViewAllButton() {
    final p = AppPalette.of(context);
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(44, 44),
      onPressed: _onViewAllCampaigns,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'view_all'.tr(),
            style: AppType.body.copyWith(color: p.tint),
          ),
          const SizedBox(width: 2),
          Icon(AppIcons.chevronForward, color: p.tint, size: 14),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return 'recently'.tr();

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day_ago'.tr() : 'days_ago'.tr()}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour_ago'.tr() : 'hours_ago'.tr()}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute_ago'.tr() : 'minutes_ago'.tr()}';
    } else {
      return 'recently'.tr();
    }
  }
}
