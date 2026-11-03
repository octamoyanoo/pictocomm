import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
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
      builder: (_) => _PlaySequenceDialog(pictos: List.of(_sentence)),
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
        child: Text('Comunicar', style: Theme.of(context).textTheme.titleLarge),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        height: 108,
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Expanded(
              child: sentence.isEmpty
                  ? const Center(
                      child: Text(
                        'Toca pictogramas para armar tu frase',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.accent),
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
                _StripAction(icon: Icons.backspace_outlined, tooltip: 'Quitar último', onPressed: onRemoveLast),
                _StripAction(icon: Icons.delete_outline, tooltip: 'Limpiar frase', onPressed: onClear),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: sentence.isEmpty ? null : onPlay,
                  icon: const Icon(Icons.play_arrow, size: 22),
                  tooltip: 'Reproducir frase',
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
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Container(
            width: 76,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
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
        ),
        Positioned(
          top: 0,
          right: 0,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: AppColors.surface, size: 14),
            ),
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
              label: const Text('Todos'),
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
        'No hay pictogramas en esta categoría',
        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
      ),
    );
  }
}

final class _PlaySequenceDialog extends StatefulWidget {
  const _PlaySequenceDialog({required this.pictos});

  final List<Picto> pictos;

  @override
  State<_PlaySequenceDialog> createState() => _PlaySequenceDialogState();
}

final class _PlaySequenceDialogState extends State<_PlaySequenceDialog> {
  static const _stepDuration = Duration(seconds: 2);

  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_stepDuration, (_) {
      if (_index < widget.pictos.length - 1) {
        setState(() => _index += 1);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final picto = widget.pictos[_index];
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 320,
            child: PictoImage(picto: picto, fit: BoxFit.contain),
          ),
          Text(picto.label, style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
