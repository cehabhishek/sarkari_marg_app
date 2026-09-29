class SearchResultModel {
  final String title;
  final String slug;
  final String category;
  final String? thumbnail;
  final String date;

  SearchResultModel({
    required this.title,
    required this.slug,
    required this.category,
    this.thumbnail,
    required this.date,
  });

  factory SearchResultModel.fromJson(Map<String, dynamic> json) {
    return SearchResultModel(
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      category: json['category'] ?? 'General',
      thumbnail: json['thumbnail'],
      date: json['date'] ?? '',
    );
  }
}
