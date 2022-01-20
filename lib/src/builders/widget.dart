import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../effects/index.dart';

class PageTurnWidget extends StatefulWidget {
  const PageTurnWidget({
    Key? key,
    required this.amount,
    this.backgroundColor = const Color(0xFFFFFFCC),
    required this.child,
  }) : super(key: key);

  final Animation<double> amount;
  final Color backgroundColor;
  final Widget child;

  @override
  _PageTurnWidgetState createState() => _PageTurnWidgetState();
}

class _PageTurnWidgetState extends State<PageTurnWidget> {
  final GlobalKey _boundaryKey = GlobalKey();
  ui.Image? _image;

  @override
  void didUpdateWidget(PageTurnWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child != widget.child) {
      _image = null;
    }
  }

  void _captureImage([Duration? timeStamp]) async {
    await Future.delayed(Duration(seconds: 1));

    RenderObject? boundary = _boundaryKey.currentContext?.findRenderObject();
    if (boundary is RenderRepaintBoundary) {
      if (kDebugMode && boundary.debugNeedsPaint) {
        return _captureImage(timeStamp);
      } else {
        ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
        WidgetsBinding.instance?.addPostFrameCallback((_) {
          setState(() => _image = image);
        });
      }
    }

    return _captureImage(timeStamp);
  }

  double get pixelRatio => MediaQuery.of(context).devicePixelRatio;

  @override
  Widget build(BuildContext context) {
    if (_image == null) WidgetsBinding.instance?.addPostFrameCallback(_captureImage);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final size = constraints.biggest;
        return Stack(
          clipBehavior: Clip.hardEdge,
          children: <Widget>[
            if (_image == null) buildBoundary(size),
            if (_image != null) buildPage(),
            buildLoading(),
          ],
        );
      },
    );
  }

  Widget buildLoading() {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: _image == null ? 1 : 0,
        duration: Duration(milliseconds: 300),
        child: Container(
          color: widget.backgroundColor,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }

  Widget buildPage() {
    return CustomPaint(
      painter: PageTurnEffect(
        amount: widget.amount,
        image: _image!,
        backgroundColor: widget.backgroundColor,
      ),
      size: Size.infinite,
    );
  }

  Widget buildBoundary(ui.Size size) {
    return Positioned(
      left: 1 + size.width,
      top: 1 + size.height,
      width: size.width,
      height: size.height,
      child: RepaintBoundary(
        key: _boundaryKey,
        child: widget.child,
      ),
    );
  }
}
