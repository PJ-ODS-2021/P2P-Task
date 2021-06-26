import 'package:flutter_test/flutter_test.dart';
import 'package:p2p_task/utils/key_value_repository.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  test('should store and retrieve a value', () async {
    final db = await databaseFactoryMemory.openDatabase('');
    final repo = KeyValueRepository(db, StoreRef(''));

    await repo.put('key', 'value');
    final value = await repo.get('key');

    expect(value, equals('value'));
  });
}
