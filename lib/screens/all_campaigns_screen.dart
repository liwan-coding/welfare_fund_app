import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons, CupertinoPageRoute;
import 'package:easy_localization/easy_localization.dart';
import '../design/design.dart';
import '../models/campaign.dart';
import '../services/campaign_service.dart';
import '../widgets/common/campaign_card.dart';
import 'campaign_donation_screen.dart';

class AllCampaignsScreen extends StatefulWidget {
  final List<Campaign> initialCampaigns;

  const AllCampaignsScreen({
    super.key,
    required this.initialCampaigns,
  });

  @override
  State<AllCampaignsScreen> createState() => _AllCampaignsScreenState();
}

class _AllCampaignsScreenState extends State<AllCampaignsScreen> {
  final CampaignService _campaignService = CampaignService();
  final TextEditingController _searchController = TextEditingController();
  static const String _allCategoryKey = '__all__';

  List<Campaign> _campaigns = [];
  List<Campaign> _filteredCampaigns = [];
  List<String> _categories = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _selectedCategory = _allCategoryKey;

  @override
  void initState() {
    super.initState();
    _campaigns = List<Campaign>.from(widget.initialCampaigns);
    if (_campaigns.isEmpty) {
      _isLoading = true;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Deferred: category labels depend on context.locale.
      setState(() {
        _updateCategories(_campaigns);
        _filteredCampaigns = _applyFilter(_searchController.text, _campaigns);
      });
      _fetchAllCampaigns();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllCampaigns() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final campaigns = await _campaignService.getCharityCampaigns();
      if (!mounted) return;

      setState(() {
        _campaigns = campaigns;
        _filteredCampaigns = _applyFilter(_searchController.text, campaigns);
        _isLoading = false;
        _updateCategories(campaigns);
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _hasError = true;
      });
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

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          AppNavBar(
            title: 'all_campaigns'.tr(),
            actions: [
              IconButton(
                tooltip: 'retry'.tr(),
                onPressed: _isLoading ? null : _fetchAllCampaigns,
                icon: const Icon(CupertinoIcons.refresh),
                color: AppPalette.of(context).tint,
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
            sliver: SliverToBoxAdapter(
              child: AppSearchField(
                controller: _searchController,
                hint: 'search_campaigns_placeholder'.tr(),
                onChanged: _onSearchChanged,
              ),
            ),
          ),
          if (_categories.length > 1)
            SliverPadding(
              padding: const EdgeInsets.only(top: AppSpace.sm),
              sliver: SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpace.screen),
                  child: AppChipBar(
                    labels: [
                      for (final c in _categories)
                        c == _allCategoryKey ? 'all'.tr() : c,
                    ],
                    selectedIndex: _categories
                        .indexOf(_selectedCategory)
                        .clamp(0, _categories.length - 1),
                    onSelected: (i) => _onCategorySelected(_categories[i]),
                  ),
                ),
              ),
            ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppSpace.screen,
              AppSpace.md,
              AppSpace.screen,
              AppSpace.xl + bottomInset,
            ),
            sliver: _buildCampaignList(),
          ),
        ],
      ),
    );
  }

  void _updateCategories(List<Campaign> campaigns) {
    final locale = context.locale.languageCode;
    final categorySet = <String>{};
    for (final campaign in campaigns) {
      final category = campaign.getLocalizedCategory(locale).trim();
      if (category.isNotEmpty) {
        categorySet.add(category);
      }
    }
    final sortedCategories = categorySet.toList()
      ..sort((a, b) => a.compareTo(b));

    _categories = [_allCategoryKey, ...sortedCategories];

    if (_selectedCategory != _allCategoryKey &&
        !_categories.contains(_selectedCategory)) {
      _selectedCategory = _allCategoryKey;
    }
  }

  Widget _buildCampaignList() {
    if (_isLoading && _campaigns.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: AppActivityIndicator()),
      );
    }

    if (_hasError && _campaigns.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: AppEmptyState(
          icon: CupertinoIcons.wifi_slash,
          message: 'error_loading_campaigns'.tr(),
          actionLabel: 'retry'.tr(),
          onAction: _fetchAllCampaigns,
        ),
      );
    }

    if (_campaigns.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: AppEmptyState(
          icon: CupertinoIcons.heart,
          message: 'no_campaigns_available'.tr(),
        ),
      );
    }

    if (_filteredCampaigns.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: AppEmptyState(
          icon: CupertinoIcons.search,
          message: 'no_campaigns_match_search'.tr(),
        ),
      );
    }

    return SliverList.builder(
      itemCount: _filteredCampaigns.length,
      itemBuilder: (context, i) => CampaignCard(
        campaign: _filteredCampaigns[i],
        onTap: () => _onCampaignTap(_filteredCampaigns[i]),
      ),
    );
  }

  void _onSearchChanged(String query) {
    final filtered = _applyFilter(query, _campaigns);
    setState(() {
      _filteredCampaigns = filtered;
    });
  }

  void _onCategorySelected(String category) {
    if (_selectedCategory == category) return;
    setState(() {
      _selectedCategory = category;
      _filteredCampaigns = _applyFilter(_searchController.text, _campaigns);
    });
  }

  List<Campaign> _applyFilter(String query, List<Campaign> source) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return source.where(_matchesSelectedCategory).toList();
    }

    return source.where((campaign) {
      final title = campaign.title.toLowerCase();
      final titleAr = campaign.titleAr.toLowerCase();
      final titleEn = campaign.titleEn.toLowerCase();
      final description = campaign.description.toLowerCase();
      final descriptionAr = campaign.descriptionAr.toLowerCase();
      final descriptionEn = campaign.descriptionEn.toLowerCase();
      final matchesQuery = title.contains(normalized) ||
          titleAr.contains(normalized) ||
          titleEn.contains(normalized) ||
          description.contains(normalized) ||
          descriptionAr.contains(normalized) ||
          descriptionEn.contains(normalized);
      return matchesQuery && _matchesSelectedCategory(campaign);
    }).toList();
  }

  bool _matchesSelectedCategory(Campaign campaign) {
    if (_selectedCategory == _allCategoryKey) return true;
    final locale = context.locale.languageCode;
    final campaignCategory = campaign.getLocalizedCategory(locale).trim();
    return campaignCategory == _selectedCategory;
  }
}
