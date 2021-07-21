import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:p2p_task/config/migrations.dart';
import 'package:p2p_task/services/database_service.dart';
import 'package:p2p_task/utils/platform_database_factory.dart';
import 'package:sembast/sembast.dart';

import 'database_service_test.mocks.dart';

@GenerateMocks([VersionedMigrationFunctionDispenser])
void main() {
  bool existsFile(String path) => File(path).existsSync();
  final databaseFactory = (databaseName, inMemory) =>
      PlatformDatabaseFactory(databaseName, inMemory);
  final databaseName = 'Harakiri';
  final testDatabaseDirectory = './build';
  final databaseLocation = '$testDatabaseDirectory/$databaseName.json';
  late DatabaseService databaseService;

  group('Persistent database', () {
    setUp(() async {
      databaseService = DatabaseService(
        databaseFactory,
        databaseName: databaseName,
      );
      await databaseService.delete();
    });

    test('#create should create database at specified location', () async {
      await databaseService.create(dbPath: testDatabaseDirectory);

      expect(existsFile(databaseLocation), true);
    });

    test('#delete should delete previously created database', () async {
      await databaseService.create(dbPath: testDatabaseDirectory);

      await databaseService.delete();

      expect(existsFile(databaseLocation), false);
    });

    test('#clear should recreate an existing database', () async {
      expect(existsFile(databaseLocation), false);
      await databaseService.create(dbPath: testDatabaseDirectory);
      expect(existsFile(databaseLocation), true);

      await databaseService.clear();

      expect(existsFile(databaseLocation), true);
    });
  });

  group('Store', () {
    setUp(() async {
      databaseService = DatabaseService(
        databaseFactory,
        databaseName: databaseName,
        inMemory: true,
      );
      await databaseService.create();
    });

    test('should delete store', () async {
      final storeRef = StoreRef('');
      expect(await storeRef.count(databaseService.database!), 0);
      final elements = ['I', 'sit', 'on', 'a', 'pink', 'tree', '.'];
      await storeRef.addAll(databaseService.database!, elements);
      expect(await storeRef.count(databaseService.database!), 7);

      await databaseService.deleteStore('');

      expect(await storeRef.count(databaseService.database!), 0);
    });
  });

  group('Versioning', () {
    late MockVersionedMigrationFunctionDispenser migrationFunctionDispenser;

    setUp(() async {
      migrationFunctionDispenser = MockVersionedMigrationFunctionDispenser();
      databaseService = DatabaseService(
        databaseFactory,
        databaseName: databaseName,
        inMemory: true,
      );
      await databaseService.create();
      await databaseService.close();
    });

    test(
      'should run a migration function with '
      'version greater than current version',
      () async {
        when(migrationFunctionDispenser.get(any)).thenReturn((_) async => null);

        await DatabaseService(
          databaseFactory,
          version: 2,
          databaseName: databaseName,
          migrationDispenser: migrationFunctionDispenser,
          inMemory: true,
        ).create();

        verify(migrationFunctionDispenser.get(2)).called(1);
        verifyNoMoreInteractions(migrationFunctionDispenser);
      },
    );

    test(
      'should run the migration functions with '
      'version greater than the current version',
      () async {
        when(migrationFunctionDispenser.get(any)).thenReturn((_) async => null);

        await DatabaseService(
          databaseFactory,
          version: 4,
          databaseName: databaseName,
          migrationDispenser: migrationFunctionDispenser,
          inMemory: true,
        ).create();

        verifyNever(migrationFunctionDispenser.get(1));
        verify(migrationFunctionDispenser.get(2)).called(1);
        verify(migrationFunctionDispenser.get(3)).called(1);
        verify(migrationFunctionDispenser.get(4)).called(1);
        verifyNever(migrationFunctionDispenser.get(5));
        verifyNoMoreInteractions(migrationFunctionDispenser);
      },
    );

    test('should run the migration functions in correct order', () async {
      when(migrationFunctionDispenser.get(any)).thenReturn((_) async => null);

      await DatabaseService(
        databaseFactory,
        version: 4,
        databaseName: databaseName,
        migrationDispenser: migrationFunctionDispenser,
        inMemory: true,
      ).create();

      verifyInOrder([
        migrationFunctionDispenser.get(2),
        migrationFunctionDispenser.get(3),
        migrationFunctionDispenser.get(4),
      ]);
      verifyNoMoreInteractions(migrationFunctionDispenser);
    });
  });

  tearDown(() async {
    await databaseService.delete();
  });
}
