import 'package:collection/collection.dart';

bool unorderedListEquality<T>(List<T> unorderedList, Set<T> expected) {
  final listSet = unorderedList.toSet();

  return listSet.length == unorderedList.length &&
      SetEquality().equals(listSet, expected);
}
