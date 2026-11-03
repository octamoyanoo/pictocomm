import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../domain/entities/picto.dart';
import '../providers/pictos_provider.dart';
import '../widgets/empty_catalog_view.dart';
import '../widgets/loading_catalog_view.dart';
import '../widgets/picto_card.dart';

final class PictogramasScreen extends StatefulWidget {
  const PictogramasScreen({super.key});

  @override
  State<PictogramasScreen> createState() => _PictogramasScreenState();
}

final class _PictogramasScreenState extends State<PictogramasScreen> {
  String _query = '';

  void _openPicto(Picto picto) {
    Navigator.of(context).pushNamed(AppRoutes.picto, arguments: picto);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PictosProvider>().state;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _PictogramasHeader(),
            Expanded(
              child: switch (state) {
                PictosLoadingState() => const LoadingCatalogView(),
                PictosLoadedState() when state.pictos.isEmpty => const EmptyCatalogView(),
                PictosLoadedState() => _PictogramasContent(state: state, query: _query, onQueryChanged: (value) => setState(() => _query = value.trim().toLowerCase()), onTapPicto: _openPicto),
                PictosFailureState() => const EmptyCatalogView(),
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }
}

final class _PictogramasHeader extends StatelessWidget {
  const _PictogramasHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text('Pictogramas', style: Theme.of(context).textTheme.titleLarge),
      ),
    );
  }
}

final class _PictogramasContent extends StatelessWidget {
  const _PictogramasContent({required this.state, required this.query, required this.onQueryChanged, required this.onTapPicto});

  final PictosLoadedState state;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<Picto> onTapPicto;

  @override
  Widget build(BuildContext context) {
    final allPictos = state.pictos;
    final pictos = query.isEmpty ? allPictos : allPictos.where((picto) => picto.label.toLowerCase().contains(query)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PictogramaSearchField(onQueryChanged),
        Expanded(
          child: pictos.isEmpty
              ? Center(
                  child: Text(
                    'Sin resultados para "$query"',
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                )
              : _PictoGrid(pictos: pictos, onTapPicto: onTapPicto),
        ),
      ],
    );
  }
}

final class _PictogramaSearchField extends StatelessWidget {
  const _PictogramaSearchField(this.onQueryChanged);

  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: TextField(
        onChanged: onQueryChanged,
        decoration: const InputDecoration(
          hintText: 'Buscar pictogramas...',
          prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
        ),
      ),
    );
  }
}

final class _PictoGrid extends StatelessWidget {
  const _PictoGrid({required this.pictos, required this.onTapPicto});

  final List<Picto> pictos;
  final ValueChanged<Picto> onTapPicto;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const cardWidth = 96.0;
        final columns = (constraints.maxWidth / cardWidth).floor().clamp(2, 5);
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.82,
          ),
          itemCount: pictos.length,
          itemBuilder: (context, index) {
            final picto = pictos[index];
            return PictoCard(picto: picto, onTap: () => onTapPicto(picto));
          },
        );
      },
    );
  }
}

