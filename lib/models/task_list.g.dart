// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskList _$TaskListFromJson(Map<String, dynamic> json) {
  return TaskList(
    json['title'] as String,
    (json['elements'] as List<dynamic>)
        .map((e) => Task.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

Map<String, dynamic> _$TaskListToJson(TaskList instance) => <String, dynamic>{
      'title': instance.title,
      'elements': instance.elements.map((e) => e.toJson()).toList(),
    };
