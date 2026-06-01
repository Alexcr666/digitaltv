
import 'package:digitaltv/ui/panel/panel.dart';
import 'package:digitaltv/ui/panel/panel/page/model/model.dart';
import 'package:digitaltv/ui/panel/panel/page/widget/utils.dart';
import 'package:digitaltv/ui/panel/panel/page/widget/widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DevicesScreen extends ConsumerStatefulWidget {
  const DevicesScreen({super.key});

  @override
  ConsumerState<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends ConsumerState<DevicesScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final devicesAsync = ref.watch(devicesStreamProvider);

    return Scaffold(
      backgroundColor: C.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          ScreenHeader(
            title: 'Dispositivos1',
            subtitle: 'Gestiona tus pantallas y asigna playlists',
            action: AddButton(
              label: '+ Agregar dispositivo',
              onTap: () => _showAddDeviceSheet(context),
            ),
          ),

          // ── Filter tabs ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: devicesAsync.when(
              data: (devices) => FilterTabs(
                selected: _filter,
                tabs: [
                  ('all', 'Todos', devices.length),
                  (
                    'online',
                    'En línea',
                    devices.where((d) => d.status == DeviceStatus.online).length
                  ),
                  (
                    'offline',
                    'Fuera línea',
                    devices
                        .where((d) => d.status == DeviceStatus.offline)
                        .length
                  ),
                ],
                onChanged: (v) => setState(() => _filter = v),
              ),
              loading: () => const SizedBox(height: 40),
              error: (_, __) => const SizedBox(height: 40),
            ),
          ),

          // ── Device list ───────────────────────────────────────────────────
          Expanded(
            child: devicesAsync.when(
              loading: () => const SkeletonList(),
              error: (e, _) => EmptyState(
                icon: Icons.error_outline_rounded,
                title: 'Error al cargar',
                subtitle: e.toString(),
              ),
              data: (devices) {
                final filtered = _filter == 'all'
                    ? devices
                    : devices.where((d) => d.status.name == _filter).toList();

                if (filtered.isEmpty) {
                  return EmptyState(
                    icon: Icons.tv_off_rounded,
                    title: 'No hay dispositivos',
                    subtitle: 'Agrega tu primera pantalla para comenzar.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) => DeviceCard(
                    device: filtered[i],
                    index: i,
                  )
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: i * 40))
                      .slideY(begin: 0.05, curve: Curves.easeOut),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDeviceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddDeviceSheet(),
    );
  }
}

// ── Device Card ───────────────────────────────────────────────────────────────
class EditDeviceSheet extends ConsumerStatefulWidget {
  final DeviceModel device;
  const EditDeviceSheet({required this.device});

  @override
  ConsumerState<EditDeviceSheet> createState() => _EditDeviceSheetState();
}

class _EditDeviceSheetState extends ConsumerState<EditDeviceSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _groupCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _tagCtrl;
  late String _resolution;
  late String _orientation;
  late List<String> _tags;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.device.name);
    _groupCtrl = TextEditingController(text: widget.device.groupName ?? '');
    _locationCtrl = TextEditingController(text: widget.device.location ?? '');
    _notesCtrl = TextEditingController(text: widget.device.notes ?? '');
    _tagCtrl = TextEditingController();
    _resolution = widget.device.resolution ?? '1920x1080';
    _orientation = widget.device.orientation ?? 'landscape';
    _tags = List.from(widget.device.tags);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _groupCtrl.dispose();
    _locationCtrl.dispose();
    _notesCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  void _addTag() {
    final t = _tagCtrl.text.trim();
    if (t.isNotEmpty && !_tags.contains(t)) {
      setState(() {
        _tags.add(t);
        _tagCtrl.clear();
      });
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final updated = DeviceModel(
        id: widget.device.id,
        name: _nameCtrl.text.trim(),
        uniqueDeviceId: widget.device.uniqueDeviceId,
        status: widget.device.status,
        groupId: _groupCtrl.text.trim().isEmpty ? null : _groupCtrl.text.trim(),
        groupName:
            _groupCtrl.text.trim().isEmpty ? null : _groupCtrl.text.trim(),
        displayUrl: widget.device.displayUrl,
        currentPlaylistId: widget.device.currentPlaylistId,
        currentPlaylistName: widget.device.currentPlaylistName,
        location: _locationCtrl.text.trim().isEmpty
            ? null
            : _locationCtrl.text.trim(),
        resolution: _resolution,
        orientation: _orientation,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        tags: _tags,
        createdAt: widget.device.createdAt,
      );
      await DeviceService().updateDevice(updated);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Sheet(
      title: 'Editar dispositivo',
      subtitle: 'ID: ${widget.device.uniqueDeviceId}',
      icon: Icons.edit_outlined,
      iconColor: C.primary,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null) ErrorBanner(message: _error!),

            // ── Fechas ────────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: DateInfoBox(
                    label: 'Creado',
                    value: _formatDate(widget.device.createdAt),
                    icon: Icons.calendar_today_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DateInfoBox(
                    label: 'Actualizado',
                    value: _formatDate(widget.device.updatedAt),
                    icon: Icons.update_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Info básica ───────────────────────────────────────────────
            SectionTitle('Información básica'),
            SheetLabel('Nombre *'),
            SheetField(
              controller: _nameCtrl,
              hint: 'Nombre del dispositivo',
              icon: Icons.label_outline_rounded,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'El nombre es obligatorio'
                  : null,
            ),
            const SizedBox(height: 14),
            SheetLabel('Grupo'),
            SheetField(
              controller: _groupCtrl,
              hint: 'Ej: Lobby, Piso 2',
              icon: Icons.group_work_outlined,
            ),
            const SizedBox(height: 14),
            SheetLabel('Ubicación'),
            SheetField(
              controller: _locationCtrl,
              hint: 'Ej: Entrada principal',
              icon: Icons.location_on_outlined,
            ),

            const SizedBox(height: 20),
            SectionTitle('Configuración técnica'),
            SheetLabel('Resolución'),
            DropdownField<String>(
              value: _resolution,
              items: const [
                '1920x1080',
                '3840x2160',
                '1280x720',
                '1024x768',
                '1366x768'
              ],
              icon: Icons.monitor_rounded,
              onChanged: (v) => setState(() => _resolution = v!),
            ),
            const SizedBox(height: 14),
            SheetLabel('Orientación'),
            Row(
              children: [
                OrientationChip(
                  label: 'Horizontal',
                  icon: Icons.stacked_bar_chart,
                  selected: _orientation == 'landscape',
                  onTap: () => setState(() => _orientation = 'landscape'),
                ),
                const SizedBox(width: 10),
                OrientationChip(
                  label: 'Vertical',
                  icon: Icons.safety_check_rounded,
                  selected: _orientation == 'portrait',
                  onTap: () => setState(() => _orientation = 'portrait'),
                ),
              ],
            ),

            const SizedBox(height: 20),
            SectionTitle('Etiquetas'),
            Row(
              children: [
                Expanded(
                  child: SheetField(
                    controller: _tagCtrl,
                    hint: 'Nueva etiqueta',
                    icon: Icons.tag_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _addTag,
                  child: Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: C.primaryLo,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: C.primary.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: C.primary, size: 20),
                  ),
                ),
              ],
            ),
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _tags
                    .map((tag) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: C.primaryLo,
                            borderRadius: BorderRadius.circular(20),
                            border:
                                Border.all(color: C.primary.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(tag,
                                  style: const TextStyle(
                                      color: C.primary, fontSize: 11)),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => setState(() => _tags.remove(tag)),
                                child: const Icon(Icons.close_rounded,
                                    size: 12, color: C.primary),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ],

            const SizedBox(height: 20),
            SectionTitle('Notas'),
            SheetField(
              controller: _notesCtrl,
              hint: 'Observaciones...',
              icon: Icons.notes_rounded,
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            SheetSubmitButton(
              label: 'Guardar cambios',
              loading: _loading,
              onTap: _save,
            ),
          ],
        ),
      ),
    );
  }
}