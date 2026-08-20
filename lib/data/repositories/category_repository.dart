import '../../core/database/app_database.dart';
import '../../core/database/daos/categories_dao.dart';

class CategoryRepository {
  CategoryRepository(this._dao);

  final CategoriesDao _dao;

  Stream<List<Category>> watchCategories({bool includeArchived = false}) =>
      _dao.watchAll(includeArchived: includeArchived);

  Stream<List<Category>> watchByType(String type) => _dao.watchByType(type);

  Future<Category?> getCategory(int id) => _dao.getById(id);

  Future<int> createCategory({
    required String name,
    required String type,
    required int colorValue,
    required String iconKey,
  }) {
    return _dao.insertCategory(
      CategoriesCompanion.insert(
        name: name,
        type: type,
        colorValue: colorValue,
        iconKey: iconKey,
      ),
    );
  }

  Future<bool> updateCategory(Category category) =>
      _dao.updateCategory(category.toCompanion(false));

  Future<void> archiveCategory(int id) => _dao.archiveCategory(id);
}
