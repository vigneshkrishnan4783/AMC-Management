import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../models/customer.dart';
import '../models/contract.dart';
import '../models/equipment.dart';
import '../models/service_visit.dart';
import '../models/checklist_item.dart';
import '../models/part_replaced.dart';
import '../models/reminder.dart';
import '../models/document_record.dart';
import '../models/company_settings.dart';
import 'tables.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  AppDatabase._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  static void initializePlatform() {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<Database> _initDatabase() async {
    initializePlatform();

    String path;
    if (kIsWeb) {
      path = 'amc_manager.db';
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final appDocDir = await getApplicationDocumentsDirectory();
      final dbFolder = Directory(p.join(appDocDir.path, 'AMCManager'));
      if (!await dbFolder.exists()) {
        await dbFolder.create(recursive: true);
      }
      path = p.join(dbFolder.path, 'amc_manager.db');
    } else {
      final dbPath = await getDatabasesPath();
      path = p.join(dbPath, 'amc_manager.db');
    }

    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute(Tables.createCustomersTable);
        await db.execute(Tables.createContractsTable);
        await db.execute(Tables.createEquipmentTable);
        await db.execute(Tables.createServiceVisitsTable);
        await db.execute(Tables.createChecklistItemsTable);
        await db.execute(Tables.createPartsReplacedTable);
        await db.execute(Tables.createRemindersTable);
        await db.execute(Tables.createDocumentsTable);
        await db.execute(Tables.createSettingsTable);

        // Prepopulate default settings
        await db.insert(
          Tables.settings,
          CompanySettings().toMap()..['id'] = 1,
        );
      },
      onOpen: (db) async {
        try {
          await db.execute('ALTER TABLE ${Tables.settings} ADD COLUMN powered_by TEXT DEFAULT "Citrus Informatics"');
        } catch (_) {}

        // Purge any legacy sample data
        try {
          await db.delete(Tables.customers, where: 'email IN (?, ?, ?)', whereArgs: [
            'admin@apexhospital.org',
            'secretary@greenvalleyrwa.com',
            'vikram@mehtalabs.in',
          ]);
          await db.delete(Tables.contracts, where: 'contract_number IN (?, ?, ?)', whereArgs: [
            'AMC-2026-001',
            'AMC-2026-002',
            'AMC-2025-089',
          ]);
        } catch (_) {}

        try {
          final cur = await db.query(Tables.settings, where: 'id = 1');
          if (cur.isNotEmpty) {
            final email = cur.first['email'] as String?;
            final phone = cur.first['phone'] as String?;
            if (email == 'service@amcmanager.com' || phone == '+91 98765 43210') {
              await db.update(
                Tables.settings,
                {
                  'email': 'vignesh.krishnan@citrusinfomatics.com',
                  'phone': '',
                  'address': '',
                  'website': '',
                  'tax_number': '',
                  'business_name': 'AMC Management',
                  'powered_by': 'Citrus Informatics',
                },
                where: 'id = 1',
              );
            }
          }
        } catch (_) {}
      },
    );
  }

  // --- CRUD: Customers ---
  Future<List<Customer>> getAllCustomers() async {
    final db = await database;
    final maps = await db.query(Tables.customers, orderBy: 'created_at DESC');
    return maps.map((m) => Customer.fromMap(m)).toList();
  }

  Future<Customer?> getCustomerById(String id) async {
    final db = await database;
    final maps = await db.query(Tables.customers, where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Customer.fromMap(maps.first);
  }

  Future<void> insertCustomer(Customer customer) async {
    final db = await database;
    await db.insert(Tables.customers, customer.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateCustomer(Customer customer) async {
    final db = await database;
    await db.update(Tables.customers, customer.toMap(), where: 'id = ?', whereArgs: [customer.id]);
  }

  Future<void> deleteCustomer(String id) async {
    final db = await database;
    await db.delete(Tables.customers, where: 'id = ?', whereArgs: [id]);
  }

  // --- CRUD: Contracts ---
  Future<List<Contract>> getAllContracts() async {
    final db = await database;
    final maps = await db.query(Tables.contracts, orderBy: 'end_date ASC');
    return maps.map((m) => Contract.fromMap(m)).toList();
  }

  Future<Contract?> getContractById(String id) async {
    final db = await database;
    final maps = await db.query(Tables.contracts, where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Contract.fromMap(maps.first);
  }

  Future<List<Contract>> getContractsByCustomerId(String customerId) async {
    final db = await database;
    final maps = await db.query(Tables.contracts, where: 'customer_id = ?', whereArgs: [customerId], orderBy: 'end_date DESC');
    return maps.map((m) => Contract.fromMap(m)).toList();
  }

  Future<void> insertContract(Contract contract) async {
    final db = await database;
    await db.insert(Tables.contracts, contract.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateContract(Contract contract) async {
    final db = await database;
    await db.update(Tables.contracts, contract.toMap(), where: 'id = ?', whereArgs: [contract.id]);
  }

  Future<void> deleteContract(String id) async {
    final db = await database;
    await db.delete(Tables.contracts, where: 'id = ?', whereArgs: [id]);
  }

  // --- CRUD: Equipment ---
  Future<List<Equipment>> getAllEquipment() async {
    final db = await database;
    final maps = await db.query(Tables.equipment, orderBy: 'name ASC');
    return maps.map((m) => Equipment.fromMap(m)).toList();
  }

  Future<List<Equipment>> getEquipmentByContractId(String contractId) async {
    final db = await database;
    final maps = await db.query(Tables.equipment, where: 'contract_id = ?', whereArgs: [contractId]);
    return maps.map((m) => Equipment.fromMap(m)).toList();
  }

  Future<List<Equipment>> getEquipmentByCustomerId(String customerId) async {
    final db = await database;
    final maps = await db.query(Tables.equipment, where: 'customer_id = ?', whereArgs: [customerId]);
    return maps.map((m) => Equipment.fromMap(m)).toList();
  }

  Future<void> insertEquipment(Equipment equipment) async {
    final db = await database;
    await db.insert(Tables.equipment, equipment.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateEquipment(Equipment equipment) async {
    final db = await database;
    await db.update(Tables.equipment, equipment.toMap(), where: 'id = ?', whereArgs: [equipment.id]);
  }

  Future<void> deleteEquipment(String id) async {
    final db = await database;
    await db.delete(Tables.equipment, where: 'id = ?', whereArgs: [id]);
  }

  // --- CRUD: Service Visits ---
  Future<List<ServiceVisit>> getAllServiceVisits() async {
    final db = await database;
    final visitMaps = await db.query(Tables.serviceVisits, orderBy: 'scheduled_date DESC');
    final List<ServiceVisit> visits = [];

    for (final v in visitMaps) {
      final visitId = v['id'] as String;
      final checkMaps = await db.query(Tables.checklistItems, where: 'visit_id = ?', whereArgs: [visitId]);
      final partMaps = await db.query(Tables.partsReplaced, where: 'visit_id = ?', whereArgs: [visitId]);

      final checklist = checkMaps.map((c) => ChecklistItem.fromMap(c)).toList();
      final parts = partMaps.map((p) => PartReplaced.fromMap(p)).toList();

      visits.add(ServiceVisit.fromMap(v, checklist: checklist, parts: parts));
    }
    return visits;
  }

  Future<ServiceVisit?> getServiceVisitById(String id) async {
    final db = await database;
    final visitMaps = await db.query(Tables.serviceVisits, where: 'id = ?', whereArgs: [id]);
    if (visitMaps.isEmpty) return null;

    final checkMaps = await db.query(Tables.checklistItems, where: 'visit_id = ?', whereArgs: [id]);
    final partMaps = await db.query(Tables.partsReplaced, where: 'visit_id = ?', whereArgs: [id]);

    final checklist = checkMaps.map((c) => ChecklistItem.fromMap(c)).toList();
    final parts = partMaps.map((p) => PartReplaced.fromMap(p)).toList();

    return ServiceVisit.fromMap(visitMaps.first, checklist: checklist, parts: parts);
  }

  Future<void> insertServiceVisit(ServiceVisit visit) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert(Tables.serviceVisits, visit.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      for (final item in visit.checklist) {
        await txn.insert(Tables.checklistItems, item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final part in visit.partsReplaced) {
        await txn.insert(Tables.partsReplaced, part.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<void> updateServiceVisit(ServiceVisit visit) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(Tables.serviceVisits, visit.toMap(), where: 'id = ?', whereArgs: [visit.id]);

      // Refresh checklist & parts
      await txn.delete(Tables.checklistItems, where: 'visit_id = ?', whereArgs: [visit.id]);
      for (final item in visit.checklist) {
        await txn.insert(Tables.checklistItems, item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await txn.delete(Tables.partsReplaced, where: 'visit_id = ?', whereArgs: [visit.id]);
      for (final part in visit.partsReplaced) {
        await txn.insert(Tables.partsReplaced, part.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<void> deleteServiceVisit(String id) async {
    final db = await database;
    await db.delete(Tables.serviceVisits, where: 'id = ?', whereArgs: [id]);
  }

  // --- CRUD: Reminders ---
  Future<List<Reminder>> getAllReminders() async {
    final db = await database;
    final maps = await db.query(Tables.reminders, orderBy: 'scheduled_date ASC');
    return maps.map((m) => Reminder.fromMap(m)).toList();
  }

  Future<void> insertReminder(Reminder reminder) async {
    final db = await database;
    await db.insert(Tables.reminders, reminder.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateReminder(Reminder reminder) async {
    final db = await database;
    await db.update(Tables.reminders, reminder.toMap(), where: 'id = ?', whereArgs: [reminder.id]);
  }

  Future<void> deleteReminder(String id) async {
    final db = await database;
    await db.delete(Tables.reminders, where: 'id = ?', whereArgs: [id]);
  }

  // --- CRUD: Documents ---
  Future<List<DocumentRecord>> getAllDocuments() async {
    final db = await database;
    final maps = await db.query(Tables.documents, orderBy: 'created_at DESC');
    return maps.map((m) => DocumentRecord.fromMap(m)).toList();
  }

  Future<List<DocumentRecord>> getDocumentsForEntity(String entityId) async {
    final db = await database;
    final maps = await db.query(Tables.documents, where: 'entity_id = ?', whereArgs: [entityId], orderBy: 'created_at DESC');
    return maps.map((m) => DocumentRecord.fromMap(m)).toList();
  }

  Future<void> insertDocument(DocumentRecord document) async {
    final db = await database;
    await db.insert(Tables.documents, document.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteDocument(String id) async {
    final db = await database;
    await db.delete(Tables.documents, where: 'id = ?', whereArgs: [id]);
  }

  // --- Settings ---
  Future<CompanySettings> getSettings() async {
    final db = await database;
    final maps = await db.query(Tables.settings, where: 'id = 1');
    if (maps.isEmpty) return CompanySettings();
    return CompanySettings.fromMap(maps.first);
  }

  Future<void> saveSettings(CompanySettings settings) async {
    final db = await database;
    await db.insert(
      Tables.settings,
      settings.toMap()..['id'] = 1,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Raw Database backup export & restore
  Future<Map<String, dynamic>> exportAllData() async {
    final db = await database;
    final customers = await db.query(Tables.customers);
    final contracts = await db.query(Tables.contracts);
    final equipment = await db.query(Tables.equipment);
    final serviceVisits = await db.query(Tables.serviceVisits);
    final checklist = await db.query(Tables.checklistItems);
    final parts = await db.query(Tables.partsReplaced);
    final reminders = await db.query(Tables.reminders);
    final documents = await db.query(Tables.documents);
    final settings = await db.query(Tables.settings);

    return {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'customers': customers,
      'contracts': contracts,
      'equipment': equipment,
      'service_visits': serviceVisits,
      'checklist_items': checklist,
      'parts_replaced': parts,
      'reminders': reminders,
      'documents': documents,
      'settings': settings,
    };
  }

  Future<void> restoreAllData(Map<String, dynamic> data) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(Tables.checklistItems);
      await txn.delete(Tables.partsReplaced);
      await txn.delete(Tables.serviceVisits);
      await txn.delete(Tables.equipment);
      await txn.delete(Tables.reminders);
      await txn.delete(Tables.documents);
      await txn.delete(Tables.contracts);
      await txn.delete(Tables.customers);
      await txn.delete(Tables.settings);

      for (final c in (data['customers'] as List? ?? [])) {
        await txn.insert(Tables.customers, Map<String, dynamic>.from(c));
      }
      for (final ct in (data['contracts'] as List? ?? [])) {
        await txn.insert(Tables.contracts, Map<String, dynamic>.from(ct));
      }
      for (final eq in (data['equipment'] as List? ?? [])) {
        await txn.insert(Tables.equipment, Map<String, dynamic>.from(eq));
      }
      for (final sv in (data['service_visits'] as List? ?? [])) {
        await txn.insert(Tables.serviceVisits, Map<String, dynamic>.from(sv));
      }
      for (final cl in (data['checklist_items'] as List? ?? [])) {
        await txn.insert(Tables.checklistItems, Map<String, dynamic>.from(cl));
      }
      for (final p in (data['parts_replaced'] as List? ?? [])) {
        await txn.insert(Tables.partsReplaced, Map<String, dynamic>.from(p));
      }
      for (final r in (data['reminders'] as List? ?? [])) {
        await txn.insert(Tables.reminders, Map<String, dynamic>.from(r));
      }
      for (final d in (data['documents'] as List? ?? [])) {
        await txn.insert(Tables.documents, Map<String, dynamic>.from(d));
      }
      for (final s in (data['settings'] as List? ?? [])) {
        await txn.insert(Tables.settings, Map<String, dynamic>.from(s));
      }
    });
  }
}
