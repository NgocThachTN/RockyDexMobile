import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/colors.dart';
import '../../domain/comic_model.dart';

class ComicGridCard extends StatelessWidget {
  final ComicModel comic;

  const ComicGridCard({super.key, required this.comic});

  String _formatFollows(int follows) {
    if (follows >= 1000000) {
      return '${(follows / 1000000).toStringAsFixed(1)}M';
    } else if (follows >= 1000) {
      return '${(follows / 1000).toStringAsFixed(1)}k';
    }
    return follows.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final statusText = {
      'dang-phat-hanh': 'Đang phát hành',
      'ongoing': 'Đang phát hành',
      'hoan-thanh': 'Hoàn thành',
      'completed': 'Hoàn thành',
      'sap-ra-mat': 'Sắp ra mắt',
      'coming_soon': 'Sắp ra mắt',
      'truyen-moi': 'Truyện mới',
    }[comic.status] ?? 'Đang phát hành';

    final statusColor = {
      'dang-phat-hanh': AppColors.primaryBlue,
      'ongoing': AppColors.primaryBlue,
      'hoan-thanh': AppColors.success,
      'completed': AppColors.success,
      'sap-ra-mat': Colors.orange,
      'coming_soon': Colors.orange,
      'truyen-moi': Colors.purple,
    }[comic.status] ?? AppColors.primaryBlue;

    return GestureDetector(
      onTap: () => context.push('/comic/${comic.slug}'),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.withOpacity(0.18),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover Image block
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(11),
                  topRight: Radius.circular(11),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: comic.thumbUrl,
                      fit: BoxFit.cover,
                      fadeInDuration: const Duration(milliseconds: 250),
                      placeholder: (context, url) => Container(
                        color: isDark ? const Color(0xFF252525) : const Color(0xFFF0F0F0),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: isDark ? const Color(0xFF252525) : const Color(0xFFF0F0F0),
                        child: const Icon(Icons.broken_image, size: 28),
                      ),
                    ),
                    // Status Badge overlay
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          statusText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Metadata content block
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comic.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // First Genre Tag
                  if (comic.category.isNotEmpty)
                    Text(
                      comic.category.first.name,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: isDark ? Colors.white38 : Colors.black38,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    const SizedBox(height: 12),
                  const SizedBox(height: 4),
                  
                  // Rating and Follows
                  if (comic.rating != null || comic.followsCount != null) ...[
                    Row(
                      children: [
                        if (comic.rating != null) ...[
                          const Icon(Icons.star_rounded, size: 13, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            comic.rating!.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (comic.followsCount != null) ...[
                          Icon(
                            Icons.bookmark_rounded,
                            size: 11,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            _formatFollows(comic.followsCount!),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Latest Chapter Badge
                      if (comic.chaptersLatest != null && comic.chaptersLatest!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Ch. ${comic.chaptersLatest!.first.chapterName}',
                            style: const TextStyle(
                              color: AppColors.primaryBlue,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        const SizedBox.shrink(),

                      // Action button indicator
                      const Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
