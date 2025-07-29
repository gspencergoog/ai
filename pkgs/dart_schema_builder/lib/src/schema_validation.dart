// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'package:collection/collection.dart';
import 'schema.dart';
import 'utils.dart';
import 'validation_error.dart';
import 'json_type.dart';
import 'object_schema.dart';
import 'list_schema.dart';
import 'string_schema.dart';
import 'number_schema.dart';

class ValidationContext {
  final Schema rootSchema;
  final bool strictFormat;
  final List<Schema> dynamicScope;

  ValidationContext(
    this.rootSchema, {
    this.strictFormat = false,
  }) : dynamicScope = [rootSchema];
}

void validateSubSchema(
  Object? schema,
  Object? data,
  List<String> currentPath,
  HashSet<ValidationError> accumulatedFailures,
  ValidationContext context,
) {
  if (schema is bool) {
    if (schema == false) {
      accumulatedFailures.add(
        ValidationError(
          ValidationErrorType.custom,
          path: currentPath,
          details: 'Schema is false',
        ),
      );
    }
    // If schema is true, it's always valid, so do nothing.
    return;
  }
  if (schema is Map) {
    Schema.fromMap(
      schema.cast<String, Object?>(),
    ).validateSchema(data, currentPath, accumulatedFailures, context);
    return;
  }
  // This should not happen for a valid schema file.
}

extension SchemaValidation on Schema {
  Schema? schemaOrBool(String key) {
    final v = value[key];
    if (v == null) return null;
    if (v is bool) {
      return Schema.fromBoolean(v, jsonPath: [key]);
    }
    return Schema.fromMap(v as Map<String, Object?>);
  }

  Map<String, Schema>? mapToSchema(String key) {
    final v = value[key];
    if (v is Map) {
      return v.map(
        (key, value) => MapEntry(
          key as String,
          Schema.fromMap(value as Map<String, Object?>),
        ),
      );
    }
    return null;
  }

  Map<String, Schema>? mapToSchemaOrBool(String key) {
    final v = value[key];
    if (v is Map) {
      return v.map(
        (key, value) {
          if (value is bool) {
            return MapEntry(
              key as String,
              Schema.fromBoolean(value),
            );
          }
          return MapEntry(
            key as String,
            Schema.fromMap(value as Map<String, Object?>),
          );
        },
      );
    }
    return null;
  }

  /// Validates the given [data] against this schema.
  ///
  /// Returns a list of [ValidationError] if validation fails,
  /// or an empty list if validation succeeds.
  List<ValidationError> validate(Object? data, {bool strictFormat = false}) {
    final failures = createHashSet();
    final context = ValidationContext(this, strictFormat: strictFormat);
    validateSchema(data, [], failures, context);
    return failures.toList();
  }

  void validateSchema(
    Object? data,
    List<String> currentPath,
    HashSet<ValidationError> accumulatedFailures,
    ValidationContext context,
  ) {
    context.dynamicScope.add(this);

    if ($dynamicRef case final ref?) {
      final referencedSchema = resolveDynamicRef(ref, context.dynamicScope);
      if (referencedSchema != null) {
        referencedSchema.validateSchema(
          data,
          currentPath,
          accumulatedFailures,
          context,
        );
      }
      context.dynamicScope.removeLast();
      return;
    }

    if ($ref case final ref?) {
      final referencedSchema = resolveRef(ref, context.rootSchema);
      if (referencedSchema != null) {
        referencedSchema.validateSchema(
          data,
          currentPath,
          accumulatedFailures,
          context,
        );
      } else {
        accumulatedFailures.add(
          ValidationError(
            ValidationErrorType.refResolutionError,
            path: currentPath,
            details: 'Failed to resolve reference: $ref',
          ),
        );
      }
      context.dynamicScope.removeLast();
      return;
    }

    // 1. Conditional Applicators: if/then/else
    if (ifSchema case final ifS?) {
      final tempFailures = createHashSet();
      validateSubSchema(ifS, data, currentPath, tempFailures, context);
      if (tempFailures.isEmpty) {
        if (thenSchema case final thenS?) {
          validateSubSchema(
            thenS,
            data,
            currentPath,
            accumulatedFailures,
            context,
          );
        }
      } else {
        if (elseSchema case final elseS?) {
          validateSubSchema(
            elseS,
            data,
            currentPath,
            accumulatedFailures,
            context,
          );
        }
      }
    }

    // 2. Schema Combiners: allOf, anyOf, oneOf, not
    if (allOf case final List allOfList?) {
      for (final subSchema in allOfList) {
        final tempFailures = createHashSet();
        validateSubSchema(
          subSchema,
          data,
          currentPath,
          tempFailures,
          context,
        );
        accumulatedFailures.addAll(tempFailures);
      }
    }

    if (anyOf case final List anyOfList?) {
      var passedCount = 0;
      for (final subSchema in anyOfList) {
        final tempFailures = createHashSet();
        validateSubSchema(
          subSchema,
          data,
          currentPath,
          tempFailures,
          context,
        );
        if (tempFailures.isEmpty) {
          passedCount++;
        }
      }
      if (passedCount == 0) {
        accumulatedFailures.add(
          ValidationError(ValidationErrorType.anyOfNotMet, path: currentPath),
        );
      }
    }

    if (oneOf case final List oneOfList?) {
      var passedCount = 0;
      for (final subSchema in oneOfList) {
        final tempFailures = createHashSet();
        validateSubSchema(
          subSchema,
          data,
          currentPath,
          tempFailures,
          context,
        );
        if (tempFailures.isEmpty) {
          passedCount++;
        }
      }
      if (passedCount != 1) {
        accumulatedFailures.add(
          ValidationError(
            ValidationErrorType.oneOfNotMet,
            path: currentPath,
            details:
                'Expected to match exactly one schema, but matched '
                '$passedCount',
          ),
        );
      }
    }

    if (not case final notSchema?) {
      final tempFailures = createHashSet();
      validateSubSchema(
        notSchema,
        data,
        currentPath,
        tempFailures,
        context,
      );
      if (tempFailures.isEmpty) {
        accumulatedFailures.add(
          ValidationError(
            ValidationErrorType.notConditionViolated,
            path: currentPath,
          ),
        );
      }
    }

    // 3. Generic Validation Keywords
    if (constValue case final constV?) {
      if (!deepEquals(data, constV)) {
        accumulatedFailures.add(
          ValidationError(
            ValidationErrorType.constMismatch,
            path: currentPath,
            details: 'Value does not match const value $constV',
          ),
        );
      }
    }

    if (enumValues case final enumV?) {
      if (!enumV.any((e) => deepEquals(data, e))) {
        accumulatedFailures.add(
          ValidationError(
            ValidationErrorType.enumValueNotAllowed,
            path: currentPath,
            details: 'Value is not one of the allowed enum values',
          ),
        );
      }
    }

    // 4. Type-Specific Validation
    validateTypeSpecificKeywords(data, currentPath, accumulatedFailures, context);
    context.dynamicScope.removeLast();
  }

  void validateTypeSpecificKeywords(
    Object? data,
    List<String> currentPath,
    HashSet<ValidationError> accumulatedFailures,
    ValidationContext context,
  ) {
    final actualType = getJsonType(data);

    // First, validate against the `type` keyword if it exists.
    final typeValue = type;
    if (typeValue != null) {
      final types = switch (typeValue) {
        String() => [
          JsonType.values.firstWhere((t) => t.typeName == typeValue),
        ],
        List() =>
          typeValue
              .map((t) => JsonType.values.firstWhere((e) => e.typeName == t))
              .toList(),
        _ => <JsonType>[],
      };

      if (types.isNotEmpty) {
        if (types.contains(JsonType.num) && actualType == JsonType.int) {
          // Integers are valid numbers.
        } else if (!types.contains(actualType)) {
          accumulatedFailures.add(
            ValidationError.typeMismatch(
              path: currentPath,
              expectedType: types.map((t) => t.typeName).join(' or '),
              actualValue: data,
            ),
          );
          // If type doesn't match, no point in running other type-specific
          // validations
          return;
        }
      }
    }

    // Now, apply keywords based on the actual type of the data.
    switch (actualType) {
      case JsonType.object:
        (this as ObjectSchema).validateObject(
          data as Map<String, Object?>,
          currentPath,
          accumulatedFailures,
          context,
        );
        break;
      case JsonType.list:
        (this as ListSchema).validateList(
          data as List,
          currentPath,
          accumulatedFailures,
          context,
        );
        break;
      case JsonType.string:
        (this as StringSchema).validateString(
          data as String,
          currentPath,
          accumulatedFailures,
          strictFormat: context.strictFormat,
        );
        break;
      case JsonType.num:
        (this as NumberSchema).validateNumber(
          data as num,
          currentPath,
          accumulatedFailures,
        );
        break;
      case JsonType.int:
        (this as IntegerSchema).validateInteger(
          (data as num).toInt(),
          currentPath,
          accumulatedFailures,
        );
        break;
      case JsonType.boolean:
      case JsonType.nil:
        // No specific keywords for bool or null besides generic ones.
        break;
    }
  }

  void validateObject(
    Map<String, Object?> data,
    List<String> currentPath,
    HashSet<ValidationError> accumulatedFailures,
    ValidationContext context,
  ) {
    final objectSchema = this as ObjectSchema;
    if (objectSchema.minProperties case final min? when data.keys.length < min) {
      accumulatedFailures.add(
        ValidationError(
          ValidationErrorType.minPropertiesNotMet,
          path: currentPath,
          details:
              'There should be at least $min properties. Only '
              '${data.keys.length} were found',
        ),
      );
    }

    if (objectSchema.maxProperties case final max? when data.keys.length > max) {
      accumulatedFailures.add(
        ValidationError(
          ValidationErrorType.maxPropertiesExceeded,
          path: currentPath,
          details: 'Exceeded maxProperties limit of $max (${data.keys.length})',
        ),
      );
    }

    for (final reqProp in objectSchema.required ?? const []) {
      if (!data.containsKey(reqProp)) {
        accumulatedFailures.add(
          ValidationError(
            ValidationErrorType.requiredPropertyMissing,
            path: currentPath,
            details: 'Required property "$reqProp" is missing',
          ),
        );
      }
    }

    if (objectSchema.dependentRequired case final dr?) {
      for (final entry in dr.entries) {
        if (data.containsKey(entry.key)) {
          for (final requiredProp in entry.value) {
            if (!data.containsKey(requiredProp)) {
              accumulatedFailures.add(
                ValidationError(
                  ValidationErrorType.dependentRequiredMissing,
                  path: currentPath,
                  details:
                      'Property "$requiredProp" is required because property '
                      '"${entry.key}" is present.',
                ),
              );
            }
          }
        }
      }
    }

    if (objectSchema.dependentSchemas case final ds?) {
      for (final entry in ds.entries) {
        if (data.containsKey(entry.key)) {
          validateSubSchema(
            entry.value,
            data,
            currentPath,
            accumulatedFailures,
            context,
          );
        }
      }
    }

    final evaluatedKeys = <String>{};
    if (objectSchema.properties case final props?) {
      for (final entry in props.entries) {
        if (data.containsKey(entry.key)) {
          currentPath.add(entry.key);
          evaluatedKeys.add(entry.key);
          entry.value.validateSchema(
            data[entry.key],
            currentPath,
            accumulatedFailures,
            context,
          );
          currentPath.removeLast();
        }
      }
    }

    if (objectSchema.patternProperties case final patternProps?) {
      for (final entry in patternProps.entries) {
        final pattern = RegExp(entry.key);
        for (final dataKey in data.keys) {
          if (pattern.hasMatch(dataKey)) {
            currentPath.add(dataKey);
            evaluatedKeys.add(dataKey);
            entry.value.validateSchema(
              data[dataKey],
              currentPath,
              accumulatedFailures,
              context,
            );
            currentPath.removeLast();
          }
        }
      }
    }

    if (objectSchema.propertyNames case final propNamesSchema?) {
      for (final key in data.keys) {
        propNamesSchema.validateSchema(
          key,
          currentPath,
          accumulatedFailures,
          context,
        );
      }
    }

    for (final dataKey in data.keys) {
      if (evaluatedKeys.contains(dataKey)) continue;

      if (objectSchema.additionalProperties case final ap?) {
        currentPath.add(dataKey);
        if (ap is bool && !ap) {
          accumulatedFailures.add(
            ValidationError(
              ValidationErrorType.additionalPropertyNotAllowed,
              path: currentPath,
              details: 'Additional property "$dataKey" is not allowed',
            ),
          );
        } else if (ap is Schema) {
          (ap as Schema).validateSchema(
            data[dataKey],
            currentPath,
            accumulatedFailures,
            context,
          );
        }
        currentPath.removeLast();
      } else if (objectSchema[kUnevaluatedProperties] case final up?) {
        currentPath.add(dataKey);
        if (up is bool && !up) {
          accumulatedFailures.add(
            ValidationError(
              ValidationErrorType.unevaluatedPropertyNotAllowed,
              path: currentPath,
              details: 'Unevaluated property "$dataKey" is not allowed',
            ),
          );
        } else if (up is Map) {
          Schema.fromMap(up.cast<String, Object?>()).validateSchema(
            data[dataKey],
            currentPath,
            accumulatedFailures,
            context,
          );
        }
        currentPath.removeLast();
      }
    }
  }

  void validateList(
    List data,
    List<String> currentPath,
    HashSet<ValidationError> accumulatedFailures,
    ValidationContext context,
  ) {
    final listSchema = this as ListSchema;
    if (listSchema.minItems case final min? when data.length < min) {
      accumulatedFailures.add(
        ValidationError(
          ValidationErrorType.minItemsNotMet,
          path: currentPath,
          details: 'List has ${data.length} items, but must have at least $min',
        ),
      );
    }

    if (listSchema.maxItems case final max? when data.length > max) {
      accumulatedFailures.add(
        ValidationError(
          ValidationErrorType.maxItemsExceeded,
          path: currentPath,
          details:
              'List has ${data.length} items, but must have less than $max',
        ),
      );
    }

    if (listSchema.uniqueItems == true) {
      final seenItems = HashSet<Object?>(
        equals: deepEquals,
        hashCode: deepHashCode,
      );
      for (final item in data) {
        if (!seenItems.add(item)) {
          accumulatedFailures.add(
            ValidationError(
              ValidationErrorType.uniqueItemsViolated,
              path: currentPath,
              details: 'List contains duplicate items',
            ),
          );
          break; // Found a duplicate, no need to check further.
        }
      }
    }

    final evaluatedItems = List<bool>.filled(data.length, false);
    if (listSchema.contains case final containsSchema?) {
      final matches = <int>[];
      for (var i = 0; i < data.length; i++) {
        final tempFailures = createHashSet();
        validateSubSchema(
          containsSchema,
          data[i],
          currentPath,
          tempFailures,
          context,
        );
        if (tempFailures.isEmpty) {
          matches.add(i);
        }
      }

      // From the spec: "The annotation result of "contains" is a boolean. If
      // any item in the array validates against the subschema, the annotation
      // result is true, otherwise it is false."
      // And for unevaluatedItems: "The items that have been evaluated during
      // the application of "prefixItems", "items", and "contains" are
      // tracked."
      // This implies that if contains is present, all items that match it are
      // considered evaluated.
      for (final index in matches) {
        evaluatedItems[index] = true;
      }

      final matchCount = matches.length;
      if (listSchema.minContains == 0 && data.isEmpty) {
        // This is a valid case.
      } else if (matchCount == 0 && (listSchema.minContains == null || listSchema.minContains! > 0)) {
        accumulatedFailures.add(
          ValidationError(
            ValidationErrorType.containsInvalid,
            path: currentPath,
            details: 'Array does not contain a valid item',
          ),
        );
      }
      if (listSchema.minContains case final min? when matchCount < min) {
        accumulatedFailures.add(
          ValidationError(
            ValidationErrorType.minContainsNotMet,
            path: currentPath,
            details:
                'Array must contain at least $min valid items, but found '
                '$matchCount',
          ),
        );
      }
      if (listSchema.maxContains case final max? when matchCount > max) {
        accumulatedFailures.add(
          ValidationError(
            ValidationErrorType.maxContainsExceeded,
            path: currentPath,
            details:
                'Array must contain at most $max valid items, but found '
                '$matchCount',
          ),
        );
      }
    }

    if (listSchema.prefixItems case final pItems?) {
      for (var i = 0; i < pItems.length && i < data.length; i++) {
        evaluatedItems[i] = true;
        currentPath.add(i.toString());
        validateSubSchema(
          pItems[i],
          data[i],
          currentPath,
          accumulatedFailures,
          context,
        );
        currentPath.removeLast();
      }
    }
    if (listSchema.items case final itemSchema?) {
      final startIndex = listSchema.prefixItems?.length ?? 0;
      for (var i = startIndex; i < data.length; i++) {
        evaluatedItems[i] = true;
        currentPath.add(i.toString());
        validateSubSchema(
          itemSchema,
          data[i],
          currentPath,
          accumulatedFailures,
          context,
        );
        currentPath.removeLast();
      }
    }
    if (listSchema.unevaluatedItems case final ui?) {
      for (var i = 0; i < data.length; i++) {
        if (!evaluatedItems[i]) {
          currentPath.add(i.toString());
          if (ui is bool && !ui) {
            accumulatedFailures.add(
              ValidationError(
                ValidationErrorType.unevaluatedItemNotAllowed,
                path: currentPath,
                details: 'Unevaluated item in list at index $i',
              ),
            );
          } else if (ui is Schema) {
            (ui as Schema).validateSchema(
              data[i],
              currentPath,
              accumulatedFailures,
              context,
            );
          }
          currentPath.removeLast();
        }
      }
    }
  }

  JsonType getJsonType(Object? data) {
    if (data is Map) return JsonType.object;
    if (data is List) return JsonType.list;
    if (data is String) return JsonType.string;
    if (data is int) return JsonType.int;
    if (data is num) {
      if (data is int || data.remainder(1) == 0) {
        return JsonType.int;
      }
      return JsonType.num;
    }
    if (data is bool) return JsonType.boolean;
    if (data == null) return JsonType.nil;
    // This should not happen for valid JSON data..
    throw StateError('Unknown JSON type for value: $data');
  }

  Schema? resolveRef(String ref, Schema rootSchema) {
    if (!ref.startsWith('#')) {
      // For now, only support local refs.
      return _findId(ref, rootSchema);
    }
    final pointer = ref.substring(1);
    if (pointer.isEmpty) {
      return rootSchema;
    }
    if (!pointer.startsWith('/')) {
      // It's an anchor.
      return _findAnchor(pointer, rootSchema);
    }

    final parts = pointer.substring(1).split('/');
    dynamic current = rootSchema;
    for (final part in parts) {
      final decodedPart =
          part.replaceAll('~1', '/').replaceAll('~0', '~');
      if (current is Schema) {
        if (!current.value.containsKey(decodedPart)) {
          return null;
        }
        current = current.value[decodedPart];
      } else if (current is Map && current.containsKey(decodedPart)) {
        current = current[decodedPart];
      } else if (current is List && int.tryParse(decodedPart) != null) {
        final index = int.parse(decodedPart);
        if (index < current.length) {
          current = current[index];
        } else {
          return null;
        }
      } else {
        return null;
      }
    }
    if (current is Schema) {
      return current;
    } else if (current is Map) {
      return Schema.fromMap(current as Map<String, Object?>);
    }
    return null;
  }

  Schema? _findId(String id, Schema schema) {
    Schema? result;
    final visited = <Map<String, Object?>>{};

    void visit(dynamic current) {
      if (result != null) return;
      if (current is Map<String, Object?>) {
        if (visited.contains(current)) return;
        visited.add(current);

        final currentSchema = Schema.fromMap(current);
        if (currentSchema.$id == id) {
          result = currentSchema;
          return;
        }
        for (final value in current.values) {
          visit(value);
        }
      } else if (current is List) {
        for (final item in current) {
          visit(item);
        }
      }
    }

    visit(schema.value);
    return result;
  }

  Schema? _findAnchor(String anchorName, Schema schema) {
    Schema? result;
    final visited = <Map<String, Object?>>{};

    void visit(dynamic current) {
      if (result != null) return;
      if (current is Map<String, Object?>) {
        if (visited.contains(current)) return;
        visited.add(current);

        final currentSchema = Schema.fromMap(current);
        if (currentSchema.$anchor == anchorName ||
            currentSchema.$dynamicAnchor == anchorName) {
          result = currentSchema;
          return;
        }
        for (final value in current.values) {
          visit(value);
        }
      } else if (current is List) {
        for (final item in current) {
          visit(item);
        }
      }
    }

    visit(schema.value);
    return result;
  }

  Schema? resolveDynamicRef(String ref, List<Schema> dynamicScope) {
    if (!ref.startsWith('#')) {
      // For now, only support local refs.
      return null;
    }
    final pointer = ref.substring(1);
    if (pointer.isEmpty) {
      return dynamicScope.last;
    }
    if (!pointer.startsWith('/')) {
      // It's a dynamic anchor.
      final anchorSchema = _findDynamicAnchor(pointer, dynamicScope);
      if (anchorSchema != null) {
        return anchorSchema;
      }
    }
    // Fallback to normal $ref resolution against the root schema.
    return resolveRef(ref, dynamicScope.first);
  }

  Schema? _findDynamicAnchor(String anchorName, List<Schema> dynamicScope) {
    for (final schema in dynamicScope.reversed) {
      final found = _findDynamicAnchorInSchema(anchorName, schema);
      if (found != null) {
        return found;
      }
    }
    return null;
  }

  Schema? _findDynamicAnchorInSchema(String anchorName, Schema schema) {
    Schema? result;
    final visited = <Map<String, Object?>>{};

    void visit(dynamic current) {
      if (result != null) return;
      if (current is Map<String, Object?>) {
        if (visited.contains(current)) return;
        visited.add(current);

        final currentSchema = Schema.fromMap(current);
        if (currentSchema.$dynamicAnchor == anchorName) {
          result = currentSchema;
          return;
        }
        for (final value in current.values) {
          visit(value);
        }
      } else if (current is List) {
        for (final item in current) {
          visit(item);
        }
      }
    }

    visit(schema.value);
    return result;
  }
}