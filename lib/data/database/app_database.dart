import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:uuid/uuid.dart';

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

        // Prepopulate demo data for small service business
        await _seedSampleData(db);
      },
    );
  }

  Future<void> _seedSampleData(Database db) async {
    const uuid = Uuid();
    final now = DateTime.now();

    // 1. Customers
    final c1 = Customer(
      id: uuid.v4(),
      name: 'Dr. Ramesh Sharma',
      company: 'Apex Multi-speciality Hospital',
      phone: '+91 98450 11223',
      email: 'admin@apexhospital.org',
      address: 'Suite 401, Health City, Ring Road, Bangalore',
      notes: 'Critical medical equipment AMC - 24/7 priority support.',
      createdAt: now.subtract(const Duration(days: 90)),
    );

    final c2 = Customer(
      id: uuid.v4(),
      name: 'Priya Narayanan',
      company: 'Green Valley Apartments RWA',
      phone: '+91 98860 33445',
      email: 'secretary@greenvalleyrwa.com',
      address: 'Green Valley Enclave, Sarjapur Road, Bangalore',
      notes: 'Water treatment and diesel generator maintenance.',
      createdAt: now.subtract(const Duration(days: 120)),
    );

    final c3 = Customer(
      id: uuid.v4(),
      name: 'Vikram Mehta',
      company: 'Mehta Diagnostics & Lab',
      phone: '+91 97410 55667',
      email: 'vikram@mehtalabs.in',
      address: '14/B Commercial Complex, Indiranagar, Bangalore',
      notes: 'HVAC and precision temperature cooling units.',
      createdAt: now.subtract(const Duration(days: 60)),
    );

    for (final c in [c1, c2, c3]) {
      await db.insert(Tables.customers, c.toMap());
    }

    // 2. Contracts
    // Contract 1: Active (ends in 180 days)
    final ct1 = Contract(
      id: uuid.v4(),
      contractNumber: 'AMC-2026-001',
      title: 'Full Comprehensive Medical HVAC Maintenance',
      customerId: c1.id,
      startDate: now.subtract(const Duration(days: 90)),
      endDate: now.add(const Duration(days: 275)),
      contractValue: 125000.0,
      paymentStatus: 'Paid',
      frequency: 'Monthly',
      termsAndConditions: 'Covers all compressor checks, filter replacements, and bi-weekly sensor calibration.',
      status: 'active',
      createdAt: now.subtract(const Duration(days: 90)),
    );

    // Contract 2: Expiring Soon (ends in 14 days!)
    final ct2 = Contract(
      id: uuid.v4(),
      contractNumber: 'AMC-2026-002',
      title: 'DG Set & Water Treatment Plant AMC',
      customerId: c2.id,
      startDate: now.subtract(const Duration(days: 351)),
      endDate: now.add(const Duration(days: 14)), // Expiring soon!
      contractValue: 78000.0,
      paymentStatus: 'Paid',
      frequency: 'Quarterly',
      termsAndConditions: 'Includes oil testing, fuel filter cleanup, and 4 quarterly scheduled services.',
      status: 'expiring_soon',
      createdAt: now.subtract(const Duration(days: 351)),
    );

    // Contract 3: Overdue / Expired (ended 5 days ago)
    final ct3 = Contract(
      id: uuid.v4(),
      contractNumber: 'AMC-2025-089',
      title: 'Precision Cooling & Backup UPS Contract',
      customerId: c3.id,
      startDate: now.subtract(const Duration(days: 370)),
      endDate: now.subtract(const Duration(days: 5)), // Expired!
      contractValue: 54000.0,
      paymentStatus: 'Partial',
      frequency: 'Bi-Annual',
      termsAndConditions: 'Semi-annual deep inspection and battery impedance check.',
      status: 'expired',
      createdAt: now.subtract(const Duration(days: 370)),
    );

    for (final ct in [ct1, ct2, ct3]) {
      await db.insert(Tables.contracts, ct.toMap());
    }

    // 3. Equipment
    final eq1 = Equipment(
      id: uuid.v4(),
      contractId: ct1.id,
      customerId: c1.id,
      name: 'Daikin VRV IV Air Handling Unit',
      brand: 'Daikin',
      modelNumber: 'RXYQ16U',
      serialNumber: 'DK-2023-88912',
      location: 'Block A, Rooftop Plant Room',
      installationDate: now.subtract(const Duration(days: 500)),
      notes: 'Clean filters every service visit.',
    );

    final eq2 = Equipment(
      id: uuid.v4(),
      contractId: ct2.id,
      customerId: c2.id,
      name: 'Kirloskar 125 kVA Silent DG Set',
      brand: 'Kirloskar',
      modelNumber: 'KG125WS',
      serialNumber: 'KIR-90214-G',
      location: 'Basement Generator Yard',
      installationDate: now.subtract(const Duration(days: 720)),
      notes: 'Next service: fuel strainer and battery electrolyte check.',
    );

    final eq3 = Equipment(
      id: uuid.v4(),
      contractId: ct3.id,
      customerId: c3.id,
      name: 'Vertiv Liebert Precision PAC 10kW',
      brand: 'Vertiv Liebert',
      modelNumber: 'PEX3-035',
      serialNumber: 'VL-774102-P',
      location: 'Server Room 2',
      installationDate: now.subtract(const Duration(days: 400)),
      notes: 'Requires replacement of condenser fan capacitor.',
    );

    for (final eq in [eq1, eq2, eq3]) {
      await db.insert(Tables.equipment, eq.toMap());
    }

    // 4. Service Visits
    // Visit 1: Scheduled for today / upcoming
    final sv1 = ServiceVisit(
      id: uuid.v4(),
      contractId: ct1.id,
      customerId: c1.id,
      scheduledDate: now.add(const Duration(hours: 4)),
      technicianName: 'Suresh Kumar',
      status: 'scheduled',
      workDoneNotes: 'Scheduled routine monthly inspection for Daikin AHU.',
    );

    // Visit 2: Completed visit with checklist and parts replaced
    final sv2 = ServiceVisit(
      id: uuid.v4(),
      contractId: ct2.id,
      customerId: c2.id,
      scheduledDate: now.subtract(const Duration(days: 15)),
      visitDate: now.subtract(const Duration(days: 15)),
      technicianName: 'Anil Verma',
      status: 'completed',
      workDoneNotes: 'Complete quarterly maintenance performed. Replaced primary fuel filter, checked radiator coolant and terminal torque.',
      completedAt: now.subtract(const Duration(days: 15)),
    );

    for (final sv in [sv1, sv2]) {
      await db.insert(Tables.serviceVisits, sv.toMap());
    }

    // Checklist for sv1
    final cl1 = [
      ChecklistItem(id: uuid.v4(), visitId: sv1.id, taskDescription: 'Inspect compressor suction and discharge pressure', isDone: false),
      ChecklistItem(id: uuid.v4(), visitId: sv1.id, taskDescription: 'Clean electrostatic air filters and evaporator coils', isDone: false),
      ChecklistItem(id: uuid.v4(), visitId: sv1.id, taskDescription: 'Verify thermostat temperature sensing calibration', isDone: false),
      ChecklistItem(id: uuid.v4(), visitId: sv1.id, taskDescription: 'Check motor blower bearing lubrication', isDone: false),
    ];
    for (final item in cl1) {
      await db.insert(Tables.checklistItems, item.toMap());
    }

    // Checklist for sv2
    final cl2 = [
      ChecklistItem(id: uuid.v4(), visitId: sv2.id, taskDescription: 'Inspect engine lube oil level & viscosity', isDone: true),
      ChecklistItem(id: uuid.v4(), visitId: sv2.id, taskDescription: 'Check fuel pipeline for leaks and clean sediment bowl', isDone: true),
      ChecklistItem(id: uuid.v4(), visitId: sv2.id, taskDescription: 'Measure battery charging voltage (min 26V)', isDone: true),
      ChecklistItem(id: uuid.v4(), visitId: sv2.id, taskDescription: 'Test automatic mains failure (AMF) transfer panel', isDone: true),
    ];
    for (final item in cl2) {
      await db.insert(Tables.checklistItems, item.toMap());
    }

    // Parts for sv2
    final p1 = PartReplaced(
      id: uuid.v4(),
      visitId: sv2.id,
      partName: 'Fleetguard Primary Fuel Filter Element',
      partNumber: 'FF-5052',
      quantity: 1,
      unitCost: 1450.0,
      notes: 'OEM replacement installed.',
    );
    final p2 = PartReplaced(
      id: uuid.v4(),
      visitId: sv2.id,
      partName: 'Castrol Heavy Duty Engine Oil (15W-40)',
      partNumber: 'ENG-OIL-15L',
      quantity: 15,
      unitCost: 320.0,
      notes: 'Fresh oil top-up.',
    );
    for (final p in [p1, p2]) {
      await db.insert(Tables.partsReplaced, p.toMap());
    }

    // 5. Reminders
    final r1 = Reminder(
      id: uuid.v4(),
      contractId: ct2.id,
      customerId: c2.id,
      triggerDaysBefore: 14,
      scheduledDate: now,
      isSent: false,
      reminderType: 'email',
      recipientEmail: c2.email,
      notes: 'Renewal reminder: Contract expires in 14 days.',
    );

    final r2 = Reminder(
      id: uuid.v4(),
      contractId: ct3.id,
      customerId: c3.id,
      triggerDaysBefore: 1,
      scheduledDate: now.subtract(const Duration(days: 5)),
      isSent: true,
      sentAt: now.subtract(const Duration(days: 5)),
      reminderType: 'email',
      recipientEmail: c3.email,
      notes: 'Final renewal reminder sent. Awaiting customer confirmation.',
    );

    for (final r in [r1, r2]) {
      await db.insert(Tables.reminders, r.toMap());
    }
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
