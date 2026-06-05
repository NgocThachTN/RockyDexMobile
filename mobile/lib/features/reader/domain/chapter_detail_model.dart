class ChapterPageImageModel {
  final int imagePage;
  final String imageFile;

  const ChapterPageImageModel({
    required this.imagePage,
    required this.imageFile,
  });

  factory ChapterPageImageModel.fromJson(Map<String, dynamic> json) {
    return ChapterPageImageModel(
      imagePage: json['image_page'] as int? ?? 1,
      imageFile: json['image_file'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'image_page': imagePage,
      'image_file': imageFile,
    };
  }
}

class ChapterDetailItemModel {
  final String id;
  final String comicName;
  final String chapterName;
  final String chapterTitle;
  final String chapterPath;
  final List<ChapterPageImageModel> chapterImage;

  const ChapterDetailItemModel({
    required this.id,
    required this.comicName,
    required this.chapterName,
    required this.chapterTitle,
    required this.chapterPath,
    required this.chapterImage,
  });

  factory ChapterDetailItemModel.fromJson(Map<String, dynamic> json) {
    final rawImages = json['chapter_image'];
    final List<ChapterPageImageModel> images = rawImages is List
        ? rawImages.map((e) => ChapterPageImageModel.fromJson(e as Map<String, dynamic>)).toList()
        : [];

    return ChapterDetailItemModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      comicName: json['comic_name'] as String? ?? '',
      chapterName: json['chapter_name'] as String? ?? '',
      chapterTitle: json['chapter_title'] as String? ?? '',
      chapterPath: json['chapter_path'] as String? ?? '',
      chapterImage: images,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'comic_name': comicName,
      'chapter_name': chapterName,
      'chapter_title': chapterTitle,
      'chapter_path': chapterPath,
      'chapter_image': chapterImage.map((e) => e.toJson()).toList(),
    };
  }
}

class ChapterDetailInfoModel {
  final String domainCdn;
  final ChapterDetailItemModel item;

  const ChapterDetailInfoModel({
    required this.domainCdn,
    required this.item,
  });

  factory ChapterDetailInfoModel.fromJson(Map<String, dynamic> json) {
    return ChapterDetailInfoModel(
      domainCdn: json['domain_cdn'] as String? ?? '',
      item: ChapterDetailItemModel.fromJson(json['item'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'domain_cdn': domainCdn,
      'item': item.toJson(),
    };
  }
}
