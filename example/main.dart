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
}
