import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [Locale('en'), Locale('fr')];

  // Common
  String get appName =>
      _localizedValues[locale.languageCode]?['app_name'] ?? 'Nalliq';
  String get yes => _localizedValues[locale.languageCode]?['yes'] ?? 'Yes';
  String get no => _localizedValues[locale.languageCode]?['no'] ?? 'No';
  String get cancel =>
      _localizedValues[locale.languageCode]?['cancel'] ?? 'Cancel';
  String get save => _localizedValues[locale.languageCode]?['save'] ?? 'Save';
  String get loading =>
      _localizedValues[locale.languageCode]?['loading'] ?? 'Loading...';
  String get error =>
      _localizedValues[locale.languageCode]?['error'] ?? 'Error';
  String get retry =>
      _localizedValues[locale.languageCode]?['retry'] ?? 'Retry';
  String get done => _localizedValues[locale.languageCode]?['done'] ?? 'Done';

  // Navigation
  String get home => _localizedValues[locale.languageCode]?['home'] ?? 'Home';
  String get profile =>
      _localizedValues[locale.languageCode]?['profile'] ?? 'Profile';
  String get settings =>
      _localizedValues[locale.languageCode]?['settings'] ?? 'Settings';
  String get cart => _localizedValues[locale.languageCode]?['cart'] ?? 'Cart';

  // Home screen
  String get appTitle =>
      _localizedValues[locale.languageCode]?['app_title'] ?? 'Nalliq';
  String get communityMap =>
      _localizedValues[locale.languageCode]?['community_map'] ??
      'Community Map';
  String get search =>
      _localizedValues[locale.languageCode]?['search'] ?? 'Search';
  String get welcomeMessage =>
      _localizedValues[locale.languageCode]?['welcome_message'] ??
      'Welcome to Nalliq!';
  String get discoverStores =>
      _localizedValues[locale.languageCode]?['discover_stores'] ??
      'Discover local stores and connect with your community';
  String get quickActions =>
      _localizedValues[locale.languageCode]?['quick_actions'] ??
      'Quick Actions';
  String get scanProduct =>
      _localizedValues[locale.languageCode]?['scan_product'] ?? 'Scan Product';
  String get findProductsNearby =>
      _localizedValues[locale.languageCode]?['find_products_nearby'] ??
      'Find products nearby';
  String get addStore =>
      _localizedValues[locale.languageCode]?['add_store'] ?? 'Add Store';
  String get createYourStore =>
      _localizedValues[locale.languageCode]?['create_your_store'] ??
      'Create your own store';
  String get communityStores =>
      _localizedValues[locale.languageCode]?['community_stores'] ??
      'Community Stores';
  String get friendsStores =>
      _localizedValues[locale.languageCode]?['friends_stores'] ??
      'Friends Stores';
  String get foodBankStores =>
      _localizedValues[locale.languageCode]?['food_bank_stores'] ??
      'Food Bank Stores';
  String get noStoresFound =>
      _localizedValues[locale.languageCode]?['no_stores_found'] ??
      'No stores found in this category yet.';
  String get errorLoadingData =>
      _localizedValues[locale.languageCode]?['error_loading_data'] ??
      'Error loading data';
  String get tryAgain =>
      _localizedValues[locale.languageCode]?['try_again'] ?? 'Try Again';

  // Settings
  String get account =>
      _localizedValues[locale.languageCode]?['account'] ?? 'Account';
  String get appearance =>
      _localizedValues[locale.languageCode]?['appearance'] ?? 'Appearance';
  String get notifications =>
      _localizedValues[locale.languageCode]?['notifications'] ??
      'Notifications';
  String get privacy =>
      _localizedValues[locale.languageCode]?['privacy'] ?? 'Privacy';
  String get location =>
      _localizedValues[locale.languageCode]?['location'] ?? 'Location';
  String get accessibility =>
      _localizedValues[locale.languageCode]?['accessibility'] ??
      'Accessibility';
  String get sound =>
      _localizedValues[locale.languageCode]?['sound'] ?? 'Sound';
  String get support =>
      _localizedValues[locale.languageCode]?['support'] ?? 'Support';
  String get about =>
      _localizedValues[locale.languageCode]?['about'] ?? 'About';
  String get logout =>
      _localizedValues[locale.languageCode]?['logout'] ?? 'Logout';

  // Account Settings
  String get editProfile =>
      _localizedValues[locale.languageCode]?['edit_profile'] ?? 'Edit Profile';
  String get identityVerification =>
      _localizedValues[locale.languageCode]?['identity_verification'] ??
      'Identity Verification';
  String get changePassword =>
      _localizedValues[locale.languageCode]?['change_password'] ??
      'Change Password';
  String get darkMode =>
      _localizedValues[locale.languageCode]?['dark_mode'] ?? 'Dark Mode';
  String get language =>
      _localizedValues[locale.languageCode]?['language'] ?? 'Language';

  // Notifications
  String get pushNotifications =>
      _localizedValues[locale.languageCode]?['push_notifications'] ??
      'Push Notifications';
  String get chatNotifications =>
      _localizedValues[locale.languageCode]?['chat_notifications'] ??
      'Chat Notifications';
  String get itemAlerts =>
      _localizedValues[locale.languageCode]?['item_alerts'] ?? 'Item Alerts';
  String get exchangeNotifications =>
      _localizedValues[locale.languageCode]?['exchange_notifications'] ??
      'Exchange Notifications';

  // Privacy
  String get showOnlineStatus =>
      _localizedValues[locale.languageCode]?['show_online_status'] ??
      'Show Online Status';
  String get profileVisibility =>
      _localizedValues[locale.languageCode]?['profile_visibility'] ??
      'Profile Visibility';
  String get shareLocation =>
      _localizedValues[locale.languageCode]?['share_location'] ??
      'Share Location';

  // Accessibility
  String get highContrast =>
      _localizedValues[locale.languageCode]?['high_contrast'] ??
      'High Contrast';
  String get largeText =>
      _localizedValues[locale.languageCode]?['large_text'] ?? 'Large Text';
  String get textScale =>
      _localizedValues[locale.languageCode]?['text_scale'] ?? 'Text Scale';
  String get screenReader =>
      _localizedValues[locale.languageCode]?['screen_reader'] ??
      'Screen Reader';
  String get reducedMotion =>
      _localizedValues[locale.languageCode]?['reduced_motion'] ??
      'Reduced Motion';

  // Requests
  String get incomingRequests =>
      _localizedValues[locale.languageCode]?['incoming_requests'] ??
      'Incoming Requests';
  String get outgoingRequests =>
      _localizedValues[locale.languageCode]?['outgoing_requests'] ??
      'Outgoing Requests';
  String get requestFrom =>
      _localizedValues[locale.languageCode]?['request_from'] ?? 'Request from';
  String get requestTo =>
      _localizedValues[locale.languageCode]?['request_to'] ?? 'Request to';
  String get requestedItems =>
      _localizedValues[locale.languageCode]?['requested_items'] ??
      'Requested Items';
  String get offeredItems =>
      _localizedValues[locale.languageCode]?['offered_items'] ??
      'Offered Items';
  String get message =>
      _localizedValues[locale.languageCode]?['message'] ?? 'Message';
  String get pending =>
      _localizedValues[locale.languageCode]?['pending'] ?? 'Pending';
  String get accepted =>
      _localizedValues[locale.languageCode]?['accepted'] ?? 'Accepted';
  String get declined =>
      _localizedValues[locale.languageCode]?['declined'] ?? 'Declined';
  String get completed =>
      _localizedValues[locale.languageCode]?['completed'] ?? 'Completed';
  String get cancelled =>
      _localizedValues[locale.languageCode]?['cancelled'] ?? 'Cancelled';

  // Password Change
  String get currentPassword =>
      _localizedValues[locale.languageCode]?['current_password'] ??
      'Current Password';
  String get newPassword =>
      _localizedValues[locale.languageCode]?['new_password'] ?? 'New Password';
  String get confirmPassword =>
      _localizedValues[locale.languageCode]?['confirm_password'] ??
      'Confirm Password';
  String get passwordsDoNotMatch =>
      _localizedValues[locale.languageCode]?['passwords_do_not_match'] ??
      'Passwords do not match';
  String get passwordTooShort =>
      _localizedValues[locale.languageCode]?['password_too_short'] ??
      'Password must be at least 6 characters';
  String get passwordChangedSuccessfully =>
      _localizedValues[locale.languageCode]?['password_changed_successfully'] ??
      'Password changed successfully';

  String get manageLocation =>
      _localizedValues[locale.languageCode]?['manage_location'] ??
      'Manage Location';

  String get helpAndSupport =>
      _localizedValues[locale.languageCode]?['help_and_support'] ??
      'Help & Support';

  String get aboutNalliq =>
      _localizedValues[locale.languageCode]?['about_nalliq'] ?? 'About Nalliq';

  String get termsAndConditions =>
      _localizedValues[locale.languageCode]?['terms_and_conditions'] ??
      'Terms and Conditions';

  String get highContrastMode =>
      _localizedValues[locale.languageCode]?['high_contrast_mode'] ??
      'High Contrast Mode';

  String get highContrastModeDescription =>
      _localizedValues[locale
          .languageCode]?['high_contrast_mode_description'] ??
      'Uses a higher contrast color scheme.';

  String get textSize =>
      _localizedValues[locale.languageCode]?['text_size'] ?? 'Text Size';

  String get reducedMotionDescription =>
      _localizedValues[locale.languageCode]?['reduced_motion_description'] ??
      'Reduces animations and motion effects.';

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_name': 'Nalliq',
      'yes': 'Yes',
      'no': 'No',
      'cancel': 'Cancel',
      'save': 'Save',
      'loading': 'Loading...',
      'error': 'Error',
      'retry': 'Retry',
      'done': 'Done',
      'home': 'Home',
      'profile': 'Profile',
      'settings': 'Settings',
      'cart': 'Cart',
      'app_title': 'Nalliq',
      'community_map': 'Community Map',
      'search': 'Search',
      'welcome_message': 'Welcome to Nalliq!',
      'discover_stores':
          'Discover local stores and connect with your community',
      'quick_actions': 'Quick Actions',
      'scan_product': 'Scan Product',
      'find_products_nearby': 'Find products nearby',
      'add_store': 'Add Store',
      'create_your_store': 'Create your own store',
      'community_stores': 'Community Stores',
      'friends_stores': 'Friends Stores',
      'food_bank_stores': 'Food Bank Stores',
      'no_stores_found': 'No stores found in this category yet.',
      'error_loading_data': 'Error loading data',
      'try_again': 'Try Again',
      'account': 'Account',
      'appearance': 'Appearance',
      'notifications': 'Notifications',
      'privacy': 'Privacy',
      'location': 'Location',
      'accessibility': 'Accessibility',
      'sound': 'Sound',
      'support': 'Support',
      'about': 'About',
      'logout': 'Logout',
      'edit_profile': 'Edit Profile',
      'identity_verification': 'Identity Verification',
      'change_password': 'Change Password',
      'dark_mode': 'Dark Mode',
      'language': 'Language',
      'push_notifications': 'Push Notifications',
      'chat_notifications': 'Chat Notifications',
      'item_alerts': 'Item Alerts',
      'exchange_notifications': 'Exchange Notifications',
      'show_online_status': 'Show Online Status',
      'profile_visibility': 'Profile Visibility',
      'share_location': 'Share Location',
      'high_contrast': 'High Contrast',
      'large_text': 'Large Text',
      'text_scale': 'Text Scale',
      'screen_reader': 'Screen Reader',
      'reduced_motion': 'Reduced Motion',
      'incoming_requests': 'Incoming Requests',
      'outgoing_requests': 'Outgoing Requests',
      'request_from': 'Request from',
      'request_to': 'Request to',
      'requested_items': 'Requested Items',
      'offered_items': 'Offered Items',
      'message': 'Message',
      'pending': 'Pending',
      'accepted': 'Accepted',
      'declined': 'Declined',
      'completed': 'Completed',
      'cancelled': 'Cancelled',
      'current_password': 'Current Password',
      'new_password': 'New Password',
      'confirm_password': 'Confirm Password',
      'passwords_do_not_match': 'Passwords do not match',
      'password_too_short': 'Password must be at least 6 characters',
      'password_changed_successfully': 'Password changed successfully',
      'help': 'Help',
      'terms_and_conditions': 'Terms and Conditions',
      'manage_location': 'Manage Location',
      'help_and_support': 'Help & Support',
      'about_nalliq': 'About Nalliq',
      'high_contrast_mode': 'High Contrast Mode',
      'high_contrast_mode_description': 'Uses a higher contrast color scheme.',
      'text_size': 'Text Size',
      'reduced_motion_description': 'Reduces animations and motion effects.',
    },
    'fr': {
      'app_name': 'Nalliq',
      'yes': 'Oui',
      'no': 'Non',
      'cancel': 'Annuler',
      'save': 'Enregistrer',
      'loading': 'Chargement...',
      'error': 'Erreur',
      'retry': 'Réessayer',
      'done': 'Terminé',
      'home': 'Accueil',
      'profile': 'Profil',
      'settings': 'Paramètres',
      'cart': 'Panier',
      'app_title': 'Nalliq',
      'community_map': 'Carte Communautaire',
      'search': 'Recherche',
      'welcome_message': 'Bienvenue sur Nalliq!',
      'discover_stores':
          'Découvrez les magasins locaux et connectez-vous avec votre communauté',
      'quick_actions': 'Actions Rapides',
      'scan_product': 'Scanner le produit',
      'find_products_nearby': 'Trouver des produits à proximité',
      'add_store': 'Ajouter un magasin',
      'create_your_store': 'Créez votre propre magasin',
      'community_stores': 'Magasins Communautaires',
      'friends_stores': 'Magasins d\'Amis',
      'food_bank_stores': 'Banques Alimentaires',
      'no_stores_found': 'Aucun magasin trouvé dans cette catégorie.',
      'error_loading_data': 'Erreur lors du chargement des données',
      'try_again': 'Réessayer',
      'account': 'Compte',
      'appearance': 'Apparence',
      'notifications': 'Notifications',
      'privacy': 'Confidentialité',
      'location': 'Localisation',
      'accessibility': 'Accessibilité',
      'sound': 'Son',
      'support': 'Support',
      'about': 'À propos',
      'logout': 'Déconnexion',
      'edit_profile': 'Modifier le profil',
      'identity_verification': 'Vérification d\'identité',
      'change_password': 'Changer le mot de passe',
      'dark_mode': 'Mode sombre',
      'language': 'Langue',
      'push_notifications': 'Notifications push',
      'chat_notifications': 'Notifications de chat',
      'item_alerts': 'Alertes d\'articles',
      'exchange_notifications': 'Notifications d\'échange',
      'show_online_status': 'Afficher le statut en ligne',
      'profile_visibility': 'Visibilité du profil',
      'share_location': 'Partager la localisation',
      'high_contrast': 'Contraste élevé',
      'large_text': 'Texte large',
      'text_scale': 'Échelle du texte',
      'screen_reader': 'Lecteur d\'écran',
      'reduced_motion': 'Mouvement réduit',
      'incoming_requests': 'Demandes reçues',
      'outgoing_requests': 'Demandes envoyées',
      'request_from': 'Demande de',
      'request_to': 'Demande à',
      'requested_items': 'Articles demandés',
      'offered_items': 'Articles offerts',
      'message': 'Message',
      'pending': 'En attente',
      'accepted': 'Accepté',
      'declined': 'Refusé',
      'completed': 'Terminé',
      'cancelled': 'Annulé',
      'current_password': 'Mot de passe actuel',
      'new_password': 'Nouveau mot de passe',
      'confirm_password': 'Confirmer le mot de passe',
      'passwords_do_not_match': 'Les mots de passe ne correspondent pas',
      'password_too_short':
          'Le mot de passe doit contenir au moins 6 caractères',
      'password_changed_successfully': 'Mot de passe modifié avec succès',
      'help': 'Aide',
      'terms_and_conditions': 'Termes et conditions',
      'manage_location': 'Gérer l\'emplacement',
      'help_and_support': 'Aide et support',
      'about_nalliq': 'À propos de Nalliq',
      'high_contrast_mode': 'Mode Contraste élevé',
      'high_contrast_mode_description':
          'Utilise un jeu de couleurs à contraste plus élevé.',
      'text_size': 'Taille du texte',
      'reduced_motion_description':
          'Réduit les animations et les effets de mouvement.',
    },
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'fr'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
