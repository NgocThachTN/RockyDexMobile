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
import '../../../library/presentation/library_providers.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final String comicSlug;
  final String chapterSlug;
  final String? apiDataUrl;
  final String? comicName;
  final String? comicThumb;
  final String? chapterName;

  const ReaderScreen({
    super.key,
    required this.comicSlug,
    required this.chapterSlug,
    this.apiDataUrl,
    this.comicName,
    this.comicThumb,
    this.chapterName,
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
  bool _isChangingChapter = false;
  String? _resolvedApiDataUrl;
  bool _initialPageJumped = false;

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
    // Invalidate libraryHistoryProvider so that next time HistoryScreen builds, it has fresh data
    ref.invalidate(libraryHistoryProvider);
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      if (maxScroll > 0) {
        final progress = (currentScroll / maxScroll * 100).toInt();
        final page = ((currentScroll / maxScroll) * _totalPages)
            .clamp(1, _totalPages)
            .toInt();

        if (page != _currentPage) {
          setState(() {
            _currentPage = page;
          });
        }

        // Throttle/Save progress periodically
        _saveReadingProgress(progress, page);
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

  void _saveReadingProgress(int progressPercent, int pageNumber) {
    final apiDataUrl = widget.apiDataUrl ?? '';
    final chapterState = ref.read(readerChapterDetailProvider(apiDataUrl));
    final comicDetailState = ref.read(comicDetailProvider(widget.comicSlug));

    String comicName =
        widget.comicName ?? widget.comicSlug.replaceAll('-', ' ');
    String chapterName =
        widget.chapterName ?? widget.chapterSlug.replaceAll('chap-', '');
    String comicThumb = widget.comicThumb ?? '';

    if (comicDetailState.hasValue) {
      final comic = comicDetailState.value!;
      comicName = comic.name;
      comicThumb = comic.thumbUrl;

      // Find the chapter name from the comic details
      ServerModel? matchedServer;
      for (final srv in comic.chapters) {
        if (srv.serverData.any((c) => c.chapterSlug == widget.chapterSlug)) {
          matchedServer = srv;
          break;
        }
      }
      final server =
          matchedServer ??
          (comic.chapters.isNotEmpty ? comic.chapters.first : null);
      if (server != null) {
        final matchedChapter = server.serverData.firstWhere(
          (c) => c.chapterSlug == widget.chapterSlug,
          orElse: () => ChapterModel(
            filename: '',
            chapterName: chapterName,
            chapterTitle: '',
            chapterApiData: '',
          ),
        );
        if (matchedChapter.chapterName.isNotEmpty) {
          chapterName = matchedChapter.chapterName;
        }
      }
    } else if (chapterState.hasValue) {
      final chapter = chapterState.value!;
      if (chapter.item.comicName.isNotEmpty) {
        comicName = chapter.item.comicName;
      }
      if (chapter.item.chapterName.isNotEmpty) {
        chapterName = chapter.item.chapterName;
      }
    }

    if (comicDetailState.hasValue && comicThumb.isEmpty) {
      comicThumb = comicDetailState.value!.thumbUrl;
    }

    // Save to repositories (local & remote)
    ref
        .read(comicRepositoryProvider)
        .saveHistory(
          comicSlug: widget.comicSlug,
          comicName: comicName,
          comicThumb: comicThumb,
          chapterSlug: widget.chapterSlug,
          chapterName: chapterName,
          progressPercent: progressPercent,
          pageNumber: pageNumber,
        );

    // Invalidate libraryHistoryProvider to refresh the history list
    ref.invalidate(libraryHistoryProvider);
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
    final initialApiDataUrl = widget.apiDataUrl ?? _resolvedApiDataUrl ?? '';
    final chapterAsync = initialApiDataUrl.isNotEmpty
        ? ref.watch(readerChapterDetailProvider(initialApiDataUrl))
        : const AsyncValue<ChapterDetailInfoModel>.loading();
    final settings = ref.watch(readerSettingsProvider);
    final comicDetailAsync = ref.watch(comicDetailProvider(widget.comicSlug));

    List<ChapterModel> chaptersList = [];
    int currentIdx = -1;
    bool hasNext = false;
    bool hasPrev = false;
    ComicDetailInfoModel? comicDetail;

    if (comicDetailAsync.hasValue) {
      comicDetail = comicDetailAsync.value!;
      ServerModel? matchedServer;
      for (final srv in comicDetail.chapters) {
        if (srv.serverData.any((c) => c.chapterSlug == widget.chapterSlug)) {
          matchedServer = srv;
          break;
        }
      }
      final server =
          matchedServer ??
          (comicDetail.chapters.isNotEmpty ? comicDetail.chapters.first : null);
      if (server != null) {
        chaptersList = server.serverData;
        currentIdx = chaptersList.indexWhere(
          (c) => c.chapterSlug == widget.chapterSlug,
        );
        hasPrev = currentIdx != -1 && currentIdx < chaptersList.length - 1;
        hasNext = currentIdx > 0;

        // Resolve apiDataUrl if it was empty and chapter was found in chapters list
        if (initialApiDataUrl.isEmpty && currentIdx != -1) {
          final matchedChapter = chaptersList[currentIdx];
          if (matchedChapter.chapterApiData.isNotEmpty) {
            final resolvedUrl = matchedChapter.chapterApiData;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _resolvedApiDataUrl != resolvedUrl) {
                setState(() {
                  _resolvedApiDataUrl = resolvedUrl;
                });
              }
            });
          }
        }
      }
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Pages Viewer
          GestureDetector(
            onTap: settings.layout == 'horizontal'
                ? null
                : _toggleUI, // Taps are handled by overlay in horizontal layout
            child: chapterAsync.when(
              data: (chapter) {
                final pages = chapter.item.chapterImage;
                _totalPages = settings.layout == 'horizontal'
                    ? pages.length + 1
                    : pages.length;

                final cdn = chapter.domainCdn;
                final path = chapter.item.chapterPath;

                // Build absolute image URLs
                final imageUrls = pages
                    .map((page) => '$cdn/$path/${page.imageFile}')
                    .toList();

                // Precache images if not done yet
                if (!_imagesPrecached) {
                  _imagesPrecached = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _precacheAllImages(imageUrls);
                  });
                }

                // Restore last read page if not done yet
                if (!_initialPageJumped) {
                  _initialPageJumped = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    final hist = await ref
                        .read(comicRepositoryProvider)
                        .getReadingHistory(widget.comicSlug);
                    if (hist != null &&
                        hist['chapter_slug'] == widget.chapterSlug) {
                      final savedPage = hist['page_number'] as int? ?? 1;
                      if (savedPage > 1 && savedPage <= _totalPages) {
                        setState(() {
                          _currentPage = savedPage;
                        });
                        if (settings.layout == 'horizontal') {
                          _pageController.jumpToPage(savedPage - 1);
                        } else {
                          if (_scrollController.hasClients) {
                            final maxScroll =
                                _scrollController.position.maxScrollExtent;
                            final targetOffset =
                                (savedPage - 1) / (_totalPages - 1) * maxScroll;
                            _scrollController.jumpTo(targetOffset);
                          }
                        }
                      }
                    }
                  });
                }

                if (settings.layout == 'horizontal') {
                  return _buildHorizontalGallery(
                    urls: imageUrls,
                    hasNext: hasNext,
                    hasPrev: hasPrev,
                    chaptersList: chaptersList,
                    currentIdx: currentIdx,
                    comicDetail: comicDetail,
                  );
                } else {
                  return _buildVerticalScroll(
                    urls: imageUrls,
                    hasNext: hasNext,
                    hasPrev: hasPrev,
                    chaptersList: chaptersList,
                    currentIdx: currentIdx,
                    comicDetail: comicDetail,
                  );
                }
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primaryBlue),
              ),
              error: (err, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Lỗi tải chương: $err',
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(
                        readerChapterDetailProvider(initialApiDataUrl),
                      ),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 1.5. Transparent Tap Areas for Horizontal Navigation
          if (settings.layout == 'horizontal' && chapterAsync.hasValue)
            ..._buildHorizontalTapOverlay(
              context: context,
              hasNext: hasNext,
              hasPrev: hasPrev,
              chaptersList: chaptersList,
              currentIdx: currentIdx,
              comicDetail: comicDetail,
            ),

          // 2. Brightness Overlay
          IgnorePointer(
            child: Container(
              color: Colors.black.withValues(alpha: 1.0 - settings.brightness),
            ),
          ),

          // 3. Top Navigation Bar Overlay
          if (_showUI) _buildTopBar(context, chapterAsync),

          // 4. Bottom Controls Overlay
          if (_showUI)
            _buildBottomControlsCompact(context, settings, comicDetailAsync),
        ],
      ),
    );
  }

  List<Widget> _buildHorizontalTapOverlay({
    required BuildContext context,
    required bool hasNext,
    required bool hasPrev,
    required List<ChapterModel> chaptersList,
    required int currentIdx,
    required ComicDetailInfoModel? comicDetail,
  }) {
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
            } else if (hasPrev && comicDetail != null) {
              _goToPreviousChapter(chaptersList, currentIdx, comicDetail);
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
            } else if (hasNext && comicDetail != null) {
              _goToNextChapter(chaptersList, currentIdx, comicDetail);
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

  Widget _buildVerticalScroll({
    required List<String> urls,
    required bool hasNext,
    required bool hasPrev,
    required List<ChapterModel> chaptersList,
    required int currentIdx,
    required ComicDetailInfoModel? comicDetail,
  }) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification is OverscrollNotification && comicDetail != null) {
          if (notification.overscroll > 14 && hasNext) {
            _goToNextChapter(chaptersList, currentIdx, comicDetail);
            return true;
          }
          if (notification.overscroll < -14 && hasPrev) {
            _goToPreviousChapter(chaptersList, currentIdx, comicDetail);
            return true;
          }
        }
        return false;
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.zero,
        itemCount: urls.length + 1,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        cacheExtent:
            3000, // Preload images 3000px ahead/behind to prevent loading blank screens
        itemBuilder: (context, index) {
          if (index == urls.length) {
            return _buildEndOfChapterPage(
              context: context,
              hasNext: hasNext,
              chaptersList: chaptersList,
              currentIdx: currentIdx,
              comicDetail: comicDetail,
              isHorizontal: false,
            );
          }
          return _VerticalPageItem(imageUrl: urls[index]);
        },
      ),
    );
  }

  Widget _buildHorizontalGallery({
    required List<String> urls,
    required bool hasNext,
    required bool hasPrev,
    required List<ChapterModel> chaptersList,
    required int currentIdx,
    required ComicDetailInfoModel? comicDetail,
  }) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification is OverscrollNotification && comicDetail != null) {
          if (notification.overscroll > 10 &&
              _currentPage >= _totalPages &&
              hasNext) {
            _goToNextChapter(chaptersList, currentIdx, comicDetail);
            return true;
          }
          if (notification.overscroll < -10 && _currentPage <= 1 && hasPrev) {
            _goToPreviousChapter(chaptersList, currentIdx, comicDetail);
            return true;
          }
        }
        return false;
      },
      child: PhotoViewGallery.builder(
        scrollPhysics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        pageController: _pageController,
        builder: (BuildContext context, int index) {
          if (index == urls.length) {
            return PhotoViewGalleryPageOptions.customChild(
              child: _buildEndOfChapterPage(
                context: context,
                hasNext: hasNext,
                chaptersList: chaptersList,
                currentIdx: currentIdx,
                comicDetail: comicDetail,
                isHorizontal: true,
              ),
              initialScale: PhotoViewComputedScale.contained,
              minScale: PhotoViewComputedScale.contained,
            );
          }
          return PhotoViewGalleryPageOptions(
            imageProvider: CachedNetworkImageProvider(urls[index]),
            initialScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2.5,
          );
        },
        itemCount: urls.length + 1,
        loadingBuilder: (context, event) => const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primaryBlue,
          ),
        ),
        onPageChanged: (index) {
          setState(() {
            _currentPage = index + 1;
          });
          final actualPage = (index + 1).clamp(1, urls.length);
          _saveReadingProgress(
            (actualPage / urls.length * 100).toInt(),
            actualPage,
          );
        },
      ),
    );
  }

  Widget _buildEndOfChapterPage({
    required BuildContext context,
    required bool hasNext,
    required List<ChapterModel> chaptersList,
    required int currentIdx,
    required ComicDetailInfoModel? comicDetail,
    required bool isHorizontal,
  }) {
    final currentChapterName =
        currentIdx != -1 && currentIdx < chaptersList.length
        ? chaptersList[currentIdx].chapterName
        : widget.chapterSlug.replaceAll('chap-', '');

    final nextChapter = hasNext ? chaptersList[currentIdx - 1] : null;

    return Container(
      width: double.infinity,
      height: isHorizontal ? double.infinity : 320,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        borderRadius: isHorizontal
            ? null
            : const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge "Đã đọc xong"
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primaryBlue.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: AppColors.primaryBlue,
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'ĐÃ ĐỌC XONG',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Tên chương hiện tại
              Text(
                'Chương $currentChapterName',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 12),

              // Dấu phân cách nhỏ
              Container(
                width: 40,
                height: 2,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(height: 20),

              if (hasNext && nextChapter != null && comicDetail != null) ...[
                // Tiêu đề chương tiếp theo
                const Text(
                  'CHƯƠNG TIẾP THEO',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Chương ${nextChapter.chapterName}${nextChapter.chapterTitle.isNotEmpty ? ": ${nextChapter.chapterTitle}" : ""}',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Nút CTA đọc tiếp chương sau
                ElevatedButton(
                  onPressed: () {
                    if (!_isChangingChapter) {
                      setState(() {
                        _isChangingChapter = true;
                      });
                      _changeChapter(nextChapter, comicDetail);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 36,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 4,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Đọc Chương Tiếp Theo',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 16),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Hướng dẫn vuốt/cuộn
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isHorizontal
                          ? Icons.swap_horiz_rounded
                          : Icons.swap_vert_rounded,
                      color: Colors.white38,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isHorizontal
                          ? 'Vuốt tiếp sang trái để chuyển chương'
                          : 'Cuộn tiếp xuống dưới để chuyển chương',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Đã hết chương mới nhất
                const Text(
                  'Bạn đã đọc hết chương mới nhất rồi!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        context.pop(); // Quay lại trang chi tiết truyện
                      },
                      icon: const Icon(Icons.info_outline, size: 16),
                      label: const Text('Chi tiết truyện'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white30),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Quay lại trang chủ
                        context.go('/home');
                      },
                      icon: const Icon(Icons.home_outlined, size: 16),
                      label: const Text('Trang chủ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white24,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    AsyncValue<ChapterDetailInfoModel> chapterAsync,
  ) {
    final comicDetailState = ref.watch(comicDetailProvider(widget.comicSlug));
    final settings = ref.watch(readerSettingsProvider);
    final topInset = MediaQuery.of(context).padding.top;

    String title = 'Đang tải...';
    if (comicDetailState.hasValue) {
      final comic = comicDetailState.value!;
      final comicName = comic.name;
      String chapterName = widget.chapterSlug.replaceAll('chap-', '');

      // Find matching chapter name
      ServerModel? matchedServer;
      for (final srv in comic.chapters) {
        if (srv.serverData.any((c) => c.chapterSlug == widget.chapterSlug)) {
          matchedServer = srv;
          break;
        }
      }
      final server =
          matchedServer ??
          (comic.chapters.isNotEmpty ? comic.chapters.first : null);
      if (server != null) {
        final matchedChapter = server.serverData.firstWhere(
          (c) => c.chapterSlug == widget.chapterSlug,
          orElse: () => ChapterModel(
            filename: '',
            chapterName: chapterName,
            chapterTitle: '',
            chapterApiData: '',
          ),
        );
        if (matchedChapter.chapterName.isNotEmpty) {
          chapterName = matchedChapter.chapterName;
        }
        title = '$comicName - Ch. $chapterName';
        if (matchedChapter.chapterTitle.isNotEmpty) {
          title += ': ${matchedChapter.chapterTitle}';
        }
      } else {
        title = '$comicName - Ch. $chapterName';
      }
    } else if (chapterAsync.hasValue) {
      final c = chapterAsync.value!;
      if (c.item.comicName.isNotEmpty) {
        title = '${c.item.comicName} - Ch. ${c.item.chapterName}';
      } else {
        title = widget.comicSlug.replaceAll('-', ' ');
      }
    } else if (chapterAsync.hasError) {
      title = 'Lỗi tải trang';
    }

    return Positioned(
      top: topInset + 10,
      left: 12,
      right: 12,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Circular Back Button
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.58),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.20),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => context.pop(),
                ),
              ),
            ),
          ),

          // Compact Center Title Pill
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.58),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                        width: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.20),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Circular Settings Button
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.58),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.20),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.tune_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  tooltip: 'Cài đặt trình đọc',
                  onPressed: () => _showReaderSettingsSheet(context, settings),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReaderSettingsSheet(BuildContext context, ReaderSettings settings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withValues(alpha: 0.9),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final currentSettings = ref.watch(readerSettingsProvider);
            return SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Cài Đặt Trình Đọc',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white70,
                            size: 20,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 16),

                    // Layout Mode
                    const Text(
                      'Chế độ đọc',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            showCheckmark: false,
                            label: const Center(
                              child: Text(
                                'Cuộn dọc',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            selected: currentSettings.layout == 'vertical',
                            selectedColor: AppColors.primaryBlue,
                            backgroundColor: Colors.white12,
                            labelStyle: TextStyle(
                              color: currentSettings.layout == 'vertical'
                                  ? Colors.white
                                  : Colors.white60,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                ref
                                    .read(readerSettingsProvider.notifier)
                                    .updateLayout('vertical');
                                setModalState(() {});
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ChoiceChip(
                            showCheckmark: false,
                            label: const Center(
                              child: Text(
                                'Lướt ngang',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            selected: currentSettings.layout == 'horizontal',
                            selectedColor: AppColors.primaryBlue,
                            backgroundColor: Colors.white12,
                            labelStyle: TextStyle(
                              color: currentSettings.layout == 'horizontal'
                                  ? Colors.white
                                  : Colors.white60,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                ref
                                    .read(readerSettingsProvider.notifier)
                                    .updateLayout('horizontal');
                                setModalState(() {});
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Brightness
                    const Text(
                      'Độ sáng màn hình',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.brightness_low,
                          color: Colors.white54,
                          size: 18,
                        ),
                        Expanded(
                          child: Slider(
                            value: currentSettings.brightness,
                            min: 0.1,
                            max: 1.0,
                            activeColor: AppColors.primaryBlue,
                            inactiveColor: Colors.white24,
                            onChanged: (val) {
                              ref
                                  .read(readerSettingsProvider.notifier)
                                  .updateBrightness(val);
                              setModalState(() {});
                            },
                          ),
                        ),
                        const Icon(
                          Icons.brightness_high,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _goToNextChapter(
    List<ChapterModel> chapters,
    int currentIdx,
    ComicDetailInfoModel comic,
  ) {
    if (_isChangingChapter || currentIdx <= 0) return;
    _changeChapter(chapters[currentIdx - 1], comic);
  }

  void _goToPreviousChapter(
    List<ChapterModel> chapters,
    int currentIdx,
    ComicDetailInfoModel comic,
  ) {
    if (_isChangingChapter ||
        currentIdx < 0 ||
        currentIdx >= chapters.length - 1) {
      return;
    }
    _changeChapter(chapters[currentIdx + 1], comic);
  }

  void _changeChapter(ChapterModel targetChap, ComicDetailInfoModel comic) {
    if (_isChangingChapter) return;
    setState(() {
      _isChangingChapter = true;
    });

    context.pushReplacement(
      '/reader/${widget.comicSlug}/${targetChap.chapterSlug}',
      extra: {
        'api_data_url': targetChap.chapterApiData,
        'comic_name': comic.name,
        'comic_thumb': comic.thumbUrl,
        'chapter_name': targetChap.chapterName,
      },
    );
  }

  void _showChapterSelectionSheet(
    BuildContext context,
    List<ChapterModel> chapters,
    int currentIdx,
    ComicDetailInfoModel comic,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withValues(alpha: 0.95),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Danh Sách Chương (${chapters.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white70,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: chapters.length,
                  itemBuilder: (context, index) {
                    final chap = chapters[index];
                    final isCurrent = index == currentIdx;

                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 2,
                      ),
                      tileColor: isCurrent
                          ? AppColors.primaryBlue.withValues(alpha: 0.15)
                          : null,
                      title: Text(
                        'Chương ${chap.chapterName}',
                        style: TextStyle(
                          color: isCurrent
                              ? AppColors.primaryBlue
                              : Colors.white,
                          fontWeight: isCurrent
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: chap.chapterTitle.isNotEmpty
                          ? Text(
                              chap.chapterTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isCurrent
                                    ? AppColors.primaryBlue.withValues(
                                        alpha: 0.7,
                                      )
                                    : Colors.white60,
                                fontSize: 11,
                              ),
                            )
                          : null,
                      trailing: isCurrent
                          ? const Icon(
                              Icons.check,
                              color: AppColors.primaryBlue,
                              size: 18,
                            )
                          : null,
                      onTap: () {
                        Navigator.pop(context); // Close bottom sheet
                        if (!isCurrent) {
                          _changeChapter(chap, comic);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomControlsCompact(
    BuildContext context,
    ReaderSettings settings,
    AsyncValue<ComicDetailInfoModel> comicDetailAsync,
  ) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final totalReadablePages = settings.layout == 'horizontal'
        ? (_totalPages - 1).clamp(1, _totalPages)
        : _totalPages;
    final currentReadablePage = _currentPage.clamp(1, totalReadablePages);

    return Positioned(
      bottom: bottomInset + 12,
      left: 12,
      right: 12,
      child: comicDetailAsync.when(
        data: (comic) {
          ServerModel? matchedServer;
          for (final srv in comic.chapters) {
            if (srv.serverData.any(
              (c) => c.chapterSlug == widget.chapterSlug,
            )) {
              matchedServer = srv;
              break;
            }
          }

          final server =
              matchedServer ??
              (comic.chapters.isNotEmpty ? comic.chapters.first : null);
          final chaptersList = server != null
              ? server.serverData
              : <ChapterModel>[];
          final currentIdx = chaptersList.indexWhere(
            (c) => c.chapterSlug == widget.chapterSlug,
          );
          final hasPrev =
              currentIdx != -1 && currentIdx < chaptersList.length - 1;
          final hasNext = currentIdx > 0;

          String currentChapterName =
              widget.chapterName ?? widget.chapterSlug.replaceAll('chap-', '');
          if (currentIdx != -1) {
            currentChapterName = chaptersList[currentIdx].chapterName;
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildReaderGlassCircleButton(
                icon: Icons.keyboard_arrow_left_rounded,
                tooltip: 'Chương trước',
                enabled: hasPrev,
                onPressed: () =>
                    _goToPreviousChapter(chaptersList, currentIdx, comic),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: InkWell(
                      onTap: chaptersList.isEmpty
                          ? null
                          : () => _showChapterSelectionSheet(
                              context,
                              chaptersList,
                              currentIdx,
                              comic,
                            ),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.58),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.14),
                            width: 0.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Text(
                              '$currentReadablePage/$totalReadablePages',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 16,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                            Expanded(
                              child: Text(
                                'Chương $currentChapterName',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_up,
                              color: Colors.white70,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildReaderGlassCircleButton(
                icon: Icons.keyboard_arrow_right_rounded,
                tooltip: 'Chương sau',
                enabled: hasNext,
                onPressed: () =>
                    _goToNextChapter(chaptersList, currentIdx, comic),
              ),
            ],
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildReaderGlassCircleButton({
    required IconData icon,
    required String tooltip,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: enabled ? 0.58 : 0.34),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: enabled ? 0.14 : 0.08),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            tooltip: tooltip,
            onPressed: enabled ? onPressed : null,
            icon: Icon(
              icon,
              color: enabled ? Colors.white : Colors.white30,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildBottomControls(
    BuildContext context,
    ReaderSettings settings,
    AsyncValue<ComicDetailInfoModel> comicDetailAsync,
  ) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Positioned(
      bottom: bottomInset + 12,
      left: 12,
      right: 12,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.58),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.14),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Page Indicator / Progress Slider
                if (_totalPages > 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4.0,
                      vertical: 0.0,
                    ),
                    child: Row(
                      children: [
                        Text(
                          (settings.layout == 'horizontal' &&
                                  _currentPage == _totalPages)
                              ? 'Hết'
                              : '$_currentPage',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 1.5,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 5.0,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 10.0,
                              ),
                              activeTrackColor: AppColors.primaryBlue,
                              inactiveTrackColor: Colors.white24,
                              thumbColor: AppColors.primaryBlue,
                            ),
                            child: Slider(
                              value: _currentPage.toDouble().clamp(
                                1.0,
                                _totalPages.toDouble(),
                              ),
                              min: 1.0,
                              max: _totalPages.toDouble(),
                              onChanged: (value) {
                                final targetPage = value.round();
                                setState(() {
                                  _currentPage = targetPage;
                                });
                                if (settings.layout == 'horizontal') {
                                  _pageController.jumpToPage(targetPage - 1);
                                } else {
                                  if (_scrollController.hasClients) {
                                    final maxScroll = _scrollController
                                        .position
                                        .maxScrollExtent;
                                    final targetOffset =
                                        (targetPage - 1) /
                                        (_totalPages - 1) *
                                        maxScroll;
                                    _scrollController.jumpTo(targetOffset);
                                  }
                                }
                              },
                            ),
                          ),
                        ),
                        Text(
                          (settings.layout == 'horizontal')
                              ? '${_totalPages - 1}'
                              : '$_totalPages',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 2),

                // 2. Chapter Skip Bar & Dropdown Select
                comicDetailAsync.when(
                  data: (comic) {
                    ServerModel? matchedServer;
                    for (final srv in comic.chapters) {
                      if (srv.serverData.any(
                        (c) => c.chapterSlug == widget.chapterSlug,
                      )) {
                        matchedServer = srv;
                        break;
                      }
                    }
                    final server =
                        matchedServer ??
                        (comic.chapters.isNotEmpty
                            ? comic.chapters.first
                            : null);
                    final chaptersList = server != null
                        ? server.serverData
                        : <ChapterModel>[];
                    final currentIdx = chaptersList.indexWhere(
                      (c) => c.chapterSlug == widget.chapterSlug,
                    );

                    final hasPrev =
                        currentIdx != -1 &&
                        currentIdx < chaptersList.length - 1;
                    final hasNext = currentIdx > 0;

                    String currentChapterName =
                        widget.chapterName ??
                        widget.chapterSlug.replaceAll('chap-', '');
                    if (currentIdx != -1) {
                      currentChapterName = chaptersList[currentIdx].chapterName;
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Skip to older chapter
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(6),
                          onPressed: hasPrev
                              ? () => _changeChapter(
                                  chaptersList[currentIdx + 1],
                                  comic,
                                )
                              : null,
                          icon: Icon(
                            Icons.skip_previous,
                            color: hasPrev ? Colors.white : Colors.white24,
                            size: 20,
                          ),
                          tooltip: 'Chương trước',
                        ),

                        // Dropdown chapter selector trigger
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                            ),
                            child: InkWell(
                              onTap: () {
                                if (chaptersList.isNotEmpty) {
                                  _showChapterSelectionSheet(
                                    context,
                                    chaptersList,
                                    currentIdx,
                                    comic,
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white24,
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'Chương $currentChapterName',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.keyboard_arrow_up,
                                      color: Colors.white70,
                                      size: 14,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Skip to newer chapter
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(6),
                          onPressed: hasNext
                              ? () => _changeChapter(
                                  chaptersList[currentIdx - 1],
                                  comic,
                                )
                              : null,
                          icon: Icon(
                            Icons.skip_next,
                            color: hasNext ? Colors.white : Colors.white24,
                            size: 20,
                          ),
                          tooltip: 'Chương sau',
                        ),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
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

class _VerticalPageItemState extends State<_VerticalPageItem>
    with AutomaticKeepAliveClientMixin {
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
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primaryBlue,
          ),
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
