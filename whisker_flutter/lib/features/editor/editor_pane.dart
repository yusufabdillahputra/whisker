import 'package:flutter/widgets.dart';

/// Panel editor (dilengkapi di Task 5).
class EditorPane extends StatelessWidget {
  final int hubId;
  final String path;
  const EditorPane({super.key, required this.hubId, required this.path});

  @override
  Widget build(BuildContext context) => Center(child: Text(path));
}
