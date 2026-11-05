import 'dart:ui' show Color;

import 'package:flutter/foundation.dart' hide Category;

import '../../domain/entities/child_profile.dart';
import '../../domain/repositories/child_profile_repository.dart';

sealed class ChildrenState {
  const ChildrenState();
}

final class ChildrenLoadingState extends ChildrenState {
  const ChildrenLoadingState();
}

final class ChildrenLoadedState extends ChildrenState {
  const ChildrenLoadedState({required this.children});

  final List<ChildProfile> children;

  bool get isEmpty => children.isEmpty;
}

final class ChildrenFailureState extends ChildrenState {
  const ChildrenFailureState(this.message);

  final String message;
}

final class ChildrenProvider extends ChangeNotifier {
  ChildrenProvider({required this.childProfileRepository});

  final ChildProfileRepository childProfileRepository;

  ChildrenState _state = const ChildrenLoadingState();

  ChildrenState get state => _state;

  Future<void> load() async {
    _state = const ChildrenLoadingState();
    notifyListeners();
    try {
      final children = await childProfileRepository.getChildren();
      _state = ChildrenLoadedState(children: children);
    } on Object catch (error) {
      _state = ChildrenFailureState(error.toString());
    }
    notifyListeners();
  }

  Future<ChildProfile> createChild(String name, int? age, int? avatarColorValue, String? photoUrl) async {
    // El color viaja como ARGB int para no arrastrar dart:ui a las llamadas
    // de alto nivel; el repositorio decide cómo persistirlo.
    final created = await childProfileRepository.createChild(
      ChildProfile(
        id: '',
        name: name,
        age: age,
        avatarColor: avatarColorValue == null ? null : Color(avatarColorValue),
        photoUrl: photoUrl,
      ),
    );
    await load();
    return created;
  }

  Future<void> deleteChild(String id) async {
    await childProfileRepository.deleteChild(id);
    await load();
  }
}
