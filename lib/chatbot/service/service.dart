
// ─────────────────────────────────────────
// SERVICIO API
// ─────────────────────────────────────────

import 'dart:convert';
import 'dart:developer';

import 'package:digitaltv/chatbot/chatbot.dart';
import 'package:digitaltv/chatbot/models/waConversations.dart';
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
}