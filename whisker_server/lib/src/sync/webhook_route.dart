import 'dart:async';

import 'package:serverpod/serverpod.dart';

import 'remote_sync.dart';

/// `POST /webhooks/github` untuk event `push` dari GitHub App.
class GithubWebhookRoute extends Route {
  final String secret;
  GithubWebhookRoute(this.secret) : super(methods: {Method.post});

  @override
  FutureOr<Result> handleCall(Session session, Request request) async {
    final body = await request.read().expand((c) => c).toList();
    final headers = {
      for (final e in request.headers.entries)
        e.key.toLowerCase(): e.value.join(','),
    };
    final (code, msg) = await handleGithubWebhook(
      session,
      headers,
      body,
      secret,
    );
    return Response(code, body: Body.fromString(msg));
  }
}
