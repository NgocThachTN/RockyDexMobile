import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../../../../core/constants/colors.dart';
import '../../../comic/data/comic_repository.dart';
import '../../domain/chapter_detail_model.dart';
import '../reader_providers.dart';
import '../../../comic/presentation/comic_detail_providers.dart';
import '../../../comic/domain/comic_detail_model.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final String comicSlug;
  final String chapterSlug;
  final String? apiDataUrl;

  const ReaderScreen({
    super.key,
    required this.comicSlug,
    required this.chapterSlug,
    this.apiDataUrl,
  });

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  bool _showUI = true;
  int _currentPage = 1;
  int _totalPages = 1;
  late final ScrollController _scrollController;
  late final PageController _pageController;
  bool _imagesPrecached = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _pageController = PageController();

    // Enter fullscreen mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // Exit fullscreen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      if (maxScroll > 0) {
        final progress = (currentScroll / maxScroll * 100).toInt();
        final page = ((currentScroll / maxScroll) * _totalPages).clamp(1, _totalPages).toInt();

        if (page != _currentPage) {
          setState(() {
            _currentPage = page;
          });
        }

        // Throttle/Save progress periodically
        _saveReadingProgress(progress);
      }
    }
  }

  Future<void> _precacheAllImages(List<String> urls) async {
    if (!mounted) return;
    // Precache first 3 pages immediately
    for (int i = 0; i < urls.length && i < 3; i++) {
      if (!mounted) return;
      precacheImage(CachedNetworkImageProvider(urls[i]), context);
    }
    // Precache the rest sequentially with a 250ms delay to prevent network congestion
    for (int i = 3; i < urls.length; i++) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      precacheImage(CachedNetworkImageProvider(urls[i]), context);
    }
  }

  void _saveReadingProgress(int progressPercent) {
    final apiDataUrl = widget.apiDataUrl ?? '';
    final chapterState = ref.read(readerChapterDetailProvider(apiDataUrl));
    final comicDetailState = ref.read(comicDetailProvider(widget.comicSlug));

    String comicName = widget.comicSlug.replaceAll('-', ' ');
    String chapterName = widget.chapterSlug.replaceAll('chap-', '');
    String comicThumb = '';

    if (chapterState.hasValue) {
      final chapter = chapterState.value!;
      comicName = chapter.item.comicName;
      chapterName = chapter.item.chapterName;
    }

    if (comicDetailState.hasValue) {
      comicThumb = comicDetailState.value!.thumbUrl;
    }

    // Save to repositories (local & remote)
    ref.read(comicRepositoryProvider).saveHistory(
          comicSlug: widget.comicSlug,
          comicName: comicName,
          comicThumb: comicThumb,
          chapterSlug: widget.chapterSlug,
          chapterName: chapterName,
          progressPercent: progressPercent,
        );
  }

  void _toggleUI() {
    setState(() {
      _showUI = !_showUI;
    });
  }

  @override
  Widget build(BuildContext context) {
    // If apiDataUrl is missing, we fetch it by fallback.
    // However, it is always passed from details screen through GoRouter extra.
    final apiDataUrl = widget.apiDataUrl ?? '';
    final chapterAsync = ref.watch(readerChapterDetailProvider(apiDataUrl));
    final settings = ref.watch(readerSettingsProvider);
    final comicDetailAsync = ref.watch(comicDetailProvider(widget.comicSlug));

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Pages Viewer
          GestureDetector(
            onTap: settings.layout == 'horizontal' ? null : _toggleUI, // Taps are handled by overlay in horizontal layout
            child: chapterAsync.when(
              data: (chapter) {
                final pages = chapter.item.chapterImage;
                _totalPages = pages.length;

                final cdn = chapter.domainCdn;
                final path = chapter.item.chapterPath;

                // Build absolute image URLs
                final imageUrls = pages.map((page) => '$cdn/$path/${page.imageFile}').toList();

                // Precache images if not done yet
                if (!_imagesPrecached) {
                  _imagesPrecached = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _precacheAllImages(imageUrls);
                  });
                }

                if (settings.layout == 'horizontal') {
                  return _buildHorizontalGallery(imageUrls);
                } else {
                  return _buildVerticalScroll(imageUrls);
                }
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primaryBlue),
              ),
              error: (err, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Lỗi tải chương: $err', style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(readerChapterDetailProvider(apiDataUrl)),
                      child: const Text('Thử lại'),
                    )
                  ],
                ),
              ),
            ),
          ),

          // 1.5. Transparent Tap Areas for Horizontal Navigation
          if (settings.layout == 'horizontal' && chapterAsync.hasValue)
            ..._buildHorizontalTapOverlay(context),

          // 2. Brightness Overlay
          IgnorePointer(
            child: Container(
              color: Colors.black.withOpacity(1.0 - settings.brightness),
            ),
          ),

          // 3. Top Navigation Bar Overlay
          if (_showUI) _buildTopBar(context, chapterAsync),

          // 4. Bottom Controls Overlay
          if (_showUI) _buildBottomControls(context, settings, comicDetailAsync),
        ],
      ),
    );
  }

  List<Widget> _buildHorizontalTapOverlay(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return [
      // Left tap area (25%)
      Positioned(
        left: 0,
        top: 0,
        bottom: 0,
        width: width * 0.25,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            if (_currentPage > 1) {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          },
        ),
      ),
      // Right tap area (25%)
      Positioned(
        right: 0,
        top: 0,
        bottom: 0,
        width: width * 0.25,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            if (_currentPage < _totalPages) {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          },
        ),
      ),
      // Center tap area (50%)
      Positioned(
        left: width * 0.25,
        right: width * 0.25,
        top: 0,
        bottom: 0,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _toggleUI,
        ),
      ),
    ];
  }

  Widget _buildVerticalScroll(List<String> urls) {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      itemCount: urls.length,
      cacheExtent: 3000, // Preload images 3000px ahead/behind to prevent loading blank screens
      itemBuilder: (context, index) {
        return _VerticalPageItem(imageUrl: urls[index]);
      },
    );
  }


  Widget _buildHorizontalGallery(List<String> urls) {
    return PhotoViewGallery.builder(
      scrollPhysics: const BouncingScrollPhysics(),
      pageController: _pageController,
      builder: (BuildContext context, int index) {
        return PhotoViewGalleryPageOptions(
          imageProvider: CachedNetworkImageProvider(urls[index]),
          initialScale: PhotoViewComputedScale.contained,
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2.5,
        );
      },
      itemCount: urls.length,
      loadingBuilder: (context, event) => const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
      ),
      onPageChanged: (index) {
        setState(() {
          _currentPage = index + 1;
        });
        _saveReadingProgress((_currentPage / _totalPages * 100).toInt());
      },
    );
  }

  Widget _buildTopBar(BuildContext context, AsyncValue<ChapterDetailInfoModel> chapterAsync) {
    final title = chapterAsync.when(
      data: (c) => '${c.item.comicName} - Ch. ${c.item.chapterName}',
      loading: () => 'Đang tải...',
      error: (_, __) => 'Lỗi tải trang',
    );

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, bottom: 12),
            color: Colors.black.withOpacity(0.6),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(
    BuildContext context,
    ReaderSettings settings,
    AsyncValue<ComicDetailInfoModel> comicDetailAsync,
  ) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black.withOpacity(0.6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Chapter Navigation (Prev / Next Buttons)
                comicDetailAsync.when(
                  data: (comic) {
                    ServerModel? matchedServer;
                    for (final srv in comic.chapters) {
                      if (srv.serverData.any((c) => c.chapterSlug == widget.chapterSlug)) {
                        matchedServer = srv;
                        break;
                      }
                    }
                    final server = matchedServer ?? (comic.chapters.isNotEmpty ? comic.chapters.first : null);
                    final chaptersList = server != null ? server.serverData : <ChapterModel>[];
                    final currentIdx = chaptersList.indexWhere((c) => c.chapterSlug == widget.chapterSlug);
                    
                    final hasPrev = currentIdx > 0;
                    final hasNext = currentIdx != -1 && currentIdx < chaptersList.length - 1;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        children: [
                          // Prev Chapter Button
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: hasPrev
                                  ? () {
                                      final prevChap = chaptersList[currentIdx - 1];
                                      context.pushReplacement(
                                        '/reader/${widget.comicSlug}/${prevChap.chapterSlug}',
                                        extra: prevChap.chapterApiData,
                                      );
                                    }
                                  : null,
                              icon: Icon(Icons.navigate_before, color: hasPrev ? Colors.white : Colors.white24, size: 20),
                              label: Text(
                                'Chương trước',
                                style: TextStyle(
                                  color: hasPrev ? Colors.white : Colors.white24,
                                  fontSize: 12,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: hasPrev ? Colors.white38 : Colors.white12),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Next Chapter Button
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: hasNext
                                  ? () {
                                      final nextChap = chaptersList[currentIdx + 1];
                                      context.pushReplacement(
                                        '/reader/${widget.comicSlug}/${nextChap.chapterSlug}',
                                        extra: nextChap.chapterApiData,
                                      );
                                    }
                                  : null,
                              icon: Icon(Icons.navigate_next, color: hasNext ? Colors.white : Colors.white38, size: 20),
                              label: Text(
                                'Chương sau',
                                style: TextStyle(
                                  color: hasNext ? Colors.white : Colors.white38,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: hasNext ? AppColors.primaryBlue : Colors.white12,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                // Page Indicator
                Text(
                  'Trang $_currentPage / $_totalPages',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 12),

                // Layout & Brightness controls
                Row(
                  children: [
                    // Layout selector icon
                    IconButton(
                      icon: Icon(
                        settings.layout == 'vertical' ? Icons.splitscreen : Icons.menu_book,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        final nextLayout = settings.layout == 'vertical' ? 'horizontal' : 'vertical';
                        ref.read(readerSettingsProvider.notifier).updateLayout(nextLayout);
                      },
                    ),
                    const SizedBox(width: 8),

                    // Brightness Slider
                    const Icon(Icons.brightness_medium, color: Colors.white54, size: 18),
                    Expanded(
                      child: Slider(
                        value: settings.brightness,
                        min: 0.1,
                        max: 1.0,
                        activeColor: AppColors.primaryBlue,
                        inactiveColor: Colors.white24,
                        onChanged: (val) {
                          ref.read(readerSettingsProvider.notifier).updateBrightness(val);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VerticalPageItem extends StatefulWidget {
  final String imageUrl;
  const _VerticalPageItem({required this.imageUrl});

  @override
  State<_VerticalPageItem> createState() => _VerticalPageItemState();
}

class _VerticalPageItemState extends State<_VerticalPageItem> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return CachedNetworkImage(
      imageUrl: widget.imageUrl,
      fit: BoxFit.fitWidth,
      width: double.infinity,
      placeholder: (context, url) => Container(
        height: 400,
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        height: 200,
        color: Colors.grey[900],
        child: const Center(
          child: Icon(Icons.broken_image, color: Colors.white30, size: 50),
        ),
      ),
    );
  }
}
