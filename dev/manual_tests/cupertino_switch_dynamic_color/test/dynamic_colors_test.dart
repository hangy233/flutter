import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_test/flutter_test.dart';

const CupertinoDynamicColor _dynamicTrackColor =
    CupertinoDynamicColor.withBrightness(
      color: Color(0xFFFFCC00),
      darkColor: Color(0xFF0055AA),
    );
const CupertinoDynamicColor _dynamicThumbColor =
    CupertinoDynamicColor.withBrightness(
      color: Color(0xFFFF5500),
      darkColor: Color(0xFF55CCFF),
    );
const Color _staticThumbColor = Color(0xFF8800BB);

Widget _withBrightness(Brightness brightness, Widget child) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: MediaQueryData(platformBrightness: brightness),
      child: CupertinoTheme(
        data: CupertinoThemeData(brightness: brightness),
        child: Center(child: child),
      ),
    ),
  );
}

Color _resolved(CupertinoDynamicColor color, Brightness brightness) {
  return brightness == Brightness.dark ? color.darkColor : color.color;
}

void _expectThumbColor(Color color) {
  expect(
    find.byType(CupertinoSwitch),
    paints
      ..rrect()
      ..rrect()
      ..rrect()
      ..rrect()
      ..rrect(color: color),
  );
}

void main() {
  const brightnessChanges = <Brightness>[
    Brightness.light,
    Brightness.dark,
    Brightness.light,
  ];

  for (final bool value in <bool>[false, true]) {
    final String state = value ? 'active' : 'inactive';

    testWidgets('custom $state track color follows brightness changes', (
      WidgetTester tester,
    ) async {
      final switchWidget = CupertinoSwitch(
        value: value,
        onChanged: (_) {},
        activeTrackColor: _dynamicTrackColor,
        inactiveTrackColor: _dynamicTrackColor,
      );
      State? switchState;
      for (final Brightness brightness in brightnessChanges) {
        await tester.pumpWidget(_withBrightness(brightness, switchWidget));
        await tester.pumpAndSettle();
        switchState ??= tester.state(find.byType(CupertinoSwitch));
        expect(tester.state(find.byType(CupertinoSwitch)), same(switchState));
        expect(
          find.byType(CupertinoSwitch),
          paints..rrect(color: _resolved(_dynamicTrackColor, brightness)),
        );
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('custom $state thumb color follows brightness changes', (
      WidgetTester tester,
    ) async {
      final switchWidget = CupertinoSwitch(
        value: value,
        onChanged: (_) {},
        thumbColor: _dynamicThumbColor,
        inactiveThumbColor: _dynamicThumbColor,
      );
      State? switchState;
      for (final Brightness brightness in brightnessChanges) {
        await tester.pumpWidget(_withBrightness(brightness, switchWidget));
        await tester.pumpAndSettle();
        switchState ??= tester.state(find.byType(CupertinoSwitch));
        expect(tester.state(find.byType(CupertinoSwitch)), same(switchState));
        _expectThumbColor(_resolved(_dynamicThumbColor, brightness));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('custom pressed $state thumb resolves its dynamic color', (
      WidgetTester tester,
    ) async {
      final switchWidget = CupertinoSwitch(
        value: value,
        onChanged: (_) {},
        thumbColor: WidgetStateColor.resolveWith((Set<WidgetState> states) {
          return states.contains(WidgetState.pressed)
              ? _dynamicThumbColor
              : _staticThumbColor;
        }),
        inactiveThumbColor: _staticThumbColor,
      );
      State? switchState;
      for (final Brightness brightness in brightnessChanges) {
        await tester.pumpWidget(_withBrightness(brightness, switchWidget));
        await tester.pumpAndSettle();
        switchState ??= tester.state(find.byType(CupertinoSwitch));
        expect(tester.state(find.byType(CupertinoSwitch)), same(switchState));
        _expectThumbColor(_staticThumbColor);
        final TestGesture gesture = await tester.startGesture(
          tester.getCenter(find.byType(CupertinoSwitch)),
        );
        try {
          await tester.pump(const Duration(milliseconds: 100));
          await tester.pumpAndSettle();
          _expectThumbColor(_resolved(_dynamicThumbColor, brightness));
          expect(tester.takeException(), isNull);
        } finally {
          await gesture.cancel();
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('default $state colors follow brightness changes', (
      WidgetTester tester,
    ) async {
      final switchWidget = CupertinoSwitch(value: value, onChanged: (_) {});
      for (final Brightness brightness in brightnessChanges) {
        await tester.pumpWidget(_withBrightness(brightness, switchWidget));
        await tester.pumpAndSettle();
        final BuildContext context = tester.element(
          find.byType(CupertinoSwitch),
        );
        expect(
          find.byType(CupertinoSwitch),
          paints..rrect(
            color: CupertinoDynamicColor.resolve(
              value
                  ? CupertinoColors.systemGreen
                  : CupertinoColors.secondarySystemFill,
              context,
            ),
          ),
        );
        _expectThumbColor(CupertinoColors.white);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('static $state colors remain unchanged across brightness', (
      WidgetTester tester,
    ) async {
      const Color trackColor = Color(0xFF22AA44);
      final switchWidget = CupertinoSwitch(
        value: value,
        onChanged: (_) {},
        activeTrackColor: trackColor,
        inactiveTrackColor: trackColor,
        thumbColor: _staticThumbColor,
        inactiveThumbColor: _staticThumbColor,
      );
      for (final Brightness brightness in brightnessChanges) {
        await tester.pumpWidget(_withBrightness(brightness, switchWidget));
        await tester.pumpAndSettle();
        expect(find.byType(CupertinoSwitch), paints..rrect(color: trackColor));
        _expectThumbColor(_staticThumbColor);
        expect(tester.takeException(), isNull);
      }
    });
  }
}
