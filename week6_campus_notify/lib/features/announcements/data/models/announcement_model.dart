import '../../domain/entities/announcement.dart';

class AnnouncementModel extends Announcement {
  const AnnouncementModel({
    required super.id,
    required super.title,
    required super.body,
    required super.route,
    required super.time,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'body': body,
    'route': route,
    'time': time,
  };

  factory AnnouncementModel.fromMap(Map<String, dynamic> map) {
    return AnnouncementModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      route: map['route']?.toString() ?? '',
      time: map['time']?.toString() ?? '',
    );
  }

  Announcement toEntity() => Announcement(
    id: id,
    title: title,
    body: body,
    route: route,
    time: time,
  );
}
