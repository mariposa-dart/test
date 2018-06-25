import 'package:html_builder/html_builder.dart';
import 'package:mariposa/string.dart';
import 'package:matcher/matcher.dart';

/// Creates a simple renderer that renders HTML5 on one line, without a `DOCTYPE`.
StringRenderer createTestRenderer() => new StringRenderer(
    pretty: false, doctype: null, whitespace: '', html5: true);

/// Ensures that a [Node] has a tag name that matches the [matcher] (can also just be a String, which will be wrapped).
Matcher hasTagName(matcher) {
  return predicate(
    (value) {
      if (value is! Node) return false;
      var node = value as Node;
      return wrapMatcher(matcher).matches(node.tagName, {});
    },
    'has a tag name that matches $matcher',
  );
}

/// Ensures that a [Node] has attributes that match the [matcher] (can also just be a Map, which will be wrapped).
Matcher hasAttributes(matcher) {
  return predicate(
    (value) {
      if (value is! Node) return false;
      var node = value as Node;
      return wrapMatcher(matcher).matches(node.attributes, {});
    },
    'has attributes that match $matcher',
  );
}

/// Asserts a [matcher] against a [Node]'s `class` attribute.
Matcher hasClass(matcher) {
  return predicate(
    (value) {
      if (value is! Node) return false;
      var node = value as Node;
      return wrapMatcher(matcher).matches(node.attributes['class'], {});
    },
    'has a `class` that matches $matcher',
  );
}

/// Asserts a [matcher] against a [Node]'s `class` attribute, as a single [String].
Matcher hasClassString(matcher) {
  return predicate(
    (value) {
      if (value is! Node) return false;
      var node = value as Node;
      var clazz = node.attributes['class'];
      String clazzStr = clazz?.toString();

      if (clazz is Iterable) {
        clazzStr = clazz.map((s) => s.toString()).join(' ');
      }

      return wrapMatcher(matcher).matches(clazzStr, {});
    },
    'has a `class` string that matches $matcher',
  );
}

/// Asserts a [matcher] against a [Node]'s `class` attribute, as a `List<String>`.
Matcher hasClassList(matcher) {
  return predicate(
    (value) {
      if (value is! Node) return false;
      var node = value as Node;
      var clazz = node.attributes['class'];
      List<String> classList = [];

      if (clazz is Iterable) {
        classList.addAll(clazz.map((s) => s.toString()));
      } else if (clazz is String) {
        classList.addAll(clazz.split(' '));
      }

      return wrapMatcher(matcher).matches(classList, {});
    },
    'has a `class` list that matches $matcher',
  );
}

/// Ensures that a [Node] has children that match the [matcher] (can also just be a List, which will be wrapped).
Matcher hasChildren(matcher) {
  return predicate(
    (value) {
      if (value is! Node) return false;
      var node = value as Node;
      return wrapMatcher(matcher).matches(node.children, {});
    },
    'has children that match $matcher',
  );
}

/// Ensures that a [Node] produces a given output, which may be a [Matcher] or [String].
///
/// Typically, prefer to use [rendersEqualTo].
///
/// [createRenderer] is forwarded to [render] from `package:mariposa/string.dart`.
Matcher rendersTo(matcher, {StringRenderer Function() createRenderer}) {
  createRenderer ??= createTestRenderer;
  return predicate(
    (value) {
      if (value is! Node) return false;
      var node = value as Node;
      var contents = render(() => node, createRenderer: createRenderer);
      return wrapMatcher(matcher).matches(contents, {});
    },
    'renders to $matcher',
  );
}

/// Ensures that a [Node] produces the exact same output as another [node].
///
/// [createRenderer] is forwarded to [render] from `package:mariposa/string.dart`.
Matcher rendersEqualTo(Node node, {StringRenderer Function() createRenderer}) {
  createRenderer ??= createTestRenderer;
  return predicate(
    (value) {
      if (value is! Node) return false;
      var thisNode = value as Node;
      var thisContents = render(() => thisNode, createRenderer: createRenderer);
      var thatContents = render(() => node, createRenderer: createRenderer);
      return equals(thisContents).matches(thatContents, {});
    },
    'renders to the same HTML as $node',
  );
}
