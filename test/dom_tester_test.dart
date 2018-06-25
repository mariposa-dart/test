import 'dart:async';
import 'package:html_builder/elements.dart';
import 'package:mariposa/mariposa.dart';
import 'package:mariposa_test/mariposa_test.dart';
import 'package:test/test.dart';

void main() {
  Completer afterRenderCompleter, beforeDestroyCompleter;
  DOMTester tester;
  DOMTesterElement h1Element;

  var app = () {
    return div(
      c: [
        h1(
          className: 'heading',
          p: {'id': 'foo'},
          c: [text('H1!!!')],
        ),
        new AfterRenderCompleterWidget(afterRenderCompleter),
        new BeforeDestroyCompleterWidget(beforeDestroyCompleter),
      ],
    );
  };

  setUp(() {
    afterRenderCompleter = new Completer();
    beforeDestroyCompleter = new Completer();
    tester = new DOMTester()..render(app);
    h1Element = tester.querySelector('h1');
    print(tester.document.outerHtml);
  });

  tearDown(() => tester.close());

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

  test('fire,nextEvent,listen', () async {
    var c = new Completer();
    var event = tester.nextEvent(h1Element, 'foo');
    h1Element.listen(
        'foo', (value) => c.isCompleted ? null : c.complete(value));
    tester.fire(h1Element, 'foo', 32);
    expect([await c.future, await event], everyElement(32));
  });

  test('widgets call afterRender', () {
    expect(afterRenderCompleter.isCompleted, true);
  });

  test('widgets call beforeDestroy', () async {
    await tester.clear();
    expect(beforeDestroyCompleter.isCompleted, true);
  });
}

class AfterRenderCompleterWidget extends Widget {
  final Completer completer;

  AfterRenderCompleterWidget(this.completer);

  @override
  Node render() => br();

  @override
  void afterRender(_) {
    print('after render!');
    completer.complete();
  }
}

class BeforeDestroyCompleterWidget extends Widget {
  final Completer completer;

  BeforeDestroyCompleterWidget(this.completer);

  @override
  Node render() => br();

  @override
  void beforeDestroy(_) {
    print('before destroy!');
    completer.complete();
  }
}
