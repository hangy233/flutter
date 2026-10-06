import 'package:cupertino_ui/cupertino_ui.dart' as cupertino;
import 'package:flutter_test/flutter_test.dart';
import 'package:cupertino_switch_dynamic_color_demo/main.dart';

const bool expectDynamicColorResolved = bool.fromEnvironment(
  'EXPECT_DYNAMIC_COLOR_RESOLVED',
);

const cupertino.Color lightTrackColor = cupertino.Color(0xffff0000);
const cupertino.Color darkTrackColor = cupertino.Color(0xff0000ff);

void main() {
  testWidgets(
    'theme toggle compares direct and resolved dynamic track colors',
    (WidgetTester tester) async {
      await tester.pumpWidget(const SwitchColorDemoApp());
      await tester.pumpAndSettle();

      final rawSwitch = find.byKey(const cupertino.ValueKey('raw-switch'));
      final resolvedSwitch = find.byKey(
        const cupertino.ValueKey('resolved-switch'),
      );

      String? text(String key) => tester
          .widget<cupertino.Text>(find.byKey(cupertino.ValueKey<String>(key)))
          .data;

      Future<void> toggleTheme() async {
        final toggle = find.byKey(const cupertino.ValueKey('theme-toggle'));
        await tester.ensureVisible(toggle);
        await tester.tap(toggle);
        await tester.pumpAndSettle();
      }

      expect(text('theme-status'), 'Theme: light');
      expect(text('expected-color'), 'Expected active track: red');
      for (final switchFinder in [rawSwitch, resolvedSwitch]) {
        expect(
          tester.widget<cupertino.CupertinoSwitch>(switchFinder).value,
          isTrue,
        );
        expect(
          cupertino.CupertinoTheme.brightnessOf(tester.element(switchFinder)),
          cupertino.Brightness.light,
        );
        expect(switchFinder, paints..rrect(color: lightTrackColor));
      }

      await toggleTheme();

      expect(text('theme-status'), 'Theme: dark');
      expect(text('expected-color'), 'Expected active track: blue');
      for (final switchFinder in [rawSwitch, resolvedSwitch]) {
        expect(
          cupertino.CupertinoTheme.brightnessOf(tester.element(switchFinder)),
          cupertino.Brightness.dark,
        );
      }
      expect(
        rawSwitch,
        paints..rrect(
          color: expectDynamicColorResolved ? darkTrackColor : lightTrackColor,
        ),
      );
      expect(resolvedSwitch, paints..rrect(color: darkTrackColor));

      await toggleTheme();

      expect(text('theme-status'), 'Theme: light');
      for (final switchFinder in [rawSwitch, resolvedSwitch]) {
        expect(switchFinder, paints..rrect(color: lightTrackColor));
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('either switch updates both controls normally', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SwitchColorDemoApp());
    await tester.pumpAndSettle();

    final rawSwitch = find.byKey(const cupertino.ValueKey('raw-switch'));
    final resolvedSwitch = find.byKey(
      const cupertino.ValueKey('resolved-switch'),
    );

    Future<void> tapSwitch(Finder switchFinder) async {
      await tester.ensureVisible(switchFinder);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();
    }

    await tapSwitch(rawSwitch);
    for (final switchFinder in [rawSwitch, resolvedSwitch]) {
      expect(
        tester.widget<cupertino.CupertinoSwitch>(switchFinder).value,
        isFalse,
      );
    }
    expect(find.text('Switches: off'), findsOneWidget);

    await tapSwitch(resolvedSwitch);
    for (final switchFinder in [rawSwitch, resolvedSwitch]) {
      expect(
        tester.widget<cupertino.CupertinoSwitch>(switchFinder).value,
        isTrue,
      );
    }
    expect(find.text('Switches: on'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
