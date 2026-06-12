import 'package:drift/drift.dart';

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get category => text()(); // fuel / lube
  TextColumn get unit => text()(); // liters / pieces
  RealColumn get pricePerUnit => real().withDefault(const Constant(0))();
  RealColumn get costPerUnit => real().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}
