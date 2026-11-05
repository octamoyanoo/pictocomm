// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get navInicio => 'Início';

  @override
  String get navPictogramas => 'Pictogramas';

  @override
  String get navComunicar => 'Comunicar';

  @override
  String get navPerfil => 'Perfil';

  @override
  String get routeNotFound => 'Rota não encontrada';

  @override
  String get loginTagline => 'Comunicação visual para todos';

  @override
  String get emailLabel => 'E-mail';

  @override
  String get emailHint => 'voce@email.com';

  @override
  String get emailRequired => 'Digite seu e-mail';

  @override
  String get emailInvalid => 'Este e-mail não é válido';

  @override
  String get passwordLabel => 'Senha';

  @override
  String get passwordHint => '••••••••';

  @override
  String get passwordRequired => 'Digite sua senha';

  @override
  String get loginButton => 'Entrar';

  @override
  String get noAccount => 'Não tem conta? ';

  @override
  String get registerLink => 'Cadastre-se aqui';

  @override
  String get nameLabel => 'Nome';

  @override
  String get nameExampleHint => 'Seu nome';

  @override
  String get nameRequired => 'Digite seu nome';

  @override
  String get passwordTooShort => 'Deve ter pelo menos 8 caracteres';

  @override
  String get confirmPasswordLabel => 'Confirmar senha';

  @override
  String get passwordsMismatch => 'As senhas não coincidem';

  @override
  String get createAccountButton => 'Criar Conta';

  @override
  String get signupTagline => 'Crie sua conta para começar';

  @override
  String get haveAccount => 'Já tem uma conta? ';

  @override
  String get loginLinkHere => 'Entrar';

  @override
  String get hola => 'Olá 👋';

  @override
  String holaName(String name) {
    return 'Olá, $name 👋';
  }

  @override
  String get changeChildTooltip => 'Trocar de criança';

  @override
  String get addMenuTooltip => 'Adicionar catálogo ou pictograma';

  @override
  String get newCatalog => 'Novo catálogo';

  @override
  String get newCatalogSub => 'Criar uma categoria';

  @override
  String get newPicto => 'Novo pictograma';

  @override
  String get newPictoSub => 'Adicionar uma imagem a uma categoria';

  @override
  String noResults(String query) {
    return 'Sem resultados para \"$query\"';
  }

  @override
  String get searchHint => 'Buscar pictogramas...';

  @override
  String get myCatalogs => 'Meus Catálogos';

  @override
  String get verTodos => 'Ver todos';

  @override
  String pictogramaCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pictogramas',
      one: '1 pictograma',
    );
    return '$_temp0';
  }

  @override
  String get pictogramasTitle => 'Pictogramas';

  @override
  String get comunicarTitle => 'Comunicar';

  @override
  String get sentenceStripEmpty =>
      'Toque nos pictogramas para montar sua frase';

  @override
  String get removeLastTooltip => 'Remover o último';

  @override
  String get clearSentenceTooltip => 'Limpar frase';

  @override
  String get playTooltip => 'Reproduzir frase';

  @override
  String get allCategoriesChip => 'Todos';

  @override
  String get emptyCategoryHint => 'Não há pictogramas nesta categoria';

  @override
  String get voiceUnavailable => 'Voz não disponível neste dispositivo';

  @override
  String get close => 'Fechar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get next => 'Continuar';

  @override
  String get keep => 'Manter';

  @override
  String get deleteForever => 'Excluir definitivamente';

  @override
  String get confirmDeleteTitle => 'Confirmar a exclusão?';

  @override
  String get deleteIrreversible => 'Esta ação não pode ser desfeita.';

  @override
  String deleteCategoryTitle(String name) {
    return 'Excluir \"$name\"?';
  }

  @override
  String deleteCategoryContent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'O catálogo e seu conteúdo serão excluídos ($count pictogramas desta criança).',
      one: 'O catálogo e seu conteúdo serão excluídos (1 pictograma desta criança).',
    );
    return '$_temp0';
  }

  @override
  String get deleteCatalogTooltip => 'Excluir catálogo';

  @override
  String get categoryEmpty => 'Ainda não há pictogramas nesta categoria';

  @override
  String deletePictoTitle(String name) {
    return 'Excluir \"$name\"?';
  }

  @override
  String get deletePictoContent =>
      'O pictograma será excluído do dispositivo desta criança.';

  @override
  String get deletePictoButton => 'Excluir pictograma';

  @override
  String get addPictoTitle => 'Novo pictograma';

  @override
  String get imageLoadError => 'Não foi possível carregar a imagem';

  @override
  String get urlDownloadError =>
      'Não foi possível baixar a imagem (o site pode bloquear). Salve-a no dispositivo e escolha pela galeria.';

  @override
  String get selectChildFirst =>
      'Escolha primeiro uma criança em \"Trocar de criança\" (RF3.4)';

  @override
  String get nameFieldRequired => 'Digite um nome';

  @override
  String get imageRequired => 'Escolha uma imagem';

  @override
  String get categoryRequired => 'Escolha uma categoria';

  @override
  String get saveError => 'Não foi possível salvar. Tente novamente.';

  @override
  String get nameFieldLabel => 'Nome';

  @override
  String get nameFieldHint => 'Ex: Água';

  @override
  String get firstCatalogWarning =>
      'Primeiro crie um catálogo para poder salvar pictogramas';

  @override
  String get categoryFieldLabel => 'Categoria';

  @override
  String get savePictoButton => 'Salvar pictograma';

  @override
  String get tapToPickImage => 'Toque para escolher uma imagem';

  @override
  String get webImageTitle => 'Imagem da web';

  @override
  String get webImageContent =>
      'No Google Imagens: mantenha pressionada a imagem → \"Copiar endereço da imagem\" e cole aqui.';

  @override
  String get urlInputHint => 'https://...';

  @override
  String get download => 'Baixar';

  @override
  String get gallery => 'Galeria';

  @override
  String get camera => 'Câmera';

  @override
  String get cameraUnavailable => 'Não disponível no navegador';

  @override
  String get pasteImageUrl => 'Colar URL da imagem';

  @override
  String get pasteUrlSub => 'Ex: uma imagem do Google Imagens';

  @override
  String get addCategoryTitle => 'Novo catálogo';

  @override
  String get categoryNameLabel => 'Nome da categoria';

  @override
  String get categoryNameHint => 'Ex: Bebidas';

  @override
  String get colorLabel => 'Cor';

  @override
  String get saveCategoryButton => 'Salvar catálogo';

  @override
  String get duplicateCategory => 'Já existe uma categoria com esse nome';

  @override
  String get profileTitle => 'Perfil';

  @override
  String get childrenSection => 'Crianças';

  @override
  String get addChildTooltip => 'Adicionar criança';

  @override
  String get noChildrenYet => 'Ainda não há crianças cadastradas';

  @override
  String get accountSection => 'Minha conta';

  @override
  String get signOut => 'Encerrar sessão';

  @override
  String get deleteProfileTooltip => 'Excluir perfil';

  @override
  String profilesLoadError(String message) {
    return 'Não foi possível ler os perfis: $message';
  }

  @override
  String selectorLoadError(String message) {
    return 'Não foi possível carregar os perfis: $message';
  }

  @override
  String get selectorTitle => 'Quem vai se comunicar hoje?';

  @override
  String get selectorSubtitle => 'Toque na sua foto para começar';

  @override
  String get selectorEmptyTitle => 'Ainda não há perfis de criança';

  @override
  String get selectorEmptySubtitle => 'Crie o primeiro para começar';

  @override
  String get createProfile => 'Criar perfil';

  @override
  String get addChildDialog => 'Adicionar criança';

  @override
  String get addChildAction => 'Adicionar';

  @override
  String deleteChildTitle(String name) {
    return 'Excluir $name?';
  }

  @override
  String get deleteChildContent =>
      'O perfil da criança será excluído do dispositivo, junto com sua configuração.';

  @override
  String deleteChildFinalContent(String name) {
    return '\"$name\" será excluído definitivamente. Esta ação não pode ser desfeita.';
  }

  @override
  String get emptyCatalogTitle => 'Ainda não há pictogramas';

  @override
  String get emptyCatalogSubtitle =>
      'Quando você adicionar imagens, elas aparecerão aqui';

  @override
  String get languageSection => 'Idioma';
}
