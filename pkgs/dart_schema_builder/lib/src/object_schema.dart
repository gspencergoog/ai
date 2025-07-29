// Copyright (c) 2025, the Dart project authors  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'schema.dart';
import 'constants.dart';
import 'json_type.dart';
import 'validation_error.dart';
import 'schema_validation.dart';

/// A JSON Schema definition for an object with properties.
///
/// See https://json-schema.org/understanding-json-schema/reference/object.html
extension type ObjectSchema.fromMap(Map<String, Object?> _value)
    implements Schema {
  factory ObjectSchema({
    // Core keywords
    String? title,
    String? description,
    // Object-specific keywords
    Map<String, Schema>? properties,
    Map<String, Schema>? patternProperties,
    List<String>? required,
    Map<String, List<String>>? dependentRequired,
    Object? additionalProperties,
    Object? unevaluatedProperties,
    Schema? propertyNames,
    int? minProperties,
    int? maxProperties,
  }) => ObjectSchema.fromMap({
    'type': JsonType.object.typeName,
    if (title != null) 'title': title,
    if (description != null) 'description': description,
    if (properties != null) 'properties': properties,
    if (patternProperties != null) 'patternProperties': patternProperties,
    if (required != null) 'required': required,
    if (dependentRequired != null) 'dependentRequired': dependentRequired,
    if (additionalProperties != null)
      'additionalProperties': additionalProperties,
    if (unevaluatedProperties != null)
      'unevaluatedProperties': unevaluatedProperties,
    if (propertyNames != null) 'propertyNames': propertyNames,
    if (minProperties != null) 'minProperties': minProperties,
    if (maxProperties != null) 'maxProperties': maxProperties,
  });

  Map<String, Schema>? get properties => mapToSchemaOrBool(kProperties);
  Map<String, Schema>? get patternProperties =>
      mapToSchemaOrBool(kPatternProperties);
  List<String>? get required => (_value[kRequired] as List?)?.cast<String>();
  Map<String, List<String>>? get dependentRequired {
    final value = _value[kDependentRequired];
    if (value is Map) {
      return value.map(
        (key, value) => MapEntry(key as String, (value as List).cast<String>()),
      );
    }
    return null;
  }

  Map<String, Schema>? get dependentSchemas =>
      mapToSchemaOrBool(kDependentSchemas);

  Object? get additionalProperties => schemaOrBool(kAdditionalProperties);
  Object? get unevaluatedProperties => schemaOrBool(kUnevaluatedProperties);
  Schema? get propertyNames => schemaOrBool(kPropertyNames);
  int? get minProperties => (_value[kMinProperties] as num?)?.toInt();
  int? get maxProperties => (_value[kMaxProperties] as num?)?.toInt();
}