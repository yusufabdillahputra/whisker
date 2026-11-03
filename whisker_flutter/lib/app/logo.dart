import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Logo Whisker (hasil style DiceBear `whisker-critters`, salinan dari
/// `design/logo/`).
class WhiskerMark extends StatelessWidget {
  final double size;
  const WhiskerMark({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Logo Whisker',
    image: true,
    child: SvgPicture.asset(
      'assets/logo/whisker-mark.svg',
      width: size,
      height: size,
    ),
  );
}
