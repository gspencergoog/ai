// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'boolean_schema.dart';
import 'constants.dart';
import 'integer_schema.dart';
import 'json_type.dart';
import 'list_schema.dart';
import 'null_schema.dart';
import 'number_schema.dart';
import 'object_schema.dart';
import 'string_schema.dart';
import 'schema_validation.dart';

export 'boolean_schema.dart';
export 'constants.dart';
export 'integer_schema.dart';
export 'json_type.dart';
export 'list_schema.dart';
export 'null_schema.dart';
export 'number_schema.dart';
export 'object_schema.dart';
export 'string_schema.dart';
export 'validation_error.dart';
export 'schema_validation.dart';

/// A JSON Schema object defining any kind of property.
///
/// See https://json-schema.org/draft/2020-12/json-schema-core.html for the full
/// specification.
///
/// **Note:** Only a subset of the json schema spec is supported by these types,
/// if you need something more complex you can create your own
/// `Map<String, Object?>` and cast it to [Schema] (or a subtype) directly.
extension type Schema.fromMap(Map<String, Object?> _value) {
  /// A combined schema, see
  /// https://json-schema.org/understanding-json-schema/reference/combining#schema-composition
  factory Schema.combined({
    // Core keywords
    Object? type,
    List<Object?>? enumValues,
    Object? constValue,
    String? title,
    String? description,
    String? $comment,
    Object? defaultValue,
    List<Object?>? examples,
    bool? deprecated,
    bool? readOnly,
    bool? writeOnly,
    Map<String, Schema>? $defs,
    String? $ref,
    String? $dynamicRef,
    String? $anchor,
    String? $dynamicAnchor,
    String? $id,
    String? $id,

    // Schema composition
    List<Object?>? allOf,
    List<Object?>? anyOf,
    List<Object?>? oneOf,
    Object? not,

    // Conditional subschemas
    Object? ifSchema,
    Object? thenSchema,
    Object? elseSchema,
    Map<String, Schema>? dependentSchemas,
  }) {
    final typeValue = switch (type) {
      JsonType() => type.typeName,
      List<JsonType>() => type.map((t) => t.typeName).toList(),
      _ => null,
    };
    return Schema.fromMap({
      if (typeValue != null) 'type': typeValue,
      if (enumValues != null) 'enum': enumValues,
      if (constValue != null) 'const': constValue,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if ($comment != null) '\$comment': $comment,
      if (defaultValue != null) 'default': defaultValue,
      if (examples != null) 'examples': examples,
      if (deprecated != null) 'deprecated': deprecated,
      if (readOnly != null) 'readOnly': readOnly,
      if (writeOnly != null) 'writeOnly': writeOnly,
      if ($defs != null) kDefs: $defs,
      if ($ref != null) kRef: $ref,
      if ($dynamicAnchor != null) kDynamicAnchor: $dynamicAnchor,
      if ($id != null) '\$id': $id,
      if ($id != null) '\$id': $id,
      if (allOf != null) 'allOf': allOf,
      if (anyOf != null) 'anyOf': anyOf,
      if (oneOf != null) 'oneOf': oneOf,
      if (not != null) 'not': not,
      if (ifSchema != null) 'if': ifSchema,
      if (thenSchema != null) 'then': thenSchema,
      if (elseSchema != null) 'else': elseSchema,
      if (dependentSchemas != null) 'dependentSchemas': dependentSchemas,
    });
  }

  /// Alias for [StringSchema.new].
  static const string = StringSchema.new;

  /// Alias for [BooleanSchema.new].
  static const boolean = BooleanSchema.new;

  /// Alias for [NumberSchema.new].
  static const num = NumberSchema.new;

  /// Alias for [IntegerSchema.new].
  static const int = IntegerSchema.new;

  /// Alias for [ListSchema.new].
  static const list = ListSchema.new;

  /// Alias for [ObjectSchema.new].
  static const object = ObjectSchema.new;

  /// Alias for [NullSchema.new].
  static const nil = NullSchema.new;

  factory Schema.fromBoolean(bool value, {List<String> jsonPath = const []}) {
    return Schema.fromMap(
      value ? {} : {'not': {}},
    );
  }

  Map<String, Object?> get value => _value;

  Object? operator [](String key) => _value[key];

  // Core Keywords
  Object? get type => _value['type'];
  List<Object?>? get enumValues => (_value['enum'] as List?)?.cast<Object?>();
  Object? get constValue => _value['const'];
  String? get title => _value['title'] as String?;
  String? get description => _value['description'] as String?;
  String? get $comment => _value['\$comment'] as String?;
  Object? get defaultValue => _value['default'];
  List<Object?>? get examples => (_value['examples'] as List?)?.cast<Object?>();
  bool? get deprecated => _value['deprecated'] as bool?;
  bool? get readOnly => _value['readOnly'] as bool?;
  bool? get writeOnly => _value['writeOnly'] as bool?;
  Map<String, Schema>? get $defs =>
      (_value[kDefs] as Map?)?.cast<String, Schema>();
  String? get $ref => _value[kRef] as String?;
  String? get $dynamicRef => _value[kDynamicRef] as String?;
  String? get $anchor => _value[kAnchor] as String?;
  String? get $dynamicAnchor => _value[kDynamicAnchor] as String?;
  String? get $id => _value['\$id'] as String?;
  String? get $id => _value['\$id'] as String?;

  // Schema Composition
  List<Object?>? get allOf => (_value['allOf'] as List?)?.cast<Object?>();
  List<Object?>? get anyOf => (_value['anyOf'] as List?)?.cast<Object?>();
  List<Object?>? get oneOf => (_value['oneOf'] as List?)?.cast<Object?>();
  Object? get not => _value['not'];

  // Conditional Subschemas
  Object? get ifSchema => _value['if'];
  Object? get thenSchema => _value['then'];
  Object? get elseSchema => _value['else'];
  Map<String, Schema>? get dependentSchemas =>
      (_value['dependentSchemas'] as Map?)?.cast<String, Schema>();
}
