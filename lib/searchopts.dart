library searchopts;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fuzzy_string/fuzzy_string.dart';

/// An [Intent] to highlight the previous option in the autocomplete list.
class SearchPreviousOptionIntent extends Intent {
  /// Creates an instance of SearchPreviousOptionIntent.
  const SearchPreviousOptionIntent();
}

/// An [Intent] to highlight the next option in the Search list.
class SearchNextOptionIntent extends Intent {
  /// Creates an instance of SearchNextOptionIntent.
  const SearchNextOptionIntent();
}

/// An [Intent] to select the current highlighted option in the Search list.
class SearchSelectOptionIntent extends Intent {
  /// Creates an instance of SearchSelectOptionIntent.
  const SearchSelectOptionIntent();
}

abstract class Option<T extends Object> {
  String get value;
  T get object;

  const Option();

  static List<Option<T>> from<T extends Object>(List<T> options, Option<T> Function(T) conveter) {
    return options.map((e) => conveter(e)).toList();
  }

  static List<Option<String>> fromString(List<String> options) {
    return from(options, (v) => _StringOption(v));
  }
}

class _StringOption extends Option<String> {
  final String _value;
  _StringOption(this._value);
  @override
  String get object => _value;
  @override
  String get value => _value;
}

class SearchOptionsRenderConfig {
  final bool isHighlighted;

  const SearchOptionsRenderConfig({required this.isHighlighted});
}

class SearchOptions<T extends Object> extends StatefulWidget {
  const SearchOptions({
    super.key,
    required this.options,
    required this.renderOption,
    required this.onSelected,
    this.previousOptionActivator = const SingleActivator(LogicalKeyboardKey.arrowUp),
    this.nextOptionActivator = const SingleActivator(LogicalKeyboardKey.arrowDown),
    this.selectOptionActivator = const SingleActivator(LogicalKeyboardKey.enter),
    this.prototypeItem,
    this.matcher = const SmithWaterman(),
  });

  final List<Option<T>> options;

  final Widget Function(BuildContext context, T item, SearchOptionsRenderConfig config)
      renderOption;

  final void Function(T item) onSelected;

  final Widget? prototypeItem;

  /// Shorcut activator to highlight the previous option
  final ShortcutActivator previousOptionActivator;

  /// Shorcut activator to highlight the next option
  final ShortcutActivator nextOptionActivator;

  /// Shorcut activator to select the current highlighted option
  final ShortcutActivator selectOptionActivator;

  /// fuzzy matching alghorithm used to filter
  final FuzzyStringMatcher matcher;

  @override
  State<SearchOptions<T>> createState() => _SearchOptionsState<T>();
}

class _SearchOptionsState<T extends Object> extends State<SearchOptions<T>> {
  ValueNotifier<int> highlighted = ValueNotifier(0);

  late List<Option<T>> filtered;

  late final Map<Type, Action<Intent>> actionMap;
  late final CallbackAction<SearchPreviousOptionIntent> previousOptionAction;
  late final CallbackAction<SearchNextOptionIntent> nextOptionAction;
  late final CallbackAction<SearchSelectOptionIntent> selectOptionAction;

  late final Map<ShortcutActivator, Intent> shortcuts;

  @override
  void initState() {
    super.initState();

    filtered = widget.options;

    shortcuts = <ShortcutActivator, Intent>{
      widget.previousOptionActivator: const SearchPreviousOptionIntent(),
      widget.nextOptionActivator: const SearchNextOptionIntent(),
      widget.selectOptionActivator: const SearchSelectOptionIntent(),
    };

    previousOptionAction =
        CallbackAction<SearchPreviousOptionIntent>(onInvoke: highlightPreviousOption);
    nextOptionAction = CallbackAction<SearchNextOptionIntent>(onInvoke: highlightNextOption);
    selectOptionAction = CallbackAction<SearchSelectOptionIntent>(onInvoke: selectOption);

    actionMap = <Type, Action<Intent>>{
      SearchPreviousOptionIntent: previousOptionAction,
      SearchNextOptionIntent: nextOptionAction,
      SearchSelectOptionIntent: selectOptionAction,
    };
  }

  void updateHighlight(int newIndex) {
    if (filtered.isNotEmpty) {
      highlighted.value = newIndex % filtered.length;
    } else {
      highlighted.value = 0;
    }
  }

  void highlightPreviousOption(SearchPreviousOptionIntent intent) {
    updateHighlight(highlighted.value - 1);
  }

  void highlightNextOption(SearchNextOptionIntent intent) {
    updateHighlight(highlighted.value + 1);
  }

  void selectOption(SearchSelectOptionIntent intent) {
    widget.onSelected(filtered[highlighted.value].object);
  }

  void updateFilter(String v) {
    if (v.isEmpty) {
      setState(() => filtered = widget.options);
      return;
    }
    final scores = widget.options
        .map((e) => (e, e.value.similarityScoreTo(v, ignoreCase: true, matcher: widget.matcher)))
        .where((e) => e.$2 > 0.5)
        .toList();
    scores.sort((a, b) => b.$2.compareTo(a.$2));

    setState(() => filtered = scores.map((e) => e.$1).toList());
    updateHighlight(highlighted.value);
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: shortcuts,
      child: Actions(
        actions: actionMap,
        child: Column(
          children: [
            TextFormField(
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.all(5.0),
              ),
              onChanged: updateFilter,
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: highlighted,
                builder: (context, _) {
                  return ListView.builder(
                    itemCount: filtered.length,
                    prototypeItem: widget.prototypeItem ??
                        widget.renderOption(
                          context,
                          widget.options.first.object,
                          const SearchOptionsRenderConfig(isHighlighted: false),
                        ),
                    itemBuilder: (context, index) => widget.renderOption(
                      context,
                      filtered[index].object,
                      SearchOptionsRenderConfig(isHighlighted: highlighted.value == index),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
