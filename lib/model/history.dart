import 'package:api/model/user.dart';
import 'package:conduit/conduit.dart';

class History extends ManagedObject<_History> implements _History {}

class _History {
  @primaryKey
  int? id;
  @Column(nullable: false)
  String? message;
  @Relate(#historyList, isRequired: true, onDelete: DeleteRule.cascade)
  User? user;
  @Column(nullable: false)
  String? datetime;
}
