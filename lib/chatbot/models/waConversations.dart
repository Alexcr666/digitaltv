
import 'package:flutter/material.dart';

class WAChatbot {
  final String id;
  String name;
  String description;
  String companyName;
  String phoneNumber;
  String phoneNumberId;
  String accessToken;
  String systemPrompt;
  String instructions;
  String aiModel;
  double temperature;
  int maxTokens;
  int contextMessages;
  bool isActive;
  List<String> humanKeywords;
  String humanTransferMessage;
  String errorMessage;
  Map<String, dynamic> stats;
  DateTime? createdAt;

  WAChatbot({
    required this.id,
    required this.name,
    this.description = '',
    this.companyName = '',
    this.phoneNumber = '',
    this.phoneNumberId = '',
    this.accessToken = '',
    this.systemPrompt = '',
    this.instructions = '',
    this.aiModel = 'gpt-4o-mini',
    this.temperature = 0.7,
    this.maxTokens = 500,
    this.contextMessages = 10,
    this.isActive = true,
    this.humanKeywords = const [],
    this.humanTransferMessage = '',
    this.errorMessage = '',
    this.stats = const {},
    this.createdAt,
  });

  factory WAChatbot.fromJson(Map<String, dynamic> j) => WAChatbot(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        description: j['description'] ?? '',
        companyName: j['companyName'] ?? '',
        phoneNumber: j['phoneNumber'] ?? '',
        phoneNumberId: j['phoneNumberId'] ?? '',
        accessToken: j['accessToken'] ?? '',
        systemPrompt: j['systemPrompt'] ?? '',
        instructions: j['instructions'] ?? '',
        aiModel: j['aiModel'] ?? 'gpt-4o-mini',
        temperature: (j['temperature'] ?? 0.7).toDouble(),
        maxTokens: j['maxTokens'] ?? 500,
        contextMessages: j['contextMessages'] ?? 10,
        isActive: j['isActive'] ?? true,
        humanKeywords: List<String>.from(j['humanKeywords'] ?? []),
        humanTransferMessage: j['humanTransferMessage'] ?? '',
        errorMessage: j['errorMessage'] ?? '',
        stats: Map<String, dynamic>.from(j['stats'] ?? {}),
        createdAt: j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt'].toString())
            : null,
      );

  String get statusLabel => isActive ? 'Activo' : 'Inactivo';
  Color get statusColor =>
      isActive ? const Color(0xFF25D366) : const Color(0xFF6B7280);
}



class WAConversation {
  final String id;
  final String botId;
  final String from;
  final String contactName;
  final String lastMessage;
  final int unreadCount;
  final bool humanControl;
  final DateTime lastMessageAt;

  WAConversation({
    required this.id,
    required this.botId,
    required this.from,
    required this.contactName,
    required this.lastMessage,
    this.unreadCount = 0,
    this.humanControl = false,
    required this.lastMessageAt,
  });

  factory WAConversation.fromJson(Map<String, dynamic> j) => WAConversation(
        id: j['id'] ?? '',
        botId: j['botId'] ?? '',
        from: j['from'] ?? '',
        contactName: j['contactName'] ?? j['from'] ?? 'Desconocido',
        lastMessage: j['lastMessage'] ?? '',
        unreadCount: j['unreadCount'] ?? 0,
        humanControl: j['humanControl'] ?? false,
        lastMessageAt: _parseDate(j['lastMessageAt']),
      );

  static DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is Map && v['_seconds'] != null) {
      return DateTime.fromMillisecondsSinceEpoch(v['_seconds'] * 1000);
    }
    return DateTime.tryParse(v.toString()) ?? DateTime.now();
  }
}

class WAMessage {
  final String id;
  final String body;
  final String role;
  final String contactName;
  final DateTime timestamp;

  WAMessage({
    required this.id,
    required this.body,
    required this.role,
    required this.contactName,
    required this.timestamp,
  });

  factory WAMessage.fromJson(Map<String, dynamic> j) => WAMessage(
        id: j['id'] ?? '',
        body: j['body'] ?? '',
        role: j['role'] ?? 'user',
        contactName: j['contactName'] ?? '',
        timestamp: WAConversation._parseDate(j['timestamp']),
      );
}
