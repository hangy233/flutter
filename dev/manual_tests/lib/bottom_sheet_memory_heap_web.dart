// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';

@JS('globalThis.performance')
external _BrowserPerformance? get _performance;

extension type _BrowserPerformance._(JSObject _) implements JSObject {
  external _BrowserMemory? get memory;
}

extension type _BrowserMemory._(JSObject _) implements JSObject {
  external double? get usedJSHeapSize;
}

double? browserHeapMegabytes() {
  final double? bytes = _performance?.memory?.usedJSHeapSize;
  return bytes != null && bytes.isFinite && bytes > 0 ? bytes / 1000000 : null;
}
