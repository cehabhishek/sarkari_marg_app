import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../models/category_model.dart';
import '../models/post_model.dart';
import '../theme/app_theme.dart';
import '../widgets/category_grid_item.dart';
import '../services/ad_service.dart';
import 'detail_screen.dart';

class CategoryWiseScreen extends StatefulWidget {
  final CategoryModel? initialCategory;
  const CategoryWiseScreen({super.key, this.initialCategory});

  @override
  State<CategoryWiseScreen> createState() => _CategoryWiseScreenState();
}

class _CategoryWiseScreenState extends State<CategoryWiseScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<CategoryModel>> _categoriesFuture;

  CategoryModel? _selectedCategory;
  Future<List<PostModel>>? _postsFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _apiService.fetchCategories();
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory;
      _postsFuture = _apiService.fetchPostsByCategory(
        widget.initialCategory!.id.toString(),
      );
    }
  }

  void _selectCategory(CategoryModel cat) {
    setState(() {
      _selectedCategory = cat;
      _postsFuture = _apiService.fetchPostsByCategory(cat.id.toString());
    });
  }

  void _clearCategory() {
    setState(() {
      _selectedCategory = null;
      _postsFuture = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: _selectedCategory == null || widget.initialCategory != null,
      onPopInvoked: (didPop) {
        if (!didPop && _selectedCategory != null && widget.initialCategory == null) {
          _clearCategory();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        bottomNavigationBar: const BottomAdBanner(),
        appBar: _buildAppBar(isDark),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _selectedCategory == null
              ? _buildCategoryGrid(isDark)
              : _buildPostsList(isDark),
        ),
      ),
    );
  }

  // ───────── APP BAR ─────────
  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      elevation: 0,
      backgroundColor:
          isDark ? const Color(0xFF0F1923) : AppTheme.accentColor,
      leading: GestureDetector(
        onTap: () {
          if (_selectedCategory != null && widget.initialCategory == null) {
            _clearCategory();
          } else {
            Navigator.pop(context);
          }
        },
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_rounded,
              color: Colors.white, size: 20),
        ),
      ),
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            _selectedCategory?.name ?? 'Categories',
            key: ValueKey(_selectedCategory?.id ?? 'categories'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.baloo2(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // ───────── CATEGORY GRID ─────────
  Widget _buildCategoryGrid(bool isDark) {
    return FutureBuilder<List<CategoryModel>>(
      key: const ValueKey('grid'),
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildGridSkeleton(isDark);
        }
        if (snapshot.hasError) {
          return _buildErrorState('Categories load nahi ho ski', isDark);
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState('Koi category nahi mili', isDark);
        }

        final categories = snapshot.data!;

        return RefreshIndicator(
          color: AppTheme.accentColor,
          onRefresh: () async {
            setState(() {
              _categoriesFuture = _apiService.fetchCategories();
            });
            await _categoriesFuture;
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${categories.length} categories available',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  return CategoryGridItem(
                    category: categories[index],
                    index: index,
                    isDark: isDark,
                    onTap: () => _selectCategory(categories[index]),
                  );
                },
              ),
            ],
          ),
        ),
      );
      },
    );
  }

  // ───────── POSTS LIST ─────────
  Widget _buildPostsList(bool isDark) {
    return FutureBuilder<List<PostModel>>(
      key: ValueKey('posts_${_selectedCategory?.id}'),
      future: _postsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildPostsSkeleton(isDark);
        }
        if (snapshot.hasError) {
          return _buildErrorState('Posts load nahi ho ske', isDark);
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
              'Is category mein abhi koi post nahi hai', isDark);
        }

        final posts = snapshot.data!;

        return RefreshIndicator(
          color: AppTheme.accentColor,
          onRefresh: () async {
            if (_selectedCategory != null) {
              setState(() {
                _postsFuture = _apiService.fetchPostsByCategory(
                  _selectedCategory!.id.toString(),
                );
              });
              await _postsFuture;
            }
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final tile = _buildPostTile(posts[index], isDark);
              if (index > 0 && index % 4 == 0) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const FeedAdBanner(),
                    tile,
                  ],
                );
              }
              return tile;
            },
          ),
        );
      },
    );
  }

  // ───────── POST TILE ─────────
  Widget _buildPostTile(PostModel post, bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => DetailScreen(slug: post.slug)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
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
                      width: 68,
                      height: 68,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 68,
                        height: 68,
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
                          horizontal: 8, vertical: 2),
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
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 11, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          post.createdAt.split(' ')[0],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                              fontSize: 11, color: Colors.grey[500]),
                        ),
                      ),
                      if (post.state.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.location_on_rounded,
                            size: 11, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            post.state,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                                fontSize: 11, color: Colors.grey[500]),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _placeholderBox() {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.article_rounded,
          color: AppTheme.accentColor, size: 26),
    );
  }

  // ───────── GRID SKELETON ─────────
  Widget _buildGridSkeleton(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: 9,
        itemBuilder: (_, __) => _ShimmerBox(
          isDark: isDark,
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[300],
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  // ───────── POSTS SKELETON ─────────
  Widget _buildPostsSkeleton(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _shimmer(height: 68, width: 68, radius: 10, isDark: isDark),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _shimmer(height: 11, width: 70, isDark: isDark),
                  const SizedBox(height: 8),
                  _shimmer(
                      height: 13,
                      width: double.infinity,
                      isDark: isDark),
                  const SizedBox(height: 6),
                  _shimmer(height: 13, width: 160, isDark: isDark),
                  const SizedBox(height: 8),
                  _shimmer(height: 11, width: 120, isDark: isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmer(
      {required double height,
      required double width,
      double radius = 8,
      required bool isDark}) {
    return _ShimmerBox(
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

  // ───────── EMPTY STATE ─────────
  Widget _buildEmptyState(String message, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.nunito(
                fontSize: 15, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ───────── ERROR STATE ─────────
  Widget _buildErrorState(String message, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Kuch galat ho gaya!',
              style: GoogleFonts.baloo2(
                  fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.nunito(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => setState(() {
                _selectedCategory = null;
                _categoriesFuture = _apiService.fetchCategories();
              }),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Dobara Try Karo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────── SHIMMER BOX ─────────
class _ShimmerBox extends StatefulWidget {
  final Widget child;
  final bool isDark;
  const _ShimmerBox({required this.child, required this.isDark});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
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
    _animation = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
      builder: (_, __) => ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: widget.isDark
              ? [Colors.grey[800]!, Colors.grey[700]!, Colors.grey[800]!]
              : [Colors.grey[300]!, Colors.grey[100]!, Colors.grey[300]!],
          stops: const [0.0, 0.5, 1.0],
          transform: GradientRotation(_animation.value),
        ).createShader(bounds),
        child: widget.child,
      ),
    );
  }
}