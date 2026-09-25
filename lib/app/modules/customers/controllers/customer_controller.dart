import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../../data/local/customer_dao.dart';
import '../../../data/models/customer_model.dart';
import '../../../Controller/AppController.dart';

class CustomerController extends GetxController {
  final CustomerDao customerDao = CustomerDao();
  final AppController appController = Get.find<AppController>();

  final RxList<CustomerModel> customers = <CustomerModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadCustomers();
  }

  Future<void> loadCustomers() async {
    isLoading.value = true;
    final bizId = appController.currentAccount.value?.businessId ?? 'default_biz';
    final list = await customerDao.getCustomers(
      query: searchQuery.value,
      businessId: bizId,
    );
    customers.assignAll(list);
    isLoading.value = false;
  }

  Future<void> saveCustomer({
    String? id,
    required String name,
    String? phone,
    String? address,
    String customerType = 'retail',
    double creditLimit = 0.0,
    double currentDebt = 0.0,
    double advanceBalance = 0.0,
  }) async {
    final bizId = appController.currentAccount.value?.businessId ?? 'default_biz';
    final customer = CustomerModel(
      id: id ?? const Uuid().v4(),
      businessId: bizId,
      name: name,
      phone: phone,
      address: address,
      customerType: customerType,
      creditLimit: creditLimit,
      currentDebt: currentDebt,
      advanceBalance: advanceBalance,
      syncStatus: 0,
    );

    await customerDao.insertOrUpdateCustomer(customer);
    await loadCustomers();
    appController.triggerAutoSync();
  }

  Future<void> repayDebt(String customerId, double amount) async {
    await customerDao.adjustCustomerDebt(customerId, -amount);
    await loadCustomers();
    appController.triggerAutoSync();
  }

  Future<void> recordAdvancePayment(String customerId, double amount) async {
    await customerDao.adjustCustomerAdvance(customerId, amount);
    await loadCustomers();
    appController.triggerAutoSync();
  }
}
