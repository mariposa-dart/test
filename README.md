# mariposa_test
[![Pub](https://img.shields.io/pub/v/mariposa_test.svg)](https://pub.dartlang.org/packages/mariposa_test)
[![build status](https://travis-ci.org/mariposa-dart/mariposa_test.svg)](https://travis-ci.org/mariposa-dart/mariposa_test)

Infrastructure for unit-testing Mariposa widgets:
* The `DOMTester` class, which can interactively run tests against a tree, supporting events
and DOM traversal.
* Multiple `Matcher` functions that can be used in unit tests.

For best results, use `package:test`. 

# `DOMTester`
*TODO: DOM tester, analogous to Flutter's `WidgetTester`.*

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