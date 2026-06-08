class CategoryModel {
  final String id;
  final String name;
  final String slug;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
    };
  }
}

class ChapterSummaryModel {
  final String filename;
  final String chapterName;
  final String chapterTitle;
  final String chapterApiData;

  const ChapterSummaryModel({
    required this.filename,
    required this.chapterName,
    required this.chapterTitle,
    required this.chapterApiData,
  });

  factory ChapterSummaryModel.fromJson(Map<String, dynamic> json) {
    return ChapterSummaryModel(
      filename: json['filename'] as String? ?? '',
      chapterName: json['chapter_name'] as String? ?? '',
      chapterTitle: json['chapter_title'] as String? ?? '',
      chapterApiData: json['chapter_api_data'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filename': filename,
      'chapter_name': chapterName,
      'chapter_title': chapterTitle,
      'chapter_api_data': chapterApiData,
    };
  }
}

class ComicModel {
  final String id;
  final String name;
  final String slug;
  final List<String> originName;
  final String status;
  final String thumbUrl;
  final List<CategoryModel> category;
  final String updatedAt;
  final List<ChapterSummaryModel>? chaptersLatest;
  final double? rating;
  final int? followsCount;

  const ComicModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.originName,
    required this.status,
    required this.thumbUrl,
    required this.category,
    required this.updatedAt,
    this.chaptersLatest,
    this.rating,
    this.followsCount,
  });

  factory ComicModel.fromJson(Map<String, dynamic> json) {
    final rawOrigin = json['origin_name'];
    final List<String> origins = rawOrigin is List
        ? rawOrigin.map((e) => e.toString()).toList()
        : [];

    final rawCategory = json['category'];
    final List<CategoryModel> cats = rawCategory is List
        ? rawCategory.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList()
        : [];

    final rawChapters = json['chaptersLatest'];
    final List<ChapterSummaryModel>? chaps = rawChapters is List
        ? rawChapters.map((e) => ChapterSummaryModel.fromJson(e as Map<String, dynamic>)).toList()
        : null;

    return ComicModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      originName: origins,
      status: json['status'] as String? ?? '',
      thumbUrl: json['thumb_url'] as String? ?? '',
      category: cats,
      updatedAt: json['updatedAt'] as String? ?? '',
      chaptersLatest: chaps,
      rating: (json['rating'] as num?)?.toDouble(),
      followsCount: json['followsCount'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'slug': slug,
      'origin_name': originName,
      'status': status,
      'thumb_url': thumbUrl,
      'category': category.map((e) => e.toJson()).toList(),
      'updatedAt': updatedAt,
      'chaptersLatest': chaptersLatest?.map((e) => e.toJson()).toList(),
      'rating': rating,
      'followsCount': followsCount,
    };
  }

  ComicModel copyWith({
    String? id,
    String? name,
    String? slug,
    List<String>? originName,
    String? status,
    String? thumbUrl,
    List<CategoryModel>? category,
    String? updatedAt,
    List<ChapterSummaryModel>? chaptersLatest,
    double? rating,
    int? followsCount,
  }) {
    return ComicModel(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      originName: originName ?? this.originName,
      status: status ?? this.status,
      thumbUrl: thumbUrl ?? this.thumbUrl,
      category: category ?? this.category,
      updatedAt: updatedAt ?? this.updatedAt,
      chaptersLatest: chaptersLatest ?? this.chaptersLatest,
      rating: rating ?? this.rating,
      followsCount: followsCount ?? this.followsCount,
    );
  }
}
