import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// Workspace Hub (dilengkapi di Task 4).
class WorkspacePage extends StatelessWidget {
  final int hubId;
  final String? docPath;
  const WorkspacePage({super.key, required this.hubId, this.docPath});

  @override
  Widget build(BuildContext context) =>
      FScaffold(child: Center(child: Text('Hub $hubId')));
}
