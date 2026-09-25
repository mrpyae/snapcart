import '../local/category_dao.dart';
import '../local/customer_dao.dart';
import '../local/customer_order_dao.dart';
import '../local/delivery_service_dao.dart';
import '../local/product_dao.dart';
import '../local/purchase_dao.dart';
import '../local/supplier_category_dao.dart';
import '../local/supplier_dao.dart';
import '../local/sync_dao.dart';
import '../local/user_dao.dart';
import '../providers/api_provider.dart';

class SyncRepository {
  final SyncDao syncDao = SyncDao();
  final ProductDao productDao = ProductDao();
  final CustomerDao customerDao = CustomerDao();
  final CustomerOrderDao customerOrderDao = CustomerOrderDao();
  final CategoryDao categoryDao = CategoryDao();
  final SupplierCategoryDao supplierCategoryDao = SupplierCategoryDao();
  final SupplierDao supplierDao = SupplierDao();
  final PurchaseDao purchaseDao = PurchaseDao();
  final DeliveryServiceDao deliveryServiceDao = DeliveryServiceDao();
  final UserDao userDao = UserDao();
  final ApiProvider apiProvider = ApiProvider();

  Future<Map<String, dynamic>> performSync({String? lastSyncTimestamp, String businessId = 'default_biz'}) async {
    // 1. Gather local pending records
    final pendingPayload = await syncDao.getPendingPushPayload(businessId: businessId);

    // 2. Transmit to server
    final syncRes = await apiProvider.performSync(pendingPayload, lastSyncTimestamp, businessId: businessId);

    if (syncRes['status'] == 'success') {
      // 3. Mark pushed records as synced locally
      if (syncRes['synced_ids'] != null) {
        await syncDao.markSynced(syncRes['synced_ids']);
      }

      // 4. Ingest delta changes from server
      final delta = syncRes['delta'];
      if (delta != null) {
        if (delta['categories'] != null) {
          await categoryDao.batchSaveCategories(delta['categories']);
        }
        if (delta['supplier_categories'] != null) {
          await supplierCategoryDao.batchSaveCategories(delta['supplier_categories']);
        }
        if (delta['suppliers'] != null) {
          await supplierDao.batchSaveSuppliers(delta['suppliers']);
        }
        if (delta['purchases'] != null) {
          await purchaseDao.batchSavePurchases(delta['purchases']);
        }
        if (delta['products'] != null) {
          await productDao.batchSaveProducts(delta['products']);
        }
        if (delta['customers'] != null) {
          await customerDao.batchSaveCustomers(delta['customers']);
        }
        if (delta['customer_orders'] != null) {
          await customerOrderDao.batchSaveCustomerOrders(delta['customer_orders']);
        }
        if (delta['delivery_services'] != null) {
          await deliveryServiceDao.batchSaveDeliveryServices(delta['delivery_services']);
        }
        if (delta['delivery_payments'] != null) {
          await deliveryServiceDao.batchSaveDeliveryPayments(delta['delivery_payments']);
        }
        if (delta['users'] != null && delta['user_accounts'] != null) {
          await userDao.cacheUsersAndAccounts(delta['users'], delta['user_accounts']);
        }
      }

      return {
        'success': true,
        'server_timestamp': delta != null ? delta['server_timestamp'] : null,
      };
    }

    return {
      'success': false,
      'message': syncRes['message'] ?? 'Sync failed',
    };
  }
}
