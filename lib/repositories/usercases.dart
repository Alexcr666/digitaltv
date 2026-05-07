// lib/domain/usecases/usecases.dart
import 'package:dartz/dartz.dart';
import 'package:digitaltv/repositories/failure.dart';
import '../entities/entities.dart';
import '../repositories/repositories.dart';


// ── AUTH USE CASES ────────────────────────────────────────────────────────────

class SignInUseCase {
  final AuthRepository _repo;
  const SignInUseCase(this._repo);

  Future<Either<Failure, UserEntity>> call(String email, String password) =>
      _repo.signIn(email, password);
}

class SignOutUseCase {
  final AuthRepository _repo;
  const SignOutUseCase(this._repo);
  Future<Either<Failure, void>> call() => _repo.signOut();
}

class WatchAuthStateUseCase {
  final AuthRepository _repo;
  const WatchAuthStateUseCase(this._repo);
  Stream<UserEntity?> call() => _repo.authStateChanges;
}

// ── DEVICE USE CASES ─────────────────────────────────────────────────────────

class WatchDevicesUseCase {
  final DeviceRepository _repo;
  const WatchDevicesUseCase(this._repo);
  Stream<List<DeviceEntity>> call() => _repo.watchDevices();
}

class RegisterDeviceUseCase {
  final DeviceRepository _repo;
  const RegisterDeviceUseCase(this._repo);

  Future<Either<Failure, DeviceEntity>> call({
    required String name,
    required String uniqueDeviceId,
    String? groupId,
  }) => _repo.registerDevice(
    name: name,
    uniqueDeviceId: uniqueDeviceId,
    groupId: groupId,
  );
}

class PushContentToDeviceUseCase {
  final AssignmentRepository _assignRepo;
  const PushContentToDeviceUseCase(this._assignRepo);

  Future<Either<Failure, AssignmentEntity>> call({
    required String deviceId,
    required String contentId,
    required String contentName,
  }) => _assignRepo.createAssignment(AssignmentEntity(
    id: '',
    targetType: AssignmentTarget.device,
    tvId: deviceId,
    contentId: contentId,
    contentName: contentName,
    priority: 1,
    active: true,
    createdAt: DateTime.now(),
  ));
}

// ── CONTENT USE CASES ────────────────────────────────────────────────────────

class WatchContentUseCase {
  final ContentRepository _repo;
  const WatchContentUseCase(this._repo);
  Stream<List<ContentEntity>> call() => _repo.watchContent();
}

class CreateContentUseCase {
  final ContentRepository _repo;
  const CreateContentUseCase(this._repo);
  Future<Either<Failure, ContentEntity>> call(ContentEntity content) =>
      _repo.createContent(content);
}

class DeleteContentUseCase {
  final ContentRepository _repo;
  const DeleteContentUseCase(this._repo);
  Future<Either<Failure, void>> call(String id) => _repo.deleteContent(id);
}

// ── ASSIGNMENT USE CASES ─────────────────────────────────────────────────────

class WatchAssignmentsUseCase {
  final AssignmentRepository _repo;
  const WatchAssignmentsUseCase(this._repo);
  Stream<List<AssignmentEntity>> call() => _repo.watchAssignments();
}

class AssignContentUseCase {
  final AssignmentRepository _repo;
  const AssignContentUseCase(this._repo);

  Future<Either<Failure, AssignmentEntity>> call({
    required AssignmentTarget target,
    String? tvId,
    String? groupId,
    required String contentId,
    required String contentName,
    int priority = 2,
  }) => _repo.createAssignment(AssignmentEntity(
    id: '',
    targetType: target,
    tvId: tvId,
    groupId: groupId,
    contentId: contentId,
    contentName: contentName,
    priority: priority,
    active: true,
    createdAt: DateTime.now(),
  ));
}

/// Resolves which content a TV should show.
/// Priority chain: device-specific (1) > group (2) > global (3)
class WatchResolvedContentUseCase {
  final AssignmentRepository _repo;
  const WatchResolvedContentUseCase(this._repo);

  Stream<ContentEntity?> call(String deviceId, String? groupId) =>
      _repo.watchResolvedContentForDevice(deviceId, groupId);
}