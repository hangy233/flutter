import 'package:cupertino_ui/cupertino_ui.dart' as cupertino;
import 'package:material_ui/material_ui.dart';

const _packageFixed = bool.fromEnvironment('PACKAGE_FIXED');

void main() => runApp(const SwitchColorDemoApp());

class SwitchColorDemoApp extends StatefulWidget {
  const SwitchColorDemoApp({super.key});

  @override
  State<SwitchColorDemoApp> createState() => _SwitchColorDemoAppState();
}

class _SwitchColorDemoAppState extends State<SwitchColorDemoApp> {
  static const _dynamicColor = cupertino.CupertinoDynamicColor.withBrightness(
    color: Color(0xffff0000),
    darkColor: Color(0xff0000ff),
  );

  bool _dark = false;
  bool _enabled = true;

  Widget _codeSnippet(BuildContext context, String code) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SelectableText(
        code,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          height: 1.5,
        ),
      ),
    ),
  );

  Widget _switchCard({
    required BuildContext context,
    required String title,
    required String description,
    required Key switchKey,
    required Color trackColor,
    required String code,
  }) => Card.outlined(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(description),
          SizedBox(
            height: 96,
            child: Center(
              child: Transform.scale(
                scale: 1.8,
                child: cupertino.CupertinoSwitch(
                  key: switchKey,
                  value: _enabled,
                  activeTrackColor: trackColor,
                  onChanged: (value) => setState(() => _enabled = value),
                ),
              ),
            ),
          ),
          _codeSnippet(context, code),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: _packageFixed
        ? 'CupertinoSwitch after internal fix'
        : 'CupertinoSwitch before internal fix',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorSchemeSeed: const Color(0xff3559e0),
      brightness: Brightness.light,
    ),
    darkTheme: ThemeData(
      colorSchemeSeed: const Color(0xff3559e0),
      brightness: Brightness.dark,
    ),
    themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
    themeAnimationDuration: Duration.zero,
    home: Scaffold(
      body: cupertino.CupertinoTheme(
        data: cupertino.CupertinoThemeData(
          brightness: _dark ? Brightness.dark : Brightness.light,
        ),
        child: Builder(
          builder: (context) {
            final resolvedColor = cupertino.CupertinoDynamicColor.resolve(
              _dynamicColor,
              context,
            );
            final rawCard = _switchCard(
              context: context,
              title: 'Direct dynamic color',
              description: 'The color is passed directly to CupertinoSwitch.',
              switchKey: const ValueKey('raw-switch'),
              trackColor: _dynamicColor,
              code: 'activeTrackColor: _dynamicColor,',
            );
            final resolvedCard = _switchCard(
              context: context,
              title: 'Explicitly resolved color',
              description: 'The same color is resolved for the current theme.',
              switchKey: const ValueKey('resolved-switch'),
              trackColor: resolvedColor,
              code:
                  'activeTrackColor:\n'
                  '  cupertino.CupertinoDynamicColor.resolve(\n'
                  '    _dynamicColor, context,\n'
                  '  ),',
            );

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _packageFixed
                            ? 'CupertinoSwitch after the internal fix'
                            : 'CupertinoSwitch before the internal fix',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'The custom color is red in light mode and blue in dark '
                        'mode. Switch themes and compare the two active tracks.',
                      ),
                      const SizedBox(height: 24),
                      const Text('Shared adaptive color'),
                      const SizedBox(height: 8),
                      _codeSnippet(
                        context,
                        'static const _dynamicColor =\n'
                        '    cupertino.CupertinoDynamicColor.withBrightness(\n'
                        '  color: Color(0xffff0000),     // Light: red\n'
                        '  darkColor: Color(0xff0000ff), // Dark: blue\n'
                        ');',
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 16,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          FilledButton(
                            key: const ValueKey('theme-toggle'),
                            onPressed: () => setState(() => _dark = !_dark),
                            child: Text(
                              _dark
                                  ? 'Switch to light mode'
                                  : 'Switch to dark mode',
                            ),
                          ),
                          Text(
                            'Theme: ${_dark ? 'dark' : 'light'}',
                            key: const ValueKey('theme-status'),
                          ),
                          Text(
                            'Switches: ${_enabled ? 'on' : 'off'}',
                            key: const ValueKey('switch-state'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: resolvedColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Expected active track: ${_dark ? 'blue' : 'red'}',
                            key: const ValueKey('expected-color'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth >= 560) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: rawCard),
                                const SizedBox(width: 16),
                                Expanded(child: resolvedCard),
                              ],
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              rawCard,
                              const SizedBox(height: 16),
                              resolvedCard,
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Expected: both active tracks follow the theme. '
                        'Both switches share the same on/off state.',
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        _packageFixed
                            ? 'cupertino_ui 1.1.1 with the local internal color fix. '
                                  'The direct-color switch has no caller workaround.'
                            : 'Original cupertino_ui 1.1.1 package.',
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}
