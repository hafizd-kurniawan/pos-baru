// Categories Management Page Models
class CategoryResponse {
  final List<Category> categories;
  final int total;
  final int currentPage;
  final int totalPages;
  final int limit;

  CategoryResponse({
    required this.categories,
    required this.total,
    required this.currentPage,
    required this.totalPages,
    required this.limit,
  });

  factory CategoryResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return CategoryResponse(
      categories: (data['categories'] as List)
          .map((e) => Category.fromJson(e))
          .toList(),
      total: data['total'],
      currentPage: data['current_page'],
      totalPages: data['total_pages'],
      limit: data['limit'],
    );
  }
}

class Category {
  final int id;
  final String name;
  final String description;
  final int itemCount;

  Category({
    required this.id,
    required this.name,
    required this.description,
    required this.itemCount,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      itemCount: json['item_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'item_count': itemCount,
    };
  }
}

class CategoryStats {
  final String category;
  final int count;

  CategoryStats({
    required this.category,
    required this.count,
  });

  factory CategoryStats.fromJson(Map<String, dynamic> json) {
    return CategoryStats(
      category: json['category'],
      count: json['count'],
    );
  }
}
