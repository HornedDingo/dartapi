import 'dart:io';
import 'package:conduit/conduit.dart';
import '../model/history.dart';
import '../model/note.dart';
import '../model/user.dart';
import '../utils/app_response.dart';
import '../utils/app_utils.dart';

class AppNoteController extends ResourceController {
  AppNoteController(this.managedContext);

  final ManagedContext managedContext;

  @Operation.post()
  Future<Response> createNote(
      @Bind.header(HttpHeaders.authorizationHeader) String header,
      @Bind.body() Note note) async {
    try {
      late final int noteId;
      final id = AppUtils.getIdFromHeader(header);
      final fUser = Query<User>(managedContext)
        ..where((user) => user.id).equalTo(id);
      final user = await fUser.fetchOne();
      await managedContext.transaction((transaction) async {
        final qCreateNote = Query<Note>(transaction)
          ..values.name = note.name
          ..values.text = note.text
          ..values.category = note.category
          ..values.dateTimeCreate = DateTime.now().toString()
          ..values.dateTimeEdit = DateTime.now().toString()
          ..values.user = user
          ..values.deleted = false;
        final createdNote = await qCreateNote.insert();
        noteId = createdNote.id!;
      });
      final noteData = await managedContext.fetchObjectWithID<Note>(noteId);
      noteData!.removePropertiesFromBackingMap(
        [
          "user",
          "status",
        ],
      );
      createHistory(
        id,
        "Заметка с номером ${noteData.id} добавлена",
      );
      return AppResponse.ok(
        body: noteData.backing.contents,
        message: 'Успешное добавление',
      );
    } catch (e) {
      return AppResponse.serverError(
        e,
        message: 'Ошибка добавления',
      );
    }
  }

  @Operation.put("id")
  Future<Response> updateNote(
      @Bind.header(HttpHeaders.authorizationHeader) String header,
      @Bind.path("id") int id,
      @Bind.body() Note note) async {
    try {
      final currentUserId = AppUtils.getIdFromHeader(header);
      final noteQuery = Query<Note>(managedContext)
        ..where((note) => note.user!.id).equalTo(currentUserId)
        ..where((note) => note.deleted).notEqualTo(true);
      final noteDB = await noteQuery.fetchOne();
      if (noteDB == null) {
        return AppResponse.ok(
          message: "Заметка не найдена",
        );
      }
      final qUpdateNote = Query<Note>(managedContext)
        ..where((note) => note.id).equalTo(noteDB.id)
        ..values.category = note.category
        ..values.name = note.name
        ..values.text = note.text
        ..values.dateTimeEdit = DateTime.now().toString()
        ..values.deleted = false;
      await qUpdateNote.update();
      createHistory(
        currentUserId,
        "Заметка с номером $id обновлена",
      );
      return AppResponse.ok(
        body: note.backing.contents,
        message: "Успешное обновление",
      );
    } catch (e) {
      return AppResponse.serverError(
        e,
        message: 'Ошибка получения',
      );
    }
  }

  @Operation.delete("id")
  Future<Response> deleteNote(
      @Bind.header(HttpHeaders.authorizationHeader) String header,
      @Bind.path("id") int id) async {
    try {
      final currentUserId = AppUtils.getIdFromHeader(header);
      final noteQuery = Query<Note>(managedContext)
        ..where((note) => note.id).equalTo(id)
        ..where((note) => note.user!.id).equalTo(currentUserId)
        ..where((note) => note.deleted).notEqualTo(true);
      final note = await noteQuery.fetchOne();
      if (note == null) {
        return AppResponse.ok(message: "Заметка не найдена");
      }
      final qLogicDeleteNote = Query<Note>(managedContext)
        ..where((note) => note.id).equalTo(id)
        ..values.deleted = true;
      await qLogicDeleteNote.update();
      createHistory(
        currentUserId,
        "Заметка с номером $id удалена",
      );
      return AppResponse.ok(
        message: 'Успешное удаление',
      );
    } catch (e) {
      return AppResponse.serverError(
        e,
        message: 'Ошибка удаления',
      );
    }
  }

  @Operation.get("id")
  Future<Response> getOneNote(
      @Bind.header(HttpHeaders.authorizationHeader) String header,
      @Bind.path("id") int id,
      {@Bind.query("restore") bool? restore}) async {
    try {
      final currentUserId = AppUtils.getIdFromHeader(header);
      final deletedNoteQuery = Query<Note>(managedContext)
        ..where((note) => note.id).equalTo(id)
        ..where((note) => note.user!.id).equalTo(currentUserId)
        ..where((note) => note.deleted).equalTo(true);
      final deletedNote = await deletedNoteQuery.fetchOne();
      String message = "Успешное получение";
      if (deletedNote != null && restore != null && restore) {
        deletedNoteQuery.values.deleted = false;
        deletedNoteQuery.update();
        message = "Успешное восстановление";
        createHistory(
          currentUserId,
          "Заметка с номером $id восстановлена",
        );
      }
      final noteQuery = Query<Note>(managedContext)
        ..where((note) => note.id).equalTo(id)
        ..where((note) => note.user!.id).equalTo(currentUserId)
        ..where((note) => note.deleted).notEqualTo(true);
      final note = await noteQuery.fetchOne();
      if (note == null) {
        return AppResponse.ok(
          message: "Заметка не найдена",
        );
      }
      note.removePropertiesFromBackingMap(
        [
          "user",
          "status",
        ],
      );
      return AppResponse.ok(
        body: note.backing.contents,
        message: message,
      );
    } catch (e) {
      return AppResponse.serverError(
        e,
        message: 'Ошибка получения',
      );
    }
  }

  @Operation.get()
  Future<Response> getNotes(
      @Bind.header(HttpHeaders.authorizationHeader) String header,
      {@Bind.query("search") String? search,
      @Bind.query("limit") int? limit,
      @Bind.query("offset") int? offset}) async {
    try {
      final id = AppUtils.getIdFromHeader(header);
      Query<Note>? notesQuery;
      if (search != null && search != "") {
        notesQuery = Query<Note>(managedContext)
          ..where((note) => note.name).contains(search)
          ..where((note) => note.user!.id).equalTo(id);
      } else {
        notesQuery = Query<Note>(managedContext)
          ..where((note) => note.user!.id).equalTo(id);
      }

      notesQuery.where((note) => note.deleted).equalTo(false);

      if (limit != null && limit > 0) {
        notesQuery.fetchLimit = limit;
      }
      if (offset != null && offset > 0) {
        notesQuery.offset = offset;
      }
      final notes = await notesQuery.fetch();
      List notesJson = List.empty(growable: true);
      for (final note in notes) {
        note.removePropertiesFromBackingMap(
          [
            "user",
            "status",
          ],
        );
        notesJson.add(note.backing.contents);
      }
      if (notesJson.isEmpty) {
        return AppResponse.ok(
          message: "Заметки не найдены",
        );
      }
      return AppResponse.ok(
        message: 'Успешное получение',
        body: notesJson,
      );
    } catch (e) {
      return AppResponse.serverError(
        e,
        message: 'Ошибка получения',
      );
    }
  }

  void createHistory(int userId, String message) async {
    final user = await managedContext.fetchObjectWithID<User>(userId);
    final createHistoryRowQuery = Query<History>(managedContext)
      ..values.datetime = DateTime.now().toString()
      ..values.user = user
      ..values.message = message;
    createHistoryRowQuery.insert();
  }
}
