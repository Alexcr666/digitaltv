
// =============================================================================
// DESIGN TOKENS
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
abstract class C {
  static const bg = Color(0xFF070B12);
  static const surface = Color(0xFF0C1018);
  static const card = Color(0xFF111827);
  static const cardHover = Color(0xFF151E2F);
  static const border = Color(0xFF1F2D45);
  static const borderFocus = Color(0xFF6366F1);
  static const primary = Color(0xFF6366F1);
  static const primaryLo = Color(0x1A6366F1);
  static const accent = Color(0xFF38BDF8);
  static const accentLo = Color(0x1A38BDF8);
  static const green = Color(0xFF22C55E);
  static const greenLo = Color(0x1A22C55E);
  static const amber = Color(0xFFF59E0B);
  static const amberLo = Color(0x1AF59E0B);
  static const red = Color(0xFFEF4444);
  static const redLo = Color(0x1AEF4444);
  static const purple = Color(0xFFA855F7);
  static const purpleLo = Color(0x1AA855F7);
  static const textHi = Color(0xFFF1F5FF);
  static const textMid = Color(0xFF7B8DB0);
  static const textLo = Color(0xFF2E3D5C);
  static const divider = Color(0xFF141E30);
}

// =============================================================================
// MODELOS
// =============================================================================

enum DeviceStatus { online, offline, warning }

enum ContentType { image, video, text, url }

class DeviceModel {
  final String id;
  final String name;
  final String uniqueDeviceId;
  final DeviceStatus status;
  final String? groupId;
  final String? groupName;
  final String? currentPlaylistId;
  final String? currentPlaylistName;
  final DateTime? lastSeen;
  final Map<String, dynamic> metadata;
  final String displayUrl;
  final String? location;
  final String? resolution;
  final String? orientation;
  final String? notes;
  final List<String> tags;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> assignedPlaylistIds;
  final List<String> assignedScheduleIds;

  const DeviceModel({
    required this.id,
    required this.name,
    required this.uniqueDeviceId,
    required this.status,
    this.groupId,
    this.groupName,
    this.currentPlaylistId,
    this.currentPlaylistName,
    this.lastSeen,
    this.metadata = const {},
    required this.displayUrl,
    this.location,
    this.resolution,
    this.orientation,
    this.notes,
    this.tags = const [],
    this.createdAt,
    this.updatedAt,
    this.assignedPlaylistIds = const [],
    this.assignedScheduleIds = const [],
  });
  factory DeviceModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    DateTime? parseDate(dynamic val) {
      try {
        if (val == null) return null;
        if (val is Timestamp) return val.toDate();
        if (val is String && val.isNotEmpty) return DateTime.tryParse(val);
        if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      } catch (e) {
        debugPrint('[DeviceModel] parseDate error: $e — val=$val');
      }
      return null;
    }

    try {
      return DeviceModel(
        id: doc.id,
        name: d['name'] ?? 'Dispositivo',
        uniqueDeviceId: d['uniqueDeviceId'] ?? '',
        status: _parseStatus(d['status']),
        groupId: d['groupId'],
        groupName: d['groupName'],
        currentPlaylistId: d['currentPlaylistId'],
        currentPlaylistName: d['currentPlaylistName'],
        lastSeen: parseDate(d['lastSeen']),
        metadata: (d['metadata'] as Map<String, dynamic>?) ?? {},
        displayUrl: d['displayUrl'] ?? '',
        location: d['location'],
        resolution: d['resolution'],
        orientation: d['orientation'],
        notes: d['notes'],
        tags: List<String>.from(d['tags'] ?? []),
        createdAt: parseDate(d['createdAt']),
        updatedAt: parseDate(d['updatedAt']),
        assignedPlaylistIds: List<String>.from(d['assignedPlaylistIds'] ?? []),
        assignedScheduleIds: List<String>.from(d['assignedScheduleIds'] ?? []),
      );
    } catch (e, stack) {
      debugPrint('[DeviceModel.fromFirestore] ERROR doc=${doc.id}: $e');
      debugPrint('[DeviceModel.fromFirestore] data=$d');
      debugPrint(stack.toString());
      // Retorna modelo mínimo para no romper la lista
      return DeviceModel(
        id: doc.id,
        name: d['name'] ?? 'Dispositivo (error)',
        uniqueDeviceId: d['uniqueDeviceId'] ?? '',
        status: DeviceStatus.offline,
        displayUrl: d['displayUrl'] ?? '',
      );
    }
  }

  static DeviceStatus _parseStatus(String? s) {
    switch (s) {
      case 'online':
        return DeviceStatus.online;
      case 'warning':
        return DeviceStatus.warning;
      default:
        return DeviceStatus.offline;
    }
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'uniqueDeviceId': uniqueDeviceId,
        'status': status.name,
        'groupId': groupId,
        'groupName': groupName,
        'currentPlaylistId': currentPlaylistId,
        'currentPlaylistName': currentPlaylistName,
        'lastSeen': FieldValue.serverTimestamp(),
        'metadata': metadata,
        'displayUrl': displayUrl,
        'location': location,
        'resolution': resolution,
        'orientation': orientation,
        'notes': notes,
        'tags': tags,
        'assignedPlaylistIds': assignedPlaylistIds,
        'assignedScheduleIds': assignedScheduleIds,
      };
}

class PlaylistItemModel {
  final String id;
  final ContentType type;
  final String title;
  final String? url; // imagen / video / url externa
  final String? textContent; // para tipo texto
  final int durationSeconds;
  final int order;

  const PlaylistItemModel({
    required this.id,
    required this.type,
    required this.title,
    this.url,
    this.textContent,
    this.durationSeconds = 10,
    required this.order,
  });

  factory PlaylistItemModel.fromMap(Map<String, dynamic> d) =>
      PlaylistItemModel(
        id: d['id'] ?? const Uuid().v4(),
        type: ContentType.values.firstWhere((e) => e.name == d['type'],
            orElse: () => ContentType.image),
        title: d['title'] ?? '',
        url: d['url'],
        textContent: d['textContent'],
        durationSeconds: d['durationSeconds'] ?? 10,
        order: d['order'] ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.name,
        'title': title,
        'url': url,
        'textContent': textContent,
        'durationSeconds': durationSeconds,
        'order': order,
      };
}

class PlaylistModel {
  final String id;
  final String name;
  final String? description;
  final List<PlaylistItemModel> items;
  final DateTime createdAt;
  final String displayToken; // token único para URL pública
  final bool isActive;

  const PlaylistModel({
    required this.id,
    required this.name,
    this.description,
    required this.items,
    required this.createdAt,
    required this.displayToken,
    this.isActive = true,
  });
  factory PlaylistModel.fromFirestore(DocumentSnapshot doc) {
    DateTime parseDate(dynamic val, DateTime fallback) {
      try {
        if (val == null) return fallback;
        if (val is Timestamp) return val.toDate();
        if (val is String && val.isNotEmpty)
          return DateTime.tryParse(val) ?? fallback;
        if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      } catch (e) {
        debugPrint('[PlaylistModel] parseDate error: $e — val=$val');
      }
      return fallback;
    }

    final d = doc.data() as Map<String, dynamic>;

    try {
      // Lee 'items' (PlaylistModel) o 'clips' (SavedPlaylist del editor) como fallback
      final rawItems = (d['items'] as List<dynamic>?) ??
          (d['clips'] as List<dynamic>?) ??
          [];

      List<PlaylistItemModel> parsedItems = [];
      for (final i in rawItems) {
        try {
          final map = i as Map<String, dynamic>;
          // SavedPlaylist.clips tienen campos distintos: type, label, url, text, durationSec
          // PlaylistItemModel.items tienen: type, title, url, textContent, durationSeconds
          parsedItems.add(PlaylistItemModel(
            id: map['id'] ?? const Uuid().v4(),
            type: ContentType.values.firstWhere(
                (e) => e.name == (map['type'] ?? 'image'),
                orElse: () => ContentType.image),
            title: map['title'] ?? map['label'] ?? '',
            url: map['url'],
            textContent: map['textContent'] ?? map['text'],
            durationSeconds:
                (map['durationSeconds'] ?? map['durationSec'] ?? 10) is int
                    ? (map['durationSeconds'] ?? map['durationSec'] ?? 10)
                    : (map['durationSeconds'] ?? map['durationSec'] ?? 10.0)
                        .round(),
            order: map['order'] ?? 0,
          ));
        } catch (e) {
          debugPrint('[PlaylistModel] error parsing item: $e');
        }
      }

      parsedItems.sort((a, b) => a.order.compareTo(b.order));

      return PlaylistModel(
        id: doc.id,
        name: d['name'] ?? 'Playlist',
        description: d['description'],
        items: parsedItems,
        createdAt: parseDate(d['createdAt'], DateTime.now()),
        displayToken: d['displayToken'] ?? '',
        isActive: d['isActive'] ?? true,
      );
    } catch (e, stack) {
      debugPrint('[PlaylistModel.fromFirestore] ERROR doc=${doc.id}: $e');
      debugPrint('[PlaylistModel.fromFirestore] data=$d');
      debugPrint(stack.toString());
      return PlaylistModel(
        id: doc.id,
        name: d['name'] ?? 'Playlist (error)',
        items: [],
        createdAt: DateTime.now(),
        displayToken: d['displayToken'] ?? '',
      );
    }
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'items': items.map((i) => i.toMap()).toList(),
        'createdAt': FieldValue.serverTimestamp(),
        'displayToken': displayToken,
        'isActive': isActive,
      };
}
