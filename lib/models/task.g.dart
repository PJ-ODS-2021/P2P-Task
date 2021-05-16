// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Task _$TaskFromJson(Map<String, dynamic> json) {
  return Task(
    id: json['id'] as String?,
    title: json['title'] as String,
    completed: json['completed'] as bool,
    due: json['due'] == null ? null : DateTime.parse(json['due'] as String),
    dueNotification: json['dueNotification'] == null
        ? null
        : DateTime.parse(json['dueNotification'] as String),
    priority: json['priority'] as String?,
  );
}

Map<String, dynamic> _$TaskToJson(Task instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'completed': instance.completed,
      'due': instance.due?.toIso8601String(),
      'dueNotification': instance.dueNotification?.toIso8601String(),
      'priority': instance.priority,
    };
