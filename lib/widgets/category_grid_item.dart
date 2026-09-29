import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/category_model.dart';

class CategoryGridItem extends StatelessWidget {
  final CategoryModel category;
  final int index;
  final bool isDark;
  final VoidCallback onTap;

  const CategoryGridItem({
    super.key,
    required this.category,
    required this.index,
    required this.isDark,
    required this.onTap,
  });

  static const List<Map<String, dynamic>> _iconMap = [
    {'icon': Icons.work_rounded,            'color': Color(0xFF1565C0)},
    {'icon': Icons.assignment_rounded,      'color': Color(0xFF6A1B9A)},
    {'icon': Icons.school_rounded,          'color': Color(0xFFE65100)},
    {'icon': Icons.verified_rounded,        'color': Color(0xFF2E7D32)},
    {'icon': Icons.military_tech_rounded,   'color': Color(0xFFC62828)},
    {'icon': Icons.account_balance_rounded, 'color': Color(0xFF00695C)},
    {'icon': Icons.local_hospital_rounded,  'color': Color(0xFFAD1457)},
    {'icon': Icons.engineering_rounded,     'color': Color(0xFF4527A0)},
    {'icon': Icons.local_police_rounded,    'color': Color(0xFF283593)},
    {'icon': Icons.gavel_rounded,           'color': Color(0xFF4E342E)},
    {'icon': Icons.science_rounded,         'color': Color(0xFF00838F)},
    {'icon': Icons.agriculture_rounded,     'color': Color(0xFF558B2F)},
  ];

  @override
  Widget build(BuildContext context) {
    final iconData = _iconMap[index % _iconMap.length];
    final Color color = iconData['color'] as Color;
    final IconData icon = iconData['icon'] as IconData;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon circle
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            // Name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                category.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}