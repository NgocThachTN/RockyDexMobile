import '../../home/domain/comic_model.dart';

class ChapterModel {
  final String filename;
  final String chapterName;
  final String chapterTitle;
  final String chapterApiData;

  const ChapterModel({
    required this.filename,
    required this.chapterName,
    required this.chapterTitle,
    required this.chapterApiData,
  });

  String get chapterSlug {
    final uri = Uri.tryParse(chapterApiData);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.last;
    }
    return chapterName;
  }

  factory ChapterModel.fromJson(Map<String, dynamic> json) {
    return ChapterModel(
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

class ServerModel {
  final String serverName;
  final List<ChapterModel> serverData;

  const ServerModel({
    required this.serverName,
    required this.serverData,
  });

  factory ServerModel.fromJson(Map<String, dynamic> json) {
    final rawData = json['server_data'];
    final List<ChapterModel> data = rawData is List
        ? rawData.map((e) => ChapterModel.fromJson(e as Map<String, dynamic>)).toList()
        : [];

    return ServerModel(
      serverName: json['server_name'] as String? ?? '',
      serverData: data,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'server_name': serverName,
      'server_data': serverData.map((e) => e.toJson()).toList(),
    };
  }
}

class ComicDetailInfoModel {
  final String id;
  final String name;
  final String slug;
  final List<String> originName;
  final String content;
  final String status;
  final String thumbUrl;
  final List<String> author;
  final List<CategoryModel> category;
  final List<ServerModel> chapters;

  const ComicDetailInfoModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.originName,
    required this.content,
    required this.status,
    required this.thumbUrl,
    required this.author,
    required this.category,
    required this.chapters,
  });

  factory ComicDetailInfoModel.fromJson(Map<String, dynamic> json) {
    final rawOrigin = json['origin_name'];
    final List<String> origins = rawOrigin is List
        ? rawOrigin.map((e) => e.toString()).toList()
        : [];

    final rawAuthor = json['author'];
    final List<String> authors = rawAuthor is List
        ? rawAuthor.map((e) => e.toString()).toList()
        : [];

    final rawCategory = json['category'];
    final List<CategoryModel> cats = rawCategory is List
        ? rawCategory.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList()
        : [];

    final rawChapters = json['chapters'];
    final List<ServerModel> chaps = rawChapters is List
        ? rawChapters.map((e) => ServerModel.fromJson(e as Map<String, dynamic>)).toList()
        : [];

    return ComicDetailInfoModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      originName: origins,
      content: json['content'] as String? ?? '',
      status: json['status'] as String? ?? '',
      thumbUrl: json['thumb_url'] as String? ?? '',
      author: authors,
      category: cats,
      chapters: chaps,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'slug': slug,
      'origin_name': originName,
      'content': content,
      'status': status,
      'thumb_url': thumbUrl,
      'author': author,
      'category': category.map((e) => e.toJson()).toList(),
      'chapters': chapters.map((e) => e.toJson()).toList(),
    };
  }
}
