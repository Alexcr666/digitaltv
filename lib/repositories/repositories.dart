// lib/domain/repositories/auth_repository.dart
import 'package:dartz/dartz.dart';
import 'package:digitaltv/repositories/failure.dart';
import '../entities/entities.dart';


abstract class AuthRepository {
  Stream<UserEntity?> get authStateChanges;
  Future<Either<Failure, UserEntity>> signIn(String email, String password);
  Future<Either<Failure, void>> signOut();
  Future<Either<Failure, UserEntity>> getCurrentUser();
}

// ─────────────────────────────────────────────────────────────────────────────
// lib/domain/repositories/device_repository.dart

abstract class DeviceRepository {
  /// Real-time stream of all devices
  Stream<List<DeviceEntity>> watchDevices();

  /// Real-time stream of devices in a group
  Stream<List<DeviceEntity>> watchDevicesByGroup(String groupId);

  /// Get single device
  Future<Either<Failure, DeviceEntity>> getDevice(String deviceId);

  /// Register new device (from TV app or admin)
  Future<Either<Failure, DeviceEntity>> registerDevice({
    required String name,
    required String uniqueDeviceId,
    String? groupId,
  });

  /// Update device info (admin)
  Future<Either<Failure, void>> updateDevice(DeviceEntity device);

  /// Update device heartbeat (called by TV app)
  Future<Either<Failure, void>> updateHeartbeat({
    required String deviceId,
    required DeviceStatus status,
    String? currentContentId,
  });

  /// Delete device
  Future<Either<Failure, void>> deleteDevice(String deviceId);
}

// ─────────────────────────────────────────────────────────────────────────────
// lib/domain/repositories/content_repository.dart

abstract class ContentRepository {
  Stream<List<ContentEntity>> watchContent();
  Future<Either<Failure, ContentEntity>> getContent(String contentId);
  Future<Either<Failure, ContentEntity>> createContent(ContentEntity content);
  Future<Either<Failure, void>> updateContent(ContentEntity content);
  Future<Either<Failure, void>> deleteContent(String contentId);
}

// ─────────────────────────────────────────────────────────────────────────────
// lib/domain/repositories/assignment_repository.dart

abstract class AssignmentRepository {
  Stream<List<AssignmentEntity>> watchAssignments();

  /// Get the resolved assignment for a specific device
  /// Priority: device-specific > group > global
  Stream<ContentEntity?> watchResolvedContentForDevice(String deviceId, String? groupId);

  Future<Either<Failure, AssignmentEntity>> createAssignment(AssignmentEntity assignment);
  Future<Either<Failure, void>> updateAssignment(AssignmentEntity assignment);
  Future<Either<Failure, void>> deleteAssignment(String assignmentId);
}

// ─────────────────────────────────────────────────────────────────────────────
// lib/domain/repositories/group_repository.dart

abstract class GroupRepository {
  Stream<List<GroupEntity>> watchGroups();
  Future<Either<Failure, GroupEntity>> createGroup({required String name, String? description});
  Future<Either<Failure, void>> updateGroup(GroupEntity group);
  Future<Either<Failure, void>> deleteGroup(String groupId);
}