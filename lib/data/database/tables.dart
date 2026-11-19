class Tables {
  static const String customers = 'customers';
  static const String contracts = 'contracts';
  static const String equipment = 'equipment';
  static const String serviceVisits = 'service_visits';
  static const String checklistItems = 'checklist_items';
  static const String partsReplaced = 'parts_replaced';
  static const String reminders = 'reminders';
  static const String documents = 'documents';
  static const String settings = 'settings';

  static const String createCustomersTable = '''
    CREATE TABLE $customers (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      company TEXT,
      phone TEXT,
      email TEXT,
      address TEXT,
      notes TEXT,
      created_at TEXT NOT NULL
    );
  ''';

  static const String createContractsTable = '''
    CREATE TABLE $contracts (
      id TEXT PRIMARY KEY,
      contract_number TEXT NOT NULL,
      title TEXT NOT NULL,
      customer_id TEXT NOT NULL,
      start_date TEXT NOT NULL,
      end_date TEXT NOT NULL,
      contract_value REAL NOT NULL,
      payment_status TEXT NOT NULL,
      frequency TEXT NOT NULL,
      terms_and_conditions TEXT,
      status TEXT NOT NULL,
      created_at TEXT NOT NULL,
      FOREIGN KEY (customer_id) REFERENCES $customers(id) ON DELETE CASCADE
    );
  ''';

  static const String createEquipmentTable = '''
    CREATE TABLE $equipment (
      id TEXT PRIMARY KEY,
      contract_id TEXT NOT NULL,
      customer_id TEXT NOT NULL,
      name TEXT NOT NULL,
      brand TEXT,
      model_number TEXT,
      serial_number TEXT,
      location TEXT,
      installation_date TEXT,
      notes TEXT,
      FOREIGN KEY (contract_id) REFERENCES $contracts(id) ON DELETE CASCADE,
      FOREIGN KEY (customer_id) REFERENCES $customers(id) ON DELETE CASCADE
    );
  ''';

  static const String createServiceVisitsTable = '''
    CREATE TABLE $serviceVisits (
      id TEXT PRIMARY KEY,
      contract_id TEXT NOT NULL,
      customer_id TEXT NOT NULL,
      scheduled_date TEXT NOT NULL,
      visit_date TEXT,
      technician_name TEXT NOT NULL,
      status TEXT NOT NULL,
      work_done_notes TEXT,
      customer_signature_base64 TEXT,
      technician_signature_base64 TEXT,
      completed_at TEXT,
      FOREIGN KEY (contract_id) REFERENCES $contracts(id) ON DELETE CASCADE,
      FOREIGN KEY (customer_id) REFERENCES $customers(id) ON DELETE CASCADE
    );
  ''';

  static const String createChecklistItemsTable = '''
    CREATE TABLE $checklistItems (
      id TEXT PRIMARY KEY,
      visit_id TEXT NOT NULL,
      task_description TEXT NOT NULL,
      is_done INTEGER NOT NULL DEFAULT 0,
      notes TEXT,
      FOREIGN KEY (visit_id) REFERENCES $serviceVisits(id) ON DELETE CASCADE
    );
  ''';

  static const String createPartsReplacedTable = '''
    CREATE TABLE $partsReplaced (
      id TEXT PRIMARY KEY,
      visit_id TEXT NOT NULL,
      part_name TEXT NOT NULL,
      part_number TEXT,
      quantity INTEGER NOT NULL DEFAULT 1,
      unit_cost REAL NOT NULL DEFAULT 0.0,
      notes TEXT,
      FOREIGN KEY (visit_id) REFERENCES $serviceVisits(id) ON DELETE CASCADE
    );
  ''';

  static const String createRemindersTable = '''
    CREATE TABLE $reminders (
      id TEXT PRIMARY KEY,
      contract_id TEXT NOT NULL,
      customer_id TEXT NOT NULL,
      trigger_days_before INTEGER NOT NULL,
      scheduled_date TEXT NOT NULL,
      is_sent INTEGER NOT NULL DEFAULT 0,
      sent_at TEXT,
      reminder_type TEXT NOT NULL,
      recipient_email TEXT NOT NULL,
      notes TEXT,
      FOREIGN KEY (contract_id) REFERENCES $contracts(id) ON DELETE CASCADE,
      FOREIGN KEY (customer_id) REFERENCES $customers(id) ON DELETE CASCADE
    );
  ''';

  static const String createDocumentsTable = '''
    CREATE TABLE $documents (
      id TEXT PRIMARY KEY,
      entity_type TEXT NOT NULL,
      entity_id TEXT NOT NULL,
      title TEXT NOT NULL,
      document_type TEXT NOT NULL,
      file_path TEXT NOT NULL,
      file_size INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL
    );
  ''';

  static const String createSettingsTable = '''
    CREATE TABLE $settings (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      business_name TEXT,
      phone TEXT,
      email TEXT,
      address TEXT,
      website TEXT,
      tax_number TEXT,
      currency_symbol TEXT,
      terms_template TEXT,
      email_notifications_enabled INTEGER,
      reminder_days_config TEXT
    );
  ''';
}
