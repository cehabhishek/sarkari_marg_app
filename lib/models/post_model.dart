import 'category_model.dart';
import '../utils/constants.dart';

class PostModel {
  final int id;
  final String categoryId;
  final String? organizationId;
  final String title;
  final String slug;
  final String state;
  final String stateId;
  final String? thumbnail;
  final String? metaDescription;
  final String description;
  final String visibility;
  final int featured;
  final String createdAt;
  final CategoryModel? category;

  PostModel({
    required this.id,
    required this.categoryId,
    this.organizationId,
    required this.title,
    required this.slug,
    required this.state,
    required this.stateId,
    this.thumbnail,
    this.metaDescription,
    required this.description,
    required this.visibility,
    required this.featured,
    required this.createdAt,
    this.category,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    String parsedStateName = '';
    String parsedStateId = '';

    if (json['state'] is Map) {
      parsedStateName = (json['state']['name'] ?? json['state']['title'] ?? '').toString().trim();
      parsedStateId = (json['state']['id'] ?? '').toString().trim();
    } else if (json['state_name'] != null) {
      parsedStateName = json['state_name'].toString().trim();
      parsedStateId = (json['state'] ?? '').toString().trim();
    } else if (json['state'] != null) {
      String val = json['state'].toString().trim();
      if (val != '0' && val.toLowerCase() != 'null' && val.isNotEmpty) {
        if (int.tryParse(val) != null) {
          parsedStateId = val;
          parsedStateName = ''; // Avoid showing numeric ID as state name
        } else {
          parsedStateName = val;
        }
      }
    }

    return PostModel(
      id: json['id'],
      categoryId: json['category_id'].toString(),
      organizationId: json['organization_id'],
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      state: parsedStateName,
      stateId: parsedStateId,
      thumbnail: json['thumbnail'] != null
          ? '${AppConstants.storageUrl}${json['thumbnail']}'
          : null,
      metaDescription: json['meta_description'],
      description: json['description'] ?? '',
      visibility: json['visibility'] ?? 'public',
      featured: json['featured'] ?? 0,
      createdAt: json['created_at'] ?? '',
      category: json['category'] != null
          ? CategoryModel.fromJson(json['category'])
          : null,
    );
  }
}