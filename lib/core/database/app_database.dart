import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'daos/accounts_dao.dart';
import 'daos/categories_dao.dart';
import 'daos/savings_goals_dao.dart';
import 'daos/transactions_dao.dart';
import 'tables/accounts.dart';
import 'tables/categories.dart';
import 'tables/savings_goals.dart';
import 'tables/transactions.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Accounts, Categories, Transactions, SavingsGoals],
  daos: [AccountsDao, CategoriesDao, TransactionsDao, SavingsGoalsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedDefaultCategories();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(savingsGoals);
          }
        },
      );

  Future<void> _seedDefaultCategories() async {
    const expenseDefaults = <(String, int, String)>[
      ('Food & Dining', 0xFFEF6C00, 'restaurant'),
      ('Transport', 0xFF1E88E5, 'directions_car'),
      ('Groceries', 0xFF43A047, 'shopping_cart'),
      ('Bills & Utilities', 0xFF6D4C41, 'receipt_long'),
      ('Health', 0xFFE53935, 'local_hospital'),
      ('Shopping', 0xFF8E24AA, 'shopping_bag'),
      ('Entertainment', 0xFFFB8C00, 'movie'),
      ('Other', 0xFF757575, 'category'),
    ];
    const incomeDefaults = <(String, int, String)>[
      ('Salary', 0xFF2E7D32, 'payments'),
      ('Gift', 0xFFD81B60, 'card_giftcard'),
      ('Other Income', 0xFF757575, 'category'),
    ];

    await batch((batch) {
      batch.insertAll(
        categories,
        [
          for (final (name, color, icon) in expenseDefaults)
            CategoriesCompanion.insert(
              name: name,
              type: 'expense',
              colorValue: color,
              iconKey: icon,
              isDefault: const Value(true),
            ),
          for (final (name, color, icon) in incomeDefaults)
            CategoriesCompanion.insert(
              name: name,
              type: 'income',
              colorValue: color,
              iconKey: icon,
              isDefault: const Value(true),
            ),
        ],
      );
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'myspendings.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
