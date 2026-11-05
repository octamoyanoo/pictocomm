import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pictocomm/features/profiles/data/datasources/local_child_profile_data_source.dart';
import 'package:pictocomm/features/profiles/data/repositories/local_child_profile_repository.dart';
import 'package:pictocomm/features/profiles/domain/entities/child_profile.dart';
import 'package:pictocomm/core/theme/app_theme.dart';

void main() {
  test('repositorio local persiste un perfil creado (SharedPreferences real con mocks)', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    const repository = LocalChildProfileRepository(dataSource: LocalChildProfileDataSource());

    final created = await repository.createChild(
      ChildProfile(
        id: '',
        name: 'Nina',
        avatarColor: AppColors.avatarPalette.first,
      ),
    );

    final children = await repository.getChildren();

    expect(created.name, 'Nina');
    expect(children, hasLength(1));
    expect(children.first.name, 'Nina');
    expect(children.first.id, isNotEmpty);
  });
}
