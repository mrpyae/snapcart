import 'package:get/get.dart';
import '../modules/auth/views/login_view.dart';
import '../modules/home/views/home_view.dart';
import '../modules/pos/views/pos_view.dart';
import '../modules/settings/views/voucher_builder_view.dart';
import 'app_routes.dart';

class AppPages {
  static const INITIAL = Routes.LOGIN;

  static final routes = [
    GetPage(
      name: Routes.LOGIN,
      page: () => const LoginView(),
    ),
    GetPage(
      name: Routes.HOME,
      page: () => const HomeView(),
    ),
    GetPage(
      name: Routes.POS,
      page: () => const POSView(),
    ),
    GetPage(
      name: Routes.VOUCHER_BUILDER,
      page: () => const VoucherBuilderView(),
    ),
  ];
}
