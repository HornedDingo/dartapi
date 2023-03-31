import 'package:api/model/user.dart';
import 'package:conduit/conduit.dart';

class Note extends ManagedObject<_Note> implements _Note {}

class _Note {
  @primaryKey
  int? id;
  @Column(nullable: false)
  String? name;
  @Column(nullable: false)
  String? text;
  @Column(nullable: false)
  String? category;
  @Column(nullable: false)
  String? dateTimeCreate;
  @Column(nullable: false)
  String? dateTimeEdit;
  @Column(nullable: false)
  bool? deleted;
  @Relate(#noteList, isRequired: true, onDelete: DeleteRule.cascade)
  User? user;
}
