import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class MeasureSize extends SingleChildRenderObjectWidget {
  const MeasureSize({super.key, required this.onChange, required Widget super.child});

  final ValueChanged<Size> onChange;

  @override
  RenderObject createRenderObject(BuildContext context) => RenderMeasureSize(onChange);

  @override
  void updateRenderObject(BuildContext context, covariant RenderMeasureSize renderObject) {
    renderObject.onChange = onChange;
  }
}

class RenderMeasureSize extends RenderProxyBox {
  RenderMeasureSize(this.onChange);

  ValueChanged<Size> onChange;
  Size? _old;

  @override
  void performLayout() {
    super.performLayout();
    final s = size;
    if (_old == s) return;
    _old = s;
    WidgetsBinding.instance.addPostFrameCallback((_) => onChange(s));
  }
}
