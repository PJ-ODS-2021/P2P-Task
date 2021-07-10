import 'package:flutter_test/flutter_test.dart';
import 'package:p2p_task/utils/key_value_repository.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  test('should store and retrieve a value', () async {
    final db = await databaseFactoryMemory.openDatabase('');
    final repo = KeyValueRepository(db, StoreRef(''));

    await repo.put('key', 'value');
    final value = await repo.get<String>('key');

    expect(value, equals('value'));
  });

  test('should purge all entries', () async {
    final db = await databaseFactoryMemory.openDatabase('');
    final repo = KeyValueRepository(db, StoreRef(''));
    await repo.put('key1', 'value1');
    var value1 = await repo.get<String>('key1');
    await repo.put('key2', 'value2');
    var value2 = await repo.get<String>('key2');
    expect(value1, 'value1');
    expect(value2, 'value2');

    await repo.purge();

    value1 = await repo.get<String>('key1');
    value2 = await repo.get<String>('key2');
    expect(value1, null);
    expect(value2, null);
  });
}
