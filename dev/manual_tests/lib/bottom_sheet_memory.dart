// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// From dev/manual_tests, use this checkout's SDK:
// ../../bin/flutter run -t lib/bottom_sheet_memory.dart (flutter.bat on Windows)

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'bottom_sheet_memory_heap_stub.dart'
    if (dart.library.js_interop) 'bottom_sheet_memory_heap_web.dart';

const int _cycles = 200;
const int _bufferBytes = 1000000;

void main() => runApp(const MaterialApp(home: _Demo()));

class _Demo extends StatefulWidget {
  const _Demo();

  @override
  State<_Demo> createState() => _DemoState();
}

class _DemoState extends State<_Demo> with TickerProviderStateMixin {
  final GlobalKey _sheetKey = GlobalKey();
  final List<String> _logs = <String>[];
  late AnimationController _controller;
  bool _running = false;

  AnimationController _newController() => AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
    reverseDuration: const Duration(milliseconds: 250),
  );

  @override
  void initState() {
    super.initState();
    _controller = _newController();
  }

  void _log(String stage, _TrackingAnimation animation) {
    final double? heap = browserHeapMegabytes();
    final line =
        '$stage: listeners=${animation.listenerCount}, '
        'test buffers=${(animation.listenerCount * _bufferBytes / 1000000).toStringAsFixed(0)} MB, '
        'JS heap=${heap == null ? 'unavailable' : '${heap.toStringAsFixed(2)} MB'}';
    debugPrint(line);
    setState(() => _logs.add(line));
  }

  Future<void> _run() async {
    // Release the previous run, then keep this controller alive after closing.
    _controller.dispose();
    _controller = _newController();
    setState(() {
      _running = true;
      _logs.clear();
    });
    final route = _TrackingRoute(
      controller: _controller,
      builder: (BuildContext context) => SizedBox(
        key: _sheetKey,
        height: 100,
        child: const Center(child: Text('Running 200 cycles, then closing automatically')),
      ),
    );
    unawaited(Navigator.of(context).push<void>(route));
    await _controller.forward();
    if (!mounted) {
      return;
    }
    await WidgetsBinding.instance.endOfFrame;

    BottomSheet? sheet;
    _sheetKey.currentContext!.visitAncestorElements((Element element) {
      if (element.widget is BottomSheet) {
        sheet = element.widget as BottomSheet;
        return false;
      }
      return true;
    });
    final _TrackingAnimation animation = route.trackedAnimation!;
    _log('Before', animation);
    for (var i = 1; i <= _cycles; i++) {
      // Invoke the actual library callbacks without waiting for 200 gestures.
      sheet!.onDragStart!(DragStartDetails());
      sheet!.onDragEnd!(DragEndDetails(primaryVelocity: 0), isClosing: false);
      if (i % 10 == 0) {
        _log('Cycle $i/$_cycles', animation);
        await Future<void>.delayed(const Duration(milliseconds: 16));
        if (!mounted) {
          return;
        }
      }
    }
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop<void>();
    await route.completed;
    if (!mounted) {
      return;
    }
    _log('After close', animation);
    setState(() => _running = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Bottom sheet listener leak')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Each subscription gets a deliberate 1 MB test buffer. '
            "JS heap is the browser's usedJSHeapSize estimate, not total Chrome memory. "
            'The controller stays alive after closing until the next run.',
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _running ? null : _run, child: const Text('Run 200 cycles')),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Text(_logs.join('\n'), style: const TextStyle(fontFamily: 'monospace')),
            ),
          ),
        ],
      ),
    ),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _TrackingRoute extends ModalBottomSheetRoute<void> {
  _TrackingRoute({required AnimationController controller, required super.builder})
    : super(
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        modalBarrierColor: Colors.transparent,
        transitionAnimationController: controller,
      );

  _TrackingAnimation? trackedAnimation;

  @override
  Animation<double>? get animation {
    final Animation<double>? parent = super.animation;
    return parent == null ? null : trackedAnimation ??= _TrackingAnimation(parent);
  }
}

class _TrackingAnimation extends Animation<double> with AnimationWithParentMixin<double> {
  _TrackingAnimation(this.parent);

  @override
  final Animation<double> parent;
  final List<(AnimationStatusListener, AnimationStatusListener)> _listeners =
      <(AnimationStatusListener, AnimationStatusListener)>[];

  int get listenerCount => _listeners.length;

  @override
  double get value => parent.value;

  @override
  void addStatusListener(AnimationStatusListener listener) {
    final buffer = Uint8List(_bufferBytes);
    for (var i = 0; i < buffer.length; i += 4096) {
      buffer[i] = 1;
    }
    void forwarded(AnimationStatus status) {
      buffer[0] = (buffer[0] + status.index + 1) & 0xff;
      listener(status);
    }

    _listeners.add((listener, forwarded));
    parent.addStatusListener(forwarded);
  }

  @override
  void removeStatusListener(AnimationStatusListener listener) {
    final int index = _listeners.indexWhere(
      ((AnimationStatusListener, AnimationStatusListener) entry) => entry.$1 == listener,
    );
    if (index != -1) {
      parent.removeStatusListener(_listeners.removeAt(index).$2);
    }
  }
}
