import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';
import '../models/post_model.dart';
import '../models/category_model.dart';
import 'category_wise_screen.dart';
import 'state_wise_screen.dart';
import 'detail_screen.dart';
import 'settings_screen.dart';
import 'search_screen.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late Future<List<CategoryModel>> _categoriesFuture;
  late Future<List<PostModel>> _latestPostsFuture;
  late Future<List<_CategoryPostsGroup>> _categoryPostsFuture;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  int _currentNavIndex = 0;

  static const String _whatsappChannelUrl =
      'https://whatsapp.com/channel/0029VaPqIm08aKvR2DyQ0V44';

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _apiService.fetchCategories();
    _latestPostsFuture = _apiService.fetchLatestPosts();
    _categoryPostsFuture = _loadCategoryPosts();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _openWhatsApp() async {
    final uri = Uri.parse(_whatsappChannelUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp channel open nahi ho saka')),
        );
      }
    }
  }

  Future<List<_CategoryPostsGroup>> _loadCategoryPosts() async {
    final categories = await _categoriesFuture;
    final groups = await Future.wait(
      categories.map((category) async {
        List<PostModel> posts = [];
        try {
          posts = await _apiService.fetchPostsByCategory(
            category.id.toString(),
          );
        } catch (_) {
          posts = [];
        }
        return _CategoryPostsGroup(
          category: category,
          posts: posts.take(5).toList(),
        );
      }),
    );
    return groups.where((group) => group.posts.isNotEmpty).toList();
  }

  Future<void> _refreshData() async {
    setState(() {
      _categoriesFuture = _apiService.fetchCategories();
      _latestPostsFuture = _apiService.fetchLatestPosts();
      _categoryPostsFuture = _loadCategoryPosts();
    });
    await Future.wait([
      _categoriesFuture,
      _latestPostsFuture,
      _categoryPostsFuture,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: RefreshIndicator(
          color: AppTheme.accentColor,
          backgroundColor: Theme.of(context).cardColor,
          onRefresh: _refreshData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildSliverAppBar(isDark, themeProvider),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSearchBarBanner(isDark),
                      _buildFeaturedSection(isDark),
                      const SizedBox(height: 20),
                      _buildWhatsAppBanner(),
                      const SizedBox(height: 24),
                      _buildCategorySection(isDark),
                      const SizedBox(height: 24),
                      _buildCategoryPostsSection(isDark),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(isDark),
    );
  }

  // ───────── SLIVER APP BAR ─────────
  Widget _buildSliverAppBar(bool isDark, ThemeProvider themeProvider) {
    return SliverAppBar(
      expandedHeight: 0,
      pinned: true,
      floating: false,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: isDark
          ? const Color(0xFF0F1923)
          : const Color(0xFF1565C0),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Sarkari Marg',
            style: GoogleFonts.baloo2(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            themeProvider.isDarkMode
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded,
            color: Colors.white,
          ),
          onPressed: () => themeProvider.toggleTheme(),
        ),
        IconButton(
          icon: const Icon(Icons.search_rounded, color: Colors.white),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SearchScreen()),
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ───────── SEARCH BAR BANNER ─────────
  Widget _buildSearchBarBanner(bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SearchScreen()),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: AppTheme.accentColor, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Search jobs, admit card, result...',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Search',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accentColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────── SECTION HEADER ─────────
  Widget _sectionHeader(
    String title,
    Color barColor, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.baloo2(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel,
                style: GoogleFonts.nunito(
                  color: AppTheme.accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ───────── SHIMMER HELPER ─────────
  Widget _shimmer({
    required double height,
    required double width,
    double radius = 8,
    required bool isDark,
  }) {
    return _ShimmerWidget(
      isDark: isDark,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[300],
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  // ───────── FEATURED SKELETON ─────────
  Widget _buildFeaturedSkeleton(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: _shimmer(height: 22, width: 140, isDark: isDark),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: 3,
            itemBuilder: (_, i) => Container(
              width: MediaQuery.of(context).size.width * 0.82,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              child: _ShimmerWidget(
                isDark: isDark,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ───────── CATEGORY SKELETON ─────────
  Widget _buildCategorySkeleton(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: _shimmer(height: 22, width: 180, isDark: isDark),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: 6,
            itemBuilder: (_, i) => Container(
              width: 82,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: _ShimmerWidget(
                isDark: isDark,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ───────── POST TILE SKELETON ─────────
  Widget _buildPostTileSkeleton(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _shimmer(height: 70, width: 70, radius: 10, isDark: isDark),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmer(height: 12, width: 70, isDark: isDark),
                const SizedBox(height: 8),
                _shimmer(height: 14, width: double.infinity, isDark: isDark),
                const SizedBox(height: 6),
                _shimmer(height: 14, width: 180, isDark: isDark),
                const SizedBox(height: 8),
                _shimmer(height: 11, width: 120, isDark: isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────── CATEGORY POSTS GROUP SKELETON ─────────
  Widget _buildCategoryGroupSkeleton(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _shimmer(height: 22, width: 160, isDark: isDark),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: List.generate(3, (_) => _buildPostTileSkeleton(isDark)),
            ),
          ),
        ],
      ),
    );
  }

  // ───────── FEATURED SECTION ─────────
  Widget _buildFeaturedSection(bool isDark) {
    return FutureBuilder<List<PostModel>>(
      future: _latestPostsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildFeaturedSkeleton(isDark);
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final featuredPosts = snapshot.data!.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Featured Posts',
                    style: GoogleFonts.baloo2(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 200,
              child: PageView.builder(
                controller: PageController(viewportFraction: 0.88),
                itemCount: featuredPosts.length,
                itemBuilder: (context, index) {
                  final post = featuredPosts[index];
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailScreen(slug: post.slug),
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: post.thumbnail != null
                            ? DecorationImage(
                                image: NetworkImage(post.thumbnail!),
                                fit: BoxFit.cover,
                                colorFilter: ColorFilter.mode(
                                  Colors.black.withOpacity(0.45),
                                  BlendMode.darken,
                                ),
                              )
                            : null,
                        gradient: post.thumbnail == null
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppTheme.accentColor,
                                  AppTheme.accentColor.withOpacity(0.6),
                                ],
                              )
                            : null,
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(16),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.8),
                                  ],
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (post.category != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      margin: const EdgeInsets.only(bottom: 6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.accentColor,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        post.category!.name.toUpperCase(),
                                        style: GoogleFonts.nunito(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ),
                                  Text(
                                    post.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.nunito(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'NEW',
                                style: GoogleFonts.nunito(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ───────── WHATSAPP BANNER ─────────
  Widget _buildWhatsAppBanner() {
    return GestureDetector(
      onTap: _openWhatsApp,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF25D366), Color(0xFF128C7E)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF25D366).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.groups_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Join WhatsApp Channel',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Instant job alerts & updates pao',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Join Now',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF128C7E),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────── CATEGORY SECTION ─────────
  Widget _buildCategorySection(bool isDark) {
    return FutureBuilder<List<CategoryModel>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildCategorySkeleton(isDark);
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final categories = snapshot.data!;
        final List<Map<String, dynamic>> categoryIcons = [
          {'icon': Icons.work_rounded, 'color': const Color(0xFF1565C0)},
          {'icon': Icons.assignment_rounded, 'color': const Color(0xFF6A1B9A)},
          {'icon': Icons.school_rounded, 'color': const Color(0xFFE65100)},
          {'icon': Icons.verified_rounded, 'color': const Color(0xFF2E7D32)},
          {
            'icon': Icons.military_tech_rounded,
            'color': const Color(0xFFC62828),
          },
          {
            'icon': Icons.account_balance_rounded,
            'color': const Color(0xFF00695C),
          },
          {
            'icon': Icons.local_hospital_rounded,
            'color': const Color(0xFFAD1457),
          },
          {'icon': Icons.engineering_rounded, 'color': const Color(0xFF4527A0)},
          {
            'icon': Icons.local_police_rounded,
            'color': const Color(0xFF283593),
          },
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(
              'Browse by Category',
              const Color(0xFF6A1B9A),
              actionLabel: 'See All',
              onAction: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CategoryWiseScreen()),
              ),
            ),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final iconData = categoryIcons[index % categoryIcons.length];
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CategoryWiseScreen(initialCategory: cat),
                      ),
                    ),
                    child: Container(
                      width: 82,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: (iconData['color'] as Color).withOpacity(
                                0.12,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              iconData['icon'] as IconData,
                              color: iconData['color'] as Color,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              cat.name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.nunito(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ───────── CATEGORY POSTS SECTION ─────────
  Widget _buildCategoryPostsSection(bool isDark) {
    return FutureBuilder<List<_CategoryPostsGroup>>(
      future: _categoryPostsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // 2 group skeletons dikhao
          return Column(
            children: List.generate(
              2,
              (_) => _buildCategoryGroupSkeleton(isDark),
            ),
          );
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Posts load nahi ho sake'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No posts found'));
        }

        final groups = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: groups.map(_buildCategoryPostsGroup).toList(),
        );
      },
    );
  }

  Widget _buildCategoryPostsGroup(_CategoryPostsGroup group) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            group.category.name,
            Colors.orange,
            actionLabel: 'View All',
            onAction: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CategoryWiseScreen(initialCategory: group.category),
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: group.posts.length,
            itemBuilder: (context, index) {
              return _buildPostListTile(group.posts[index]);
            },
          ),
        ],
      ),
    );
  }

  // ───────── POST LIST TILE ─────────
  Widget _buildPostListTile(PostModel post) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailScreen(slug: post.slug)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: post.thumbnail != null && post.thumbnail!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: post.thumbnail!,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 70,
                        height: 70,
                        color: Colors.grey.withValues(alpha: 0.15),
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => _placeholderBox(),
                    )
                  : _placeholderBox(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.category != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        post.category!.name,
                        style: GoogleFonts.nunito(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.accentColor,
                        ),
                      ),
                    ),
                  Text(
                    post.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // ── Fixed overflow row ──
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 11,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          post.createdAt.split(' ')[0],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                      if (post.state.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.location_on_rounded,
                          size: 11,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            post.state,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderBox() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.article_rounded, color: AppTheme.accentColor, size: 28),
    );
  }

  // ───────── BOTTOM NAV ─────────
  Widget _buildBottomNav(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
              _navItem(
                1,
                Icons.grid_view_rounded,
                Icons.grid_view_outlined,
                'Categories',
              ),
              _navItem(
                2,
                Icons.location_city_rounded,
                Icons.location_city_outlined,
                'States',
              ),
              _navItem(
                3,
                Icons.settings_rounded,
                Icons.settings_outlined,
                'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
  ) {
    final isActive = _currentNavIndex == index;
    return GestureDetector(
      onTap: () async {
        if (index == 0) {
          setState(() => _currentNavIndex = 0);
          return;
        }
        setState(() => _currentNavIndex = index);
        if (index == 1) {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CategoryWiseScreen()),
          );
        } else if (index == 2) {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StateWiseScreen()),
          );
        } else if (index == 3) {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          );
        }
        if (mounted) {
          setState(() => _currentNavIndex = 0);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.accentColor.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : inactiveIcon,
              color: isActive ? AppTheme.accentColor : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppTheme.accentColor : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────── DATA CLASS ─────────
class _CategoryPostsGroup {
  final CategoryModel category;
  final List<PostModel> posts;
  const _CategoryPostsGroup({required this.category, required this.posts});
}

// ───────── SHIMMER WIDGET ─────────
class _ShimmerWidget extends StatefulWidget {
  final Widget child;
  final bool isDark;
  const _ShimmerWidget({required this.child, required this.isDark});

  @override
  State<_ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<_ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _animation = Tween<double>(
      begin: -1.5,
      end: 1.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: widget.isDark
                  ? [Colors.grey[800]!, Colors.grey[700]!, Colors.grey[800]!]
                  : [Colors.grey[300]!, Colors.grey[100]!, Colors.grey[300]!],
              stops: const [0.0, 0.5, 1.0],
              transform: GradientRotation(_animation.value),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}
