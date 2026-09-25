import 'package:get/get.dart';
import 'en_us.dart';
import 'my_mm.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': enUS,
    'my_MM': myMM,
  };
}
