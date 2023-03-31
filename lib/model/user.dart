import 'package:api/model/history.dart';
import 'package:conduit/conduit.dart';
import 'package:api/model/note.dart';

class User extends ManagedObject<_User> implements _User {}

class _User {
  @primaryKey
  int? id;
  @Column(unique: true, indexed: true)
  String? login;
  @Column(unique: true, indexed: true)
  String? email;
  @Serialize(input: true, output: false)
  String? password;
  @Column(nullable: true)
  String? accessToken;
  @Column(nullable: true)
  String? refreshToken;
  ManagedSet<Note>? noteList;
  ManagedSet<History>? historyList;
  @Column(omitByDefault: true)
  String? salt;
  @Column(omitByDefault: true)
  String? hashPassword;
}
