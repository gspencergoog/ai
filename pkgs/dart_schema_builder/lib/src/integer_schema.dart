// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'schema.dart';
import 'json_type.dart';
import 'validation_error.dart';
import 'schema_validation.dart';

/// A JSON Schema definition for an [int].
extension type IntegerSchema.fromMap(Map<String, Object?> _value)
    implements Schema {
  factory IntegerSchema({
    // Core keywords
    String? title,
    String? description,
    // Number-specific keywords
    int? minimum,
    int? maximum,
    int? exclusiveMinimum,
    int? exclusiveMaximum,
    num? multipleOf,
  }) => IntegerSchema.fromMap({
    'type': JsonType.int.typeName,
    if (title != null) 'title': title,
    if (description != null) 'description': description,
    if (minimum != null) 'minimum': minimum,
    if (maximum != null) 'maximum': maximum,
    if (exclusiveMinimum != null) 'exclusiveMinimum': exclusiveMinimum,
    if (exclusiveMaximum != null) 'exclusiveMaximum': exclusiveMaximum,
    if (multipleOf != null) 'multipleOf': multipleOf,
  });

  int? get minimum => _value['minimum'] as int?;
  num? get maximum => _value['maximum'] as num?;
  num? get exclusiveMinimum => _value['exclusiveMinimum'] as num?;
  num? get exclusiveMaximum => _value['exclusiveMaximum'] as num?;
  num? get multipleOf => _value['multipleOf'] as num?;

  void validateInteger(
    int data,
    List<String> currentPath,
    HashSet<ValidationError> accumulatedFailures,
  ) {
    if (minimum case final min? when data < min) {
      accumulatedFailures.add(
        ValidationError(
          ValidationErrorType.minimumNotMet,
          path: currentPath,
          details: 'Value $data is less than the minimum of $min',
        ),
      );
    }
    if (maximum case final max? when data > max) {
      accumulatedFailures.add(
        ValidationError(
          ValidationErrorType.maximumExceeded,
          path: currentPath,
          details: 'Value $data is more than the maximum of $max',
        ),
      );
    }
    if (exclusiveMinimum case final exclusiveMin? when data <= exclusiveMin) {
      accumulatedFailures.add(
        ValidationError(
          ValidationErrorType.exclusiveMinimumNotMet,
          path: currentPath,
          details: 'Value $data is not greater than $exclusiveMin',
        ),
      );
    }
    if (exclusiveMaximum case final exclusiveMax? when data >= exclusiveMax) {
      accumulatedFailures.add(
        ValidationError(
          ValidationErrorType.exclusiveMaximumExceeded,
          path: currentPath,
          details: 'Value $data is not less than $exclusiveMax',
        ),
      );
    }
    if (multipleOf case final multOf? when multOf != 0) {
      final remainder = data / multOf;
      if (remainder.isInfinite || remainder.isNaN) {
        accumulatedFailures.add(
          ValidationError(
            ValidationErrorType.multipleOfInvalid,
            path: currentPath,
            details: 'Value $data is not a multiple of $multOf',
          ),
        );
      } else if ((remainder - remainder.truncate()).abs() > 1e-9) {
        accumulatedFailures.add(
          ValidationError(
            ValidationErrorType.multipleOfInvalid,
            path: currentPath,
            details: 'Value $data is not a multiple of $multOf',
          ),
        );
      }
    }
  }
}