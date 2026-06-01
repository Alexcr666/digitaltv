// lib/data/repositories/firestore_device_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:digitaltv/entities/entities.dart';
import 'package:digitaltv/model/models.dart';
import 'package:digitaltv/repositories/failure.dart';
import 'package:digitaltv/repositories/repositories.dart';

class FirestoreDeviceRepository implements DeviceRepository {
  final FirebaseFirestore _db;
  FirestoreDeviceRepository(this._db);

  CollectionReference get _col => _db.collection('devices');

  @override
  Stream<List<DeviceEntity>> watchDevices() {
    return _col.orderBy('lastSeen', descending: true).snapshots().map((s) =>
        s.docs.map((d) => DeviceModel.fromFirestore(d).toEntity()).toList());
  }

  @override
  Stream<List<DeviceEntity>> watchDevicesByGroup(String groupId) {
    return _col.where('groupId', isEqualTo: groupId).snapshots().map((s) =>
        s.docs.map((d) => DeviceModel.fromFirestore(d).toEntity()).toList());
  }

  @override
  Future<Either<Failure, DeviceEntity>> getDevice(String deviceId) async {
    try {
      final doc = await _col.doc(deviceId).get();
      if (!doc.exists) return Left(NotFoundFailure('Device not found'));
      return Right(DeviceModel.fromFirestore(doc).toEntity());
    } on FirebaseException catch (e) {
      return Left(FirestoreFailure(e.message ?? 'Firestore error'));
    }
  }

  @override
  Future<Either<Failure, DeviceEntity>> registerDevice({
    required String name,
    required String uniqueDeviceId,
    String? groupId,
  }) async {
    try {
      final ref = _col.doc();
      final model = DeviceModel(
        id: ref.id,
        name: name,
        uniqueDeviceId: uniqueDeviceId,
        status: 'offline',
        groupId: groupId,
        lastSeen: Timestamp.now(),
        metadata: {},
      );
      await ref.set(model.toFirestore());
      return Right(model.toEntity());
    } on FirebaseException catch (e) {
      return Left(FirestoreFailure(e.message ?? 'Firestore error'));
    }
  }

  @override
  Future<Either<Failure, void>> updateDevice(DeviceEntity device) async {
    try {
      await _col.doc(device.id).update({
        'name': device.name,
        'groupId': device.groupId,
      });
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(FirestoreFailure(e.message ?? 'Firestore error'));
    }
  }

  @override
  Future<Either<Failure, void>> updateHeartbeat({
    required String deviceId,
    required DeviceStatus status,
    String? currentContentId,
  }) async {
    try {
      await _col.doc(deviceId).update({
        'status': status.name,
        'lastSeen': FieldValue.serverTimestamp(),
        if (currentContentId != null) 'currentContentId': currentContentId,
      });
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(FirestoreFailure(e.message ?? 'Firestore error'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteDevice(String deviceId) async {
    try {
      await _col.doc(deviceId).delete();
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(FirestoreFailure(e.message ?? 'Firestore error'));
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// lib/data/repositories/firestore_assignment_repository.dart

class FirestoreAssignmentRepository implements AssignmentRepository {
  final FirebaseFirestore _db;
  FirestoreAssignmentRepository(this._db);

  CollectionReference get _col => _db.collection('assignments');

  @override
  Stream<List<AssignmentEntity>> watchAssignments() {
    return _col.orderBy('priority').snapshots().map((s) => s.docs
        .map((d) => AssignmentModel.fromFirestore(d).toEntity())
        .toList());
  }

  /// The core resolution logic:
  /// 1. Device-specific assignment (priority 1)
  /// 2. Group assignment (priority 2)
  /// 3. Global assignment (priority 3)
  @override
  Stream<ContentEntity?> watchResolvedContentForDevice(
    String deviceId,
    String? groupId,
  ) {
    return _col
        .where('active', isEqualTo: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final assignments = snapshot.docs
          .map((d) => AssignmentModel.fromFirestore(d).toEntity())
          .toList();

      // Sort by priority ascending (1 = highest)
      assignments.sort((a, b) => a.priority.compareTo(b.priority));

      AssignmentEntity? resolved;

      for (final a in assignments) {
        if (a.targetType == AssignmentTarget.device && a.tvId == deviceId) {
          resolved = a;
          break;
        }
      }
      if (resolved == null && groupId != null) {
        for (final a in assignments) {
          if (a.targetType == AssignmentTarget.group && a.groupId == groupId) {
            resolved = a;
            break;
          }
        }
      }
      if (resolved == null) {
        for (final a in assignments) {
          if (a.targetType == AssignmentTarget.global) {
            resolved = a;
            break;
          }
        }
      }

      if (resolved == null) return null;

      // Fetch the actual content
      try {
        final doc =
            await _db.collection('content').doc(resolved.contentId).get();
        if (!doc.exists) return null;
        return ContentModel.fromFirestore(doc).toEntity();
      } catch (_) {
        return null;
      }
    });
  }

  @override
  Future<Either<Failure, AssignmentEntity>> createAssignment(
      AssignmentEntity a) async {
    try {
      final ref = _col.doc();
      final model = AssignmentModel(
        id: ref.id,
        targetType: a.targetType.name,
        tvId: a.tvId,
        groupId: a.groupId,
        contentId: a.contentId,
        contentName: a.contentName,
        priority: a.priority,
        active: a.active,
        createdAt: Timestamp.now(),
      );
      await ref.set(model.toFirestore());
      return Right(model.toEntity());
    } on FirebaseException catch (e) {
      return Left(FirestoreFailure(e.message ?? 'Error'));
    }
  }

  @override
  Future<Either<Failure, void>> updateAssignment(AssignmentEntity a) async {
    try {
      await _col.doc(a.id).update({'active': a.active, 'priority': a.priority});
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(FirestoreFailure(e.message ?? 'Error'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAssignment(String id) async {
    try {
      await _col.doc(id).delete();
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(FirestoreFailure(e.message ?? 'Error'));
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// lib/data/repositories/firestore_content_repository.dart

class FirestoreContentRepository implements ContentRepository {
  final FirebaseFirestore _db;
  FirestoreContentRepository(this._db);

  CollectionReference get _col => _db.collection('content');

  @override
  Stream<List<ContentEntity>> watchContent() {
    return _col.orderBy('createdAt', descending: true).snapshots().map((s) =>
        s.docs.map((d) => ContentModel.fromFirestore(d).toEntity()).toList());
  }

  @override
  Future<Either<Failure, ContentEntity>> getContent(String id) async {
    try {
      final doc = await _col.doc(id).get();
      if (!doc.exists) return Left(NotFoundFailure());
      return Right(ContentModel.fromFirestore(doc).toEntity());
    } on FirebaseException catch (e) {
      return Left(FirestoreFailure(e.message ?? ''));
    }
  }

  @override
  Future<Either<Failure, ContentEntity>> createContent(ContentEntity c) async {
    try {
      final ref = _col.doc();
      final model = ContentModel(
        id: ref.id,
        name: c.name,
        type: c.type.name,
        url: c.url,
        textContent: c.textContent,
        durationSeconds: c.duration.inSeconds,
        createdAt: Timestamp.now(),
        ownerId: c.ownerId,
        tags: c.tags,
        playlistItemIds: c.playlistItemIds,
      );
      await ref.set(model.toFirestore());
      return Right(model.toEntity());
    } on FirebaseException catch (e) {
      return Left(FirestoreFailure(e.message ?? ''));
    }
  }

  @override
  Future<Either<Failure, void>> updateContent(ContentEntity c) async {
    try {
      await _col.doc(c.id).update({
        'name': c.name,
        'url': c.url,
        'textContent': c.textContent,
        'durationSeconds': c.duration.inSeconds,
        'tags': c.tags,
      });
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(FirestoreFailure(e.message ?? ''));
    }
  }

  @override
  Future<Either<Failure, void>> deleteContent(String id) async {
    try {
      await _col.doc(id).delete();
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(FirestoreFailure(e.message ?? ''));
    }
  }
}
