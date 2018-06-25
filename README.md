# mariposa_test
[![Pub](https://img.shields.io/pub/v/mariposa_test.svg)](https://pub.dartlang.org/packages/mariposa_test)
[![build status](https://travis-ci.org/mariposa-dart/mariposa_test.svg)](https://travis-ci.org/mariposa-dart/mariposa_test)

Infrastructure for unit-testing Mariposa widgets:
* The `DOMTester` class, which can interactively run tests against a tree, supporting events
and DOM traversal.
* Multiple `Matcher` functions that can be used in unit tests.

For best results, use `package:test`. 

# `DOMTester`
Those familiar with Flutter's `WidgetTester` will understand the `DOMTester` class.
This class renders Mariposa widgets into an AST from `package:html`, which can then be interacted
with, as though it were a real browser DOM. Oof course, things like Web API's will be unavailable
from a command-line setting, but the best practice is to use abstraction to mock these things in
at testing time, anyways.

The `DOMTester` API is more or less the same as `mariposa/dom` or `mariposa/string`:

```dart
import 'dart:async';
import 'package:html_builder/elements.dart';
import 'package:mariposa/mariposa.dart';
import 'package:mariposa_test/mariposa_test.dart';
import 'package:test/test.dart';

void main() {
  DOMTester tester;

  var app = () {
    return div(
      c: [
        h1(
          className: 'heading',
          p: {'id': 'foo'},
          c: [text('H1!!!')],
        ),
        myWidget(),
        myOtherWidget(),
      ],
    );
  };

  setUp(() {
    tester = new DOMTester()..render(app);
  });

  tearDown(() => tester.close());
}
```

However, `DOMTester` exposes the following functionality for easy testing:

* `getElementById`
* `querySelector`
* `querySelectorAll`
* `fire` - Fire an event from an element
* `nextEvent` - Listen for the next event of a specific type fired by an element

`DOMTester` methods deal with objects of the type `DOMTesterElement`, which has a property
`nativeElement` that points to a `package:html` element. For complex functionality, feel free
to use this provision.

```dart
void main() {
  test('getElementById', () {
      expect(tester.getElementById('foo'), h1Element);
    });
  
    test('getElementsByClassName', () {
      expect(tester.getElementsByClassName('heading'), contains(h1Element));
    });
  
    test('getElementsByTagName', () {
      expect(tester.getElementsByTagName('h1'), contains(h1Element));
    });
  
    test('querySelector', () {
      expect(h1Element?.nativeElement?.text, 'H1!!!');
    });
  
    test('querySelectorAll', () {
      expect(tester.querySelectorAll('.heading'), contains(h1Element));
    });
    
    test('fire', () {
      tester.fire(h1Element, 'the event', someData);
    });
    
    test('handle click', () async {
      var ev = await tester.nextEvent(h1Element, 'the event');
      expect(ev, isNotNull);
    });
}
```

# Matchers
All of the below `Matcher` functions accept either concrete objects, or
`Matcher` instances; therefore, they can be combined together.

## Single-node
* `hasTagName` - Matches a node's tag name
* `hasAttributes` - Matches a node's attributes
* `hasChildren` - Matches a node's children
* `hasClass` - Matches a node's `class` attribute
* `hasClassString` - Matches a node's `class` attribute, after transforming it to a `String`
* `hasClassList` - Matches a node's `class` attribute, after transforming it to a `List<String>`

```dart
void main() {
  test('hasTagName', () {
    expect(br(), hasTagName('br'));
  });

  test('hasAttributes', () {
    expect(
      h('p', {'foo': 'bar', 'baz': 'quux'}),
      allOf(
        hasAttributes(containsPair('foo', 'bar')),
        isNot(hasAttributes(containsPair('foo', 'baz'))),
      ),
    );
  });

  test('hasChildren', () {
    expect(
      div(c: [br()]),
      allOf(
        hasChildren(anyElement(rendersTo('<br>'))),
        isNot(hasChildren(anyElement(rendersTo('<hr>')))),
      ),
    );
  });
  
  test('hasClassList', () {
    expect(
      h('a', {'class': 'b c'}),
      allOf(
        hasClassList(['b', 'c']),
        isNot(hasClassList(['d'])),
      ),
    );
  });
}
```

## Two-node
* `rendersTo` - Asserts that a node renders to a given HTML string or `Matcher`.
* `rendersEqualTo` - Asserts that two nodes produce the same output.

```dart
void main() {
    test('rendersTo', () {
      expect(
        div(c: [br()]),
        allOf(
          rendersTo('<div><br></div>'),
          isNot(rendersTo('<dip><hr></dip>')),
        ),
      );
    });
  
    test('rendersEqualTo', () {
      expect(
        div(c: [br()]),
        allOf(
          rendersEqualTo(div(c: [br()])),
          rendersEqualTo(h('div', {}, [br()])),
          isNot(rendersEqualTo(p())),
        ),
      );
    });
}
```