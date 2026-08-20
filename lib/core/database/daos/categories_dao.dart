import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/categories.dart';

part 'categories_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoriesDao extends DatabaseAccessor<AppDatabase> with _$CategoriesDaoMixin {
  CategoriesDao(super.db);

  Stream<List<Category>> watchAll({bool includeArchived = false}) {
    final query = select(categories)
      ..where((c) => includeArchived ? const Constant(true) : c.isArchived.equals(false))
      ..orderBy([(c) => OrderingTerm.asc(c.name)]);
    return query.watch();
  }

  Stream<List<Category>> watchByType(String type) {
    final query = select(categories)
      ..where((c) => c.type.equals(type) & c.isArchived.equals(false))
      ..orderBy([(c) => OrderingTerm.asc(c.name)]);
    return query.watch();
  }

  Future<Category?> getById(int id) =>
      (select(categories)..where((c) => c.id.equals(id))).getSingleOrNull();

  Future<int> insertCategory(CategoriesCompanion entry) => into(categories).insert(entry);

  Future<bool> updateCategory(CategoriesCompanion entry) => update(categories).replace(entry);

  Future<void> archiveCategory(int id) => (update(categories)..where((c) => c.id.equals(id)))
      .write(const CategoriesCompanion(isArchived: Value(true)));
}
