import 'dart:convert';
import 'dart:io';

class AppwriteAdminClient {
  AppwriteAdminClient({
    required this.endpoint,
    required this.projectId,
    required this.apiKey,
  });

  final String endpoint;
  final String projectId;
  final String apiKey;
  final HttpClient _client = HttpClient();

  Future<Map<String, dynamic>> request({
    required String method,
    required String path,
    Map<String, dynamic>? body,
  }) async {
    final cleanEndpoint = endpoint.endsWith('/')
        ? endpoint.substring(0, endpoint.length - 1)
        : endpoint;
    final uri = Uri.parse('$cleanEndpoint$path');
    final req = await _client.openUrl(method, uri);

    req.headers.set('X-Appwrite-Project', projectId);
    req.headers.set('X-Appwrite-Key', apiKey);
    req.headers.set('Content-Type', 'application/json');

    if (body != null) {
      final jsonBytes = utf8.encode(jsonEncode(body));
      req.add(jsonBytes);
    }

    final res = await req.close();
    final resBody = await utf8.decodeStream(res);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (resBody.isEmpty) return <String, dynamic>{};
      try {
        return jsonDecode(resBody) as Map<String, dynamic>;
      } catch (_) {
        return <String, dynamic>{};
      }
    } else {
      String message = 'HTTP ${res.statusCode}';
      try {
        final decoded = jsonDecode(resBody) as Map<String, dynamic>?;
        if (decoded != null && decoded.containsKey('message')) {
          message = '${decoded['message']} (Code: ${res.statusCode})';
        }
      } catch (_) {
        if (resBody.isNotEmpty) message = resBody;
      }
      throw HttpException(message, uri: uri);
    }
  }

  void close() => _client.close();
}

void main(List<String> args) async {
  print('======================================================');
  print('    ResolveFlow - Appwrite Automatic Setup Script     ');
  print('======================================================\n');

  // 1. Resolve Endpoint
  String endpoint = 'https://sgp.cloud.appwrite.io/v1';
  stdout.write('Appwrite Endpoint [$endpoint] (press Enter to keep): ');
  final inputEndpoint = stdin.readLineSync()?.trim();
  if (inputEndpoint != null && inputEndpoint.isNotEmpty) {
    endpoint = inputEndpoint;
  }

  // 2. Resolve Project ID
  String defaultProjectId = '6ae023f9002178809f28';
  stdout.write('Appwrite Project ID [$defaultProjectId] (press Enter to keep): ');
  final inputProjectId = stdin.readLineSync()?.trim();
  final projectId = (inputProjectId != null && inputProjectId.isNotEmpty)
      ? inputProjectId
      : defaultProjectId;

  // 3. Resolve API Key
  String? apiKey;
  if (args.isNotEmpty && args[0].trim().isNotEmpty) {
    apiKey = args[0].trim();
  } else if (Platform.environment['APPWRITE_API_KEY'] != null &&
      Platform.environment['APPWRITE_API_KEY']!.trim().isNotEmpty) {
    apiKey = Platform.environment['APPWRITE_API_KEY']!.trim();
  } else {
    stdout.write('Enter your Appwrite Secret API Key: ');
    apiKey = stdin.readLineSync()?.trim();
  }

  if (apiKey == null || apiKey.isEmpty) {
    print('\n❌ Error: API Key is required.');
    print('1. Go to Appwrite Console > Project Settings > View API Keys');
    print('2. Create Key with scopes: databases.write, collections.write, attributes.write, documents.write, teams.write');
    print('3. Run again: dart scripts/setup_appwrite.dart <API_KEY>');
    exit(1);
  }

  final client = AppwriteAdminClient(
    endpoint: endpoint,
    projectId: projectId,
    apiKey: apiKey,
  );

  try {
    // -------------------------------------------------------------------------
    // Step 0: Test Connection & Authentication
    // -------------------------------------------------------------------------
    stdout.write('\nTesting connection to $endpoint (Project: $projectId)... ');
    Map<String, dynamic> databasesResponse;
    try {
      databasesResponse = await client.request(method: 'GET', path: '/databases');
      print('✅ Connected & Authorized');
    } catch (e) {
      print('❌ FAILED\n');
      print('Connection Error: $e\n');
      print('Troubleshooting:');
      print('1. Check if your Endpoint is correct');
      print('2. Verify your Project ID in Appwrite Console > Project Settings');
      print('3. Verify your API Key has the required scopes');
      exit(1);
    }

    // -------------------------------------------------------------------------
    // Step 1: Detect Existing Database (Free Tier allows 1 Database)
    // -------------------------------------------------------------------------
    String activeDatabaseId = 'resolveflow_main';
    final existingDatabases = databasesResponse['databases'] as List?;

    if (existingDatabases != null && existingDatabases.isNotEmpty) {
      final existingDb = existingDatabases.first as Map<String, dynamic>;
      activeDatabaseId = (existingDb['\$id'] ?? existingDb['id']).toString();
      final dbName = existingDb['name'] ?? activeDatabaseId;
      print('ℹ️ Free plan limit detected: Using existing database [$activeDatabaseId] ("$dbName")');
    } else {
      stdout.write('Creating Database [$activeDatabaseId]... ');
      try {
        await client.request(
          method: 'POST',
          path: '/databases',
          body: {
            'databaseId': activeDatabaseId,
            'name': 'ResolveFlow Main DB',
            'enabled': true,
          },
        );
        print('✅ Created');
      } catch (e) {
        if (e.toString().contains('already exists') || e.toString().contains('409')) {
          print('ℹ️ Already exists');
        } else {
          print('❌ $e');
          exit(1);
        }
      }
    }

    // Automatically sync app_secrets.dart with activeDatabaseId
    _syncAppSecrets(activeDatabaseId);

    // -------------------------------------------------------------------------
    // Step 2: Create RBAC Teams
    // -------------------------------------------------------------------------
    print('\nConfiguring RBAC Teams...');
    final teams = [
      {'teamId': 'technicians', 'name': 'Technicians'},
      {'teamId': 'managers', 'name': 'Managers'},
    ];

    for (final team in teams) {
      stdout.write('  - Team [${team['teamId']}]... ');
      try {
        await client.request(
          method: 'POST',
          path: '/teams',
          body: {
            'teamId': team['teamId'],
            'name': team['name'],
          },
        );
        print('✅ Done');
      } catch (e) {
        if (e.toString().contains('already exists') || e.toString().contains('409')) {
          print('ℹ️ Exists');
        } else {
          print('⚠️ $e');
        }
      }
    }

    // -------------------------------------------------------------------------
    // Step 3: Create Collections with RBAC Permissions
    // -------------------------------------------------------------------------
    print('\nConfiguring Collections in database [$activeDatabaseId]...');
    final collections = [
      {
        'collectionId': 'parts_inventory',
        'name': 'Parts Inventory',
        'permissions': [
          'read("team:technicians")',
          'read("team:managers")',
          'create("team:managers")',
          'update("team:managers")',
          'delete("team:managers")',
        ],
        'documentSecurity': false,
      },
      {
        'collectionId': 'work_orders',
        'name': 'Work Orders',
        'permissions': [
          'read("team:technicians")',
          'read("team:managers")',
          'create("team:technicians")',
          'update("team:technicians")',
        ],
        'documentSecurity': false,
      },
      {
        'collectionId': 'work_order_parts',
        'name': 'Work Order Parts',
        'permissions': [
          'read("team:technicians")',
          'read("team:managers")',
          'create("team:technicians")',
        ],
        'documentSecurity': false,
      },
      {
        'collectionId': 'resolutions_vector',
        'name': 'Resolutions Vector',
        'permissions': [
          'read("users")',
          'create("team:technicians")',
          'create("team:managers")',
          'update("team:technicians")',
        ],
        'documentSecurity': false,
      },
    ];

    for (final col in collections) {
      stdout.write('  - Collection [${col['collectionId']}]... ');
      try {
        await client.request(
          method: 'POST',
          path: '/databases/$activeDatabaseId/collections',
          body: {
            'collectionId': col['collectionId'],
            'name': col['name'],
            'permissions': col['permissions'],
            'documentSecurity': col['documentSecurity'],
            'enabled': true,
          },
        );
        print('✅ Created');
      } catch (e) {
        if (e.toString().contains('already exists') || e.toString().contains('409')) {
          print('ℹ️ Exists');
        } else {
          print('⚠️ $e');
        }
      }
    }

    // -------------------------------------------------------------------------
    // Step 4: Provision Schema Attributes
    // -------------------------------------------------------------------------
    print('\nProvisioning Schema Attributes...');

    // Attributes for parts_inventory
    await _createStringAttribute(client, activeDatabaseId, 'parts_inventory', key: 'sku', size: 100, required: true);
    await _createStringAttribute(client, activeDatabaseId, 'parts_inventory', key: 'name', size: 255, required: true);
    await _createIntegerAttribute(client, activeDatabaseId, 'parts_inventory', key: 'quantity_on_hand', required: false, min: 0, defaultValue: 0);
    await _createIntegerAttribute(client, activeDatabaseId, 'parts_inventory', key: 'min_threshold', required: false, min: 0, defaultValue: 2);
    await _createFloatAttribute(client, activeDatabaseId, 'parts_inventory', key: 'unit_price', required: false, defaultValue: 0.0);
    await _createStringAttribute(client, activeDatabaseId, 'parts_inventory', key: 'location', size: 255, required: false);

    // Attributes for work_orders
    await _createStringAttribute(client, activeDatabaseId, 'work_orders', key: 'work_order_number', size: 50, required: true);
    await _createStringAttribute(client, activeDatabaseId, 'work_orders', key: 'symptom_title', size: 255, required: true);
    await _createStringAttribute(client, activeDatabaseId, 'work_orders', key: 'resolution_summary', size: 4000, required: true);
    await _createStringAttribute(client, activeDatabaseId, 'work_orders', key: 'technician_id', size: 100, required: true);
    await _createStringAttribute(client, activeDatabaseId, 'work_orders', key: 'technician_name', size: 150, required: false);
    await _createStringAttribute(client, activeDatabaseId, 'work_orders', key: 'status', size: 50, required: false, defaultValue: 'completed');
    await _createStringAttribute(client, activeDatabaseId, 'work_orders', key: 'created_at', size: 50, required: true);

    // Attributes for work_order_parts
    await _createStringAttribute(client, activeDatabaseId, 'work_order_parts', key: 'work_order_id', size: 100, required: true);
    await _createStringAttribute(client, activeDatabaseId, 'work_order_parts', key: 'sku', size: 100, required: true);
    await _createStringAttribute(client, activeDatabaseId, 'work_order_parts', key: 'part_name', size: 255, required: true);
    await _createIntegerAttribute(client, activeDatabaseId, 'work_order_parts', key: 'quantity_deducted', required: false, min: 1, defaultValue: 1);
    await _createStringAttribute(client, activeDatabaseId, 'work_order_parts', key: 'timestamp', size: 50, required: true);

    // Attributes for resolutions_vector
    await _createStringAttribute(client, activeDatabaseId, 'resolutions_vector', key: 'title', size: 255, required: true);
    await _createStringAttribute(client, activeDatabaseId, 'resolutions_vector', key: 'symptom', size: 4000, required: true);
    await _createStringAttribute(client, activeDatabaseId, 'resolutions_vector', key: 'observation', size: 4000, required: false);
    await _createStringAttribute(client, activeDatabaseId, 'resolutions_vector', key: 'fix_procedure', size: 8000, required: true);
    await _createStringAttribute(client, activeDatabaseId, 'resolutions_vector', key: 'required_sku', size: 100, required: true);
    await _createFloatAttribute(client, activeDatabaseId, 'resolutions_vector', key: 'similarity_score', required: false, defaultValue: 1.0);

    // -------------------------------------------------------------------------
    // Step 5: Wait for Appwrite to finish processing attributes
    // -------------------------------------------------------------------------
    print('\nWaiting 4 seconds for Appwrite to index attributes...');
    await Future.delayed(const Duration(seconds: 4));

    // -------------------------------------------------------------------------
    // Step 6: Seed Initial Realistic Parts & Resolution Vectors
    // -------------------------------------------------------------------------
    print('Seeding Initial Test Data...');
    await _seedInitialData(client, activeDatabaseId);

    print('\n======================================================');
    print('  🎉 Appwrite Database & RBAC Configured Successfully! ');
    print('======================================================');
    print('Endpoint:    $endpoint');
    print('Project ID:  $projectId');
    print('Database ID: $activeDatabaseId');
    print('Collections: parts_inventory, work_orders, work_order_parts, resolutions_vector');
    print('Teams:       technicians, managers');
    print('======================================================\n');
  } catch (e) {
    print('\n❌ Setup stopped: $e');
  } finally {
    client.close();
  }
}

void _syncAppSecrets(String databaseId) {
  try {
    final secretsFile = File('lib/src/config/app_secrets.dart');
    if (secretsFile.existsSync()) {
      var content = secretsFile.readAsStringSync();
      final regex = RegExp(r"(static const String databaseId = String\.fromEnvironment\(\s*'APPWRITE_DATABASE_ID',\s*defaultValue:\s*')([^']*)(')");
      if (regex.hasMatch(content)) {
        content = content.replaceFirstMapped(regex, (m) => '${m[1]}$databaseId${m[3]}');
        secretsFile.writeAsStringSync(content);
        print('✓ Synced lib/src/config/app_secrets.dart with Database ID: $databaseId');
      }
    }
  } catch (_) {}
}

Future<void> _seedInitialData(AppwriteAdminClient client, String databaseId) async {
  final sampleParts = [
    {
      'sku': 'RAD-CAP-04',
      'name': 'Radiator Pressure Cap 1.1 Bar',
      'quantity_on_hand': 8,
      'min_threshold': 2,
      'unit_price': 18.50,
      'location': 'Aisle 3, Bin B4',
    },
    {
      'sku': 'THRM-82C',
      'name': 'High-Flow Engine Thermostat (82°C)',
      'quantity_on_hand': 5,
      'min_threshold': 2,
      'unit_price': 34.00,
      'location': 'Aisle 2, Bin A1',
    },
    {
      'sku': 'O2S-UP-01',
      'name': 'Heated Upstream Oxygen Sensor',
      'quantity_on_hand': 3,
      'min_threshold': 1,
      'unit_price': 89.90,
      'location': 'Aisle 4, Bin C2',
    },
    {
      'sku': 'FLT-CAB-HEPA',
      'name': 'High-Efficiency Cabin Air Filter',
      'quantity_on_hand': 12,
      'min_threshold': 4,
      'unit_price': 24.50,
      'location': 'Aisle 1, Bin D3',
    },
    {
      'sku': 'BRK-PAD-F02',
      'name': 'Ceramic Front Brake Pad Set',
      'quantity_on_hand': 6,
      'min_threshold': 2,
      'unit_price': 65.00,
      'location': 'Aisle 5, Bin A3',
    },
  ];

  for (final part in sampleParts) {
    try {
      final docId = part['sku']!.toString().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');
      await client.request(
        method: 'POST',
        path: '/databases/$databaseId/collections/parts_inventory/documents',
        body: {
          'documentId': docId,
          'data': part,
        },
      );
      print('  ✓ Seeded Part: ${part['sku']} - ${part['name']}');
    } catch (e) {
      if (e.toString().contains('already exists') || e.toString().contains('409')) {
        print('  ℹ️ Part ${part['sku']} already seeded');
      } else {
        print('  ⚠️ Part ${part['sku']}: $e');
      }
    }
  }

  final sampleResolutions = [
    {
      'title': 'Coolant Boiling into Reservoir Tank at Highway Speed',
      'symptom': 'coolant boiling into reservoir tank after highway speed engine temp spiking',
      'observation': 'Radiator cap rubber seal warped; relief valve releasing prematurely under 0.9 bar system pressure.',
      'fix_procedure': '1. Wait for engine to cool completely.\n2. Depressurize and remove radiator cap.\n3. Clean neck flange and inspect for corrosion.\n4. Install new high-pressure 1.1 Bar radiator cap.\n5. Top off 50/50 coolant mix and bleed air pockets.',
      'required_sku': 'RAD-CAP-04',
      'similarity_score': 0.95,
    },
    {
      'title': 'Engine Running Too Cold / Slow Warm-up Heater Ineffective',
      'symptom': 'engine slow to reach operating temperature heater blows lukewarm air thermostat stuck open',
      'observation': 'Coolant temperature gauge reads low on highway; OBD-II code P0128 detected.',
      'fix_procedure': '1. Drain 2 liters of coolant from radiator drain plug.\n2. Unbolt upper radiator hose neck housing.\n3. Extract old stuck-open thermostat and scrape gasket surface clean.\n4. Fit new 82°C thermostat with jiggle pin facing upward (12 o\'clock).\n5. Re-torque to 14 Nm and perform vacuum coolant refill.',
      'required_sku': 'THRM-82C',
      'similarity_score': 0.92,
    },
    {
      'title': 'Rough Idle and Hesitation Under Acceleration with CEL P0135',
      'symptom': 'rough idle engine hesitation poor fuel economy check engine light oxygen sensor heater circuit',
      'observation': 'Bank 1 Sensor 1 internal heater resistance open circuit (infinite ohms on multimeter).',
      'fix_procedure': '1. Disconnect upstream sensor harness clip.\n2. Apply penetrating fluid to exhaust bung.\n3. Use 22mm slotted sensor socket to break old unit free.\n4. Apply high-temp anti-seize paste to replacement sensor threads (avoid tip).\n5. Torque to 40 Nm, plug in harness, and clear DTC codes.',
      'required_sku': 'O2S-UP-01',
      'similarity_score': 0.89,
    },
  ];

  for (final res in sampleResolutions) {
    try {
      final docId = 'res_${res['required_sku'].toString().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_')}';
      await client.request(
        method: 'POST',
        path: '/databases/$databaseId/collections/resolutions_vector/documents',
        body: {
          'documentId': docId,
          'data': res,
        },
      );
      print('  ✓ Seeded Resolution: ${res['title']}');
    } catch (e) {
      if (e.toString().contains('already exists') || e.toString().contains('409')) {
        print('  ℹ️ Resolution ${res['required_sku']} already seeded');
      } else {
        print('  ⚠️ Resolution ${res['required_sku']}: $e');
      }
    }
  }
}

Future<void> _createStringAttribute(
  AppwriteAdminClient client,
  String databaseId,
  String collectionId, {
  required String key,
  required int size,
  required bool required,
  String? defaultValue,
}) async {
  stdout.write('  - [$collectionId] attribute string "$key"... ');
  try {
    final body = <String, dynamic>{
      'key': key,
      'size': size,
      'required': required,
    };
    if (defaultValue != null) {
      body['default'] = defaultValue;
    }
    await client.request(
      method: 'POST',
      path: '/databases/$databaseId/collections/$collectionId/attributes/string',
      body: body,
    );
    print('✅ Done');
  } catch (e) {
    if (e.toString().contains('already exists') || e.toString().contains('409')) {
      print('ℹ️ Exists');
    } else {
      print('⚠️ $e');
    }
  }
}

Future<void> _createIntegerAttribute(
  AppwriteAdminClient client,
  String databaseId,
  String collectionId, {
  required String key,
  required bool required,
  int? min,
  int? max,
  int? defaultValue,
}) async {
  stdout.write('  - [$collectionId] attribute integer "$key"... ');
  try {
    final body = <String, dynamic>{
      'key': key,
      'required': required,
    };
    if (min != null) body['min'] = min;
    if (max != null) body['max'] = max;
    if (defaultValue != null) body['default'] = defaultValue;

    await client.request(
      method: 'POST',
      path: '/databases/$databaseId/collections/$collectionId/attributes/integer',
      body: body,
    );
    print('✅ Done');
  } catch (e) {
    if (e.toString().contains('already exists') || e.toString().contains('409')) {
      print('ℹ️ Exists');
    } else {
      print('⚠️ $e');
    }
  }
}

Future<void> _createFloatAttribute(
  AppwriteAdminClient client,
  String databaseId,
  String collectionId, {
  required String key,
  required bool required,
  double? min,
  double? max,
  double? defaultValue,
}) async {
  stdout.write('  - [$collectionId] attribute float "$key"... ');
  try {
    final body = <String, dynamic>{
      'key': key,
      'required': required,
    };
    if (min != null) body['min'] = min;
    if (max != null) body['max'] = max;
    if (defaultValue != null) body['default'] = defaultValue;

    await client.request(
      method: 'POST',
      path: '/databases/$databaseId/collections/$collectionId/attributes/float',
      body: body,
    );
    print('✅ Done');
  } catch (e) {
    if (e.toString().contains('already exists') || e.toString().contains('409')) {
      print('ℹ️ Exists');
    } else {
      print('⚠️ $e');
    }
  }
}
