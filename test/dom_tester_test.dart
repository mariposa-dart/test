import 'dart:async';
import 'package:html_builder/elements.dart';
import 'package:mariposa/mariposa.dart';
import 'package:mariposa_test/mariposa_test.dart';
import 'package:test/test.dart';

void main() {
  Completer afterRenderCompleter, beforeDestroyCompleter;
  DomTester tester;
  DomTesterElement h1Element;
  Node convertedH1Element;

  var app = () {
    return div(
      c: [
        h1(
          id: 'foo',
          className: 'heading',
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
    tester = new DomTester()..render(app);
    h1Element = tester.querySelector('h1');
    convertedH1Element = convertNode(h1Element.nativeElement);
    print(tester.document.outerHtml);
  });

  tearDown(() => tester.close());

  test('convertNode', () {
    expect(
      convertedH1Element,
      allOf(
        hasTagName('h1'),
        hasClassString('heading'),
        hasAttributes({'id': 'foo', 'class': 'heading'}),
        hasChildren(hasLength(1)),
      ),
    );
  });

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

  test('enqueues tasks', () {
    var buf = new StringBuffer();
    var tester = new DomTester();
    var app = () {
      return new TaskEnqueuingWidget(buf);
    };

    tester.render(app);
    print(buf);
    expect(buf.toString(), 'hello!');
  });
}

class TaskEnqueuingWidget extends ContextAwareWidget {
  static bool written = false;

  final StringBuffer buf;

  TaskEnqueuingWidget(this.buf);

  @override
  void contextAwareAfterRender(RenderContext context, AbstractElement element) {
    if (!written) {
      context.enqueue((_) {
        buf.write('hello!');
        written = true;
      });
    }
  }

  @override
  Node contextAwareRender(RenderContext context) {
    return div();
  }
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
