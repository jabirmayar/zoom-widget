import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:mno_zoom_widget/zoom_hit_corners.dart';

class ZoomGestureDetector extends StatelessWidget {
  const ZoomGestureDetector({
    Key? key,
    this.zoomHitCornersDetector,
    this.onScaleStart,
    this.onScaleUpdate,
    this.onScaleEnd,
    this.onDoubleTap,
    required this.child,
    this.onTapUp,
    this.onTapDown,
    this.behavior,
  }) : super(key: key);

  final GestureDoubleTapCallback? onDoubleTap;
  final ZoomHitCornersDetector? zoomHitCornersDetector;

  final GestureScaleStartCallback? onScaleStart;
  final GestureScaleUpdateCallback? onScaleUpdate;
  final GestureScaleEndCallback? onScaleEnd;

  final GestureTapUpCallback? onTapUp;
  final GestureTapDownCallback? onTapDown;

  final Widget child;

  final HitTestBehavior? behavior;

  @override
  Widget build(BuildContext context) {
    final scope = ZoomGestureDetectorScope.of(context);

    final Axis? axis = scope?.axis;

    final Map<Type, GestureRecognizerFactory> gestures =
        <Type, GestureRecognizerFactory>{};

    if (onTapDown != null || onTapUp != null) {
      gestures[TapGestureRecognizer] =
          GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
        () => TapGestureRecognizer(debugOwner: this),
        (TapGestureRecognizer instance) {
          instance
            ..onTapDown = onTapDown
            ..onTapUp = onTapUp;
        },
      );
    }

    gestures[ZoomGestureRecognizer] =
        GestureRecognizerFactoryWithHandlers<ZoomGestureRecognizer>(
      () => ZoomGestureRecognizer(zoomHitCornersDetector, this, axis),
      (ZoomGestureRecognizer instance) {
        instance
          ..onStart = onScaleStart
          ..onUpdate = onScaleUpdate
          ..onEnd = onScaleEnd;
      },
    );

    gestures[DoubleTapGestureRecognizer] =
        GestureRecognizerFactoryWithHandlers<DoubleTapGestureRecognizer>(
      () => DoubleTapGestureRecognizer(debugOwner: this),
      (DoubleTapGestureRecognizer instance) {
        instance.onDoubleTap = onDoubleTap;
      },
    );

    return RawGestureDetector(
      behavior: behavior ?? HitTestBehavior.translucent,
      gestures: gestures,
      child: child,
    );
  }
}

class ZoomGestureRecognizer extends ScaleGestureRecognizer {
  ZoomGestureRecognizer(
    this.zoomHitCornersDetector,
    Object debugOwner,
    this.validateAxis,
  ) : super(debugOwner: debugOwner);
  final ZoomHitCornersDetector? zoomHitCornersDetector;
  final Axis? validateAxis;

  Map<int, Offset> _pointerLocations = <int, Offset>{};

  Offset? _initialFocalPoint;
  Offset? _currentFocalPoint;

  bool ready = true;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (ready) {
      ready = false;
      _pointerLocations = <int, Offset>{};
    }
    super.addAllowedPointer(event);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    ready = true;
    super.didStopTrackingLastPointer(pointer);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (validateAxis != null) {
      _computeEvent(event);
      _updateDistances();
      _decideIfWeAcceptEvent(event);
    }
    super.handleEvent(event);
  }

  void _computeEvent(PointerEvent event) {
    if (event is PointerMoveEvent) {
      if (!event.synthesized) {
        _pointerLocations[event.pointer] = event.position;
      }
    } else if (event is PointerDownEvent) {
      _pointerLocations[event.pointer] = event.position;
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      _pointerLocations.remove(event.pointer);
    }

    _initialFocalPoint = _currentFocalPoint;
  }

  void _updateDistances() {
    final int count = _pointerLocations.keys.length;
    Offset focalPoint = Offset.zero;
    for (int pointer in _pointerLocations.keys) {
      focalPoint += _pointerLocations[pointer]!;
    }
    _currentFocalPoint =
        count > 0 ? focalPoint / count.toDouble() : Offset.zero;
  }

  void _decideIfWeAcceptEvent(PointerEvent event) {
    if (!(event is PointerMoveEvent)) {
      return;
    }
    final Offset move = _initialFocalPoint! - _currentFocalPoint!;
    final bool? shouldMove = validateAxis == Axis.vertical
        ? zoomHitCornersDetector?.shouldMoveY(move)
        : zoomHitCornersDetector?.shouldMoveX(move);
    if (shouldMove == true || _pointerLocations.keys.length > 1) {
      resolve(GestureDisposition.accepted);
    }
  }
}

/// An [InheritedWidget] responsible to give a axis aware scope to the internal[GestureRecognizer].
///
/// When using this, PhotoView will test if the content zoomed has hit edge every time user pinches,
/// if so, it will let parent gesture detectors win the gesture arena
///
/// Useful when placing PhotoView inside a gesture sensitive context,
/// such as [PageView], [Dismissible], [BottomSheet].
///
/// Usage example:
/// ```
/// ZoomGestureDetectorScope(
///   axis: Axis.vertical,
///   child: PhotoView(
///     imageProvider: AssetImage("assets/pudim.jpg"),
///   ),
/// );
/// ```
class ZoomGestureDetectorScope extends InheritedWidget {
  ZoomGestureDetectorScope({
    required this.axis,
    required Widget child,
  }) : super(child: child);

  static ZoomGestureDetectorScope? of(BuildContext context) {
    final ZoomGestureDetectorScope? scope =
        context.dependOnInheritedWidgetOfExactType<ZoomGestureDetectorScope>();
    return scope;
  }

  final Axis axis;

  @override
  bool updateShouldNotify(ZoomGestureDetectorScope oldWidget) =>
      axis != oldWidget.axis;
}
