import 'package:drift/drift.dart';

@DataClassName('Account')
class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 60)();
  TextColumn get type => text()(); // cash, bank, card, wallet
  TextColumn get currencyCode => text().withDefault(const Constant('TND'))();
  IntColumn get initialBalanceMinor =>
      integer().withDefault(const Constant(0))();
  IntColumn get colorValue => integer()();
  TextColumn get iconKey => text()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
