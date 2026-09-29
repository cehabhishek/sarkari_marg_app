import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/post_model.dart';
import '../models/category_model.dart';
import '../models/search_result_model.dart';
import '../models/state_model.dart';
import '../utils/constants.dart';

class ApiService {
  // 1. Categories (no pagination, direct list)
  Future<List<CategoryModel>> fetchCategories() async {
    final response = await http.get(Uri.parse('${AppConstants.baseUrl}/categories'));
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((json) => CategoryModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load categories');
    }
  }

  // 2. Latest posts (paginated response – extract 'data' array)
  Future<List<PostModel>> fetchLatestPosts() async {
    final response = await http.get(Uri.parse('${AppConstants.baseUrl}/posts'));
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      final List data = jsonResponse['data']; // 👈 Extract data array
      return data.map((json) => PostModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load latest posts');
    }
  }

  // 3. Posts by category (paginated response)
  Future<List<PostModel>> fetchPostsByCategory(String categoryId) async {
    final response = await http.get(Uri.parse('${AppConstants.baseUrl}/posts/category/$categoryId'));
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      final List data = jsonResponse['data'];
      return data.map((json) => PostModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load posts by category');
    }
  }

  // 4. Posts by state (paginated response) with multi-tier fallback (ID -> Name -> Local Filter)
  Future<List<PostModel>> fetchPostsByState(String stateParam, {String? altParam}) async {
    // 1. Try querying with the primary param (e.g. ID like "5" or slug/name)
    try {
      final response = await http.get(Uri.parse('${AppConstants.baseUrl}/posts/state/$stateParam'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final List data = jsonResponse['data'] ?? [];
        final posts = data
            .map((json) => PostModel.fromJson(json))
            .where((p) => p.state.isNotEmpty && p.state != '0' && p.state.toLowerCase() != 'null')
            .toList();
        if (posts.isNotEmpty) {
          return posts;
        }
      }
    } catch (_) {}

    // 2. If primary param returned 0 posts, try alternative param (e.g. Name like "Uttar Pradesh")
    if (altParam != null && altParam.isNotEmpty && altParam != stateParam) {
      try {
        final response = await http.get(Uri.parse('${AppConstants.baseUrl}/posts/state/$altParam'));
        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
          final List data = jsonResponse['data'] ?? [];
          final posts = data
              .map((json) => PostModel.fromJson(json))
              .where((p) => p.state.isNotEmpty && p.state != '0' && p.state.toLowerCase() != 'null')
              .toList();
          if (posts.isNotEmpty) {
            return posts;
          }
        }
      } catch (_) {}
    }

    // 3. Guaranteed Local Fallback: Filter from latest posts if API returned 0 posts
    try {
      final allPosts = await fetchLatestPosts();
      return allPosts
          .where((p) =>
              (stateParam.isNotEmpty && (p.stateId == stateParam || p.state.toLowerCase() == stateParam.toLowerCase())) ||
              (altParam != null && altParam.isNotEmpty && (p.stateId == altParam || p.state.toLowerCase() == altParam.toLowerCase())))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // 5. Single post detail (direct object, not paginated)
  Future<PostModel> fetchPostDetail(String slug) async {
    final response = await http.get(Uri.parse('${AppConstants.baseUrl}/post/$slug'));
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      return PostModel.fromJson(jsonResponse);
    } else {
      throw Exception('Failed to load post detail');
    }
  }

  // 6. Get unique states as StateModel objects
  Future<List<StateModel>> fetchAllStateModels() async {
    try {
      final response = await http.get(Uri.parse('${AppConstants.baseUrl}/states'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          final list = data
              .where((item) => item != null)
              .map((item) => item is Map
                  ? StateModel.fromJson(Map<String, dynamic>.from(item))
                  : StateModel(id: item.toString(), name: item.toString()))
              .where((s) =>
                  s.name.isNotEmpty &&
                  s.name != '0' &&
                  s.name.toLowerCase() != 'null' &&
                  int.tryParse(s.name) == null)
              .toSet()
              .toList();
          if (list.isNotEmpty) {
            list.sort((a, b) => a.name.compareTo(b.name));
            return list;
          }
        }
      }
    } catch (_) {}

    final posts = await fetchLatestPosts();
    final Map<String, StateModel> stateMap = {};
    for (var p in posts) {
      if (p.state.isNotEmpty &&
          p.state != '0' &&
          p.state.toLowerCase() != 'null' &&
          int.tryParse(p.state) == null) {
        String idToUse = p.stateId.isNotEmpty ? p.stateId : p.state;
        stateMap[p.state.toLowerCase()] = StateModel(id: idToUse, name: p.state);
      }
    }
    final list = stateMap.values.toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  Future<List<String>> fetchAllStates() async {
    final models = await fetchAllStateModels();
    return models.map((m) => m.name).toList();
  }

  // 7. Live AJAX search
  Future<List<SearchResultModel>> searchPosts(String query) async {
    if (query.trim().length < 2) return [];

    // First try /api/search/ajax
    var url = Uri.parse('${AppConstants.baseUrl}/search/ajax?q=${Uri.encodeQueryComponent(query.trim())}');
    var response = await http.get(url);

    // If 404, fallback to domain root /search/ajax (if route is in web.php)
    if (response.statusCode == 404) {
      final rootUrl = AppConstants.baseUrl.replaceAll('/api', '');
      url = Uri.parse('$rootUrl/search/ajax?q=${Uri.encodeQueryComponent(query.trim())}');
      response = await http.get(url);
    }

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => SearchResultModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search posts');
    }
  }
}