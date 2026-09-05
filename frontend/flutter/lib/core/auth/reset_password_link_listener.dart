import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ResetPasswordLinkListener {
  ResetPasswordLinkListener._();
  static final ResetPasswordLinkListener instance = ResetPasswordLinkListener._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  final _listeners = <void Function(String)>[];
  String? _pendingAccessToken;
  bool _started = false;

  String? get pendingAccessToken => _pendingAccessToken;

  Future<void> init() async {
    if (_started) return;
    _started = true;
    if (kIsWeb) {
      _handleUri(Uri.base);
      return;
    }
    _sub = _appLinks.uriLinkStream.listen(_handleUri);
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) _handleUri(initialUri);
  }

  void listen(void Function(String accessToken) onAccessToken) {
    _listeners.add(onAccessToken);
    final token = _pendingAccessToken;
    if (token != null) {
      onAccessToken(token);
    }
  }

  void removeListener(void Function(String accessToken) listener) {
    _listeners.remove(listener);
  }

  void _handleUri(Uri uri) {
    final token = _extractAccessToken(uri);
    if (token == null) return;
    _pendingAccessToken = token;
    for (final listener in List.of(_listeners)) {
      listener(token);
    }
  }

  String? _extractAccessToken(Uri uri) {
    if (!kIsWeb && uri.scheme != 'biomarkai') return null;
    final fromQuery = uri.queryParameters['access_token'];
    if (fromQuery != null) return fromQuery;
    if (uri.fragment.isNotEmpty) {
      final fragmentParams = Uri.splitQueryString(uri.fragment);
      final token = fragmentParams['access_token'];
      if (token != null && token.isNotEmpty) return token;
    }
    final rawQuery = uri.query;
    if (rawQuery.isEmpty) return null;
    return Uri.splitQueryString(rawQuery)['access_token'];
  }

  Future<void> dispose() async => _sub?.cancel();
}
