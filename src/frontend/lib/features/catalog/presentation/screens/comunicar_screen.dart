import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pictocomm/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../voice/domain/voice_provider.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/picto.dart';
import '../providers/pictos_provider.dart';
import '../widgets/loading_catalog_view.dart';
import '../widgets/picto_card.dart';
import '../widgets/picto_image.dart';

final class ComunicarScreen extends StatefulWidget {
  const ComunicarScreen({super.key});

  @override
  State<ComunicarScreen> createState() => _ComunicarScreenState();
}

final class _ComunicarScreenState extends State<ComunicarScreen> {
  final List<Picto> _sentence = [];
  String? _categoryId;

  void _addPicto(Picto picto) => setState(() => _sentence.add(picto));

  void _removeAt(int index) => setState(() => _sentence.removeAt(index));

  void _removeLast() {
    setState(() {
      if (_sentence.isNotEmpty) {
        _sentence.removeLast();
      }
    });
  }

  void _clearSentence() => setState(() => _sentence.clear());

  void _showPlaySequence() {
    if (_sentence.isEmpty) {
      return;
    }
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _PlaySequenceDialog(
        pictos: List.of(_sentence),
        voiceProvider: context.read<VoiceProvider>(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PictosProvider>().state;
    return Scaffold(
      body: SafeArea(
        child: switch (state) {
          PictosLoadingState() || PictosFailureState() => const LoadingCatalogView(),
          PictosLoadedState() => _ComunicarContent(
              state: state,
              sentence: _sentence,
              categoryId: _categoryId,
              onCategorySelected: (value) => setState(() => _categoryId = value),
              onPictoTapped: _addPicto,
              onRemoveAt: _removeAt,
              onRemoveLast: _removeLast,
              onClear: _clearSentence,
              onPlay: _showPlaySequence,
            ),
        },
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }
}

final class _ComunicarContent extends StatelessWidget {
  const _ComunicarContent({
    required this.state,
    required this.sentence,
    required this.categoryId,
    required this.onCategorySelected,
    required this.onPictoTapped,
    required this.onRemoveAt,
    required this.onRemoveLast,
    required this.onClear,
    required this.onPlay,
  });

  final PictosLoadedState state;
  final List<Picto> sentence;
  final String? categoryId;
  final ValueChanged<String?> onCategorySelected;
  final ValueChanged<Picto> onPictoTapped;
  final ValueChanged<int> onRemoveAt;
  final VoidCallback onRemoveLast;
  final VoidCallback onClear;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final pictos = categoryId == null ? state.pictos : state.pictosOf(categoryId!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _ComunicarHeader(),
        _SentenceStrip(
          sentence: sentence,
          onRemoveAt: onRemoveAt,
          onRemoveLast: onRemoveLast,
          onClear: onClear,
          onPlay: onPlay,
        ),
        _CategoryChips(
          categories: state.categories,
          selectedId: categoryId,
          onSelected: onCategorySelected,
        ),
        Expanded(
          child: pictos.isEmpty
              ? const EmptyCategoryHint()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    const cardWidth = 88.0;
                    final columns = (constraints.maxWidth / cardWidth).floor().clamp(2, 6);
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.78,
                      ),
                      itemCount: pictos.length,
                      itemBuilder: (context, index) {
                        final picto = pictos[index];
                        return PictoCard(picto: picto, onTap: () => onPictoTapped(picto));
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

final class _ComunicarHeader extends StatelessWidget {
  const _ComunicarHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(AppLocalizations.of(context)!.comunicarTitle, style: Theme.of(context).textTheme.titleLarge),
      ),
    );
  }
}

final class _SentenceStrip extends StatelessWidget {
  const _SentenceStrip({required this.sentence, required this.onRemoveAt, required this.onRemoveLast, required this.onClear, required this.onPlay});

  final List<Picto> sentence;
  final ValueChanged<int> onRemoveAt;
  final VoidCallback onRemoveLast;
  final VoidCallback onClear;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        height: 160,
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Expanded(
              child: sentence.isEmpty
                  ? Center(
                      child: Text(
                        l10n.sentenceStripEmpty,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.accent),
                      ),
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: sentence.length,
                      separatorBuilder: (_, index) => const Icon(Icons.chevron_right, color: AppColors.accent, size: 18),
                      itemBuilder: (context, index) {
                        return _SentenceChip(
                          picto: sentence[index],
                          onRemove: () => onRemoveAt(index),
                        );
                      },
                    ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _StripAction(icon: Icons.backspace_outlined, tooltip: l10n.removeLastTooltip, onPressed: onRemoveLast),
                _StripAction(icon: Icons.delete_outline, tooltip: l10n.clearSentenceTooltip, onPressed: onClear),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: sentence.isEmpty ? null : onPlay,
                  icon: const Icon(Icons.play_arrow, size: 22),
                  tooltip: l10n.playTooltip,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.surface,
                    disabledBackgroundColor: AppColors.textMuted.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final class _StripAction extends StatelessWidget {
  const _StripAction({required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      color: AppColors.accent,
    );
  }
}

final class _SentenceChip extends StatelessWidget {
  const _SentenceChip({required this.picto, required this.onRemove});

  final Picto picto;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 76,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              SizedBox(
                height: 40,
                child: PictoImage(picto: picto),
              ),
              Text(
                picto.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        // Mini-basura de cada picto (RF1.9): quitar uno por uno sin borrar
        // el resto de la frase.
        GestureDetector(
          onTap: onRemove,
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
          ),
        ),
      ],
    );
  }
}

final class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.categories, required this.selectedId, required this.onSelected});

  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(AppLocalizations.of(context)!.allCategoriesChip),
              selected: selectedId == null,
              onSelected: (_) => onSelected(null),
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selectedId == null ? AppColors.accent : AppColors.textSecondary,
              ),
              selectedColor: AppColors.accentLight,
              showCheckmark: false,
            ),
          ),
          for (final category in categories)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(category.name),
                selected: selectedId == category.id,
                onSelected: (_) => onSelected(category.id),
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selectedId == category.id ? AppColors.accent : AppColors.textSecondary,
                ),
                selectedColor: AppColors.accentLight,
                showCheckmark: false,
              ),
            ),
        ],
      ),
    );
  }
}

final class EmptyCategoryHint extends StatelessWidget {
  const EmptyCategoryHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        AppLocalizations.of(context)!.emptyCategoryHint,
        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
      ),
    );
  }
}

/// Reproduce la frase palabra por palabra (RF1.5–1.7): avanza al siguiente
/// picto recién cuando el TTS terminó de sonar la palabra actual, y resalta
/// el picto activo mientras suena (señal imagen-palabra para el niño).
///
/// Cerrar el diálogo detiene la voz de inmediato (RF1: nunca deja la voz
/// sonando fuera de control).
final class _PlaySequenceDialog extends StatefulWidget {
  const _PlaySequenceDialog({required this.pictos, required this.voiceProvider});

  final List<Picto> pictos;
  final VoiceProvider voiceProvider;

  @override
  State<_PlaySequenceDialog> createState() => _PlaySequenceDialogState();
}

final class _PlaySequenceDialogState extends State<_PlaySequenceDialog> {
  static const double _chipExtent = 92.0;

  int _index = 0;
  bool _voiceFailed = false;
  bool _cancelled = false;
  late final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    unawaited(_play());
  }

  Future<void> _play() async {
    for (var i = 0; i < widget.pictos.length; i++) {
      if (_cancelled || !mounted) {
        return;
      }
      setState(() => _index = i);
      _scrollTo(i);
      try {
        // Timeout de seguridad: si el engine de voz no dispara fin de locución
        // (falla silenciosa del sistema), la frase sigue avanzando igual.
        await widget.voiceProvider.speak(widget.pictos[i].label).timeout(const Duration(seconds: 6));
      } on VoiceException {
        if (mounted) {
          setState(() => _voiceFailed = true);
        }
      } on TimeoutException {
        if (mounted) {
          setState(() => _voiceFailed = true);
        }
      }
    }
  }

  void _scrollTo(int index) {
    if (!_scrollController.hasClients) {
      return;
    }
    final maxScroll = _scrollController.position.maxScrollExtent;
    final target = (index * _chipExtent).clamp(0.0, maxScroll);
    unawaited(_scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    // Garantía RF1: la voz nunca queda activa fuera del Play (se cierra por
    // botón X, por toque fuera del diálogo o por el sistema).
    unawaited(widget.voiceProvider.stop());
    _cancelled = true;
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final picto = widget.pictos[_index];
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 340,
            child: PictoImage(picto: picto, fit: BoxFit.contain),
          ),
          const SizedBox(height: 8),
          Text(
            picto.label,
            style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.w700),
          ),
          if (_voiceFailed) ...[
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.voiceUnavailable,
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ],
          const SizedBox(height: 16),
          // Tira de frase con destaque karaoke (pregunta abierta #1 de RF1).
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.pictos.length,
              controller: _scrollController,
              separatorBuilder: (_, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final active = index == _index;
                return _PlayChip(picto: widget.pictos[index], active: active);
              },
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 28),
            tooltip: AppLocalizations.of(context)!.close,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}

final class _PlayChip extends StatelessWidget {
  const _PlayChip({required this.picto, required this.active});

  final Picto picto;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: active ? 1.12 : 1.0,
      duration: const Duration(milliseconds: 150),
      child: Container(
        width: 84,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: active ? 1.0 : 0.75),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? AppColors.accent : Colors.white38,
            width: active ? 3 : 1,
          ),
        ),
        child: Column(
          children: [
            Expanded(child: PictoImage(picto: picto)),
            Text(
              picto.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
