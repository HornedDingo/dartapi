import 'dart:async';
import 'dart:io';
import 'package:conduit/conduit.dart';
import '../model/history.dart';
import '../utils/app_response.dart';
import '../utils/app_utils.dart';

class AppHistoryController extends ResourceController {
  AppHistoryController(this.managedContext);

  final ManagedContext managedContext;

  @Operation.get()
  Future<Response> getHistory(
      @Bind.header(HttpHeaders.authorizationHeader) String header) async {
    try {
      final currentUserId = AppUtils.getIdFromHeader(header);
      final historyQuery = Query<History>(managedContext)
        ..where((history) => history.user!.id).equalTo(currentUserId);
      final histories = await historyQuery.fetch();
      List historiesJson = List.empty(growable: true);
      for (final history in histories) {
        history.removePropertiesFromBackingMap(
          ["user", "id"],
        );
        historiesJson.add(history.backing.contents);
      }
      if (historiesJson.isEmpty) {
        return AppResponse.ok(
          message: 'История не найдена',
        );
      }
      historiesJson = historiesJson.reversed.toList();
      return AppResponse.ok(
        body: historiesJson,
        message: "Успешное получение",
      );
    } catch (e) {
      return AppResponse.serverError(
        e,
        message: 'Ошибка получения',
      );
    }
  }
}
