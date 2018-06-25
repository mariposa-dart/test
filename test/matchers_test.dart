import 'package:html_builder/elements.dart';
import 'package:mariposa_test/mariposa_test.dart';
import 'package:test/test.dart';

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

  group('class testers', () {
    var node = h('a', {
      'class': ['b', 'c']
    });

    test('hasClass', () {
      expect(
        node,
        allOf(
          hasClass(['b', 'c']),
          isNot(hasClass(contains('d'))),
        ),
      );
    });

    test('hasClassString', () {
      expect(
        node,
        allOf(
          hasClassString('b c'),
          isNot(hasClassString('d')),
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
  });

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
