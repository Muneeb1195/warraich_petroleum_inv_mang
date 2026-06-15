import 'dart:async';
import 'dart:developer' show log;
import 'package:drift/drift.dart' show Value;
import '../database/app_database.dart';
import 'firebase_auth_service.dart';

enum SyncStatus { idle, syncing, error }

class SyncService {
  final FirebaseAuthService _auth;
  final AppDatabase _localDb;
  final String _uid;
  Timer? _periodicTimer;
  SyncStatus _status = SyncStatus.idle;
  String? _lastError;
  bool _syncInProgress = false;

  SyncService(this._auth, this._localDb, this._uid);

  SyncStatus get status => _status;
  String? get lastError => _lastError;

  final _statusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get statusStream async* {
    yield _status;
    yield* _statusController.stream;
  }

  void _setStatus(SyncStatus s) {
    _status = s;
    if (_statusController.isClosed) return;
    _statusController.add(s);
  }

  String get _basePath => 'users/$_uid';

  Future<void> initialize() async {
    _setStatus(SyncStatus.syncing);
    bool pullSucceeded = false;
    try {
      await pullAllFromCloud();
      pullSucceeded = true;
      _setStatus(SyncStatus.idle);
    } catch (e) {
      _lastError = e.toString();
      log('Sync init pull failed: $e');
      _setStatus(SyncStatus.error);
    }
    if (pullSucceeded) {
      try {
        await syncAllToCloud();
        _setStatus(SyncStatus.idle);
      } catch (e) {
        _lastError = e.toString();
        log('Sync initial push failed: $e');
        _setStatus(SyncStatus.error);
      }
    }

    _periodicTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      try {
        await pullAllFromCloud();
        await syncAllToCloud();
        _setStatus(SyncStatus.idle);
      } catch (e) {
        _lastError = e.toString();
        log('Sync periodic failed: $e');
        _setStatus(SyncStatus.error);
      }
    });
  }

  void dispose() {
    _periodicTimer?.cancel();
    _statusController.close();
  }

  Future<void> syncAllToCloud() async {
    if (_syncInProgress) return;
    _syncInProgress = true;
    try {
      _setStatus(SyncStatus.syncing);
      await _syncAllToNode('shifts', _getShiftsSnapshot);
      await _syncAllToNode('shift_sales', _getShiftSalesSnapshot);
      await _syncAllToNode('expenses', _getExpensesSnapshot);
      await _syncAllToNode('products', _getProductsSnapshot);
      await _syncAllToNode('employees', _getEmployeesSnapshot);
      await _syncAllToNode('payroll', _getPayrollSnapshot);
    } finally {
      _syncInProgress = false;
    }
  }

  Future<void> syncCollection(String name) async {
    _setStatus(SyncStatus.syncing);
    switch (name) {
      case 'shifts':
        await _syncAllToNode('shifts', _getShiftsSnapshot);
      case 'shift_sales':
        await _syncAllToNode('shift_sales', _getShiftSalesSnapshot);
      case 'expenses':
        await _syncAllToNode('expenses', _getExpensesSnapshot);
      case 'products':
        await _syncAllToNode('products', _getProductsSnapshot);
      case 'employees':
        await _syncAllToNode('employees', _getEmployeesSnapshot);
      case 'payroll':
        await _syncAllToNode('payroll', _getPayrollSnapshot);
    }
    _setStatus(SyncStatus.idle);
  }

  Future<void> syncRecord(String collection, String id, Map<String, dynamic> data) async {
    _setStatus(SyncStatus.syncing);
    try {
      await _auth.putData('$_basePath/$collection/$id', data);
    } finally {
      _setStatus(SyncStatus.idle);
    }
  }

  Future<void> deleteRecord(String collection, String id) async {
    _setStatus(SyncStatus.syncing);
    try {
      await _auth.deleteData('$_basePath/$collection/$id');
    } finally {
      _setStatus(SyncStatus.idle);
    }
  }

  Future<void> pullAllFromCloud() async {
    if (_syncInProgress) return;
    _syncInProgress = true;
    try {
      await _pullNode('shifts', _applyShiftsFromCloud);
      await _pullNode('shift_sales', _applyShiftSalesFromCloud);
      await _pullNode('expenses', _applyExpensesFromCloud);
      await _pullNode('products', _applyProductsFromCloud);
      await _pullNode('employees', _applyEmployeesFromCloud);
      await _pullNode('payroll', _applyPayrollFromCloud);
    } finally {
      _syncInProgress = false;
    }
  }

  Future<void> _syncAllToNode(String node, Future<Map<String, dynamic>> Function() getData) async {
    final data = await getData();
    log('sync: pushing $node (${data.length} items) to cloud');
    await _auth.putData('$_basePath/$node', data);
    log('sync: $node pushed OK');
  }

  Future<Map<String, dynamic>> _getShiftsSnapshot() async {
    final shifts = await _localDb.shiftDao.getAllShifts();
    return {for (final s in shifts) s.id.toString(): {
      'id': s.id,
      'type': s.type,
      'status': s.status,
      'startDate': s.startDate.toIso8601String(),
      'endDate': s.endDate?.toIso8601String(),
      'closedBy': s.closedBy,
      'totalSales': s.totalSales,
      'totalExpenses': s.totalExpenses,
      'updatedAt': s.updatedAt.toIso8601String(),
    }};
  }

  Future<Map<String, dynamic>> _getShiftSalesSnapshot() async {
    final sales = await _localDb.shiftDao.getAllShiftSales();
    return {for (final s in sales) s.id.toString(): {
      'id': s.id,
      'shiftId': s.shiftId,
      'productId': s.productId,
      'openingReading': s.openingReading,
      'closingReading': s.closingReading,
      'quantitySold': s.quantitySold,
      'totalAmount': s.totalAmount,
      'cashCollected': s.cashCollected,
      'cardCollected': s.cardCollected,
      'creditCollected': s.creditCollected,
      'createdAt': s.updatedAt.toIso8601String(),
      'updatedAt': s.updatedAt.toIso8601String(),
    }};
  }

  Future<Map<String, dynamic>> _getExpensesSnapshot() async {
    final expenses = await _localDb.expenseDao.getAllExpenses();
    return {for (final e in expenses) e.id.toString(): {
      'id': e.id,
      'category': e.category,
      'amount': e.amount,
      'description': e.description,
      'date': e.date.toIso8601String(),
      'shiftId': e.shiftId,
      'createdBy': e.createdBy,
      'updatedAt': e.updatedAt.toIso8601String(),
    }};
  }

  Future<Map<String, dynamic>> _getProductsSnapshot() async {
    final products = await _localDb.productDao.getAllProductsIncludingInactive();
    return {for (final p in products) p.id.toString(): {
      'id': p.id,
      'name': p.name,
      'category': p.category,
      'unit': p.unit,
      'pricePerUnit': p.pricePerUnit,
      'costPerUnit': p.costPerUnit,
      'isActive': p.isActive,
      'updatedAt': p.updatedAt.toIso8601String(),
    }};
  }

  Future<Map<String, dynamic>> _getEmployeesSnapshot() async {
    final employees = await _localDb.employeeDao.getAllEmployeesIncludingInactive();
    return {for (final e in employees) e.id.toString(): {
      'id': e.id,
      'name': e.name,
      'phone': e.phone,
      'role': e.role,
      'defaultShift': e.defaultShift,
      'salary': e.salary,
      'isActive': e.isActive,
      'updatedAt': e.updatedAt.toIso8601String(),
    }};
  }

  Future<Map<String, dynamic>> _getPayrollSnapshot() async {
    final payroll = await _localDb.payrollDao.getAllPayroll();
    return {for (final p in payroll) p.id.toString(): {
      'id': p.id,
      'employeeId': p.employeeId,
      'month': p.month,
      'year': p.year,
      'baseSalary': p.baseSalary,
      'deductions': p.deductions,
      'advances': p.advances,
      'bonuses': p.bonuses,
      'netPay': p.netPay,
      'isPaid': p.isPaid,
      'paidDate': p.paidDate?.toIso8601String(),
      'updatedAt': p.updatedAt.toIso8601String(),
    }};
  }

  Future<void> _pullNode(String node, Future<void> Function(Map<dynamic, dynamic>) apply) async {
    final data = await _auth.getData('$_basePath/$node');
    if (data != null) {
      await apply(data);
    }
  }

  Future<void> _applyExpensesFromCloud(Map<dynamic, dynamic> entries) async {
    for (final entry in entries.values) {
      try {
        final data = entry as Map<dynamic, dynamic>;
        final id = data['id'] as int;
        final cloudUpdatedAt = DateTime.parse(data['updatedAt'] as String);

        final local = await _localDb.expenseDao.getExpenseById(id);
        if (local != null) {
          if (cloudUpdatedAt.isAfter(local.updatedAt)) {
            await _localDb.expenseDao.updateExpense(id, ExpensesCompanion(
              category: Value(data['category'] as String),
              amount: Value((data['amount'] as num).toDouble()),
              description: Value(data['description'] as String?),
              date: Value(DateTime.parse(data['date'] as String)),
              shiftId: Value(data['shiftId'] as int?),
              createdBy: Value(data['createdBy'] as int?),
              updatedAt: Value(cloudUpdatedAt),
            ));
          }
        } else {
          await _localDb.expenseDao.addExpense(ExpensesCompanion(
            category: Value(data['category'] as String),
            amount: Value((data['amount'] as num).toDouble()),
            description: Value(data['description'] as String?),
            date: Value(DateTime.parse(data['date'] as String)),
            shiftId: Value(data['shiftId'] as int?),
            createdBy: Value(data['createdBy'] as int?),
            updatedAt: Value(cloudUpdatedAt),
          ));
        }
      } catch (e) {
        log('sync: skipping malformed expense record: $e');
      }
    }
  }

  Future<void> _applyShiftsFromCloud(Map<dynamic, dynamic> entries) async {
    for (final entry in entries.values) {
      try {
        final data = entry as Map<dynamic, dynamic>;
        final id = data['id'] as int;
        final cloudUpdatedAt = DateTime.parse(data['updatedAt'] as String);

        final local = await _localDb.shiftDao.getShiftById(id);
        if (local != null) {
          if (cloudUpdatedAt.isAfter(local.updatedAt)) {
            await _localDb.shiftDao.updateShift(id, ShiftsCompanion(
              type: Value(data['type'] as String),
              status: Value(data['status'] as String),
              startDate: Value(DateTime.parse(data['startDate'] as String)),
              endDate: Value(data['endDate'] != null ? DateTime.parse(data['endDate'] as String) : null),
              closedBy: Value(data['closedBy'] as int?),
              totalSales: Value((data['totalSales'] as num).toDouble()),
              totalExpenses: Value((data['totalExpenses'] as num).toDouble()),
              updatedAt: Value(cloudUpdatedAt),
            ));
          }
        } else {
          await _localDb.shiftDao.createShift(ShiftsCompanion(
            type: Value(data['type'] as String),
            status: Value(data['status'] as String),
            startDate: Value(DateTime.parse(data['startDate'] as String)),
            endDate: Value(data['endDate'] != null ? DateTime.parse(data['endDate'] as String) : null),
            closedBy: Value(data['closedBy'] as int?),
            totalSales: Value((data['totalSales'] as num).toDouble()),
            totalExpenses: Value((data['totalExpenses'] as num).toDouble()),
            updatedAt: Value(cloudUpdatedAt),
          ));
        }
      } catch (e) {
        log('sync: skipping malformed shift record: $e');
      }
    }
  }

  Future<void> _applyShiftSalesFromCloud(Map<dynamic, dynamic> entries) async {
    for (final entry in entries.values) {
      try {
        final data = entry as Map<dynamic, dynamic>;
        final id = data['id'] as int;
        final cloudUpdatedAt = DateTime.parse(data['updatedAt'] as String);
        final quantitySold = (data['quantitySold'] as num).toDouble();

        final local = await _localDb.shiftDao.getSaleById(id);
        if (local != null) {
          if (cloudUpdatedAt.isAfter(local.updatedAt)) {
            await _localDb.shiftDao.updateSaleInShift(id, ShiftSalesCompanion(
              shiftId: Value(data['shiftId'] as int),
              productId: Value(data['productId'] as int),
              openingReading: Value((data['openingReading'] as num).toDouble()),
              closingReading: Value((data['closingReading'] as num).toDouble()),
              quantitySold: Value(quantitySold),
              totalAmount: Value((data['totalAmount'] as num).toDouble()),
              cashCollected: Value((data['cashCollected'] as num).toDouble()),
              cardCollected: Value((data['cardCollected'] as num).toDouble()),
              creditCollected: Value((data['creditCollected'] as num).toDouble()),
              updatedAt: Value(cloudUpdatedAt),
            ));
          }
        } else {
          final inventory = await _localDb.productDao.getInventory(data['productId'] as int);
          if (inventory != null && inventory.currentStock < quantitySold) {
            log('sync: skipping shift_sale $id from cloud — insufficient stock (${inventory.currentStock} < $quantitySold)');
            continue;
          }
          await _localDb.shiftDao.addSaleToShift(ShiftSalesCompanion(
            shiftId: Value(data['shiftId'] as int),
            productId: Value(data['productId'] as int),
            openingReading: Value((data['openingReading'] as num).toDouble()),
            closingReading: Value((data['closingReading'] as num).toDouble()),
            quantitySold: Value(quantitySold),
            totalAmount: Value((data['totalAmount'] as num).toDouble()),
            cashCollected: Value((data['cashCollected'] as num).toDouble()),
            cardCollected: Value((data['cardCollected'] as num).toDouble()),
            creditCollected: Value((data['creditCollected'] as num).toDouble()),
            updatedAt: Value(cloudUpdatedAt),
          ));
        }
      } catch (e) {
        log('sync: skipping malformed shift_sale record: $e');
      }
    }
  }

  Future<void> _applyProductsFromCloud(Map<dynamic, dynamic> entries) async {
    for (final entry in entries.values) {
      try {
        final data = entry as Map<dynamic, dynamic>;
        final id = data['id'] as int;
        final cloudUpdatedAt = DateTime.parse(data['updatedAt'] as String);

        final local = await _localDb.productDao.getProductById(id);
        if (local != null) {
          if (cloudUpdatedAt.isAfter(local.updatedAt)) {
            await _localDb.productDao.updateProduct(id, ProductsCompanion(
              name: Value(data['name'] as String),
              category: Value(data['category'] as String),
              unit: Value(data['unit'] as String),
              pricePerUnit: Value((data['pricePerUnit'] as num).toDouble()),
              costPerUnit: Value((data['costPerUnit'] as num).toDouble()),
              isActive: Value(data['isActive'] as bool),
              updatedAt: Value(cloudUpdatedAt),
            ));
          }
        } else {
          await _localDb.productDao.addProduct(ProductsCompanion(
            name: Value(data['name'] as String),
            category: Value(data['category'] as String),
            unit: Value(data['unit'] as String),
            pricePerUnit: Value((data['pricePerUnit'] as num).toDouble()),
            costPerUnit: Value((data['costPerUnit'] as num).toDouble()),
            isActive: Value(data['isActive'] as bool),
            updatedAt: Value(cloudUpdatedAt),
          ));
        }
      } catch (e) {
        log('sync: skipping malformed product record: $e');
      }
    }
  }

  Future<void> _applyEmployeesFromCloud(Map<dynamic, dynamic> entries) async {
    for (final entry in entries.values) {
      try {
        final data = entry as Map<dynamic, dynamic>;
        final id = data['id'] as int;
        final cloudUpdatedAt = DateTime.parse(data['updatedAt'] as String);

        final local = await _localDb.employeeDao.getEmployeeById(id);
        if (local != null) {
          if (cloudUpdatedAt.isAfter(local.updatedAt)) {
            await _localDb.employeeDao.updateEmployee(id, EmployeesCompanion(
              name: Value(data['name'] as String),
              phone: Value(data['phone'] as String?),
              role: Value(data['role'] as String),
              defaultShift: Value(data['defaultShift'] as String? ?? 'both'),
              salary: Value((data['salary'] as num).toDouble()),
              isActive: Value(data['isActive'] as bool),
              updatedAt: Value(cloudUpdatedAt),
            ));
          }
        } else {
          await _localDb.employeeDao.addEmployee(EmployeesCompanion(
            name: Value(data['name'] as String),
            phone: Value(data['phone'] as String?),
            role: Value(data['role'] as String),
            defaultShift: Value(data['defaultShift'] as String? ?? 'both'),
            salary: Value((data['salary'] as num).toDouble()),
            isActive: Value(data['isActive'] as bool),
            updatedAt: Value(cloudUpdatedAt),
          ));
        }
      } catch (e) {
        log('sync: skipping malformed employee record: $e');
      }
    }
  }

  Future<void> _applyPayrollFromCloud(Map<dynamic, dynamic> entries) async {
    for (final entry in entries.values) {
      try {
        final data = entry as Map<dynamic, dynamic>;
        final id = data['id'] as int;
        final cloudUpdatedAt = DateTime.parse(data['updatedAt'] as String);

        final local = await _localDb.payrollDao.getPayrollById(id);
        if (local != null) {
          if (cloudUpdatedAt.isAfter(local.updatedAt)) {
            await _localDb.payrollDao.updatePayroll(id, PayrollCompanion(
              employeeId: Value(data['employeeId'] as int),
              month: Value(data['month'] as int),
              year: Value(data['year'] as int),
              baseSalary: Value((data['baseSalary'] as num).toDouble()),
              deductions: Value((data['deductions'] as num).toDouble()),
              advances: Value((data['advances'] as num).toDouble()),
              bonuses: Value((data['bonuses'] as num).toDouble()),
              netPay: Value((data['netPay'] as num).toDouble()),
              isPaid: Value(data['isPaid'] as bool),
              paidDate: Value(data['paidDate'] != null ? DateTime.parse(data['paidDate'] as String) : null),
              updatedAt: Value(cloudUpdatedAt),
            ));
          }
        } else {
          await _localDb.payrollDao.generatePayrollRaw(PayrollCompanion(
            employeeId: Value(data['employeeId'] as int),
            month: Value(data['month'] as int),
            year: Value(data['year'] as int),
            baseSalary: Value((data['baseSalary'] as num).toDouble()),
            deductions: Value((data['deductions'] as num).toDouble()),
            advances: Value((data['advances'] as num).toDouble()),
            bonuses: Value((data['bonuses'] as num).toDouble()),
            netPay: Value((data['netPay'] as num).toDouble()),
            isPaid: Value(data['isPaid'] as bool),
            paidDate: Value(data['paidDate'] != null ? DateTime.parse(data['paidDate'] as String) : null),
            updatedAt: Value(cloudUpdatedAt),
          ));
        }
      } catch (e) {
        log('sync: skipping malformed payroll record: $e');
      }
    }
  }
}
