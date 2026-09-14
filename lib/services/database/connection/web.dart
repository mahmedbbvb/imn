import 'package:drift/drift.dart';
import 'package:drift/web.dart';

DatabaseConnection connect() {
  return DatabaseConnection(
    WebDatabase('imn_web_db'),
  );
}
