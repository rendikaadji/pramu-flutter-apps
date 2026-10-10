import 'package:pramu_apps/core/models/wire.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:pramu_apps/core/validators.dart';
import 'package:pramu_apps/features/auth/domain/auth.dart';

enum NotificationType {
  verification,
  application,
  interview,
  chat,
  agreement,
  booking,
  payment,
  rating,
  report,
  unknown;

  static NotificationType from(String? s) => enumFromWire(values, s, unknown);
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.targetId,
    this.readAt,
    this.role,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
    id: j['id'] as String,
    type: NotificationType.from(j['type'] as String?),
    title: j['title'] as String,
    body: j['body'] as String,
    createdAt: parseApiTime(j['created_at'] as String),
    targetId: j['target_id'] as String?,
    readAt: j['read_at'] == null ? null : parseApiTime(j['read_at'] as String),
    role: Role.from(j['role'] as String?),
  );

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final String? targetId; // ULID entitas tujuan
  final DateTime? readAt;

  /// Peran penerima notifikasi (null = tidak diketahui / tak perlu ganti peran).
  final Role? role;

  bool get unread => readAt == null;

  AppNotification markRead(DateTime at) => AppNotification(
    id: id,
    type: type,
    title: title,
    body: body,
    createdAt: createdAt,
    targetId: targetId,
    readAt: readAt ?? at,
    role: role,
  );

  /// Rute tujuan (allowlist). Null bila type tak dikenal / id bukan ULID.
  String? get route => notificationRoute(type, targetId);
}

/// Payload push = `type` + ULID. Dipakai in-app list dan handler FCM.
String? notificationRoute(NotificationType type, String? id) {
  if (type == NotificationType.verification) return Routes.verificationStatus;
  if (!isUlid(id)) return null;
  return switch (type) {
    NotificationType.verification => null,
    NotificationType.application => Routes.applicationDetail(id!),
    NotificationType.interview => Routes.interviewDetail(id!),
    NotificationType.chat => Routes.chatRoom(id!),
    NotificationType.agreement => Routes.agreementReview(id!),
    NotificationType.booking => Routes.bookingDetail(id!),
    NotificationType.payment => Routes.periodStatus(id!),
    NotificationType.rating => Routes.rating(id!),
    NotificationType.report => Routes.reportStatus(id!),
    NotificationType.unknown => null,
  };
}
