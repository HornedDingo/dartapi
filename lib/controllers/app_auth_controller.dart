import 'dart:io';
import 'package:conduit/conduit.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';
import '../model/response.dart';
import '../model/user.dart';
import '../utils/app_utils.dart';

class AppAuthController extends ResourceController {
  AppAuthController(this.managedContext);

  final ManagedContext managedContext;

  @Operation.post()
  Future<Response> signIn(@Bind.body() User user) async {
    if (user.password == null || user.login == null) {
      return Response.badRequest(
        body: ModelResponse(
          message: 'Password and login required',
        ),
      );
    }
    try {
      final qFindUser = Query<User>(managedContext)
        ..where((element) => element.login).equalTo(user.login)
        ..returningProperties(
          (element) => [
            element.id,
            element.salt,
            element.hashPassword,
          ],
        );
      final findUser = await qFindUser.fetchOne();
      if (findUser == null) {
        throw QueryException.input(
          'Пользователь не найден',
          [],
        );
      }
      final requestHashPassword = generatePasswordHash(
        user.password ?? '',
        findUser.salt ?? '',
      );
      if (requestHashPassword == findUser.hashPassword) {
        _updateTokens(findUser.id ?? -1, managedContext);
        final newUser =
            await managedContext.fetchObjectWithID<User>(findUser.id);
        return Response.ok(
          ModelResponse(
            data: newUser!.backing.contents,
            message: 'Успешная авторизация',
          ),
        );
      } else {
        throw QueryException.input(
          'Неверный пароль',
          [],
        );
      }
    } on QueryException catch (e) {
      return Response.serverError(
        body: ModelResponse(
          message: e.message,
        ),
      );
    }
  }

  @Operation.put()
  Future<Response> signUp(@Bind.body() User user) async {
    if (user.password == null || user.login == null || user.email == null) {
      return Response.badRequest(
        body: ModelResponse(
          message: 'Поля password, login и email обязательны',
        ),
      );
    }
    final salt = generateRandomSalt();
    final hashPassword = generatePasswordHash(
      user.password!,
      salt,
    );
    try {
      late final int id;
      await managedContext.transaction(
        (transaction) async {
          final qCreateUser = Query<User>(transaction)
            ..values.login = user.login
            ..values.email = user.email
            ..values.salt = salt
            ..values.hashPassword = hashPassword;
          final createdUser = await qCreateUser.insert();
          id = createdUser.id!;
          _updateTokens(id, transaction);
        },
      );
      final userData = await managedContext.fetchObjectWithID<User>(id);
      return Response.ok(
        ModelResponse(
          data: userData!.backing.contents,
          message: 'Пользователь успешно зарегистрирован',
        ),
      );
    } on QueryException catch (e) {
      return Response.serverError(
        body: ModelResponse(message: e.message),
      );
    }
  }

  void _updateTokens(int id, ManagedContext transaction) async {
    final Map<String, String> tokens = _getTokens(id);
    final qUpdateTokens = Query<User>(transaction)
      ..where((element) => element.id).equalTo(id)
      ..values.accessToken = tokens['access']
      ..values.refreshToken = tokens['refresh'];
    await qUpdateTokens.updateOne();
  }

  Map<String, String> _getTokens(int id) {
    final key = Platform.environment['SECRET_KEY'] ?? 'SECRET_KEY';
    final accessClaimSet = JwtClaim(
      maxAge: const Duration(hours: 1),
      otherClaims: {'id': id},
    );
    final refreshClaimSet = JwtClaim(
      otherClaims: {'id': id},
    );
    final tokens = <String, String>{};
    tokens['access'] = issueJwtHS256(accessClaimSet, key);
    tokens['refresh'] = issueJwtHS256(refreshClaimSet, key);
    return tokens;
  }
}
