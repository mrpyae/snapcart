import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../../data/local/db_helper.dart';
import '../../../data/models/expense_model.dart';
import '../../../Controller/AppController.dart';

class ExpenseController extends GetxController {
  final dbHelper = DBHelper.instance;
  final AppController appController = Get.find<AppController>();

  final RxList<ExpenseModel> expenses = <ExpenseModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    isLoading.value = true;
    final db = await dbHelper.database;
    final bizId = appController.currentAccount.value?.businessId ?? 'default_biz';
    final res = await db.query(
      'expenses',
      where: 'business_id = ?',
      whereArgs: [bizId],
      orderBy: 'expense_date DESC',
    );
    expenses.assignAll(res.map((e) => ExpenseModel.fromJson(e)).toList());
    isLoading.value = false;
  }

  Future<void> addExpense({
    required String category,
    required double amount,
    String paymentMethod = 'cash',
    String? description,
  }) async {
    final user = appController.currentUser.value;
    final account = appController.currentAccount.value;
    if (user == null || account == null) return;

    final db = await dbHelper.database;
    final expense = ExpenseModel(
      id: const Uuid().v4(),
      businessId: account.businessId,
      category: category,
      amount: amount,
      userId: user.id,
      paymentMethod: paymentMethod,
      expenseDate: DateTime.now().toIso8601String(),
      description: description,
      syncStatus: 0,
    );

    await db.insert('expenses', expense.toMap());
    await loadExpenses();
    appController.triggerAutoSync();
  }
}
