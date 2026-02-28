/// 文件用途：数据传输服务（F12）——通过本地 HttpServer 提供配对与同步交换接口，并支持向对端发起请求。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'sync_models.dart';

typedef PairRequestHandler =
    Future<PairRequestResponse> Function(
      PairRequest request,
      InternetAddress peer,
    );
typedef PairConfirmHandler =
    Future<PairConfirmResponse> Function(
      PairConfirmRequest request,
      InternetAddress peer,
    );
typedef TokenValidator =
    Future<bool> Function(String fromDeviceId, String token);
typedef SyncExchangeHandler =
    Future<SyncExchangeResponse> Function(
      SyncExchangeRequest request,
      InternetAddress peer,
    );

/// 传输服务：同时扮演服务端（接收）与客户端（发送）。
class TransferService {
  static const int transferPort = 19877;

  TransferService();

  HttpServer? _server;

  PairRequestHandler? onPairRequest;
  PairConfirmHandler? onPairConfirm;
  TokenValidator? validateToken;
  SyncExchangeHandler? onSyncExchange;

  /// 启动本地服务端。
  Future<void> startServer() async {
    if (_server != null) return;

    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, transferPort);
      _server!.listen(_handleRequest);
    } catch (e) {
      // 端口被占用/权限不足时不应导致应用崩溃，降级为“仅客户端发起”能力。
      debugPrint('TransferService startServer failed: $e');
      _server = null;
    }
  }

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      final path = request.uri.path;
      final method = request.method.toUpperCase();

      if (method == 'GET' && path == '/ping') {
        await _writeJson(request.response, {'status': 'ok'});
        return;
      }

      if (method == 'POST' && path == '/pair/request') {
        final handler = onPairRequest;
        if (handler == null) {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
          return;
        }

        final body = await utf8.decoder.bind(request).join();
        final json = SyncJsonCodec.decodeObject(body);
        final result = await handler(
          PairRequest.fromJson(json),
          request.connectionInfo?.remoteAddress ?? InternetAddress.loopbackIPv4,
        );
        await _writeJson(request.response, result.toJson());
        return;
      }

      if (method == 'POST' && path == '/pair/confirm') {
        final handler = onPairConfirm;
        if (handler == null) {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
          return;
        }

        final body = await utf8.decoder.bind(request).join();
        final json = SyncJsonCodec.decodeObject(body);
        final result = await handler(
          PairConfirmRequest.fromJson(json),
          request.connectionInfo?.remoteAddress ?? InternetAddress.loopbackIPv4,
        );
        await _writeJson(request.response, result.toJson());
        return;
      }

      if (method == 'POST' && path == '/sync/exchange') {
        final handler = onSyncExchange;
        final validator = validateToken;
        if (handler == null || validator == null) {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
          return;
        }

        final token = _extractBearerToken(
          request.headers.value('authorization'),
        );
        if (token == null) {
          request.response.statusCode = HttpStatus.unauthorized;
          await _writeJson(request.response, {'error': 'missing_token'});
          return;
        }

        final body = await utf8.decoder.bind(request).join();
        final json = SyncJsonCodec.decodeObject(body);
        final req = SyncExchangeRequest.fromJson(json);
        final ok = await validator(req.fromDeviceId, token);
        if (!ok) {
          request.response.statusCode = HttpStatus.unauthorized;
          await _writeJson(request.response, {'error': 'invalid_token'});
          return;
        }

        final resp = await handler(
          req,
          request.connectionInfo?.remoteAddress ?? InternetAddress.loopbackIPv4,
        );
        await _writeJson(request.response, resp.toJson());
        return;
      }

      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
    } catch (e) {
      debugPrint('TransferService request failed: $e');
      try {
        request.response.statusCode = HttpStatus.internalServerError;
        await _writeJson(request.response, {'error': 'internal_error'});
      } catch (_) {
        // 忽略二次异常。
      }
    }
  }

  /// 发送同步交换请求到对端。
  Future<SyncExchangeResponse> exchange({
    required String ipAddress,
    required String token,
    required SyncExchangeRequest request,
  }) async {
    final client = HttpClient();
    try {
      final url = Uri.parse('http://$ipAddress:$transferPort/sync/exchange');
      final httpReq = await client.postUrl(url);
      httpReq.headers.contentType = ContentType.json;
      httpReq.headers.set('authorization', 'Bearer $token');
      httpReq.write(jsonEncode(request.toJson()));

      final httpResp = await httpReq.close();
      final body = await utf8.decoder.bind(httpResp).join();

      if (httpResp.statusCode != HttpStatus.ok) {
        throw HttpException(
          'sync exchange failed: ${httpResp.statusCode} $body',
          uri: url,
        );
      }

      final json = SyncJsonCodec.decodeObject(body);
      return SyncExchangeResponse.fromJson(json);
    } finally {
      client.close(force: true);
    }
  }

  /// 向对端发起配对请求。
  Future<PairRequestResponse> requestPairing({
    required String ipAddress,
    required PairRequest request,
  }) async {
    final client = HttpClient();
    try {
      final url = Uri.parse('http://$ipAddress:$transferPort/pair/request');
      final httpReq = await client.postUrl(url);
      httpReq.headers.contentType = ContentType.json;
      httpReq.write(jsonEncode(request.toJson()));

      final httpResp = await httpReq.close();
      final body = await utf8.decoder.bind(httpResp).join();

      if (httpResp.statusCode != HttpStatus.ok) {
        throw HttpException(
          'pair request failed: ${httpResp.statusCode} $body',
          uri: url,
        );
      }

      final json = SyncJsonCodec.decodeObject(body);
      return PairRequestResponse(
        sessionId: json['session_id'] as String,
        expiresAtMs: json['expires_at_ms'] as int,
      );
    } finally {
      client.close(force: true);
    }
  }

  /// 向对端发起配对确认。
  Future<PairConfirmResponse> confirmPairing({
    required String ipAddress,
    required PairConfirmRequest request,
  }) async {
    final client = HttpClient();
    try {
      final url = Uri.parse('http://$ipAddress:$transferPort/pair/confirm');
      final httpReq = await client.postUrl(url);
      httpReq.headers.contentType = ContentType.json;
      httpReq.write(jsonEncode(request.toJson()));

      final httpResp = await httpReq.close();
      final body = await utf8.decoder.bind(httpResp).join();

      if (httpResp.statusCode != HttpStatus.ok) {
        throw HttpException(
          'pair confirm failed: ${httpResp.statusCode} $body',
          uri: url,
        );
      }

      final json = SyncJsonCodec.decodeObject(body);
      return PairConfirmResponse(authToken: json['auth_token'] as String);
    } finally {
      client.close(force: true);
    }
  }

  /// 关闭本地服务端。
  Future<void> stopServer() async {
    await _server?.close(force: true);
    _server = null;
  }

  /// 探测对端是否在线（HTTP /ping）。
  ///
  /// 返回值：
  /// - true：对端服务可访问且返回 200
  /// - false：超时/拒绝连接/非 200 等均视为离线
  Future<bool> ping({required String ipAddress}) async {
    final client = HttpClient();
    try {
      client.connectionTimeout = const Duration(seconds: 2);
      final url = Uri.parse('http://$ipAddress:$transferPort/ping');
      final httpReq = await client.getUrl(url);
      final httpResp = await httpReq.close();
      // 读取响应体以确保连接完整关闭（避免 socket 复用导致资源占用）。
      await utf8.decoder.bind(httpResp).drain();
      return httpResp.statusCode == HttpStatus.ok;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  Future<void> dispose() async {
    await stopServer();
  }

  String? _extractBearerToken(String? header) {
    if (header == null) return null;
    final trimmed = header.trim();
    if (!trimmed.toLowerCase().startsWith('bearer ')) return null;
    final token = trimmed.substring(7).trim();
    return token.isEmpty ? null : token;
  }

  Future<void> _writeJson(HttpResponse response, Object body) async {
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(body));
    await response.close();
  }
}
