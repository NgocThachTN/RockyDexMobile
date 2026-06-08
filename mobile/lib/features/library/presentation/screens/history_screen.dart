import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/storage/local_storage.dart';
import '../library_providers.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch Sử Đọc'),
        centerTitle: true,
        actions: [
          Consumer(
            builder: (context, ref, child) {
              return IconButton(
                icon: const Icon(Icons.delete_sweep_outlined),
                tooltip: 'Xóa lịch sử',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Xóa lịch sử'),
                      content: const Text('Bạn có chắc chắn muốn xóa toàn bộ lịch sử đọc truyện không?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Hủy'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(foregroundColor: AppColors.error),
                          child: const Text('Xóa'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await LocalStorage.clearHistory();
                    ref.invalidate(libraryHistoryProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã xóa toàn bộ lịch sử đọc'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                },
              );
            },
          ),
        ],
      ),
      body: const HistoryContent(),
    );
  }
}

class HistoryContent extends ConsumerWidget {
  const HistoryContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(libraryHistoryProvider);

    return RefreshIndicator(
        onRefresh: () async => ref.invalidate(libraryHistoryProvider),
        child: historyAsync.when(
          data: (list) {
            if (list.isEmpty) {
              return const Center(
                child: Text('Chưa có lịch sử đọc truyện'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final item = list[index];
                final slug = item['comic_slug'];
                final name = item['comic_name'];
                final thumb = item['comic_thumb'] ?? '';
                final chapName = item['chapter_name'];
                final progress = item['progress_percent'] as int? ?? 0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        // Thumb
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: CachedNetworkImage(
                            imageUrl: thumb,
                            width: 55,
                            height: 75,
                            fit: BoxFit.cover,
                            fadeInDuration: const Duration(milliseconds: 250),
                            errorWidget: (context, url, error) => Container(
                              width: 55,
                              height: 75,
                              color: Theme.of(context).scaffoldBackgroundColor,
                              child: const Icon(Icons.broken_image, size: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Đã đọc: Chương $chapName',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              // Progress Bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress / 100.0,
                                  backgroundColor: Theme.of(context).dividerColor,
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                                  minHeight: 4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Action Buttons
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.play_circle_outline, color: AppColors.primaryBlue, size: 28),
                              onPressed: () {
                                context.push('/comic/$slug');
                              },
                              tooltip: 'Đọc tiếp',
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline, color: Colors.grey[500], size: 24),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Xóa lịch sử'),
                                    content: Text('Bạn có chắc chắn muốn xóa "$name" khỏi lịch sử đọc không?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Hủy'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        style: TextButton.styleFrom(foregroundColor: AppColors.error),
                                        child: const Text('Xóa'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  await LocalStorage.deleteHistory(slug);
                                  ref.invalidate(libraryHistoryProvider);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Đã xóa "$name" khỏi lịch sử'),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                }
                              },
                              tooltip: 'Xóa khỏi lịch sử',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (err, stack) => Center(child: Text('Lỗi: $err')),
        ),
      );
    }
  }
