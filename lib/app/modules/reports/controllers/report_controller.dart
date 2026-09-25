import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/local/db_helper.dart';
import '../../../data/local/sale_dao.dart';
import '../../../data/models/sale_order_model.dart';
import '../../../Controller/AppController.dart';

class ReportController extends GetxController {
  final dbHelper = DBHelper.instance;
  final SaleDao saleDao = SaleDao();
  AppController? get appController => Get.isRegistered<AppController>() ? Get.find<AppController>() : null;

  // Overview metrics
  final RxDouble todaySales = 0.0.obs;
  final RxDouble todayExpenses = 0.0.obs;
  final RxDouble todayProfit = 0.0.obs;
  final RxInt totalOrdersToday = 0.obs;
  final RxDouble filteredExpenses = 0.0.obs;
  final RxBool isLoading = false.obs;

  // Sales Vouchers & Report Filters
  final RxList<SaleOrderModel> salesVouchers = <SaleOrderModel>[].obs;
  final Rx<DateTime?> startDate = Rx<DateTime?>(DateTime.now().subtract(const Duration(days: 7)));
  final Rx<DateTime?> endDate = Rx<DateTime?>(DateTime.now());
  final RxString selectedDatePreset = 'THIS_WEEK'.obs; // 'TODAY', 'YESTERDAY', 'THIS_WEEK', 'THIS_MONTH', 'ALL', 'CUSTOM'
  final RxString searchQuery = ''.obs; // Customer name, Phone, or Voucher No
  final RxString selectedPaymentMethod = 'ALL'.obs; // 'ALL', 'cash', 'kpay', 'wave', etc.

  @override
  void onInit() {
    super.onInit();
    loadDashboardMetrics();
    loadSalesVouchers();
    loadExpensesForPeriod();
  }

  // Summary Metrics
  double get filteredTotalRevenue => salesVouchers.fold(0.0, (sum, v) => sum + v.grandTotal);
  double get filteredTotalPaid => salesVouchers.fold(0.0, (sum, v) => sum + v.paidAmount);
  double get filteredTotalDue => salesVouchers.fold(0.0, (sum, v) => sum + v.dueAmount);
  double get filteredProfit => filteredTotalRevenue - filteredExpenses.value;
  int get filteredVoucherCount => salesVouchers.length;

  Future<void> loadDashboardMetrics() async {
    final db = await dbHelper.database;
    final bizId = appController?.currentAccount.value?.businessId ?? 'default_biz';
    final today = DateTime.now().toIso8601String().substring(0, 10);

    // 1. Sales metrics
    final salesRes = await db.rawQuery(
      'SELECT COUNT(*) as count, SUM(grand_total) as total_sales, SUM(paid_amount) as total_paid FROM sales_orders WHERE (business_id = ? OR business_id = "default_biz" OR business_id IS NULL OR business_id = "") AND SUBSTR(sale_date, 1, 10) = ?',
      [bizId, today],
    );
    if (salesRes.isNotEmpty) {
      totalOrdersToday.value = int.tryParse(salesRes.first['count']?.toString() ?? '0') ?? 0;
      todaySales.value = double.tryParse(salesRes.first['total_sales']?.toString() ?? '0') ?? 0.0;
    }

    // 2. Expense metrics
    final expenseRes = await db.rawQuery(
      'SELECT SUM(amount) as total_expense FROM expenses WHERE (business_id = ? OR business_id = "default_biz" OR business_id IS NULL OR business_id = "") AND SUBSTR(expense_date, 1, 10) = ?',
      [bizId, today],
    );
    if (expenseRes.isNotEmpty) {
      todayExpenses.value = double.tryParse(expenseRes.first['total_expense']?.toString() ?? '0') ?? 0.0;
    }

    // 3. Profit estimate
    todayProfit.value = todaySales.value - todayExpenses.value;
  }

  Future<void> loadExpensesForPeriod() async {
    try {
      final db = await dbHelper.database;
      final bizId = appController?.currentAccount.value?.businessId ?? 'default_biz';
      String sql = 'SELECT SUM(amount) as total FROM expenses WHERE (business_id = ? OR business_id = "default_biz" OR business_id IS NULL OR business_id = "")';
      List<dynamic> args = [bizId];

      if (startDate.value != null) {
        final startStr = startDate.value!.toIso8601String().substring(0, 10);
        sql += ' AND SUBSTR(expense_date, 1, 10) >= ?';
        args.add(startStr);
      }
      if (endDate.value != null) {
        final endStr = endDate.value!.toIso8601String().substring(0, 10);
        sql += ' AND SUBSTR(expense_date, 1, 10) <= ?';
        args.add(endStr);
      }

      final res = await db.rawQuery(sql, args);
      if (res.isNotEmpty && res.first['total'] != null) {
        filteredExpenses.value = double.tryParse(res.first['total']?.toString() ?? '0') ?? 0.0;
      } else {
        filteredExpenses.value = 0.0;
      }
    } catch (_) {
      filteredExpenses.value = 0.0;
    }
  }

  Future<void> loadSalesVouchers() async {
    isLoading.value = true;
    try {
      final bizId = appController?.currentAccount.value?.businessId ?? 'default_biz';
      final list = await saleDao.getFilteredSales(
        startDate: startDate.value,
        endDate: endDate.value,
        query: searchQuery.value,
        paymentMethod: selectedPaymentMethod.value,
        businessId: bizId,
      );
      salesVouchers.assignAll(list);
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  void setDatePreset(String preset, BuildContext context) async {
    selectedDatePreset.value = preset;
    final now = DateTime.now();

    if (preset == 'TODAY') {
      startDate.value = DateTime(now.year, now.month, now.day);
      endDate.value = DateTime(now.year, now.month, now.day);
    } else if (preset == 'YESTERDAY') {
      final yesterday = now.subtract(const Duration(days: 1));
      startDate.value = DateTime(yesterday.year, yesterday.month, yesterday.day);
      endDate.value = DateTime(yesterday.year, yesterday.month, yesterday.day);
    } else if (preset == 'THIS_WEEK') {
      startDate.value = now.subtract(const Duration(days: 7));
      endDate.value = now;
    } else if (preset == 'THIS_MONTH') {
      startDate.value = DateTime(now.year, now.month, 1);
      endDate.value = now;
    } else if (preset == 'ALL') {
      startDate.value = null;
      endDate.value = null;
    } else if (preset == 'CUSTOM') {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now().add(const Duration(days: 30)),
        initialDateRange: DateTimeRange(
          start: startDate.value ?? now.subtract(const Duration(days: 7)),
          end: endDate.value ?? now,
        ),
      );
      if (picked != null) {
        startDate.value = picked.start;
        endDate.value = picked.end;
      }
    }
    loadExpensesForPeriod();
    loadSalesVouchers();
  }
}
