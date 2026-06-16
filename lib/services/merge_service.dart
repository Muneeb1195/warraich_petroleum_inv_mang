import 'dart:developer' show log;
import 'package:drift/drift.dart';
import '../database/app_database.dart';

class MergeService {
  static Future<void> mergeDatabases(AppDatabase current, AppDatabase backup) async {
    log('merge: starting merge...');

    await current.transaction(() async {
      final productMap = await _mergeProducts(current, backup);
      log('merge: products done (${productMap.length} remapped)');

      final employeeMap = await _mergeEmployees(current, backup);
      log('merge: employees done (${employeeMap.length} remapped)');

      await _mergeInventory(current, backup, productMap);
      log('merge: inventory done');

      final shiftMap = await _mergeShifts(current, backup, employeeMap);
      log('merge: shifts done (${shiftMap.length} remapped)');

      await _mergeInventoryTransactions(current, backup, productMap, shiftMap);
      log('merge: inventory transactions done');

      await _mergeShiftSales(current, backup, shiftMap, productMap);
      log('merge: shift sales done');

      await _mergeExpenses(current, backup, shiftMap, employeeMap);
      log('merge: expenses done');

      await _mergePayroll(current, backup, employeeMap);
      log('merge: payroll done');

      await _mergeSettings(current, backup);
      log('merge: settings done');
    });

    log('merge: complete');
  }

  static Future<Map<int, int>> _mergeProducts(AppDatabase current, AppDatabase backup) async {
    final currentProducts = await current.select(current.products).get();
    final backupProducts = await backup.select(backup.products).get();
    final idMap = <int, int>{};

    final currentByName = <String, Product>{};
    for (final p in currentProducts) {
      currentByName['${p.name}|${p.category}|${p.unit}'] = p;
    }

    for (final bp in backupProducts) {
      final key = '${bp.name}|${bp.category}|${bp.unit}';
      final existing = currentByName[key];

      if (existing != null) {
        idMap[bp.id] = existing.id;
        // Always update from backup (backup is the source of truth for restore)
        await current.update(current.products).replace(bp.copyWith(id: existing.id));
      } else {
        final newId = await current.into(current.products).insert(
          ProductsCompanion.insert(
            name: bp.name,
            category: bp.category,
            unit: bp.unit,
            pricePerUnit: Value(bp.pricePerUnit),
            costPerUnit: Value(bp.costPerUnit),
            isActive: Value(bp.isActive),
            updatedAt: Value(bp.updatedAt),
          ),
        );
        idMap[bp.id] = newId;
      }
    }

    return idMap;
  }

  static Future<Map<int, int>> _mergeEmployees(AppDatabase current, AppDatabase backup) async {
    final currentEmployees = await current.select(current.employees).get();
    final backupEmployees = await backup.select(backup.employees).get();
    final idMap = <int, int>{};

    final currentByName = <String, Employee>{};
    for (final e in currentEmployees) {
      currentByName['${e.name}|${e.role}|${e.phone ?? ''}'] = e;
    }

    for (final be in backupEmployees) {
      final key = '${be.name}|${be.role}|${be.phone ?? ''}';
      final existing = currentByName[key];

      if (existing != null) {
        idMap[be.id] = existing.id;
        if (be.updatedAt.isAfter(existing.updatedAt)) {
          await current.update(current.employees).replace(be.copyWith(id: existing.id));
        }
      } else {
        final newId = await current.into(current.employees).insert(
          EmployeesCompanion.insert(
            name: be.name,
            phone: Value(be.phone),
            role: be.role,
            defaultShift: Value(be.defaultShift),
            salary: Value(be.salary),
            joiningDate: Value(be.joiningDate),
            isActive: Value(be.isActive),
            updatedAt: Value(be.updatedAt),
          ),
        );
        idMap[be.id] = newId;
      }
    }

    return idMap;
  }

  static Future<void> _mergeInventory(AppDatabase current, AppDatabase backup, Map<int, int> productMap) async {
    final backupInventory = await backup.select(backup.inventory).get();
    final currentInventory = await current.select(current.inventory).get();
    final currentByProductId = <int, InventoryData>{};
    for (final inv in currentInventory) {
      currentByProductId[inv.productId] = inv;
    }

    for (final bi in backupInventory) {
      final newProductId = productMap[bi.productId];
      if (newProductId == null) continue;
      final existing = currentByProductId[newProductId];

      if (existing != null) {
        // Always update from backup (backup is the source of truth for restore)
        await current.update(current.inventory).replace(
          bi.copyWith(id: existing.id, productId: newProductId),
        );
      } else {
        await current.into(current.inventory).insert(
          InventoryCompanion.insert(
            productId: newProductId,
            currentStock: Value(bi.currentStock),
            minStock: Value(bi.minStock),
            maxStock: Value(bi.maxStock),
            lastUpdated: Value(bi.lastUpdated),
          ),
        );
      }
    }
  }

  static Future<void> _mergeInventoryTransactions(AppDatabase current, AppDatabase backup, Map<int, int> productMap, Map<int, int> shiftMap) async {
    final backupTxns = await backup.select(backup.inventoryTransactions).get();
    final currentTxns = await current.select(current.inventoryTransactions).get();
    final currentByKey = <String, InventoryTransaction>{};
    for (final t in currentTxns) {
      currentByKey['${t.createdAt}|${t.type}|${t.productId}|${t.quantity}'] = t;
    }

    for (final bt in backupTxns) {
      final newProductId = productMap[bt.productId];
      if (newProductId == null) continue;
      final newRefId = bt.referenceId != null ? shiftMap[bt.referenceId!] : null;
      final key = '${bt.createdAt}|${bt.type}|$newProductId|${bt.quantity}';
      final existing = currentByKey[key];

      if (existing != null) {
        if (bt.createdAt.isAfter(existing.createdAt)) {
          await current.update(current.inventoryTransactions).replace(bt.copyWith(
            id: existing.id,
            productId: newProductId,
            referenceId: Value(newRefId),
          ));
        }
      } else {
        await current.into(current.inventoryTransactions).insert(
          InventoryTransactionsCompanion.insert(
            productId: newProductId,
            type: bt.type,
            quantity: bt.quantity,
            unitCost: Value(bt.unitCost),
            referenceId: Value(newRefId),
            notes: Value(bt.notes),
            createdAt: Value(bt.createdAt),
          ),
        );
      }
    }
  }

  static Future<Map<int, int>> _mergeShifts(AppDatabase current, AppDatabase backup, Map<int, int> employeeMap) async {
    final currentShifts = await current.select(current.shifts).get();
    final backupShifts = await backup.select(backup.shifts).get();
    final idMap = <int, int>{};

    final currentByDate = <String, Shift>{};
    for (final s in currentShifts) {
      currentByDate['${s.startDate}|${s.type}'] = s;
    }

    for (final bs in backupShifts) {
      final key = '${bs.startDate}|${bs.type}';
      final existing = currentByDate[key];

      final newClosedBy = bs.closedBy != null ? employeeMap[bs.closedBy!] : null;

      if (existing != null) {
        idMap[bs.id] = existing.id;
        if (bs.updatedAt.isAfter(existing.updatedAt)) {
          await current.update(current.shifts).replace(bs.copyWith(
            id: existing.id,
            closedBy: Value(newClosedBy),
          ));
        }
      } else {
        final newId = await current.into(current.shifts).insert(
          ShiftsCompanion.insert(
            type: bs.type,
            startDate: bs.startDate,
            endDate: Value(bs.endDate),
            status: Value(bs.status),
            totalSales: Value(bs.totalSales),
            totalExpenses: Value(bs.totalExpenses),
            notes: Value(bs.notes),
            closedBy: Value(newClosedBy),
            updatedAt: Value(bs.updatedAt),
          ),
        );
        idMap[bs.id] = newId;
      }
    }

    return idMap;
  }

  static Future<void> _mergeShiftSales(AppDatabase current, AppDatabase backup, Map<int, int> shiftMap, Map<int, int> productMap) async {
    final backupSales = await backup.select(backup.shiftSales).get();
    final currentSales = await current.select(current.shiftSales).get();
    final currentByKey = <String, ShiftSale>{};
    for (final s in currentSales) {
      currentByKey['${s.shiftId}|${s.productId}|${s.openingReading.toStringAsFixed(6)}'] = s;
    }

    for (final bs in backupSales) {
      final newShiftId = shiftMap[bs.shiftId];
      final newProductId = productMap[bs.productId];
      if (newShiftId == null || newProductId == null) continue;
      final key = '$newShiftId|$newProductId|${bs.openingReading.toStringAsFixed(6)}';
      final existing = currentByKey[key];

      if (existing != null) {
        if (bs.updatedAt.isAfter(existing.updatedAt)) {
          await current.update(current.shiftSales).replace(bs.copyWith(
            id: existing.id,
            shiftId: newShiftId,
            productId: newProductId,
          ));
        }
      } else {
        await current.into(current.shiftSales).insert(
          ShiftSalesCompanion.insert(
            shiftId: newShiftId,
            productId: newProductId,
            openingReading: Value(bs.openingReading),
            closingReading: Value(bs.closingReading),
            quantitySold: Value(bs.quantitySold),
            totalAmount: Value(bs.totalAmount),
            cashCollected: Value(bs.cashCollected),
            cardCollected: Value(bs.cardCollected),
            creditCollected: Value(bs.creditCollected),
            updatedAt: Value(bs.updatedAt),
          ),
        );
      }
    }
  }

  static Future<void> _mergeExpenses(AppDatabase current, AppDatabase backup, Map<int, int> shiftMap, Map<int, int> employeeMap) async {
    final backupExpenses = await backup.select(backup.expenses).get();
    final currentExpenses = await current.select(current.expenses).get();
    final currentByKey = <String, Expense>{};
    for (final e in currentExpenses) {
      currentByKey['${e.date}|${e.category}|${e.amount}|${e.description}|${e.createdAt}'] = e;
    }

    for (final be in backupExpenses) {
      final key = '${be.date}|${be.category}|${be.amount}|${be.description}|${be.createdAt}';
      final existing = currentByKey[key];

      if (existing != null) {
        if (be.updatedAt.isAfter(existing.updatedAt)) {
          final newShiftId = be.shiftId != null ? shiftMap[be.shiftId!] : null;
          final newCreatedBy = be.createdBy != null ? employeeMap[be.createdBy!] : null;
          await current.update(current.expenses).replace(be.copyWith(
            id: existing.id,
            shiftId: Value(newShiftId),
            createdBy: Value(newCreatedBy),
          ));
        }
      } else {
        final newShiftId = be.shiftId != null ? shiftMap[be.shiftId!] : null;
        final newCreatedBy = be.createdBy != null ? employeeMap[be.createdBy!] : null;

        await current.into(current.expenses).insert(
          ExpensesCompanion.insert(
            category: be.category,
            amount: be.amount,
            description: Value(be.description),
            date: be.date,
            shiftId: Value(newShiftId),
            createdBy: Value(newCreatedBy),
            createdAt: Value(be.createdAt),
            updatedAt: Value(be.updatedAt),
          ),
        );
      }
    }
  }

  static Future<void> _mergePayroll(AppDatabase current, AppDatabase backup, Map<int, int> employeeMap) async {
    final backupPayroll = await backup.select(backup.payroll).get();
    final currentPayroll = await current.select(current.payroll).get();
    final currentByKey = <String, PayrollData>{};
    for (final p in currentPayroll) {
      currentByKey['${p.employeeId}|${p.month}|${p.year}'] = p;
    }

    for (final bp in backupPayroll) {
      final newEmployeeId = employeeMap[bp.employeeId];
      if (newEmployeeId == null) continue;
      final key = '$newEmployeeId|${bp.month}|${bp.year}';
      final existing = currentByKey[key];

      if (existing != null) {
        if (bp.updatedAt.isAfter(existing.updatedAt)) {
          await current.update(current.payroll).replace(bp.copyWith(
            id: existing.id,
            employeeId: newEmployeeId,
          ));
        }
      } else {
        await current.into(current.payroll).insert(
          PayrollCompanion.insert(
            employeeId: newEmployeeId,
            month: bp.month,
            year: bp.year,
            baseSalary: bp.baseSalary,
            deductions: Value(bp.deductions),
            advances: Value(bp.advances),
            bonuses: Value(bp.bonuses),
            netPay: bp.netPay,
            isPaid: Value(bp.isPaid),
            paidDate: Value(bp.paidDate),
            notes: Value(bp.notes),
            updatedAt: Value(bp.updatedAt),
          ),
        );
      }
    }
  }

  static Future<void> _mergeSettings(AppDatabase current, AppDatabase backup) async {
    final backupSettings = await backup.select(backup.appSettings).get();
    for (final setting in backupSettings) {
      await current.into(current.appSettings).insertOnConflictUpdate(
        AppSettingsCompanion.insert(
          key: setting.key,
          value: setting.value,
        ),
      );
    }
  }
}
