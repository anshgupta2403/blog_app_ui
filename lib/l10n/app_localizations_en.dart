// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get welcome => 'Welcome to Blogify!';

  @override
  String get readBlogs => 'Read amazing blogs';

  @override
  String get writePublish => 'Write and publish your own';

  @override
  String get saveFavorites => 'Save your favorites';

  @override
  String get shareWorld => 'Share with the world';

  @override
  String get getStarted => 'Get started now!';

  @override
  String get next => 'Next';
}
