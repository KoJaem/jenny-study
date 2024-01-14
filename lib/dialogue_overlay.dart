import 'dart:ui';

import 'package:flame/components.dart';
import 'package:jenny_study/constants/customColor.dart';

class DialogueOverlay extends PositionComponent {
  DialogueOverlay({
    super.size,
    super.position,
    this.bgColor,
  });
  final Color? bgColor;

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = bgColor ?? CustomColor.darkBlueGray.withAlpha(150),
    );
  }
}
