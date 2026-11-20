import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rivalfit/app/theme/app_colors.dart';
import 'package:rivalfit/app/widgets/app_card.dart';

import '../../domain/models/saved_training_session.dart';
import '../../domain/models/training_session.dart';
import '../controllers/training_storage_providers.dart';

/// Recovery stays in Entrenar so pending sessions remain accessible after
/// navigation, logout/login and process restarts with the same account.
class SavedTrainingSessionsCard extends ConsumerStatefulWidget {
  const SavedTrainingSessionsCard({super.key});

  @override
  ConsumerState<SavedTrainingSessionsCard> createState() =>
      _SavedTrainingSessionsCardState();
}

class _SavedTrainingSessionsCardState
    extends ConsumerState<SavedTrainingSessionsCard>
    with WidgetsBindingObserver {
  bool _busy = false;
  bool _showAll = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_sync());
  }

  Future<void> _sync({bool force = false}) async {
    try {
      final repository = await ref.read(
        trainingSessionRepositoryProvider.future,
      );
      await repository?.sync(force: force);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'No se pudieron sincronizar tus sesiones. Inténtalo más tarde.',
        );
      }
    }
  }

  Future<void> _recover(
    SavedTrainingSession record, {
    required bool discard,
  }) async {
    if (_busy) return;
    if (discard) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('¿Descartar esta sesión?'),
          content: const Text(
            'Se eliminará el resultado interrumpido de este teléfono.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Descartar'),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repository = await ref.read(
        trainingSessionRepositoryProvider.future,
      );
      if (repository == null) throw StateError('No session account');
      if (discard) {
        await repository.discardDraft(record.result.sessionId);
      } else {
        await repository.complete(record.result);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'No se pudo guardar el cambio. El resultado sigue disponible.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(savedTrainingSessionsProvider);
    return state.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('No se pudieron recuperar tus sesiones guardadas.'),
            TextButton(
              onPressed: () {
                ref.invalidate(savedTrainingSessionsProvider);
                ref.invalidate(trainingSessionRepositoryProvider);
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
      data: (records) {
        if (records.isEmpty) return const SizedBox.shrink();
        final needsAttention = records
            .where((r) => r.state != SavedSessionState.confirmed)
            .toList();
        if (needsAttention.isEmpty && _error == null) {
          final latest = records.first;
          return AppCard(
            showShadow: false,
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.success,
                  semanticLabel: 'Sincronizada',
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Última sesión',
                        style: TextStyle(
                          color: AppColors.grayMain,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _sessionLabel(latest),
                        style: const TextStyle(
                          color: AppColors.carbon,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        _date(latest),
                        style: const TextStyle(
                          color: AppColors.grayMain,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        final visible = needsAttention
            .take(_showAll ? needsAttention.length : 3)
            .toList();
        final repository = ref
            .watch(trainingSessionRepositoryProvider)
            .valueOrNull;
        return Container(
          margin: const EdgeInsets.only(bottom: 18),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.subtleBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tus sesiones',
                style: TextStyle(
                  color: AppColors.carbon,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              for (final record in visible) ...[
                const SizedBox(height: 14),
                Text(
                  _sessionLabel(record),
                  style: const TextStyle(
                    color: AppColors.carbon,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _status(record),
                  style: const TextStyle(color: AppColors.grayMain),
                ),
                Text(
                  _date(record),
                  style: const TextStyle(
                    color: AppColors.grayMain,
                    fontSize: 12,
                  ),
                ),
                if (record.state == SavedSessionState.draft)
                  Wrap(
                    spacing: 8,
                    children: [
                      if (record.result.validReps > 0)
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => _recover(record, discard: false),
                          child: const Text('Guardar resultado'),
                        ),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => _recover(record, discard: true),
                        child: const Text('Descartar'),
                      ),
                    ],
                  ),
              ],
              if (repository?.remote.enabled == true &&
                  records.any((r) => r.state == SavedSessionState.pending))
                TextButton(
                  onPressed: repository!.syncing
                      ? null
                      : () => _sync(force: true),
                  child: Text(
                    repository.syncing
                        ? 'Sincronizando…'
                        : 'Reintentar sincronización',
                  ),
                ),
              if (needsAttention.length > 3)
                TextButton(
                  onPressed: () => setState(() => _showAll = !_showAll),
                  child: Text(
                    _showAll
                        ? 'Mostrar menos'
                        : 'Ver las ${needsAttention.length} sesiones',
                  ),
                ),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],
          ),
        );
      },
    );
  }

  String _sessionLabel(SavedTrainingSession record) {
    final reps = record.result.validReps;
    final name =
        TrainingMovement.forId(record.result.exerciseId)?.label ??
        record.result.exerciseId;
    return '$name · $reps ${reps == 1 ? 'repetición' : 'repeticiones'}';
  }

  String _status(SavedTrainingSession record) => switch (record.state) {
    SavedSessionState.draft =>
      'Sesión interrumpida · Recupera el último resultado guardado',
    SavedSessionState.pending =>
      'Guardada en este teléfono · Pendiente de sincronizar',
    SavedSessionState.confirmed => 'Sincronizada',
    SavedSessionState.rejected =>
      record.error ?? 'Guardada en este teléfono · No aceptada por el servidor',
  };

  String _date(SavedTrainingSession record) {
    final date = record.result.startedAtUtc.toLocal();
    return '${date.day}/${date.month}/${date.year} · '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
