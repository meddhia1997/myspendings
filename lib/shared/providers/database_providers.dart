import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/transaction_repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return AccountRepository(db.accountsDao, db);
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return CategoryRepository(db.categoriesDao);
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return TransactionRepository(db.transactionsDao);
});

// Reactive data streams consumed directly by the UI.

final accountsProvider = StreamProvider.autoDispose((ref) {
  return ref.watch(accountRepositoryProvider).watchAccounts();
});

final accountBalanceProvider = StreamProvider.autoDispose.family<int, int>((ref, accountId) {
  return ref.watch(accountRepositoryProvider).watchBalance(accountId);
});

final categoriesProvider = StreamProvider.autoDispose((ref) {
  return ref.watch(categoryRepositoryProvider).watchCategories();
});

final categoriesByTypeProvider = StreamProvider.autoDispose.family((ref, String type) {
  return ref.watch(categoryRepositoryProvider).watchByType(type);
});

final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final monthlyTransactionsProvider = StreamProvider.autoDispose((ref) {
  final month = ref.watch(selectedMonthProvider);
  return ref.watch(transactionRepositoryProvider).watchForMonth(month);
});
