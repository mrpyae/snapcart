import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;
  static Completer<Database>? _dbOpenCompleter;

  DBHelper._init() {
    _ensureFactoryInit();
  }

  static void _ensureFactoryInit() {
    try {
      if (kIsWeb) {
        databaseFactory = databaseFactoryFfiWeb;
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
    } catch (_) {}
  }

  Future<Database> get database async {
    if (_database != null) return _database!;

    if (_dbOpenCompleter != null) {
      return await _dbOpenCompleter!.future;
    }

    _dbOpenCompleter = Completer<Database>();
    try {
      _ensureFactoryInit();
      _database = await _initDB('snapcart_pos.db');
      _dbOpenCompleter!.complete(_database!);
      return _database!;
    } catch (e) {
      _dbOpenCompleter!.completeError(e);
      _dbOpenCompleter = null;
      rethrow;
    }
  }

  /// Resolve the absolute filesystem path to the active SQLite database
  Future<String> getDatabasePath([String filePath = 'snapcart_pos.db']) async {
    if (kIsWeb) return filePath;
    try {
      final db = await database;
      if (db.path.isNotEmpty) return db.path;
    } catch (_) {}

    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final docDir = await getApplicationDocumentsDirectory();
        return join(docDir.path, 'SnapCart', filePath);
      } else {
        final dbPath = await getDatabasesPath();
        return join(dbPath, filePath);
      }
    } catch (_) {
      return filePath;
    }
  }

  /// Flushes in-flight Write-Ahead Log (WAL) to main .db file
  Future<void> flushWal() async {
    try {
      if (!kIsWeb) {
        final db = await database;
        await db.rawQuery('PRAGMA wal_checkpoint(FULL);');
      }
    } catch (_) {}
  }

  /// Safely closes the database connection and resets the singleton instance
  Future<void> closeDatabase() async {
    if (_database != null) {
      try {
        await _database!.close();
      } catch (_) {}
      _database = null;
    }
    _dbOpenCompleter = null;
  }

  /// Reopens the database connection and runs schema migration
  Future<Database> reopenDatabase() async {
    await closeDatabase();
    return await database;
  }

  Future<Database> _initDB(String filePath) async {
    _ensureFactoryInit();

    Database db;
    if (kIsWeb) {
      db = await databaseFactoryFfiWeb.openDatabase(
        filePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: _createDB,
        ),
      );
      await _migrateSchema(db);
      return db;
    }

    String path;
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final docDir = await getApplicationDocumentsDirectory();
        path = join(docDir.path, 'SnapCart', filePath);
        await Directory(dirname(path)).create(recursive: true);
        db = await databaseFactoryFfi.openDatabase(
          path,
          options: OpenDatabaseOptions(
            version: 1,
            onCreate: _createDB,
          ),
        );
      } else {
        final dbPath = await getDatabasesPath();
        path = join(dbPath, filePath);
        db = await databaseFactory.openDatabase(
          path,
          options: OpenDatabaseOptions(
            version: 1,
            onCreate: _createDB,
          ),
        );
      }
    } catch (_) {
      path = filePath;
      db = await databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: _createDB,
        ),
      );
    }

    await _migrateSchema(db);
    return db;
  }

  Future<void> _migrateSchema(Database db) async {
    try {
      await db.execute('ALTER TABLE products ADD COLUMN is_one_set INTEGER DEFAULT 0;');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE products ADD COLUMN image_url TEXT;');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE products ADD COLUMN product_status TEXT DEFAULT "AVAILABLE";');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE customers ADD COLUMN advance_balance REAL DEFAULT 0.0;');
    } catch (_) {}

    // Alter sales_orders to add delivery and COD columns
    try { await db.execute('ALTER TABLE sales_orders ADD COLUMN delivery_type TEXT DEFAULT "SELF_COLLECT";'); } catch (_) {}
    try { await db.execute('ALTER TABLE sales_orders ADD COLUMN delivery_service_id TEXT;'); } catch (_) {}
    try { await db.execute('ALTER TABLE sales_orders ADD COLUMN delivery_service_name TEXT;'); } catch (_) {}
    try { await db.execute('ALTER TABLE sales_orders ADD COLUMN delivery_address TEXT;'); } catch (_) {}
    try { await db.execute('ALTER TABLE sales_orders ADD COLUMN tracking_no TEXT;'); } catch (_) {}
    try { await db.execute('ALTER TABLE sales_orders ADD COLUMN is_cod INTEGER DEFAULT 0;'); } catch (_) {}
    try { await db.execute('ALTER TABLE sales_orders ADD COLUMN cod_amount REAL DEFAULT 0.0;'); } catch (_) {}
    try { await db.execute('ALTER TABLE sales_orders ADD COLUMN delivery_status TEXT DEFAULT "PENDING";'); } catch (_) {}
    try { await db.execute('ALTER TABLE sales_orders ADD COLUMN cod_settlement_status TEXT DEFAULT "PENDING";'); } catch (_) {}

    // Alter customer_orders to add delivery columns
    try { await db.execute('ALTER TABLE customer_orders ADD COLUMN delivery_type TEXT DEFAULT "SELF_COLLECT";'); } catch (_) {}
    try { await db.execute('ALTER TABLE customer_orders ADD COLUMN delivery_service_id TEXT;'); } catch (_) {}
    try { await db.execute('ALTER TABLE customer_orders ADD COLUMN delivery_service_name TEXT;'); } catch (_) {}
    try { await db.execute('ALTER TABLE customer_orders ADD COLUMN is_cod INTEGER DEFAULT 0;'); } catch (_) {}
    try { await db.execute('ALTER TABLE customer_orders ADD COLUMN cod_amount REAL DEFAULT 0.0;'); } catch (_) {}
    try { await db.execute('ALTER TABLE customer_orders ADD COLUMN delivery_status TEXT DEFAULT "PENDING";'); } catch (_) {}
    try { await db.execute('ALTER TABLE customer_orders ADD COLUMN cod_settlement_status TEXT DEFAULT "PENDING";'); } catch (_) {}

    // Alter delivery_services for in-house and rider compensation
    try { await db.execute('ALTER TABLE delivery_services ADD COLUMN service_type TEXT DEFAULT "EXTERNAL";'); } catch (_) {}
    try { await db.execute('ALTER TABLE delivery_services ADD COLUMN rider_type TEXT DEFAULT "SALARY";'); } catch (_) {}
    try { await db.execute('ALTER TABLE delivery_services ADD COLUMN commission_type TEXT DEFAULT "PERCENT";'); } catch (_) {}
    try { await db.execute('ALTER TABLE delivery_services ADD COLUMN commission_val REAL DEFAULT 0.0;'); } catch (_) {}
    try { await db.execute('ALTER TABLE delivery_services ADD COLUMN default_delivery_fee REAL DEFAULT 0.0;'); } catch (_) {}

    // Alter sales_orders and customer_orders for rider commission & delivery fee
    try { await db.execute('ALTER TABLE sales_orders ADD COLUMN rider_commission_amount REAL DEFAULT 0.0;'); } catch (_) {}
    try { await db.execute('ALTER TABLE customer_orders ADD COLUMN rider_commission_amount REAL DEFAULT 0.0;'); } catch (_) {}
    try { await db.execute('ALTER TABLE customer_orders ADD COLUMN delivery_fee REAL DEFAULT 0.0;'); } catch (_) {}

    // Alter customer_orders and items for supplier and purchase linkage
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS app_settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
    } catch (_) {}
    try { await db.execute('ALTER TABLE customer_orders ADD COLUMN supplier_id TEXT;'); } catch (_) {}
    try { await db.execute('ALTER TABLE customer_orders ADD COLUMN supplier_name TEXT;'); } catch (_) {}
    try { await db.execute('ALTER TABLE customer_orders ADD COLUMN linked_purchase_id TEXT;'); } catch (_) {}
    try { await db.execute('ALTER TABLE customer_order_items ADD COLUMN supplier_id TEXT;'); } catch (_) {}
    try { await db.execute('ALTER TABLE customer_order_items ADD COLUMN supplier_name TEXT;'); } catch (_) {}
    try { await db.execute('ALTER TABLE purchase_items ADD COLUMN customer_order_id TEXT;'); } catch (_) {}
    try { await db.execute('ALTER TABLE purchase_items ADD COLUMN customer_order_no TEXT;'); } catch (_) {}

    // Alter purchases & purchase_items for Supplier PO, Follow-up & Partial Receiving
    try { await db.execute('ALTER TABLE purchases ADD COLUMN expected_delivery_date TEXT;'); } catch (_) {}
    try { await db.execute('ALTER TABLE purchases ADD COLUMN last_follow_up_date TEXT;'); } catch (_) {}
    try { await db.execute('ALTER TABLE purchases ADD COLUMN follow_up_notes TEXT;'); } catch (_) {}
    try { await db.execute('ALTER TABLE purchase_items ADD COLUMN ordered_quantity REAL;'); } catch (_) {}
    try { await db.execute('ALTER TABLE purchase_items ADD COLUMN received_quantity REAL;'); } catch (_) {}
    try { await db.execute('ALTER TABLE purchase_items ADD COLUMN rejected_quantity REAL DEFAULT 0.0;'); } catch (_) {}
    try { await db.execute('ALTER TABLE purchase_items ADD COLUMN status TEXT DEFAULT "RECEIVED";'); } catch (_) {}
    try { await db.execute('ALTER TABLE suppliers ADD COLUMN supplier_category_id TEXT;'); } catch (_) {}

    // Ensure new tables are created on existing databases
    await _createPurchaseAndSupplierTables(db);
    await _createHeldOrdersTable(db);
    await _createCustomerOrdersTable(db);
    await _createDeliveryServiceTables(db);
  }

  Future<void> _createDeliveryServiceTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS delivery_services (
        id TEXT PRIMARY KEY,
        business_id TEXT DEFAULT 'default_biz',
        name TEXT NOT NULL,
        service_type TEXT DEFAULT 'EXTERNAL',
        rider_type TEXT DEFAULT 'SALARY',
        commission_type TEXT DEFAULT 'PERCENT',
        commission_val REAL DEFAULT 0.0,
        default_delivery_fee REAL DEFAULT 0.0,
        phone TEXT,
        contact_person TEXT,
        base_fee REAL DEFAULT 0.0,
        coverage_area TEXT,
        receivable_balance REAL DEFAULT 0.0,
        notes TEXT,
        is_active INTEGER DEFAULT 1,
        sync_status INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS delivery_payments (
        id TEXT PRIMARY KEY,
        business_id TEXT DEFAULT 'default_biz',
        delivery_service_id TEXT NOT NULL,
        amount REAL NOT NULL,
        payment_method TEXT DEFAULT 'cash',
        notes TEXT,
        payment_date TEXT,
        sync_status INTEGER DEFAULT 0,
        created_at TEXT
      )
    ''');

    // Seed default couriers if empty
    try {
      final res = await db.rawQuery('SELECT COUNT(*) as count FROM delivery_services');
      final count = (res.first['count'] as num?)?.toInt() ?? 0;
      if (count == 0) {
        final now = DateTime.now().toIso8601String();
        await db.insert('delivery_services', {
          'id': 'del-svc-001',
          'business_id': 'default_biz',
          'name': 'Royal Express',
          'service_type': 'EXTERNAL',
          'rider_type': 'SALARY',
          'commission_type': 'PERCENT',
          'commission_val': 0.0,
          'default_delivery_fee': 0.0,
          'phone': '01-2305555',
          'contact_person': 'Yangon Dispatch',
          'base_fee': 0.0,
          'coverage_area': 'Yangon & Greater Cities',
          'receivable_balance': 0.0,
          'notes': 'Next-day delivery courier',
          'is_active': 1,
          'sync_status': 1,
          'created_at': now,
          'updated_at': now,
        });
        await db.insert('delivery_services', {
          'id': 'del-svc-002',
          'business_id': 'default_biz',
          'name': 'Ninja Van',
          'service_type': 'EXTERNAL',
          'rider_type': 'SALARY',
          'commission_type': 'PERCENT',
          'commission_val': 0.0,
          'default_delivery_fee': 0.0,
          'phone': '09-777000111',
          'contact_person': 'Customer Service',
          'base_fee': 0.0,
          'coverage_area': 'Nationwide Door-to-Door',
          'receivable_balance': 0.0,
          'notes': 'Nationwide COD delivery network',
          'is_active': 1,
          'sync_status': 1,
          'created_at': now,
          'updated_at': now,
        });
        await db.insert('delivery_services', {
          'id': 'del-svc-003',
          'business_id': 'default_biz',
          'name': 'In-House Rider',
          'service_type': 'IN_HOUSE',
          'rider_type': 'COMMISSION',
          'commission_type': 'PERCENT',
          'commission_val': 20.0,
          'default_delivery_fee': 2000.0,
          'phone': '09-123456789',
          'contact_person': 'Ko Aung',
          'base_fee': 0.0,
          'coverage_area': 'Nearby Townships',
          'receivable_balance': 0.0,
          'notes': 'Direct local shop rider (20% commission)',
          'is_active': 1,
          'sync_status': 1,
          'created_at': now,
          'updated_at': now,
        });
      }
    } catch (_) {}
  }

  Future<void> _createCustomerOrdersTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS customer_orders (
        id TEXT PRIMARY KEY,
        order_no TEXT UNIQUE NOT NULL,
        business_id TEXT DEFAULT 'default_biz',
        customer_id TEXT,
        customer_name TEXT NOT NULL,
        customer_phone TEXT,
        customer_address TEXT,
        order_source TEXT DEFAULT 'PHONE',
        lead_account TEXT,
        appointment_date TEXT,
        appointment_type TEXT DEFAULT 'LOOM_WEAVING',
        supplier_id TEXT,
        supplier_name TEXT,
        linked_purchase_id TEXT,
        status TEXT DEFAULT 'PENDING',
        total_amount REAL NOT NULL,
        advance_amount REAL DEFAULT 0.0,
        due_amount REAL DEFAULT 0.0,
        payment_method TEXT DEFAULT 'cash',
        notes TEXT,
        delivery_fee REAL DEFAULT 0.0,
        rider_commission_amount REAL DEFAULT 0.0,
        delivery_type TEXT DEFAULT 'SELF_COLLECT',
        delivery_service_id TEXT,
        delivery_service_name TEXT,
        is_cod INTEGER DEFAULT 0,
        cod_amount REAL DEFAULT 0.0,
        delivery_status TEXT DEFAULT 'PENDING',
        cod_settlement_status TEXT DEFAULT 'PENDING',
        sync_status INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS customer_order_items (
        id TEXT PRIMARY KEY,
        customer_order_id TEXT NOT NULL,
        product_id TEXT,
        item_name TEXT NOT NULL,
        fabric_type TEXT,
        color TEXT,
        supplier_id TEXT,
        supplier_name TEXT,
        quantity REAL NOT NULL,
        unit TEXT DEFAULT 'piece',
        unit_price REAL NOT NULL,
        subtotal REAL NOT NULL,
        design_notes TEXT,
        sync_status INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> _createHeldOrdersTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS held_orders (
        id TEXT PRIMARY KEY,
        business_id TEXT DEFAULT 'default_biz',
        customer_id TEXT,
        customer_name TEXT,
        customer_phone TEXT,
        cart_json TEXT NOT NULL,
        subtotal REAL NOT NULL,
        discount REAL DEFAULT 0.0,
        tax_rate REAL DEFAULT 0.0,
        delivery_fee REAL DEFAULT 0.0,
        grand_total REAL NOT NULL,
        notes TEXT,
        created_at TEXT
      )
    ''');
  }

  Future<void> _createPurchaseAndSupplierTables(Database db) async {
    // Supplier Categories Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS supplier_categories (
        id TEXT PRIMARY KEY,
        business_id TEXT DEFAULT 'default_biz',
        name TEXT NOT NULL,
        description TEXT,
        is_active INTEGER DEFAULT 1,
        sync_status INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Suppliers Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS suppliers (
        id TEXT PRIMARY KEY,
        business_id TEXT DEFAULT 'default_biz',
        supplier_category_id TEXT,
        name TEXT NOT NULL,
        phone TEXT,
        company_name TEXT,
        address TEXT,
        payable_balance REAL DEFAULT 0.0,
        advance_balance REAL DEFAULT 0.0,
        is_active INTEGER DEFAULT 1,
        sync_status INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Purchases Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS purchases (
        id TEXT PRIMARY KEY,
        business_id TEXT DEFAULT 'default_biz',
        invoice_no TEXT UNIQUE NOT NULL,
        supplier_id TEXT,
        supplier_name TEXT,
        user_id TEXT,
        total_amount REAL NOT NULL,
        paid_amount REAL DEFAULT 0.0,
        due_amount REAL DEFAULT 0.0,
        payment_method TEXT DEFAULT 'cash',
        status TEXT DEFAULT 'RECEIVED',
        expected_delivery_date TEXT,
        last_follow_up_date TEXT,
        follow_up_notes TEXT,
        notes TEXT,
        purchase_date TEXT,
        sync_status INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Purchase Items Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS purchase_items (
        id TEXT PRIMARY KEY,
        purchase_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        unit TEXT,
        cost_price REAL NOT NULL,
        quantity REAL NOT NULL,
        ordered_quantity REAL,
        received_quantity REAL,
        rejected_quantity REAL DEFAULT 0.0,
        subtotal REAL NOT NULL,
        status TEXT DEFAULT 'RECEIVED',
        customer_order_id TEXT,
        customer_order_no TEXT,
        sync_status INTEGER DEFAULT 0,
        created_at TEXT
      )
    ''');

    // Supplier Payments Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS supplier_payments (
        id TEXT PRIMARY KEY,
        business_id TEXT DEFAULT 'default_biz',
        supplier_id TEXT NOT NULL,
        purchase_id TEXT,
        amount REAL NOT NULL,
        type TEXT DEFAULT 'PAYMENT',
        payment_method TEXT DEFAULT 'cash',
        notes TEXT,
        payment_date TEXT,
        sync_status INTEGER DEFAULT 0,
        created_at TEXT
      )
    ''');

    // Product Suppliers Mapping Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS product_suppliers (
        id TEXT PRIMARY KEY,
        business_id TEXT DEFAULT 'default_biz',
        product_id TEXT NOT NULL,
        supplier_id TEXT NOT NULL,
        supplier_sku TEXT,
        cost_price REAL DEFAULT 0.0,
        is_preferred INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT,
        UNIQUE(product_id, supplier_id)
      )
    ''');
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Users Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        username TEXT UNIQUE NOT NULL,
        phone TEXT,
        password_hash TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        sync_status INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // 2. User Accounts / Branch Profiles (Multi-Account & RBAC)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_accounts (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        business_id TEXT DEFAULT 'default_biz',
        branch_name TEXT DEFAULT 'Main Branch',
        role_name TEXT DEFAULT 'cashier',
        passcode TEXT,
        permissions TEXT,
        is_default INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        sync_status INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // 3. Categories Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id TEXT PRIMARY KEY,
        business_id TEXT DEFAULT 'default_biz',
        name TEXT NOT NULL,
        description TEXT,
        is_active INTEGER DEFAULT 1,
        sync_status INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // 4. Products Table (Textile & General Retail)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS products (
        id TEXT PRIMARY KEY,
        business_id TEXT DEFAULT 'default_biz',
        category_id TEXT,
        barcode TEXT,
        name TEXT NOT NULL,
        fabric_type TEXT,
        size TEXT,
        color TEXT,
        unit TEXT DEFAULT 'piece',
        cost_price REAL DEFAULT 0.0,
        retail_price REAL NOT NULL,
        wholesale_price REAL DEFAULT 0.0,
        min_wholesale_qty REAL DEFAULT 5.0,
        stock_qty REAL DEFAULT 0.0,
        min_stock_alert REAL DEFAULT 5.0,
        image_url TEXT,
        is_one_set INTEGER DEFAULT 0,
        product_status TEXT DEFAULT 'AVAILABLE',
        is_active INTEGER DEFAULT 1,
        sync_status INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // 5. Customers Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS customers (
        id TEXT PRIMARY KEY,
        business_id TEXT DEFAULT 'default_biz',
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        customer_type TEXT DEFAULT 'retail',
        credit_limit REAL DEFAULT 0.0,
        current_debt REAL DEFAULT 0.0,
        advance_balance REAL DEFAULT 0.0,
        sync_status INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // 6. Sales Orders Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sales_orders (
        id TEXT PRIMARY KEY,
        business_id TEXT DEFAULT 'default_biz',
        voucher_no TEXT UNIQUE NOT NULL,
        customer_id TEXT,
        user_id TEXT NOT NULL,
        user_account_id TEXT NOT NULL,
        user_name TEXT NOT NULL,
        subtotal REAL NOT NULL,
        tax_amount REAL DEFAULT 0.0,
        discount_amount REAL DEFAULT 0.0,
        delivery_fee REAL DEFAULT 0.0,
        grand_total REAL NOT NULL,
        paid_amount REAL NOT NULL,
        change_amount REAL DEFAULT 0.0,
        due_amount REAL DEFAULT 0.0,
        payment_method TEXT DEFAULT 'cash',
        sale_status TEXT DEFAULT 'PAID',
        notes TEXT,
        sale_date TEXT,
        sync_status INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // 7. Sales Order Items Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sales_order_items (
        id TEXT PRIMARY KEY,
        sale_order_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        unit TEXT,
        price REAL NOT NULL,
        cost_price REAL DEFAULT 0.0,
        quantity REAL NOT NULL,
        discount REAL DEFAULT 0.0,
        total REAL NOT NULL,
        sync_status INTEGER DEFAULT 0,
        created_at TEXT
      )
    ''');

    // 8. Debt Repayments Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS debt_repayments (
        id TEXT PRIMARY KEY,
        business_id TEXT DEFAULT 'default_biz',
        customer_id TEXT NOT NULL,
        sale_order_id TEXT,
        user_id TEXT NOT NULL,
        amount_paid REAL NOT NULL,
        payment_method TEXT DEFAULT 'cash',
        notes TEXT,
        payment_date TEXT,
        sync_status INTEGER DEFAULT 0,
        created_at TEXT
      )
    ''');

    // 9. Expenses Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS expenses (
        id TEXT PRIMARY KEY,
        business_id TEXT DEFAULT 'default_biz',
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        user_id TEXT NOT NULL,
        payment_method TEXT DEFAULT 'cash',
        expense_date TEXT,
        description TEXT,
        sync_status INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // 10. Purchase & Supplier Tables
    await _createPurchaseAndSupplierTables(db);

    // 11. Delivery Services & Payments Tables
    await _createDeliveryServiceTables(db);

    // Direct seed without extra lock
    try {
      await db.insert('users', {
        'id': 'usr-admin-001',
        'name': 'Shop Owner / Admin',
        'username': 'admin',
        'phone': '09111111111',
        'password_hash': '123456',
        'is_active': 1,
        'sync_status': 1,
      });

      await db.insert('users', {
        'id': 'usr-cashier-002',
        'name': 'Ma Hla (Cashier)',
        'username': 'cashier',
        'phone': '09222222222',
        'password_hash': '123456',
        'is_active': 1,
        'sync_status': 1,
      });

      await db.insert('user_accounts', {
        'id': 'acc-admin-main',
        'user_id': 'usr-admin-001',
        'business_id': 'default_biz',
        'branch_name': 'Main Branch (Owner)',
        'role_name': 'owner',
        'passcode': '1234',
        'permissions': '["pos_sale","apply_discount","void_order","view_reports","view_cost_price","manage_products","manage_stock","manage_expenses"]',
        'is_default': 1,
        'is_active': 1,
        'sync_status': 1,
      });

      await db.insert('user_accounts', {
        'id': 'acc-admin-branch2',
        'user_id': 'usr-admin-001',
        'business_id': 'default_biz',
        'branch_name': 'Branch 2 (Manager)',
        'role_name': 'manager',
        'passcode': '1234',
        'permissions': '["pos_sale","apply_discount","void_order","view_reports","view_cost_price","manage_products","manage_stock","manage_expenses"]',
        'is_default': 0,
        'is_active': 1,
        'sync_status': 1,
      });

      await db.insert('user_accounts', {
        'id': 'acc-cashier-01',
        'user_id': 'usr-cashier-002',
        'business_id': 'default_biz',
        'branch_name': 'Counter 1 (Cashier)',
        'role_name': 'cashier',
        'passcode': '0000',
        'permissions': '["pos_sale","apply_discount"]',
        'is_default': 1,
        'is_active': 1,
        'sync_status': 1,
      });

      await db.insert('products', {
        'id': 'prod-01',
        'business_id': 'default_biz',
        'barcode': '10001',
        'name': 'မြန်မာဝတ်စုံ ရင်ဖုံးအင်္ကျီ',
        'fabric_type': 'ချည်သား',
        'size': 'M',
        'color': 'အနီ',
        'unit': 'piece',
        'cost_price': 12000.0,
        'retail_price': 18500.0,
        'wholesale_price': 16000.0,
        'min_wholesale_qty': 5.0,
        'stock_qty': 25.0,
        'min_stock_alert': 5.0,
        'is_active': 1,
        'sync_status': 1,
      });
    } catch (_) {}
  }

  Future<String?> getSetting(String key) async {
    try {
      final db = await instance.database;
      final res = await db.query('app_settings', where: 'key = ?', whereArgs: [key], limit: 1);
      if (res.isNotEmpty) {
        return res.first['value'] as String?;
      }
    } catch (_) {}
    return null;
  }

  Future<void> setSetting(String key, String value) async {
    try {
      final db = await instance.database;
      await db.insert(
        'app_settings',
        {
          'key': key,
          'value': value,
          'updated_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
