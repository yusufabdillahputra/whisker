import 'package:flutter/widgets.dart';

/// Palet pencarian (dilengkapi di Task 7).
class SearchPanel extends StatelessWidget {
  final int hubId;
  final ValueChanged<String> onOpen;
  const SearchPanel({super.key, required this.hubId, required this.onOpen});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
