// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'constants.dart';
import 'integer_schema.dart';
import 'json_type.dart';
import 'list_schema.dart';
import 'number_schema.dart';
import 'object_schema.dart';
import 'schema.dart';
import 'schema_registry.dart';
import 'string_schema.dart';
import 'utils.dart';
import 'validation_error.dart';

class ValidationContext {
  final Schema rootSchema;
  final bool strictFormat;
  final List<Schema> dynamicScope;
  final Uri? sourceUri;
  final SchemaRegistry schemaRegistry;
  final Set<String> evaluatedKeys;

  ValidationContext(
    this.rootSchema, {
    this.strictFormat = false,
    this.sourceUri,
    required this.schemaRegistry,
  })  : dynamicScope = [rootSchema],
        evaluatedKeys = {};

  ValidationContext._copyWith({
    required this.rootSchema,
    required this.strictFormat,
    required this.dynamicScope,
    required this.sourceUri,
    required this.schemaRegistry,
    required this.evaluatedKeys,
  });

  ValidationContext withSourceUri(Uri newSourceUri) {
    return ValidationContext._copyWith(
      rootSchema: rootSchema,
      strictFormat: strictFormat,
      dynamicScope: dynamicScope,
      sourceUri: newSourceUri,
      schemaRegistry: schemaRegistry,
      evaluatedKeys: evaluatedKeys,
    );
  }
}

Future<void> validateSubSchema(
  Object? schema,
  Object? data,
  List<String> currentPath,
  HashSet<ValidationError> accumulatedFailures,
  ValidationContext context,
) async {
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
    await Schema.fromMap(
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
      return v.map((key, value) {
        if (value is bool) {
          return MapEntry(key as String, Schema.fromBoolean(value));
        }
        return MapEntry(
          key as String,
          Schema.fromMap(value as Map<String, Object?>),
        );
      });
    }
    return null;
  }

  /// Validates the given [data] against this schema.
  ///
  /// Returns a list of [ValidationError] if validation fails,
  /// or an empty list if validation succeeds.
  Future<List<ValidationError>> validate(
    Object? data, {
    bool strictFormat = false,
    Uri? sourceUri,
  }) async {
    final failures = createHashSet();
    final schemaRegistry = SchemaRegistry();
    final baseUri = sourceUri ?? Uri.parse('local://schema');
    schemaRegistry.addSchema(baseUri, this);
    final context = ValidationContext(
      this,
      strictFormat: strictFormat,
      sourceUri: baseUri,
      schemaRegistry: schemaRegistry,
    );
    await validateSchema(data, [], failures, context);
    return failures.toList();
  }

  Future<void> validateSchema(
    Object? data,
    List<String> currentPath,
    HashSet<ValidationError> accumulatedFailures,
    ValidationContext context,
  ) async {
    context.dynamicScope.add(this);

    if ($dynamicRef case final ref?) {
      final resolution = await resolveDynamicRef(
        ref,
        context.dynamicScope,
        context,
      );
      if (resolution case (final referencedSchema, final referencedUri)?) {
        final newContext = context.withSourceUri(referencedUri);
        await referencedSchema.validateSchema(
          data,
          currentPath,
          accumulatedFailures,
          newContext,
        );
      }
      context.dynamicScope.removeLast();
      return;
    }

    if ($ref case final ref?) {
      final resolution = await resolveRef(
        ref,
        context.rootSchema,
        context,
      );
      if (resolution case (final referencedSchema, final referencedUri)?) {
        // First, validate against the referenced schema.
        final newContext = context.withSourceUri(referencedUri);
        await referencedSchema.validateSchema(
          data,
          currentPath,
          accumulatedFailures,
          newContext,
        );

        // Then, validate against the sibling keywords.
        final siblingSchemaMap = {...value};
        siblingSchemaMap.remove(kRef);
        if (siblingSchemaMap.isNotEmpty) {
          final siblingSchema = Schema.fromMap(siblingSchemaMap);
          await siblingSchema.validateSchema(
            data,
            currentPath,
            accumulatedFailures,
            context,
          );
        }
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
      await validateSubSchema(ifS, data, currentPath, tempFailures, context);
      if (tempFailures.isEmpty) {
        if (thenSchema case final thenS?) {
          await validateSubSchema(
            thenS,
            data,
            currentPath,
            accumulatedFailures,
            context,
          );
        }
      } else {
        if (elseSchema case final elseS?) {
          await validateSubSchema(
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
        await validateSubSchema(
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
      final allAnyOfFailures = <ValidationError>[];
      for (final subSchema in anyOfList) {
        final tempFailures = createHashSet();
        await validateSubSchema(
          subSchema,
          data,
          currentPath,
          tempFailures,
          context,
        );
        if (tempFailures.isEmpty) {
          passedCount++;
        } else {
          allAnyOfFailures.addAll(tempFailures);
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
        await validateSubSchema(
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
      await validateSubSchema(
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
    if (value.containsKey(kConst)) {
      final constV = value[kConst];
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
    await validateTypeSpecificKeywords(
      data,
      currentPath,
      accumulatedFailures,
      context,
    );

    // 5. Unevaluated Properties
    if (data is Map<String, Object?>) {
      if (this[kUnevaluatedProperties] case final up?) {
        for (final dataKey in data.keys) {
          if (!context.evaluatedKeys.contains(dataKey)) {
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
              await Schema.fromMap(up.cast<String, Object?>()).validateSchema(
                data[dataKey],
                currentPath,
                accumulatedFailures,
                context,
              );
            }
            context.evaluatedKeys.add(dataKey);
            currentPath.removeLast();
          }
        }
      }
    }
    context.dynamicScope.removeLast();
  }

  Future<void> validateTypeSpecificKeywords(
    Object? data,
    List<String> currentPath,
    HashSet<ValidationError> accumulatedFailures,
    ValidationContext context,
  ) async {
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
        await (this as ObjectSchema).validateObject(
          data as Map<String, Object?>,
          currentPath,
          accumulatedFailures,
          context,
        );
        break;
      case JsonType.list:
        await (this as ListSchema).validateList(
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

  Future<void> validateObject(
    Map<String, Object?> data,
    List<String> currentPath,
    HashSet<ValidationError> accumulatedFailures,
    ValidationContext context,
  ) async {
    final objectSchema = this as ObjectSchema;
    if (objectSchema.minProperties case final min?
        when data.keys.length < min) {
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

    if (objectSchema.maxProperties case final max?
        when data.keys.length > max) {
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
          await validateSubSchema(
            entry.value,
            data,
            currentPath,
            accumulatedFailures,
            context,
          );
        }
      }
    }

    final evaluatedKeys = context.evaluatedKeys;
    if (objectSchema.properties case final props?) {
      for (final entry in props.entries) {
        if (data.containsKey(entry.key)) {
          currentPath.add(entry.key);
          evaluatedKeys.add(entry.key);
          await entry.value.validateSchema(
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
            await entry.value.validateSchema(
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
        await propNamesSchema.validateSchema(
          key,
          currentPath,
          accumulatedFailures,
          context,
        );
      }
    }

    // Special handling for the `type` keyword when validating a schema.
    if (data.containsKey('type')) {
      final typeValue = data['type'];
      final types = switch (typeValue) {
        String() => [typeValue],
        List() => typeValue.cast<String>(),
        _ => null,
      };
      if (types == null) {
        accumulatedFailures.add(
          ValidationError(
            ValidationErrorType.typeMismatch,
            path: [...currentPath, 'type'],
            details: 'The value of "type" must be a string or an array of strings',
          ),
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
          await (ap as Schema).validateSchema(
            data[dataKey],
            currentPath,
            accumulatedFailures,
            context,
          );
        }
        currentPath.removeLast();
        evaluatedKeys.add(dataKey);
      }
    }
  }

  Future<void> validateList(
    List data,
    List<String> currentPath,
    HashSet<ValidationError> accumulatedFailures,
    ValidationContext context,
  ) async {
    final evaluatedItems = <int>{};
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

    if (listSchema.contains case final containsSchema?) {
      final matches = <int>[];
      for (var i = 0; i < data.length; i++) {
        final tempFailures = createHashSet();
        await validateSubSchema(
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
        evaluatedItems.add(index);
      }

      final matchCount = matches.length;
      if (listSchema.minContains == 0 && data.isEmpty) {
        // This is a valid case.
      } else if (matchCount == 0 &&
          (listSchema.minContains == null || listSchema.minContains! > 0)) {
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
        evaluatedItems.add(i);
        currentPath.add(i.toString());
        await validateSubSchema(
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
        evaluatedItems.add(i);
        currentPath.add(i.toString());
        await validateSubSchema(
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
        if (!evaluatedItems.contains(i)) {
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
            await (ui as Schema).validateSchema(
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

  Future<(Schema, Uri)?> resolveRef(
    String ref,
    Schema rootSchema,
    ValidationContext context,
  ) async {
    final baseUri = context.sourceUri!;
    final refUri = baseUri.resolve(ref);
    final schema = await context.schemaRegistry.resolve(refUri);
    if (schema == null) return null;
    return (schema, refUri);
  }

  Future<(Schema, Uri)?> resolveDynamicRef(
    String ref,
    List<Schema> dynamicScope,
    ValidationContext context,
  ) async {
    if (!ref.startsWith('#')) {
      // For now, only support local refs.
      return null;
    }
    final pointer = ref.substring(1);
    if (pointer.isEmpty) {
      return (dynamicScope.last, context.sourceUri!);
    }
    if (!pointer.startsWith('/')) {
      // It's a dynamic anchor.
      final anchorSchema = _findDynamicAnchor(pointer, dynamicScope);
      if (anchorSchema != null) {
        // The anchor doesn't change the URI context.
        return (anchorSchema, context.sourceUri!);
      }
    }
    // Fallback to normal $ref resolution against the root schema.
    return await resolveRef(ref, dynamicScope.first, context);
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