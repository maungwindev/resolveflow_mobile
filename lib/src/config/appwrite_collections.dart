/// Identifiers for Appwrite Database Collections and RBAC Teams.
class AppwriteConstants {
  AppwriteConstants._();

  // ---------------------------------------------------------------------------
  // RBAC Teams (Role-Based Access Control)
  // ---------------------------------------------------------------------------
  static const String teamTechnicians = 'technicians';
  static const String teamManagers = 'managers';

  // ---------------------------------------------------------------------------
  // Database Collections
  // ---------------------------------------------------------------------------
  
  /// Parts Inventory (Catalog Storage)
  /// - Read: technicians, managers
  /// - Write/Update: managers
  static const String collectionPartsInventory = String.fromEnvironment(
    'COLLECTION_PARTS_INVENTORY',
    defaultValue: '6ae065c4003e59720f54', // Matched from your Appwrite Console
  );

  /// Work Orders (Operations Registry)
  /// - Read: technicians, managers
  /// - Create/Write: technicians
  /// - Audit/Read: managers
  static const String collectionWorkOrders = String.fromEnvironment(
    'COLLECTION_WORK_ORDERS',
    defaultValue: '6ae0679f003505fdf886',
  );

  /// Work Order Parts Deduction Ledger (Audit Trail)
  /// - Read: technicians, managers
  /// - Create/Write: technicians
  /// - Audit/Read: managers
  static const String collectionWorkOrderParts = String.fromEnvironment(
    'COLLECTION_WORK_ORDER_PARTS',
    defaultValue: '6ae068e1003d9c0e09ac',
  );

  /// Resolutions (Knowledge Base Semantic Index)
  /// - Read (Search): all authenticated users
  /// - Write (Add Knowledge): technicians, managers
  static const String collectionResolutionsVector = String.fromEnvironment(
    'COLLECTION_RESOLUTIONS_VECTOR',
    defaultValue: '6ae069650017ed80e2fc',
  );
}
