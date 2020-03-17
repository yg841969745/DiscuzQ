import 'dart:convert';

import 'package:discuzq/utils/StringHelper.dart';
import 'package:discuzq/utils/authorizationHelper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:discuzq/models/appModel.dart';
import 'package:discuzq/router/routeBuilder.dart';
import 'package:discuzq/views/loginDelegate.dart';

class AuthHelper {
  /// pop login delegate
  static login({BuildContext context}) =>
      Navigator.of(context).push(DiscuzCupertinoPageRoute(
          fullscreenDialog: true,
          builder: (_) {
            return const LoginDelegate();
          }));

  /// requst login dialog and waiting for login result
  static Future<bool> requsetShouldLogin(
      {BuildContext context, AppModel model}) async {
    bool success = false;

    ///
    /// 如果已经登录了直接返回 true
    /// 不要再次弹出登录对话框
    ///
    if (model.user != null) {
      return Future.value(true);
    }

    final LoginDelegate authentication = LoginDelegate(
      onRequested: (bool val) {
        success = val;
      },
    );

    await showCupertinoModalPopup(
        context: context,
        builder: (_) {
          return authentication;
        });

    return Future.value(success);
  }

  /// 处理用户请求退出登录
  static Future<void> logout({@required AppModel model}) async {
    await AuthorizationHelper().clearAll();
    model.updateUser(null);
  }

  ///
  /// 从本地读取已存的用户信息
  /// 从本地获取，如果用户没有登录的情况下会为null， 但是无关紧要
  ///
  static Future<void> getUserFromLocal({@required AppModel model}) async {
    try {
      final dynamic user = await AuthorizationHelper().getUser();
      model.updateUser(jsonDecode(user));
    } catch (e) {
      print(e);
    }
  }

  ///
  /// Magic! let a dynamic data transform into app state
  /// Process login and register request
  ///
  static Future<void> processLoginByResponseData(dynamic response,
      {@required AppModel model}) async {
    ///
    /// 读取accessToken
    ///
    final String accessToken = response['data']['attributes']['access_token'];
    if (StringHelper.isEmpty(string: accessToken) == true) {
      return Future.value(false);
    }

    ///
    /// 读取refreshToken
    ///
    final String refreshToken = response['data']['attributes']['refresh_token'];
    if (StringHelper.isEmpty(string: accessToken) == true) {
      return Future.value(false);
    }

    ///
    /// 读取用户信息
    ///
    final List<dynamic> included = response['included'];
    final dynamic user =
        included.where((it) => it['type'] == "users").toList()[0];

    ///
    /// 存储accessToken
    /// 先清除，在保存，否则保存会失败
    /// 调用clear只会清除一个项目，这样会导致用户切换信息错误
    /// 所以要清除token 和用户信息存储，在回调处理中在进行更新用户信息的Process提示
    /// 我不想写update逻辑，就这样简单粗暴无bug多完美？
    ///
    await AuthorizationHelper()
        .clear(key: AuthorizationHelper.authorizationKey);
    await AuthorizationHelper().clear(key: AuthorizationHelper.userKey);
    await AuthorizationHelper().clear(key: AuthorizationHelper.refreshTokenKey);

    /// 保存token
    await AuthorizationHelper()
        .save(data: jsonEncode(user), key: AuthorizationHelper.userKey);
    await AuthorizationHelper()
        .save(data: accessToken, key: AuthorizationHelper.authorizationKey);
    await AuthorizationHelper()
        .save(data: refreshToken, key: AuthorizationHelper.refreshTokenKey);

    /// 更新用户状态
    model.updateUser(user);
  }
}
