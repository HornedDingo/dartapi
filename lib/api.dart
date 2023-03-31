import 'dart:io';

import 'package:api/controllers/app_history_controller.dart';
import 'package:api/controllers/app_note_controller.dart';
import 'package:conduit/conduit.dart';
import 'package:api/controllers/app_auth_controller.dart';
import 'package:api/controllers/app_token_controller.dart';
import 'package:api/controllers/app_user_controller.dart';

class AppService extends ApplicationChannel {
  late final ManagedContext managedContext;

  @override
  Future prepare() {
    final persistentStore = _initDatabase();
    managedContext = ManagedContext(
      ManagedDataModel.fromCurrentMirrorSystem(),
      persistentStore,
    );
    return super.prepare();
  }

  @override
  Controller get entryPoint => Router()
    ..route('token/[:refresh]').link(
      () => AppAuthController(managedContext),
    )
    ..route('user').link(AppTokenController.new)!.link(
          () => AppUserController(managedContext),
        )
    ..route('note/[:id]').link(AppTokenController.new)!.link(
          () => AppNoteController(managedContext),
        )
    ..route('history').link(AppTokenController.new)!.link(
          () => AppHistoryController(managedContext),
        );

  PersistentStore _initDatabase() {
    final config = AppConfiguration.fromFile(
      File(options!.configurationFilePath!),
    );
    final db = config.database;
    final username = db.username;
    final password = db.password;
    final host = db.host;
    final port = db.port;
    final databaseName = db.databaseName;
    return PostgreSQLPersistentStore(
      username,
      password,
      host,
      port,
      databaseName,
    );
  }
}

class AppConfiguration extends Configuration {
  AppConfiguration.fromFile(File file) : super.fromFile(file);
  late DatabaseConfiguration database;
}
