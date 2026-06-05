// ─────────────────────────────────────────
// CONFIG VIEW
// ─────────────────────────────────────────
import 'package:digitaltv/chatbot/color.dart';
import 'package:digitaltv/chatbot/models/waConversations.dart';
import 'package:digitaltv/chatbot/page/widget.dart';
import 'package:digitaltv/chatbot/page/widget.dart' as widget2;
import 'package:digitaltv/chatbot/service/service.dart';
import 'package:flutter/material.dart';

class ConfigView extends StatefulWidget {
  final WAChatbot bot;
  final WAService service;
  final VoidCallback onBack;
  final VoidCallback onSaved;
  const ConfigView(
      {required this.bot,
      required this.service,
      required this.onBack,
      required this.onSaved});

  @override
  State<ConfigView> createState() => _ConfigViewState();
}

class _ConfigViewState extends State<ConfigView> {
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _companyCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _phoneIdCtrl;
  late TextEditingController _tokenCtrl;
  late TextEditingController _promptCtrl;
  late TextEditingController _instructionsCtrl;
  late TextEditingController _errorMsgCtrl;
  late TextEditingController _transferMsgCtrl;
  late TextEditingController _keywordsCtrl;
  String _model = 'gpt-4o-mini';
  double _temperature = 0.7;
  int _maxTokens = 500;
  int _contextMessages = 10;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final b = widget.bot;
    _nameCtrl = TextEditingController(text: b.name);
    _descCtrl = TextEditingController(text: b.description);
    _companyCtrl = TextEditingController(text: b.companyName);
    _phoneCtrl = TextEditingController(text: b.phoneNumber);
    _phoneIdCtrl = TextEditingController(text: b.phoneNumberId);
    _tokenCtrl = TextEditingController(text: b.accessToken);
    _promptCtrl = TextEditingController(text: b.systemPrompt);
    _instructionsCtrl = TextEditingController(text: b.instructions);
    _errorMsgCtrl = TextEditingController(
        text: b.errorMessage.isNotEmpty
            ? b.errorMessage
            : 'Lo siento, hubo un error. Intenta de nuevo.');
    _transferMsgCtrl = TextEditingController(
        text: b.humanTransferMessage.isNotEmpty
            ? b.humanTransferMessage
            : 'Te conecto con un agente. Un momento por favor.');
    _keywordsCtrl = TextEditingController(text: b.humanKeywords.join(', '));
    _model = b.aiModel;
    _temperature = b.temperature;
    _maxTokens = b.maxTokens;
    _contextMessages = b.contextMessages;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _companyCtrl.dispose();
    _phoneCtrl.dispose();
    _phoneIdCtrl.dispose();
    _tokenCtrl.dispose();
    _promptCtrl.dispose();
    _instructionsCtrl.dispose();
    _errorMsgCtrl.dispose();
    _transferMsgCtrl.dispose();
    _keywordsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final keywords = _keywordsCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    await widget.service.updateChatbot(widget.bot.id, {
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'companyName': _companyCtrl.text.trim(),
      'phoneNumber': _phoneCtrl.text.trim(),
      'phoneNumberId': _phoneIdCtrl.text.trim(),
      'accessToken': _tokenCtrl.text.trim(),
      'systemPrompt': _promptCtrl.text.trim(),
      'instructions': _instructionsCtrl.text.trim(),
      'aiModel': _model,
      'temperature': _temperature,
      'maxTokens': _maxTokens,
      'contextMessages': _contextMessages,
      'humanKeywords': keywords,
      'errorMessage': _errorMsgCtrl.text.trim(),
      'humanTransferMessage': _transferMsgCtrl.text.trim(),
    });

    setState(() => _saving = false);
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WAColors.bg,
      child: Column(
        children: [
          PageHeader(
            title: 'Configurar Bot',
            subtitle: widget.bot.name,
            icon: Icons.settings_rounded,
            iconColor: WAColors.accent,
            onBack: widget.onBack,
            actions: [
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: WAColors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  minimumSize: Size.zero, // ✅
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap, // ✅
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_rounded, size: 16),
                    const SizedBox(width: 8),
                    Text(_saving ? 'Guardando...' : 'Guardar'),
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Col 1
                  Expanded(
                    child: Column(
                      children: [
                        WACard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Información básica',
                                  style: TextStyle(
                                      color: WAColors.textPri,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15)),
                              const SizedBox(height: 16),
                              widget2.FormField(
                                  label: 'Nombre del bot',
                                  controller: _nameCtrl),
                              const SizedBox(height: 12),
                              widget2.FormField(
                                  label: 'Descripción',
                                  controller: _descCtrl,
                                  maxLines: 2),
                              const SizedBox(height: 12),
                              widget2.FormField(
                                  label: 'Empresa / Negocio',
                                  controller: _companyCtrl),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        WACard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Configuración WhatsApp',
                                  style: TextStyle(
                                      color: WAColors.textPri,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15)),
                              const SizedBox(height: 8),
                              const Text(
                                  'Datos de tu cuenta de WhatsApp Business (Meta)',
                                  style: TextStyle(
                                      color: WAColors.textMuted, fontSize: 12)),
                              const SizedBox(height: 14),
                              widget2.FormField(
                                label: 'Número de WhatsApp',
                                controller: _phoneCtrl,
                                hint: 'Ej: +573001234567',
                              ),
                              const SizedBox(height: 12),
                              widget2.FormField(
                                label: 'Phone Number ID (Meta)',
                                controller: _phoneIdCtrl,
                                hint: 'ID del número en Meta Business',
                              ),
                              const SizedBox(height: 12),
                              widget2.FormField(
                                label: 'Access Token (Meta)',
                                controller: _tokenCtrl,
                                hint: 'Token de acceso de Meta',
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        WACard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Prompt del sistema',
                                  style: TextStyle(
                                      color: WAColors.textPri,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15)),
                              const SizedBox(height: 12),
                              widget2.FormField(
                                label: 'System Prompt',
                                controller: _promptCtrl,
                                maxLines: 6,
                                hint:
                                    'Eres un asistente de WhatsApp para {empresa}...',
                              ),
                              const SizedBox(height: 12),
                              widget2.FormField(
                                label: 'Instrucciones adicionales',
                                controller: _instructionsCtrl,
                                maxLines: 4,
                                hint:
                                    'Reglas específicas: horarios, precios...',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Col 2
                  Expanded(
                    child: Column(
                      children: [
                        WACard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Configuración IA',
                                  style: TextStyle(
                                      color: WAColors.textPri,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15)),
                              const SizedBox(height: 16),
                              const Text('Modelo',
                                  style: TextStyle(
                                      color: WAColors.textSec, fontSize: 12)),
                              const SizedBox(height: 6),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: WAColors.bg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: WAColors.border),
                                ),
                                child: DropdownButton<String>(
                                  value: _model,
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  dropdownColor: WAColors.card,
                                  style: const TextStyle(
                                      color: WAColors.textPri, fontSize: 13),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'gpt-4o-mini',
                                        child: Text('GPT-4o Mini (rápido)')),
                                    DropdownMenuItem(
                                        value: 'gpt-4o',
                                        child: Text('GPT-4o (potente)')),
                                    DropdownMenuItem(
                                        value: 'gpt-3.5-turbo',
                                        child: Text('GPT-3.5 Turbo')),
                                  ],
                                  onChanged: (v) => setState(() => _model = v!),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Text('Creatividad (Temperatura)',
                                      style: TextStyle(
                                          color: WAColors.textSec,
                                          fontSize: 12)),
                                  const Spacer(),
                                  Text(_temperature.toStringAsFixed(1),
                                      style: const TextStyle(
                                          color: WAColors.green,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                ],
                              ),
                              Slider(
                                value: _temperature,
                                min: 0,
                                max: 1,
                                divisions: 10,
                                activeColor: WAColors.green,
                                inactiveColor: WAColors.border,
                                onChanged: (v) =>
                                    setState(() => _temperature = v),
                              ),
                              Row(
                                children: [
                                  const Text('Máx. tokens',
                                      style: TextStyle(
                                          color: WAColors.textSec,
                                          fontSize: 12)),
                                  const Spacer(),
                                  Text('$_maxTokens',
                                      style: const TextStyle(
                                          color: WAColors.accent,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                ],
                              ),
                              Slider(
                                value: _maxTokens.toDouble(),
                                min: 100,
                                max: 2000,
                                divisions: 19,
                                activeColor: WAColors.accent,
                                inactiveColor: WAColors.border,
                                onChanged: (v) =>
                                    setState(() => _maxTokens = v.toInt()),
                              ),
                              Row(
                                children: [
                                  const Text('Mensajes de contexto',
                                      style: TextStyle(
                                          color: WAColors.textSec,
                                          fontSize: 12)),
                                  const Spacer(),
                                  Text('$_contextMessages',
                                      style: const TextStyle(
                                          color: WAColors.info,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                ],
                              ),
                              Slider(
                                value: _contextMessages.toDouble(),
                                min: 3,
                                max: 20,
                                divisions: 17,
                                activeColor: WAColors.info,
                                inactiveColor: WAColors.border,
                                onChanged: (v) => setState(
                                    () => _contextMessages = v.toInt()),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        WACard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Control Humano',
                                  style: TextStyle(
                                      color: WAColors.textPri,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15)),
                              const SizedBox(height: 8),
                              const Text(
                                  'Palabras que activan el traspaso al agente',
                                  style: TextStyle(
                                      color: WAColors.textMuted, fontSize: 12)),
                              const SizedBox(height: 12),
                              widget2.FormField(
                                label: 'Palabras clave (separadas por coma)',
                                controller: _keywordsCtrl,
                                hint: 'humano, agente, persona, help',
                              ),
                              const SizedBox(height: 12),
                              widget2.FormField(
                                label: 'Mensaje de transferencia',
                                controller: _transferMsgCtrl,
                                maxLines: 2,
                              ),
                              const SizedBox(height: 12),
                              widget2.FormField(
                                label: 'Mensaje de error',
                                controller: _errorMsgCtrl,
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
