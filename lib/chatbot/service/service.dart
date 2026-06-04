
// ─────────────────────────────────────────
// SERVICIO API
// ─────────────────────────────────────────

import 'dart:convert';
import 'dart:developer';

import 'package:digitaltv/chatbot/chatbot.dart';
import 'package:digitaltv/chatbot/models/waConversations.dart';
import 'package:digitaltv/chatbot/page/massSend.dart';
import 'package:http/http.dart' as http;
class WAService {
  final String userId;
  WAService(this.userId);

  Future<Map<String, dynamic>> _get(String path) async {
    final r = await http.get(Uri.parse('$kWABaseUrl$path'),
        headers: {'Content-Type': 'application/json'});
        log("message12: "+Uri.parse('$kWABaseUrl$path').toString()+".  :  "+r.body);
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _post(
      String path, Map<String, dynamic> body) async {
    final r = await http.post(Uri.parse('$kWABaseUrl$path'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body));
            log("message123: "+Uri.parse('$kWABaseUrl$path').toString()+".  :   "+r.body);
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _patch(
      String path, Map<String, dynamic> body) async {
    final r = await http.patch(Uri.parse('$kWABaseUrl$path'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body));
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _delete(String path) async {
    final r = await http.delete(Uri.parse('$kWABaseUrl$path'),
        headers: {'Content-Type': 'application/json'});
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<List<WAChatbot>> getChatbots() async {
    final res = await _get('/api/wa/chatbots/$userId');
    if (res['success'] == true) {
      return (res['data']['chatbots'] as List)
          .map((e) => WAChatbot.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<String?> createChatbot(Map<String, dynamic> config) async {
    final res =
        await _post('/api/wa/chatbots', {'userId': userId, 'chatbot': config});
    return res['success'] == true ? res['data']['id'] as String : null;
  }

  Future<bool> updateChatbot(String botId, Map<String, dynamic> updates) async {
    final res = await _patch('/api/wa/chatbots/$userId/$botId', updates);
    return res['success'] == true;
  }

  Future<bool> deleteChatbot(String botId) async {
    final res = await _delete('/api/wa/chatbots/$userId/$botId');
    return res['success'] == true;
  }

  Future<bool> toggleAI(String botId) async {
    final res =
        await _post('/api/wa/chatbots/$userId/$botId/toggle-ai', {});
    return res['success'] == true;
  }

  Future<Map<String, dynamic>?> getBotStatus(String botId) async {
    final res = await _get('/api/wa/chatbots/$userId/$botId/status');
    return res['success'] == true
        ? res['data'] as Map<String, dynamic>
        : null;
  }

  Future<Map<String, dynamic>?> getBotSummary(String botId) async {
    final res = await _get('/api/wa/chatbots/$userId/$botId/summary');
    return res['success'] == true
        ? res['data'] as Map<String, dynamic>
        : null;
  }

  Future<Map<String, dynamic>?> getBotStats(String botId,
      {String period = '7d'}) async {
    final res =
        await _get('/api/wa/chatbots/$userId/$botId/stats?period=$period');
    return res['success'] == true
        ? res['data'] as Map<String, dynamic>
        : null;
  }

  Future<List<WAConversation>> getConversations(String botId) async {
    final res =
        await _get('/api/wa/chatbots/$userId/$botId/conversations');
    if (res['success'] == true) {
      return (res['data']['conversations'] as List)
          .map((e) => WAConversation.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<WAMessage>> getMessages(String conversationId) async {
    final res =
        await _get('/api/wa/conversations/$conversationId/messages');
    if (res['success'] == true) {
      return (res['data']['messages'] as List)
          .map((e) => WAMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<bool> sendMessage(
      String conversationId, String text, String agentName) async {
    final res = await _post('/api/wa/conversations/$conversationId/send',
        {'text': text, 'agentName': agentName});
    return res['success'] == true;
  }

  Future<bool> setHumanControl(
      String conversationId, bool enable) async {
    final res = await _post(
        '/api/wa/conversations/$conversationId/human-control',
        {'enable': enable});
    return res['success'] == true;
  }

  Future<Map<String, dynamic>?> getDashboard() async {
    final res = await _get('/api/wa/dashboard/$userId');
    return res['success'] == true
        ? res['data'] as Map<String, dynamic>
        : null;
  }
  // ── TOKEN USAGE ──
  Future<Map<String, dynamic>> getTokenUsage({String period = '7d'}) async {
    final res = await _get('/api/wa/tokens/$userId?period=$period');
    return res['success'] == true
        ? res['data'] as Map<String, dynamic>
        : {'totalTokens': 0, 'promptTokens': 0, 'completionTokens': 0, 'estimatedCost': 0.0, 'daily': [], 'byBot': []};
  }

  // ── MASS SEND ──
  Future<Map<String, dynamic>> sendMassMessage({
    required String botId,
    required List<String> contactIds,
    required String message,
    String? templateId,
  }) async {
    final res = await _post('/api/wa/chatbots/$userId/$botId/mass-send', {
      'contactIds': contactIds,
      'message': message,
      if (templateId != null) 'templateId': templateId,
    });
    return res;
  }

  Future<List<Map<String, dynamic>>> getMassSendHistory(String botId) async {
    final res = await _get('/api/wa/chatbots/$userId/$botId/mass-send/history');
    if (res['success'] == true) {
      return List<Map<String, dynamic>>.from(res['data']['history'] ?? []);
    }
    return [];
  }

  // ── TEMPLATES ──
  Future<List<Map<String, dynamic>>> getTemplates(String botId) async {
    final res = await _get('/api/wa/chatbots/$userId/$botId/templates');
    if (res['success'] == true) {
      return List<Map<String, dynamic>>.from(res['data']['templates'] ?? []);
    }
    return [];
  }

  Future<bool> saveTemplate(
      {required String botId,
      required String name,
      required String body,
      required String category}) async {
    final res = await _post('/api/wa/chatbots/$userId/$botId/templates', {
      'name': name,
      'body': body,
      'category': category,
    });
    return res['success'] == true;
  }

  Future<bool> deleteTemplate(String botId, String templateId) async {
    final res =
        await _delete('/api/wa/chatbots/$userId/$botId/templates/$templateId');
    return res['success'] == true;
  }

  // ── PHONE VERIFICATION ──
  Future<Map<String, dynamic>> verifyPhoneNumber(
      String botId, String displayName) async {
    final res = await _post(
        '/api/wa/chatbots/$userId/$botId/verify-phone', {'displayName': displayName});
    return res;
  }

  Future<Map<String, dynamic>> getPhoneStatus(String botId) async {
    final res = await _get('/api/wa/chatbots/$userId/$botId/phone-status');
    return res['success'] == true ? res['data'] as Map<String, dynamic> : {};
  }


  // ── TEMPLATES RICH ──
  Future<List<WATemplate>> getTemplatesRich(String botId) async {
    final res = await _get('/api/wa/chatbots/$userId/$botId/templates/rich');
    if (res['success'] == true) {
      return (res['data']['templates'] as List)
          .map((e) => WATemplate.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<bool> saveTemplateRich({
    required String botId,
    required String name,
    required String category,
    required String headerType,
    required String headerText,
    required String body,
    required String footer,
    required List<Map<String, dynamic>> buttons,
    required List<String> bodyVariables,
  }) async {
    final res = await _post('/api/wa/chatbots/$userId/$botId/templates/rich', {
      'name': name,
      'category': category,
      'headerType': headerType,
      'headerText': headerText,
      'body': body,
      'footer': footer,
      'buttons': buttons,
      'bodyVariables': bodyVariables,
      'status': 'PENDING',
    });
    return res['success'] == true;
  }

  Future<bool> syncMetaTemplates(String botId) async {
    final res = await _post('/api/wa/chatbots/$userId/$botId/templates/sync-meta', {});
    return res['success'] == true;
  }

  // ── TOKEN USAGE ADVANCED ──
  Future<Map<String, dynamic>> getTokenUsageAdvanced(Map<String, String> params) async {
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final res = await _get('/api/wa/tokens/$userId?$query');
    return res['success'] == true
        ? res['data'] as Map<String, dynamic>
        : {
            'totalTokens': 0, 'promptTokens': 0, 'completionTokens': 0,
            'estimatedCost': 0.0, 'totalCalls': 0, 'daily': [], 'byBot': []
          };
  }
}