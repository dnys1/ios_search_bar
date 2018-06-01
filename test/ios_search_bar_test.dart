import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ios_search_bar/ios_search_bar.dart';

void main() {
  UniqueKey _searchBarKey;
  Duration _animationDuration;
  TextEditingController _searchTextController;
  FocusNode _searchFocusNode;
  Animation _animation;
  AnimationController _animationController;

  setUp(() {
    _searchBarKey = new UniqueKey();
    _animationDuration = new Duration(milliseconds: 200);

    _searchTextController = new TextEditingController();
    _searchFocusNode = new FocusNode();
  });

  tearDown(() {
    _animationController.dispose();
  });

  Future<Null> _buildSearchBar(WidgetTester tester) {
    _animationController = new AnimationController(
      duration: _animationDuration,
      vsync: tester,
    );
    _animation = new CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
      reverseCurve: Curves.easeInOut,
    );

    _searchFocusNode.addListener(() {
      if (!_animationController.isAnimating) {
        _animationController.forward();
      }
    });

    return tester.pumpWidget(new StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return new MaterialApp(
          home: new CupertinoPageScaffold(
            navigationBar: new CupertinoNavigationBar(
              middle: new IOSSearchBar(
                key: _searchBarKey,
                controller: _searchTextController,
                focusNode: _searchFocusNode,
                animation: _animation,
                onCancel: () {
                  _searchTextController.clear();
                  _searchFocusNode.unfocus();
                  _animationController.reverse();
                },
                onClear: () {
                  _searchTextController.clear();
                },
                onSubmit: (String text) {
                  _searchTextController.clear();
                  _searchFocusNode.unfocus();
                  _animationController.reverse();
                },
              ),
            ),
            child: new Container(),
          ),
        );
      }
    ));
  }

  testWidgets('test text input', (WidgetTester tester) async {
    await _buildSearchBar(tester);
    expect(_searchTextController.text, equals(''));
  });

  testWidgets('test animation on tap', (WidgetTester tester) async {
    await _buildSearchBar(tester);

    // Focus the text input
    await tester.tap(find.byKey(_searchBarKey));
    await tester.pumpAndSettle(_animationDuration);
    expect(_searchFocusNode.hasFocus, equals(true));
    expect(_animationController.isCompleted, equals(true));
  });

  testWidgets('test clear search', (WidgetTester tester) async {
    await _buildSearchBar(tester);

    // Focus the text input
    await tester.tap(find.byKey(_searchBarKey));
    await tester.pumpAndSettle(_animationDuration);

    // Enter test text
    await tester.enterText(find.byKey(_searchBarKey), 'Testing Clear');
    expect(_searchTextController.text, equals('Testing Clear'));

    // Tap the clear button
    await tester.tap(find.byType(CupertinoButton).first);
    expect(_searchTextController.text, equals(''));
    expect(_searchFocusNode.hasFocus, equals(true));
  });

  testWidgets('test cancel search', (WidgetTester tester) async {
    await _buildSearchBar(tester);

    // Focus the text input
    await tester.tap(find.byKey(_searchBarKey));
    await tester.pumpAndSettle(_animationDuration);

    // Enter test text
    await tester.enterText(find.byKey(_searchBarKey), 'Testing Cancel');
    expect(_searchTextController.text, equals('Testing Cancel'));

    // Tap the cancel button
    await tester.tap(find.byType(CupertinoButton).last);
    await tester.pumpAndSettle(_animationDuration);
    expect(_searchTextController.text, equals(''));
    expect(_searchFocusNode.hasFocus, equals(false));
    expect(_animationController.isDismissed, equals(true));
  });

  testWidgets('test submit search', (WidgetTester tester) async {
    await _buildSearchBar(tester);

    // Focus the text input
    await tester.tap(find.byKey(_searchBarKey));
    await tester.pumpAndSettle(_animationDuration);

    // Enter test text
    await tester.enterText(find.byKey(_searchBarKey), 'Testing Submit');
    expect(_searchTextController.text, equals('Testing Submit'));

    // Find search field and submit text
    EditableText searchField = tester.widget(find.byType(EditableText));
    searchField.onSubmitted(_searchTextController.text);
    await tester.pumpAndSettle();
    expect(_searchFocusNode.hasFocus, equals(false));
    expect(_animationController.isDismissed, equals(true));
    expect(_searchTextController.text, equals(''));
  });
}
