import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

import '../../app/logo.dart';
import '../../client.dart';

/// Halaman login: `SignInWidget` Serverpod (GitHub di produksi, email di
/// dev) dengan logo dan tema Forui.
class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    final typography = context.theme.typography;
    return FScaffold(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(24),
            children: [
              const Center(child: WhiskerMark(size: 72)),
              const SizedBox(height: 12),
              Text(
                'Masuk ke Whisker',
                textAlign: TextAlign.center,
                style: typography.body.xl.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              Material(
                type: MaterialType.transparency,
                child: SignInWidget(
                  client: client,
                  onError: (error) => showFToast(
                    context: context,
                    variant: FToastVariant.destructive,
                    title: Text('Login gagal: $error'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
