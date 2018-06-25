import 'dart:async';
import 'package:html/dom.dart' hide Node;
import 'package:html_builder/html_builder.dart';
import 'package:mariposa/mariposa.dart';
import 'package:tuple/tuple.dart';

/// A class that renders Mariposa widgets into a `package:html` [Document].
///
/// [DOMTester] exposes friendly API's that make it easy to test isomorphic Mariposa applications.
class DOMTester {
  /// The [RenderContext] context that all nodes are ultimately rendered against.
  final RenderContext renderContext = new RenderContext(null);

  /// The `package:html` that the tree is rendered into.
  final Document document = new Document.html('<html><body></body></html>');

  final Map<Element, List<Tuple2<DOMTesterElement, Widget>>> _elements = {};
  void Function() _rerender;

  /// Renders a UI that can then be interacted with.
  void render([Node Function() app]) {
    if (_rerender != null) {
      close();
      _rerender();
    } else if (app != null) {
      _rerender = () => _render(app);
      _rerender();
    }
  }

  /// Triggers an event in the [element].
  void fire(DOMTesterElement element, String eventName, [data]) {
    element._events
        .putIfAbsent(
            eventName, () => new StreamController.broadcast(sync: true))
        .add(data);
  }

  /// Returns a [Future] that completes when the [element] fires an event with the given [eventName].
  Future<T> nextEvent<T>(DOMTesterElement element, String eventName) {
    var c = new Completer<T>();
    StreamSubscription<T> sub;

    sub = element.listen<T>(
        eventName, (value) => c.isCompleted ? null : c.complete(value));

    sub.onDone(() => c.isCompleted
        ? null
        : c.completeError(new StateError(
            'The element was closed before an event was fired.')));

    sub.onError((e, st) => c.isCompleted ? null : c.completeError(e, st));
    return c.future;
  }

  Future close() => clear();

  /// Clears the DOM, deleting all elements.
  Future clear() async {
    for (var el in _elements.keys) {
      var tuples = _elements[el] ?? [];

      for (var tuple in tuples) {
        tuple.item2.beforeDestroy(tuple.item1);
        await tuple.item1.close();
      }
    }

    _elements.clear();

    for (var el in DOMTesterElement._cache.keys.toList()) {
      await DOMTesterElement._cache[el]?.close();
    }
  }

  /// Returns the first element with the given [id].
  DOMTesterElement getElementById(String id) {
    var el = document.getElementById(id);
    return el == null ? null : new DOMTesterElement(el);
  }

  /// Finds all elements with the given [classNames].
  Iterable<DOMTesterElement> getElementsByClassName(String classNames) {
    return document
        .getElementsByClassName(classNames)
        .map((el) => new DOMTesterElement(el));
  }

  /// Finds all elements with the given [tagNames].
  Iterable<DOMTesterElement> getElementsByTagName(String tagNames) {
    return document
        .getElementsByTagName(tagNames)
        .map((el) => new DOMTesterElement(el));
  }

  /// Returns the first element that matches the given [selector].
  DOMTesterElement querySelector(String selector) {
    var el = document.querySelector(selector);
    return el == null ? null : new DOMTesterElement(el);
  }

  /// Returns all elements that match the given [selector].
  Iterable<DOMTesterElement> querySelectorAll(String selector) {
    return document
        .querySelectorAll(selector)
        .map((el) => new DOMTesterElement(el));
  }

  void _render(Node Function() app) {
    _renderInner(app(), document.body, renderContext);
  }

  void _renderInner(Node node, Element target, RenderContext context) {
    if (node is Widget) {
      _renderWidget(node, target, context.createChild());
    } else {
      _renderNode(node, target, context.createChild());
    }
  }

  void _renderNode(Node node, Element target, RenderContext context) {
    if (node is TextNode) {
      target.append(new Text(node.text));
    } else {
      _compileAttributes(node.attributes, target.attributes);

      for (var child in node.children) {
        if (child is TextNode) {
          _renderNode(child, target, context.createChild());
        } else {
          var el = new Element.tag(child.tagName);
          target.append(el);
          _renderInner(child, el, context.createChild());
        }
      }
    }
  }

  void _renderWidget(Widget widget, Element target, RenderContext context) {
    var node = widget is ContextAwareWidget
        ? widget.contextAwareRender(context)
        : widget.render();
    _renderNode(node, target, context);

    var ref = new DOMTesterElement(target);
    widget is ContextAwareWidget
        ? widget.contextAwareAfterRender(context, ref)
        : widget.afterRender(ref);
    _elements.putIfAbsent(target, () => []).add(new Tuple2(ref, widget));
  }

  void _compileAttributes(Map props, Map<dynamic, String> out) {
    props.forEach((k, v) {
      if (v == null || v == false) return;

      if (v is Function)
        out[k] = v.toString();
      else if (v == true)
        out[k] = k;
      else if (v is List)
        out[k] = v.join(', ');
      else if (v is Map) {
        int i = 0;
        var b = v.keys.fold<StringBuffer>(new StringBuffer(), (out, k) {
          if (i++ > 0) out.write('; ');
          return out..write('$k: ${v[k]}');
        });
        out[k] = b.toString();
      } else
        out[k] = v.toString();
    });
  }
}

/// A wrapper around a `package:html` [Element].
class DOMTesterElement extends AbstractElement<dynamic, Element> {
  final Element nativeElement;

  static final Map<Element, DOMTesterElement> _cache = {};
  final Map<String, StreamController> _events = {};

  factory DOMTesterElement(Element nativeElement) => _cache.putIfAbsent(
      nativeElement, () => new DOMTesterElement._(nativeElement));

  DOMTesterElement._(this.nativeElement);

  @override
  Map<String, String> get attributes => nativeElement.attributes
      .map<String, String>((k, v) => new MapEntry(k.toString(), v));

  @override
  String get value => nativeElement.attributes['value'];

  @override
  void set value(String v) => nativeElement.attributes['value'] = v;

  @override
  Iterable<DOMTesterElement> get children =>
      nativeElement.children.map((el) => new DOMTesterElement(el));

  @override
  Future close() async {
    await Future.wait(children.map((el) => el.close()));
    _events.values.forEach((ctrl) => ctrl.close());
    _cache.remove(nativeElement);
  }

  @override
  StreamSubscription<U> listen<U>(
      String eventName, void Function(U event) callback) {
    return _events
        .putIfAbsent(
            eventName, () => new StreamController.broadcast(sync: true))
        .stream
        .cast<U>()
        .listen(callback);
  }

  @override
  DOMTesterElement get parent => nativeElement.parent == null
      ? null
      : new DOMTesterElement(nativeElement.parent);

  @override
  DOMTesterElement querySelector(String selectors) {
    var el = nativeElement.querySelector(selectors);
    return el == null ? null : new DOMTesterElement(el);
  }

  @override
  Iterable<DOMTesterElement> querySelectorAll(String selectors) {
    return nativeElement
        .querySelectorAll(selectors)
        .map((el) => new DOMTesterElement(el));
  }
}
