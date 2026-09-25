import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:snapcart/app/data/local/db_helper.dart';
import 'package:snapcart/app/translations/app_translations.dart';
import 'package:snapcart/app/translations/en_us.dart';
import 'package:snapcart/app/translations/my_mm.dart';
import 'package:snapcart/app/Controller/AppController.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Multi-Language (English & Myanmar) Translation & Persistence Test Suite', () {
    test('Dictionary Parity: Every en_US key exists and is non-empty in my_MM', () {
      expect(enUS.isNotEmpty, true, reason: 'en_US dictionary should not be empty');
      expect(myMM.isNotEmpty, true, reason: 'my_MM dictionary should not be empty');

      final missingKeysInMyanmar = <String>[];
      final emptyValuesInMyanmar = <String>[];

      for (final key in enUS.keys) {
        if (!myMM.containsKey(key)) {
          missingKeysInMyanmar.add(key);
        } else if (myMM[key]!.trim().isEmpty) {
          emptyValuesInMyanmar.add(key);
        }
      }

      expect(missingKeysInMyanmar, isEmpty,
          reason: 'my_MM is missing translation keys: $missingKeysInMyanmar');
      expect(emptyValuesInMyanmar, isEmpty,
          reason: 'my_MM has empty translation values for keys: $emptyValuesInMyanmar');
    });

    test('AppTranslations exposes keys correctly for GetX', () {
      final translations = AppTranslations();
      final keys = translations.keys;

      expect(keys.containsKey('en_US'), true);
      expect(keys.containsKey('my_MM'), true);
      expect(keys['en_US']!['menu_pos'], 'POS Counter');
      expect(keys['my_MM']!['menu_pos'], 'အရောင်းကောင်တာ');
      expect(keys['my_MM']!['language_settings'], 'ဘာသာစကား ရွေးချယ်မှု');
    });

    test('AppController language switching and SQLite persistence', () async {
      final dbHelper = DBHelper.instance;
      final db = await dbHelper.database;
      // Ensure app_settings table exists
      await db.execute('''
        CREATE TABLE IF NOT EXISTS app_settings (
          key TEXT PRIMARY KEY,
          value TEXT,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      final controller = AppController();
      Get.put<AppController>(controller);

      // Default should be en_US
      expect(controller.currentLanguageCode, 'en');

      // Change language to Myanmar
      await controller.changeLanguage('my');
      expect(controller.currentLanguageCode, 'my');
      expect(controller.currentLocale.value, const Locale('my', 'MM'));

      // Verify persisted in SQLite
      final savedInDb = await dbHelper.getSetting('app_language');
      expect(savedInDb, 'my');

      // Change language back to English
      await controller.changeLanguage('en');
      expect(controller.currentLanguageCode, 'en');
      expect(controller.currentLocale.value, const Locale('en', 'US'));

      final savedAgain = await dbHelper.getSetting('app_language');
      expect(savedAgain, 'en');
    });
  });
}
