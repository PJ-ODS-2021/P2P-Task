import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:p2p_task/config/migrations.dart';
import 'package:p2p_task/services/database_service.dart';
import 'package:p2p_task/utils/platform_database_factory.dart';

import 'database_service_test.mocks.dart';

@GenerateMocks([VersionedMigrationFunctionDispenser])
void main() {
  final databaseFactory = PlatformDatabaseFactory();
  final databaseName = 'Harakiri';

  group('#create', () {
    test('should create database at specified location', () async {
      final dbPath = './build';
      final finalPath = '$dbPath/$databaseName.json';
      final databaseService =
          DatabaseService(databaseFactory, databaseName: databaseName);

      await databaseService.create(dbPath: dbPath);

      final file = File(finalPath);
      expect(await file.exists(), true);
      file.deleteSync();
    });
  });

  group('#delete', () {
    test('should delete previously created database', () async {
      final dbPath = './build';
      final finalPath = '$dbPath/$databaseName.json';
      final databaseService =
          DatabaseService(databaseFactory, databaseName: databaseName);

      await databaseService.create(dbPath: dbPath);
      print(dbPath);
      print(databaseService.database!.path);

      await databaseService.delete();

      final file = File(finalPath);
      expect(await file.exists(), false);
    });
  });

  group('#clear', () {
    test('should recreate an existing database', () async {
      final dbPath = './build';
      final finalPath = '$dbPath/$databaseName.json';
      final databaseService =
          DatabaseService(databaseFactory, databaseName: databaseName);
      final file = File(finalPath);
      expect(await file.exists(), false);
      await databaseService.create(dbPath: dbPath);
      expect(await file.exists(), true);

      await databaseService.create(dbPath: dbPath);

      expect(await file.exists(), true);
    });
  });

  group('versioning', () {
    late MockVersionedMigrationFunctionDispenser migrationFunctionDispenser;
    late DatabaseService databaseService;

    setUp(() async {
      databaseService = DatabaseService(
        databaseFactory,
        databaseName: databaseName,
      );
      migrationFunctionDispenser = MockVersionedMigrationFunctionDispenser();
      await databaseService.create();
      await databaseService.close();
    });

    test(
        'should run a migration function with '
        'version greater than current version', () async {
      when(migrationFunctionDispenser.get(any)).thenReturn((_) async => null);

      await DatabaseService(
        databaseFactory,
        version: 2,
        databaseName: databaseName,
        migrationDispenser: migrationFunctionDispenser,
      ).create();

      verify(migrationFunctionDispenser.get(2)).called(1);
      verifyNoMoreInteractions(migrationFunctionDispenser);
    });

    test(
        'should run the migration functions with '
        'version greater than the current version', () async {
      when(migrationFunctionDispenser.get(any)).thenReturn((_) async => null);

      await DatabaseService(
        databaseFactory,
        version: 4,
        databaseName: databaseName,
        migrationDispenser: migrationFunctionDispenser,
      ).create();

      verifyNever(migrationFunctionDispenser.get(1));
      verify(migrationFunctionDispenser.get(2)).called(1);
      verify(migrationFunctionDispenser.get(3)).called(1);
      verify(migrationFunctionDispenser.get(4)).called(1);
      verifyNever(migrationFunctionDispenser.get(5));
      verifyNoMoreInteractions(migrationFunctionDispenser);
    });

    test('should run the migration functions in correct order', () async {
      when(migrationFunctionDispenser.get(any)).thenReturn((_) async => null);

      await DatabaseService(
        databaseFactory,
        version: 4,
        databaseName: databaseName,
        migrationDispenser: migrationFunctionDispenser,
      ).create();

      verifyInOrder([
        migrationFunctionDispenser.get(2),
        migrationFunctionDispenser.get(3),
        migrationFunctionDispenser.get(4),
      ]);
      verifyNoMoreInteractions(migrationFunctionDispenser);
    });

    tearDown(() async {
      await databaseService.delete();
    });
  });
}
