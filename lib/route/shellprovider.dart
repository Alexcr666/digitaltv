// lib/firestore/shell_providers.dart
// =============================================================================
// Providers faltantes para main_shell.dart
//   - onlineDevicesCountProvider
//   - registerDeviceUseCaseProvider
//   - themeProvider  (si aún no lo tienes)
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Reutiliza los providers y entidades ya definidos en dashboard_complete.dart
// (o donde los tengas). Ajusta el import según tu estructura real:
import 'package:digitaltv/entities/entities.dart'; // DeviceEntity, DeviceStatus
// import 'package:digitaltv/presentation/providers/stream_providers.dart'; // devicesStreamProvider

// =============================================================================
// 1. onlineDevicesCountProvider
//    Deriva del stream de dispositivos y filtra los que están online.
// =============================================================================

/// Devuelve el conteo de dispositivos con status == online en tiempo real.
final onlineDevicesCountProvider = StreamProvider<int>((ref) {
  return FirebaseFirestore.instance
      .collection('devices')
      .where('status', isEqualTo: 'online')
      .snapshots()
      .map((snap) => snap.size);
});

// =============================================================================
// 2. RegisterDeviceUseCase
//    Encapsula la lógica de registrar un dispositivo nuevo en Firestore.
// =============================================================================

/// Resultado tipado: éxito o fallo con mensaje.
sealed class RegisterResult {}

class RegisterSuccess extends RegisterResult {}

class RegisterFailure extends RegisterResult {
  final String message;
  RegisterFailure(this.message);
}

/// Caso de uso que crea el documento en la colección `devices`.
class RegisterDeviceUseCase {
  final FirebaseFirestore _firestore;
  RegisterDeviceUseCase(this._firestore);

  Future<RegisterResult> call({
    required String name,
    required String uniqueDeviceId,
  }) async {
    // Validación básica
    if (name.trim().isEmpty) {
      return RegisterFailure('Device name cannot be empty.');
    }
    if (uniqueDeviceId.trim().isEmpty) {
      return RegisterFailure('Device ID cannot be empty.');
    }

    try {
      // Verifica si el uniqueDeviceId ya existe
      final existing = await _firestore
          .collection('devices')
          .where('uniqueDeviceId', isEqualTo: uniqueDeviceId.trim())
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        return RegisterFailure(
            'A device with ID "$uniqueDeviceId" is already registered.');
      }

      // Crea el documento con un ID auto-generado
      await _firestore.collection('devices').add({
        'name': name.trim(),
        'uniqueDeviceId': uniqueDeviceId.trim(),
        'status': 'offline',
        'groupId': null,
        'groupName': null,
        'currentContentId': null,
        'lastSeen': FieldValue.serverTimestamp(),
        'metadata': {},
        'createdAt': FieldValue.serverTimestamp(),
      });

      return RegisterSuccess();
    } on FirebaseException catch (e) {
      return RegisterFailure(e.message ?? 'Firebase error occurred.');
    } catch (e) {
      return RegisterFailure('Unexpected error: $e');
    }
  }
}

/// Provider del caso de uso. Se puede sobreescribir en tests con un mock.
final registerDeviceUseCaseProvider = Provider<RegisterDeviceUseCase>((ref) {
  return RegisterDeviceUseCase(FirebaseFirestore.instance);
});

// =============================================================================
// 3. themeProvider
//    Persiste la preferencia light/dark del usuario en memoria.
//    (Para persistencia real, usa shared_preferences)
// =============================================================================

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system; // valor inicial

  void toggle() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  void setMode(ThemeMode mode) {
    state = mode;
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);
