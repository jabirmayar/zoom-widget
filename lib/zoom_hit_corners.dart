import 'package:flutter/widgets.dart';

mixin ZoomHitCornersDetector {
  static const int threshold = 8;

  Offset get position;

  double get childWidth;

  double get childHeight;

  double get screenWidth;

  double get screenHeight;

  _HitCorners hitCornersX() {
    if (screenWidth + threshold >= childWidth) {
      return const _HitCorners(hasHitMin: true, hasHitMax: true);
    }
    double x = position.dx;
    _CornersRange cornersX = this.cornersX();
    return _HitCorners(
        hasHitMin: x - threshold <= cornersX.min,
        hasHitMax: x + threshold >= cornersX.max);
  }

  _HitCorners hitCornersY() {
    if (screenHeight + threshold >= childHeight) {
      return const _HitCorners(hasHitMin: true, hasHitMax: true);
    }
    double y = position.dy;
    _CornersRange cornersY = this.cornersY();
    return _HitCorners(
        hasHitMin: y - threshold <= cornersY.min,
        hasHitMax: y + threshold >= cornersY.max);
  }

  _CornersRange cornersX() {
    double widthDiff = childWidth - screenWidth;
    return _CornersRange(0, widthDiff);
  }

  _CornersRange cornersY() {
    double heightDiff = childHeight - screenHeight;
    return _CornersRange(0, heightDiff);
  }

  bool shouldMoveX(Offset move) {
    _HitCorners hitCornersX = this.hitCornersX();
    if (hitCornersX.hasHitBoth) {
      return false;
    }

    if (hitCornersX.hasHitAny) {
      if (hitCornersX.hasHitMax) {
        return move.dx < 0;
      }
      return move.dx > 0;
    }
    return true;
  }

  bool shouldMoveY(Offset move) {
    _HitCorners hitCornersY = this.hitCornersY();
    if (hitCornersY.hasHitBoth) {
      return false;
    }
    if (hitCornersY.hasHitAny) {
      if (hitCornersY.hasHitMax) {
        return move.dy < 0;
      }
      return move.dy > 0;
    }
    return true;
  }
}

class _HitCorners {
  const _HitCorners({
    required this.hasHitMin,
    required this.hasHitMax,
  });

  final bool hasHitMin;
  final bool hasHitMax;

  bool get hasHitAny => hasHitMin || hasHitMax;

  bool get hasHitBoth => hasHitMin && hasHitMax;

  @override
  String toString() =>
      '_HitCorners{hasHitMin: $hasHitMin, hasHitMax: $hasHitMax}';
}

/// Simple class to store a min and a max value
class _CornersRange {
  const _CornersRange(this.min, this.max);

  final double min;
  final double max;

  @override
  String toString() => '_CornersRange{min: $min, max: $max}';
}
