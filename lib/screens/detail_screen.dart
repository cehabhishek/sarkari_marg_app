import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../models/post_model.dart';
import '../theme/app_theme.dart';
import '../services/ad_service.dart';

class DetailScreen extends StatefulWidget {
  final String slug;
  const DetailScreen({super.key, required this.slug});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen>
    with SingleTickerProviderStateMixin {
  late Future<PostModel> _postFuture;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _postFuture = ApiService().fetchPostDetail(widget.slug);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open: $url'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  String? _extractApplyLink(String html) {
    final regex = RegExp(r'''https?://[^\s"'<>]+''');
    final match = regex.firstMatch(html);
    return match?.group(0);
  }

  static const Map<String, String> _btnColorMap = {
    'sm-btn-green':    '#2E7D32',
    'sm-btn-orange':   '#E65100',
    'sm-btn-blue':     '#1565C0',
    'sm-btn-yellow':   '#F57F17',
    'sm-btn-purple':   '#6A1B9A',
    'sm-btn-gray':     '#546E7A',
    'sm-btn-whatsapp': '#25D366',
    'sm-btn-telegram': '#0088CC',
    'sm-btn-facebook': '#1877F2',
  };

  String _decodeEntities(String input) {
    String r = input
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&nbsp;', ' ');
    r = r
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&nbsp;', ' ');
    return r;
  }

  String _cleanNonTableHtml(String html) {
    String result = html;

    result = result.replaceAllMapped(
      RegExp(r'<p\s+class="sm-status-green">(.*?)</p>', dotAll: true),
      (m) => '<p style="background:#e8f5e9;color:#2e7d32;padding:10px 14px;'
          'border-left:4px solid #2e7d32;border-radius:6px;font-weight:700;">'
          '${m.group(1)}</p>',
    );
    result = result.replaceAllMapped(
      RegExp(r'<p\s+class="sm-status-orange">(.*?)</p>', dotAll: true),
      (m) => '<p style="background:#fff3e0;color:#e65100;padding:10px 14px;'
          'border-left:4px solid #e65100;border-radius:6px;font-weight:700;">'
          '${m.group(1)}</p>',
    );
    result = result.replaceAllMapped(
      RegExp(r'<p\s+class="sm-status-red">(.*?)</p>', dotAll: true),
      (m) => '<p style="background:#ffebee;color:#c62828;padding:10px 14px;'
          'border-left:4px solid #c62828;border-radius:6px;font-weight:700;">'
          '${m.group(1)}</p>',
    );
    result = result.replaceAllMapped(
      RegExp(r'<p\s+class="sm-connect-title">(.*?)</p>', dotAll: true),
      (m) => '<p style="font-weight:800;font-size:16px;margin-top:16px;">${m.group(1)}</p>',
    );
    result = result.replaceAllMapped(
      RegExp(r'<p\s+class="sm-connect-sub">(.*?)</p>', dotAll: true),
      (m) => '<p style="color:gray;font-size:13px;">${m.group(1)}</p>',
    );
    result = result.replaceAllMapped(
      RegExp(r'<p\s+class="sm-connect-note">(.*?)</p>', dotAll: true),
      (m) => '<p style="color:gray;font-size:12px;">${m.group(1)}</p>',
    );
    result = result.replaceAllMapped(
      RegExp(r'<a\b([^>]*?)class="([^"]*sm-btn[^"]*)"([^>]*)>'),
      (match) {
        final before = match.group(1) ?? '';
        final classAttr = match.group(2) ?? '';
        final after = match.group(3) ?? '';
        String hexColor = '#1565C0';
        _btnColorMap.forEach((cls, clr) {
          if (classAttr.contains(cls)) hexColor = clr;
        });
        return '<a$before$after style="display:block;margin-bottom:8px;'
            'color:$hexColor;border:1.5px solid $hexColor;'
            'padding:10px 14px;border-radius:8px;font-weight:700;'
            'text-decoration:none;">';
      },
    );
    result = result.replaceAll(RegExp(r'''\s*class="sm-[^"]*"'''), '');
    result = result.replaceAll('&lt;br&gt;', '<br>');
    return result;
  }

  List<Map<String, String>> _splitIntoChunks(String html) {
    final chunks = <Map<String, String>>[];
    final tableRegex = RegExp(r'<table[\s\S]*?</table>', caseSensitive: false);
    int lastEnd = 0;
    for (final match in tableRegex.allMatches(html)) {
      if (match.start > lastEnd) {
        final before = html.substring(lastEnd, match.start).trim();
        if (before.isNotEmpty) chunks.add({'type': 'html', 'content': before});
      }
      chunks.add({'type': 'table', 'content': match.group(0)!});
      lastEnd = match.end;
    }
    if (lastEnd < html.length) {
      final after = html.substring(lastEnd).trim();
      if (after.isNotEmpty) chunks.add({'type': 'html', 'content': after});
    }
    return chunks;
  }

  List<List<String>> _parseTableRows(String tableHtml) {
    final rows = <List<String>>[];
    final rowRegex = RegExp(r'<tr[^>]*>([\s\S]*?)</tr>', caseSensitive: false);
    final cellRegex = RegExp(r'<t[dh][^>]*>([\s\S]*?)</t[dh]>', caseSensitive: false);
    for (final rowMatch in rowRegex.allMatches(tableHtml)) {
      final cells = <String>[];
      for (final cellMatch in cellRegex.allMatches(rowMatch.group(1)!)) {
        String cellText = cellMatch.group(1) ?? '';
        cellText = cellText.replaceAll(RegExp(r'<[^>]+>'), '').trim();
        cellText = cellText
            .replaceAll('&lt;', '<').replaceAll('&gt;', '>')
            .replaceAll('&amp;', '&').replaceAll('&quot;', '"')
            .replaceAll('&nbsp;', ' ').trim();
        cells.add(cellText);
      }
      if (cells.isNotEmpty) rows.add(cells);
    }
    return rows;
  }

  bool _hasHeader(String tableHtml) {
    return tableHtml.toLowerCase().contains('<thead') ||
        tableHtml.toLowerCase().contains('<th');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomNavigationBar: const BottomAdBanner(),
      body: FutureBuilder<PostModel>(
        future: _postFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildSkeleton(isDark);
          }
          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }
          if (!snapshot.hasData) {
            return _buildErrorState('Post not found');
          }
          _animController.forward();
          final post = snapshot.data!;
          return FadeTransition(
            opacity: _fadeAnim,
            child: _buildContent(post, isDark),
          );
        },
      ),
    );
  }

  // ───────── MAIN CONTENT ─────────
  Widget _buildContent(PostModel post, bool isDark) {
    return CustomScrollView(
      slivers: [
        // ── SliverAppBar — title always visible, share button removed ──
        SliverAppBar(
          expandedHeight: post.thumbnail != null ? 260 : 0,
          pinned: true,
          elevation: 0,
          backgroundColor:
              isDark ? const Color(0xFF0F1923) : AppTheme.accentColor,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          // ── Back button ──
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
          // ── Title — post.title hamesha dikhega ──
          title: Text(
            post.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.baloo2(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          // ── Thumbnail hai toh flexible space ──
          flexibleSpace: post.thumbnail != null
              ? FlexibleSpaceBar(
                  // Title FlexibleSpaceBar mein nahi — upar title property mein hai
                  titlePadding: EdgeInsets.zero,
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: post.thumbnail!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppTheme.accentColor.withValues(alpha: 0.1),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: AppTheme.accentColor.withValues(alpha: 0.2),
                          child: Icon(Icons.image_not_supported_rounded,
                              color: AppTheme.accentColor, size: 48),
                        ),
                      ),
                      // Gradient overlay — neeche se fade
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.3),
                              Colors.black.withOpacity(0.75),
                            ],
                            stops: const [0.0, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : null,
        ),

        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitleCard(post, isDark),
              const SizedBox(height: 12),
              _buildMetaInfoRow(post, isDark),
              const SizedBox(height: 16),
              _buildDescriptionSection(post, isDark),
              _buildDisclaimerBox(isDark),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }

  // ───────── TITLE CARD ─────────
  Widget _buildTitleCard(PostModel post, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.category != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.accentColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.folder_rounded, size: 12, color: AppTheme.accentColor),
                  const SizedBox(width: 5),
                  Text(
                    post.category!.name.toUpperCase(),
                    style: GoogleFonts.nunito(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.accentColor,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Text(
            post.title,
            style: GoogleFonts.baloo2(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.3,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  // ───────── META INFO ROW ─────────
  Widget _buildMetaInfoRow(PostModel post, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          if (post.state.isNotEmpty) ...[
            _MetaChip(
              icon: Icons.location_on_rounded,
              label: post.state,
              color: const Color(0xFF2E7D32),
            ),
            _verticalDivider(),
          ],
          _MetaChip(
            icon: Icons.calendar_today_rounded,
            label: _formatDate(post.createdAt),
            color: const Color(0xFF1565C0),
          ),
          if (post.featured == 1) ...[
            _verticalDivider(),
            _MetaChip(
              icon: Icons.star_rounded,
              label: 'Featured',
              color: const Color(0xFFF57F17),
            ),
          ],
        ],
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 28,
      color: Colors.grey.withOpacity(0.2),
      margin: const EdgeInsets.symmetric(horizontal: 10),
    );
  }

  // ───────── DESCRIPTION SECTION ─────────
  Widget _buildDescriptionSection(PostModel post, bool isDark) {
    final decoded = _decodeEntities(post.description);
    final cleaned = _cleanNonTableHtml(decoded);
    final chunks = _splitIntoChunks(cleaned);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(
                bottom: BorderSide(color: AppTheme.accentColor.withOpacity(0.15)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.description_rounded,
                      color: AppTheme.accentColor, size: 16),
                ),
                const SizedBox(width: 10),
                Text(
                  'Full Details',
                  style: GoogleFonts.baloo2(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ),

          // Chunks
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: chunks.map((chunk) {
                if (chunk['type'] == 'table') {
                  return _buildCustomTable(chunk['content']!, isDark);
                } else {
                  return _buildHtmlBlock(chunk['content']!, isDark);
                }
              }).toList(),
            ),
          ),

          // Apply Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final applyLink = _extractApplyLink(post.description);
                  if (applyLink == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('No apply link found in description'),
                        backgroundColor: Colors.red[700],
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  _launchURL(applyLink);
                },
                icon: const Icon(Icons.open_in_browser_rounded, size: 18),
                label: Text(
                  'Apply Online',
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────── HTML BLOCK ─────────
  Widget _buildHtmlBlock(String html, bool isDark) {
    if (html.trim().isEmpty) return const SizedBox.shrink();
    return Html(
      data: html,
      style: {
        'body': Style(
          fontSize: FontSize(14.5),
          fontFamily: GoogleFonts.nunito().fontFamily,
          lineHeight: LineHeight(1.7),
          color: isDark ? Colors.grey[200] : Colors.grey[850],
          margin: Margins.zero,
          padding: HtmlPaddings.symmetric(horizontal: 12, vertical: 4),
        ),
        'h1': Style(
          fontSize: FontSize(20), fontWeight: FontWeight.w800,
          fontFamily: GoogleFonts.baloo2().fontFamily,
          color: Theme.of(context).textTheme.bodyLarge?.color,
          margin: Margins.only(top: 16, bottom: 8),
        ),
        'h2': Style(
          fontSize: FontSize(18), fontWeight: FontWeight.w700,
          fontFamily: GoogleFonts.baloo2().fontFamily,
          color: Theme.of(context).textTheme.bodyLarge?.color,
          margin: Margins.only(top: 14, bottom: 6),
        ),
        'h3': Style(
          fontSize: FontSize(16), fontWeight: FontWeight.w700,
          fontFamily: GoogleFonts.baloo2().fontFamily,
          color: AppTheme.accentColor,
          margin: Margins.only(top: 12, bottom: 6),
        ),
        'p': Style(margin: Margins.only(bottom: 10)),
        'a': Style(
          color: AppTheme.accentColor,
          textDecoration: TextDecoration.underline,
          fontWeight: FontWeight.w600,
        ),
        'ul': Style(margin: Margins.only(left: 8, bottom: 8)),
        'ol': Style(margin: Margins.only(left: 8, bottom: 8)),
        'li': Style(
          margin: Margins.only(bottom: 4),
          color: isDark ? Colors.grey[200] : Colors.grey[800],
        ),
        'strong': Style(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
        'blockquote': Style(
          border: Border(left: BorderSide(color: AppTheme.accentColor, width: 3)),
          padding: HtmlPaddings.only(left: 12, top: 4, bottom: 4),
          margin: Margins.only(bottom: 12),
          color: isDark ? Colors.grey[400] : Colors.grey[600],
          fontStyle: FontStyle.italic,
        ),
        'img': Style(width: Width(double.infinity)),
        'hr': Style(
          border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1)),
          margin: Margins.symmetric(vertical: 12),
        ),
      },
      extensions: [
        TagExtension(
          tagsToExtend: {'a'},
          builder: (extensionContext) {
            final href = extensionContext.attributes['href'];
            final styleAttr = extensionContext.attributes['style'] ?? '';
            final innerText = extensionContext.element?.text ??
                extensionContext.innerHtml ?? '';
            final isBtn = styleAttr.contains('display:block');

            if (isBtn) {
              Color btnColor = AppTheme.accentColor;
              final colorMatch =
                  RegExp(r'color:(#[0-9A-Fa-f]{6})').firstMatch(styleAttr);
              if (colorMatch != null) {
                try {
                  final hex = colorMatch.group(1)!.replaceAll('#', '');
                  btnColor = Color(int.parse('FF$hex', radix: 16));
                } catch (_) {}
              }
              return GestureDetector(
                onTap: () => href != null ? _launchURL(href) : null,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: btnColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: btnColor.withOpacity(0.4), width: 1.2),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.open_in_new_rounded, color: btnColor, size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          innerText,
                          style: GoogleFonts.nunito(
                            fontSize: 13, fontWeight: FontWeight.w700, color: btnColor,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: btnColor.withOpacity(0.6), size: 18),
                    ],
                  ),
                ),
              );
            }

            return GestureDetector(
              onTap: () => href != null ? _launchURL(href) : null,
              child: Text(
                innerText,
                style: TextStyle(
                  color: AppTheme.accentColor,
                  decoration: TextDecoration.underline,
                  decorationColor: AppTheme.accentColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.5,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ───────── CUSTOM TABLE ─────────
  Widget _buildCustomTable(String tableHtml, bool isDark) {
    final rows = _parseTableRows(tableHtml);
    if (rows.isEmpty) return const SizedBox.shrink();

    final hasHeader = _hasHeader(tableHtml);
    final headerRow = hasHeader ? rows.first : null;
    final bodyRows = hasHeader ? rows.skip(1).toList() : rows;

    final borderColor =
        isDark ? Colors.grey.withOpacity(0.3) : Colors.grey.withOpacity(0.25);
    final evenRowBg = isDark
        ? Colors.white.withOpacity(0.03)
        : Colors.grey.withOpacity(0.04);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (headerRow != null)
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.12),
                    border: Border(bottom: BorderSide(color: borderColor, width: 1)),
                  ),
                  child: Row(
                    children: headerRow.asMap().entries.map((entry) {
                      final isLast = entry.key == headerRow.length - 1;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          border: isLast
                              ? null
                              : Border(right: BorderSide(color: borderColor, width: 1)),
                        ),
                        constraints: const BoxConstraints(minWidth: 80),
                        child: Text(
                          entry.value,
                          style: GoogleFonts.nunito(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.accentColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ...bodyRows.asMap().entries.map((rowEntry) {
                final isEven = rowEntry.key % 2 == 0;
                final isLast = rowEntry.key == bodyRows.length - 1;
                final cells = rowEntry.value;
                return Container(
                  decoration: BoxDecoration(
                    color: isEven ? evenRowBg : Colors.transparent,
                    border: isLast
                        ? null
                        : Border(bottom: BorderSide(color: borderColor, width: 1)),
                  ),
                  child: Row(
                    children: cells.asMap().entries.map((cellEntry) {
                      final isCellLast = cellEntry.key == cells.length - 1;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          border: isCellLast
                              ? null
                              : Border(right: BorderSide(color: borderColor, width: 1)),
                        ),
                        constraints: const BoxConstraints(minWidth: 80),
                        child: Text(
                          cellEntry.value,
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.grey[300] : Colors.grey[800],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }).toList(),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ───────── DISCLAIMER & SOURCE BOX ─────────
  Widget _buildDisclaimerBox(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFFF59E0B).withOpacity(0.4) : const Color(0xFFF59E0B),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_outlined, color: Color(0xFFD97706), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Disclaimer & Official Source',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Sarkari Marg is an independent private informational app and does NOT represent any government entity. Information is gathered from official government portals listed in the App Settings & Play Store description (upsc.gov.in, ssc.gov.in, indianrailways.gov.in, ncs.gov.in, employmentnews.gov.in, ibps.in). Candidates must always verify details on the respective official government portal before applying.',
            style: GoogleFonts.nunito(
              fontSize: 13.5,
              height: 1.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF78350F),
            ),
          ),
        ],
      ),
    );
  }

  // ───────── SKELETON ─────────
  Widget _buildSkeleton(bool isDark) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 260,
          pinned: true,
          backgroundColor:
              isDark ? const Color(0xFF0F1923) : AppTheme.accentColor,
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
          title: Text(
            'Loading...',
            style: GoogleFonts.baloo2(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: _shimmerBox(
              height: double.infinity,
              width: double.infinity,
              radius: 0,
              isDark: isDark,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _shimmerBox(height: 22, width: 100, isDark: isDark),
                      const SizedBox(height: 12),
                      _shimmerBox(height: 24, width: double.infinity, isDark: isDark),
                      const SizedBox(height: 8),
                      _shimmerBox(height: 24, width: double.infinity, isDark: isDark),
                      const SizedBox(height: 8),
                      _shimmerBox(height: 24, width: 200, isDark: isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      _shimmerBox(height: 16, width: 80, isDark: isDark),
                      const SizedBox(width: 20),
                      _shimmerBox(height: 16, width: 80, isDark: isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _shimmerBox(height: 18, width: 120, isDark: isDark),
                      const SizedBox(height: 16),
                      ...List.generate(
                        6,
                        (i) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _shimmerBox(
                            height: 14,
                            width: i % 3 == 2 ? 200 : double.infinity,
                            isDark: isDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _shimmerBox({
    required double height,
    required double width,
    double radius = 8,
    required bool isDark,
  }) {
    return _ShimmerWidget(
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

  Widget _buildErrorState(String message) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.accentColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Post Detail',
            style: GoogleFonts.baloo2(color: Colors.white)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Kuch galat ho gaya!',
                style: GoogleFonts.baloo2(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(message,
                style: GoogleFonts.nunito(color: Colors.grey[500]),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Go Back'),
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

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      const months = [
        'Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return dateStr.split(' ')[0];
    }
  }
}

// ───────── META CHIP ─────────
class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MetaChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.nunito(
                  fontSize: 12, fontWeight: FontWeight.w700, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────── SHIMMER ─────────
class _ShimmerWidget extends StatefulWidget {
  final Widget child;
  const _ShimmerWidget({required this.child});

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: isDark
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