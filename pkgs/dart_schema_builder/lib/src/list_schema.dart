// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'package:collection/collection.dart';
import 'schema.dart';
import 'constants.dart';
import 'json_type.dart';
import 'validation_error.dart';
import 'utils.dart';
import 'schema_validation.dart';

/// A JSON Schema definition for a [List].
extension type ListSchema.fromMap(Map<String, Object?> _value)
    implements Schema {
  factory ListSchema({
    // Core keywords
    String? title,
    String? description,
    // List-specific keywords
    Schema? items,
    List<Schema>? prefixItems,
    Object? unevaluatedItems,
    Schema? contains,
    int? minContains,
    int? maxContains,
    int? minItems,
    int? maxItems,
    bool? uniqueItems,
  }) => ListSchema.fromMap({
    'type': JsonType.list.typeName,
    if (title != null) 'title': title,
    if (description != null) 'description': description,
    if (items != null) 'items': items,
    if (prefixItems != null) 'prefixItems': prefixItems,
    if (unevaluatedItems != null) 'unevaluatedItems': unevaluatedItems,
    if (contains != null) 'contains': contains,
    if (minContains != null) 'minContains': minContains,
    if (maxContains != null) 'maxContains': maxContains,
    if (minItems != null) 'minItems': minItems,
    if (maxItems != null) 'maxItems': maxItems,
    if (uniqueItems != null) 'uniqueItems': uniqueItems,
  });

  Schema? get items => schemaOrBool(kItems);
  List<Object?>? get prefixItems {
    final items = _value[kPrefixItems] as List?;
    if (items == null) return null;
    return items.map((item) {
      if (item is bool) return item;
      return Schema.fromMap(item as Map<String, Object?>);
    }).toList();
  }
  Object? get unevaluatedItems => schemaOrBool(kUnevaluatedItems);
  Schema? get contains => schemaOrBool(kContains);
  int? get minContains => (_value[kMinContains] as num?)?.toInt();
  int? get maxContains => (_value[kMaxContains] as num?)?.toInt();
  int? get minItems => (_value[kMinItems] as num?)?.toInt();
  int? get maxItems => (_value[kMaxItems] as num?)?.toInt();
  bool? get uniqueItems => _value[kUniqueItems] as bool?;
}