import 'dart:async';
import 'package:angel_container/angel_container.dart';
import 'package:html/dom.dart' hide Node;
import 'package:html/dom.dart' as html show Node;
import 'package:html_builder/html_builder.dart';
import 'package:mariposa/src/render_context_impl.dart';
import 'package:mariposa/mariposa.dart';
import 'package:tuple/tuple.dart';

/// Converts a `package:html` [node] into a `package:html_builder` [Node].
Node convertNode(html.Node node) {
  if (node is Text) {
    return new TextNode(node.data);
  } else if (node is Element) {
    return new NodeBuilder(node.localName)
        .changeAttributes(
            node.attributes.map((k, v) => new MapEntry(k.toString(), v)))
        .changeChildren(node.nodes.map(convertNode))
        .build();
  }

  throw new ArgumentError();
}

/// A class that renders Mariposa widgets into a `package:html` [Document].
///
/// [DomTester] exposes friendly API's that make it easy to test isomorphic Mariposa applications.
class DomTester {
  RenderContextImpl _renderContext;

  /// The `package:html` that the tree is rendered into.
  final Document document = new Document.html('<html><body></body></html>');

  final Map<Element, List<Tuple2<DomTesterElement, Widget>>> _elements = {};
  void Function() _rerender;

  DomTester({Reflector reflector: const EmptyReflector()}) {
    _renderContext = new RenderContextImpl(reflector);
  }

  /// The [RenderContext] context that all nodes are ultimately rendered against.
  RenderContext get renderContext => _renderContext;

  /// Renders a UI that can then be interacted with.
  void render([Node Function() app]) {
    if (_rerender != null) {
      close();
      _rerender();
    } else if (app != null) {
      _rerender = () => _render(app);
      _rerender();
    }

    if (_renderContext.tasks.isNotEmpty) {
      while (_renderContext.tasks.isNotEmpty) {
        _renderContext.tasks.removeFirst()(_renderContext);
      }

      _rerender();
    }
  }

  /// Triggers an event in the [element].
  void fire(DomTesterElement element, String eventName, [data]) {
    element._events
        .putIfAbsent(
            eventName, () => new StreamController.broadcast(sync: true))
        .add(data);
  }

  /// Returns a [Future] that completes when the [element] fires an event with the given [eventName].
  Future<T> nextEvent<T>(DomTesterElement element, String eventName) {
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

    for (var el in DomTesterElement._cache.keys.toList()) {
      await DomTesterElement._cache[el]?.close();
    }
  }

  /// Returns the first element with the given [id].
  DomTesterElement getElementById(String id) {
    var el = document.getElementById(id);
    return el == null ? null : new DomTesterElement(el);
  }

  /// Finds all elements with the given [classNames].
  Iterable<DomTesterElement> getElementsByClassName(String classNames) {
    return document
        .getElementsByClassName(classNames)
        .map((el) => new DomTesterElement(el));
  }

  /// Finds all elements with the given [tagNames].
  Iterable<DomTesterElement> getElementsByTagName(String tagNames) {
    return document
        .getElementsByTagName(tagNames)
        .map((el) => new DomTesterElement(el));
  }

  /// Returns the first element that matches the given [selector].
  DomTesterElement querySelector(String selector) {
    var el = document.querySelector(selector);
    return el == null ? null : new DomTesterElement(el);
  }

  /// Returns all elements that match the given [selector].
  Iterable<DomTesterElement> querySelectorAll(String selector) {
    return document
        .querySelectorAll(selector)
        .map((el) => new DomTesterElement(el));
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

    var ref = new DomTesterElement(target);
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
class DomTesterElement extends AbstractElement<dynamic, Element> {
  final Element nativeElement;

  static final Map<Element, DomTesterElement> _cache = {};
  final Map<String, StreamController> _events = {};

  factory DomTesterElement(Element nativeElement) => _cache.putIfAbsent(
      nativeElement, () => new DomTesterElement._(nativeElement));

  DomTesterElement._(this.nativeElement);

  @override
  Map<String, String> get attributes => nativeElement.attributes
      .map<String, String>((k, v) => new MapEntry(k.toString(), v));

  @override
  String get value => nativeElement.attributes['value'];

  @override
  void set value(String v) => nativeElement.attributes['value'] = v;

  @override
  Iterable<DomTesterElement> get children =>
      nativeElement.children.map((el) => new DomTesterElement(el));

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
  DomTesterElement get parent => nativeElement.parent == null
      ? null
      : new DomTesterElement(nativeElement.parent);

  @override
  DomTesterElement querySelector(String selectors) {
    var el = nativeElement.querySelector(selectors);
    return el == null ? null : new DomTesterElement(el);
  }

  @override
  Iterable<DomTesterElement> querySelectorAll(String selectors) {
    return nativeElement
        .querySelectorAll(selectors)
        .map((el) => new DomTesterElement(el));
  }
}
