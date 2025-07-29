

// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:characters/characters.dart';

const kAdditionalProperties = 'additionalProperties';
const kAllOf = 'allOf';
const kAnyOf = 'anyOf';
const kConst = 'const';
const kContains = 'contains';
const kDefault = 'default';
const kDependentRequired = 'dependentRequired';
const kDependentSchemas = 'dependentSchemas';
const kDescription = 'description';
const kElse = 'else';
const kEnum = 'enum';
const kExamples = 'examples';
const kExclusiveMaximum = 'exclusiveMaximum';
const kExclusiveMinimum = 'exclusiveMinimum';
const kFormat = 'format';
const kIf = 'if';
const kItems = 'items';
const kMaximum = 'maximum';
const kMaxItems = 'maxItems';
const kMaxLength = 'maxLength';
const kMaxProperties = 'maxProperties';
const kMinimum = 'minimum';
const kMinItems = 'minItems';
const kMinLength = 'minLength';
const kMinProperties = 'minProperties';
const kMultipleOf = 'multipleOf';
const kNot = 'not';
const kOneOf = 'oneOf';
const kPattern = 'pattern';
const kPatternProperties = 'patternProperties';
const kPrefixItems = 'prefixItems';
const kProperties = 'properties';
const kPropertyNames = 'propertyNames';
const kReadOnly = 'readOnly';
const kRef = '\$ref';
const kRequired = 'required';
const kThen = 'then';
const kTitle = 'title';
const kType = 'type';
const kUnevaluatedItems = 'unevaluatedItems';
const kUnevaluatedProperties = 'unevaluatedProperties';
const kUniqueItems = 'uniqueItems';
const kWriteOnly = 'writeOnly';
const kDefs = '\$defs';
const kComment = '\$comment';
const kDeprecated = 'deprecated';
const kMinContains = 'minContains';
const kMaxContains = 'maxContains';

/// The valid types for properties in a JSON schema.
enum JsonType {
  object('object'),
  list('array'),
  string('string'),
  num('number'),
  int('integer'),
  boolean('boolean'),
  nil('null');

  const JsonType(this.typeName);

  final String typeName;
}

/// Enum representing the types of validation failures when checking data
/// against a schema.
enum ValidationErrorType {
  // For custom validation.
  custom,

  // General
  typeMismatch,
  constMismatch,
  enumValueNotAllowed,
  formatInvalid,

  // Schema combinators
  allOfNotMet,
  anyOfNotMet,
  oneOfNotMet,
  notConditionViolated,
  ifThenElseInvalid,

  // Object specific
  requiredPropertyMissing,
  dependentRequiredMissing,
  additionalPropertyNotAllowed,
  minPropertiesNotMet,
  maxPropertiesExceeded,
  propertyNamesInvalid,
  patternPropertyValueInvalid,
  unevaluatedPropertyNotAllowed,

  // Array/List specific
  minItemsNotMet,
  maxItemsExceeded,
  uniqueItemsViolated,
  containsInvalid,
  minContainsNotMet,
  maxContainsExceeded,
  itemInvalid,
  prefixItemInvalid,
  unevaluatedItemNotAllowed,

  // String specific
  minLengthNotMet,
  maxLengthExceeded,
  patternMismatch,

  // Number/Integer specific
  minimumNotMet,
  maximumExceeded,
  exclusiveMinimumNotMet,
  exclusiveMaximumExceeded,
  multipleOfInvalid,
}

/// A validation error with detailed information about the location of the
/// error.
extension type ValidationError.fromMap(Map<String, Object?> _value) {
  factory ValidationError(
    ValidationErrorType error, {
    required List<String> path,
    String? details,
  }) =>
      ValidationError.fromMap({
        'error': error.name,
        'path': path.toList(),
        if (details != null) 'details': details,
      });

  factory ValidationError.typeMismatch({
    required List<String> path,
    required Object expectedType, // Can be String or List<String>
    required Object? actualValue,
  }) =>
      ValidationError(
        ValidationErrorType.typeMismatch,
        path: path,
        details: 'Value `$actualValue` is not of type `$expectedType`',
      );

  /// The type of validation error that occurred.
  ValidationErrorType get error =>
      ValidationErrorType.values.firstWhere((t) => t.name == _value['error']);

  /// The path to the object that had the error.
  List<String> get path => (_value['path'] as List).cast<String>();

  /// Additional details about the error (optional).
  String? get details => _value['details'] as String?;

  String toErrorString() {
    return '${details != null ? '$details' : error.name} at path '
        '#root${path.map((p) => '["$p"]').join('')}'
        '';
  }
}

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
      if ($defs != null) '\$defs': $defs,
      if ($ref != null) '\$ref': $ref,
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

  factory Schema.fromBoolean(
    bool value, {
    List<String> jsonPath = const [],
  }) {
    return Schema.fromMap({
      if (value)
        kComment: 'boolean schema true'
      else
        kComment: 'boolean schema false',
    });
  }

  Object? operator [](String key) => _value[key];

  // Core Keywords
  Object? get type => _value['type'];
  List<Object?>? get enumValues =>
      (_value['enum'] as List?)?.cast<Object?>();
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
      (_value['\$defs'] as Map?)?.cast<String, Schema>();
  String? get $ref => _value['\$ref'] as String?;

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

void _validateSubSchema(
  Object? schema,
  Object? data,
  List<String> currentPath,
  HashSet<ValidationError> accumulatedFailures,
  Schema rootSchema,
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
    Schema.fromMap(schema.cast<String, Object?>())._validateSchema(
      data,
      currentPath,
      accumulatedFailures,
      rootSchema,
    );
    return;
  }
  // This should not happen for a valid schema file.
}

extension SchemaValidation on Schema {
  Schema? _schemaOrBool(String key) {
    final value = _value[key];
    if (value == null) return null;
    if (value is bool) {
      return Schema.fromBoolean(
        value,
        jsonPath: [key],
      );
    }
    return Schema.fromMap(value as Map<String, Object?>);
  }

  Map<String, Schema>? _mapToSchema(String key) {
    final value = _value[key];
    if (value is Map) {
      return value.map(
        (key, value) => MapEntry(
          key as String,
          Schema.fromMap(value as Map<String, Object?>),
        ),
      );
    }
    return null;
  }

  /// Validates the given [data] against this schema.
  ///
  /// Returns a list of [ValidationError] if validation fails,
  /// or an empty list if validation succeeds.
  List<ValidationError> validate(Object? data) {
    final failures = _createHashSet();
    _validateSchema(data, [], failures, this);
    return failures.toList();
  }

  void _validateSchema(
    Object? data,
    List<String> currentPath,
    HashSet<ValidationError> accumulatedFailures,
    Schema rootSchema,
  ) {
    if ($ref case final ref?) {
      final referencedSchema = _resolveRef(ref, rootSchema);
      if (referencedSchema != null) {
        _validateSubSchema(
          referencedSchema,
          data,
          currentPath,
          accumulatedFailures,
          rootSchema,
        );
      }
      // Not handling the case where the ref is not found for now.
      // The test suite will tell us what to do.
      return;
    }

    // 1. Conditional Applicators: if/then/else
    if (ifSchema case final ifS?) {
      final tempFailures = _createHashSet();
      _validateSubSchema(ifS, data, currentPath, tempFailures, rootSchema);
      if (tempFailures.isEmpty) {
        if (thenSchema case final thenS?) {
          _validateSubSchema(
            thenS,
            data,
            currentPath,
            accumulatedFailures,
            rootSchema,
          );
        }
      } else {
        if (elseSchema case final elseS?) {
          _validateSubSchema(
            elseS,
            data,
            currentPath,
            accumulatedFailures,
            rootSchema,
          );
        }
      }
    }

    // 2. Schema Combiners: allOf, anyOf, oneOf, not
    if (allOf case final List allOfList?) {
      final initialFailureCount = accumulatedFailures.length;
      for (final subSchema in allOfList) {
        _validateSubSchema(
          subSchema,
          data,
          currentPath,
          accumulatedFailures,
          rootSchema,
        );
      }
      if (accumulatedFailures.length > initialFailureCount) {
        accumulatedFailures.add(
          ValidationError(ValidationErrorType.allOfNotMet, path: currentPath),
        );
      }
    }

    if (anyOf case final List anyOfList?) {
      var passedCount = 0;
      for (final subSchema in anyOfList) {
        final tempFailures = _createHashSet();
        _validateSubSchema(
            subSchema, data, currentPath, tempFailures, rootSchema);
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
        final tempFailures = _createHashSet();
        _validateSubSchema(
            subSchema, data, currentPath, tempFailures, rootSchema);
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
                'Expected to match exactly one schema, but matched $passedCount',
          ),
        );
      }
    }

    if (not case final notSchema?) {
      final tempFailures = _createHashSet();
      _validateSubSchema(notSchema, data, currentPath, tempFailures, rootSchema);
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
      if (!_deepEquals(data, constV)) {
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
      if (!enumV.any((e) => _deepEquals(data, e))) {
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
    _validateTypeSpecificKeywords(data, currentPath, accumulatedFailures);
  }

  void _validateTypeSpecificKeywords(
    Object? data,
    List<String> currentPath,
    HashSet<ValidationError> accumulatedFailures,
  ) {
    final actualType = _getJsonType(data);

    // First, validate against the `type` keyword if it exists.
    final typeValue = type;
    if (typeValue != null) {
      final types = switch (typeValue) {
        String() => [
            JsonType.values.firstWhere((t) => t.typeName == typeValue)
          ],
        List() => typeValue
            .map((t) => JsonType.values.firstWhere((e) => e.typeName == t))
            .toList(),
        _ => <JsonType>[],
      };

      if (types.isNotEmpty && !types.contains(actualType)) {
        accumulatedFailures.add(
          ValidationError.typeMismatch(
            path: currentPath,
            expectedType: types.map((t) => t.typeName).join(' or '),
            actualValue: data,
          ),
        );
        return; // If type doesn't match, no point in running other type-specific validations
      }
    }

    // Now, apply keywords based on the actual type of the data.
    switch (actualType) {
      case JsonType.object:
        (this as ObjectSchema)._validateObject(
          data as Map<String, Object?>,
          currentPath,
          accumulatedFailures,
        );
        break;
      case JsonType.list:
        (this as ListSchema)._validateList(
          data as List,
          currentPath,
          accumulatedFailures,
        );
        break;
      case JsonType.string:
        (this as StringSchema)._validateString(
          data as String,
          currentPath,
          accumulatedFailures,
        );
        break;
      case JsonType.num:
      case JsonType.int:
        (this as NumberSchema)._validateNumber(
          data as num,
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

  JsonType _getJsonType(Object? data) {
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
    // This should not happen for valid JSON data.
    throw StateError('Unknown JSON type for value: $data');
  }

  Schema? _resolveRef(String ref, Schema rootSchema) {
    if (!ref.startsWith('#/')) {
      // For now, only support local refs.
      return null;
    }
    final parts = ref.substring(2).split('/');
    dynamic current = rootSchema;
    for (final part in parts) {
      final decodedPart = Uri.decodeComponent(
        part.replaceAll('~1', '/').replaceAll('~0', '~'),
      );
      if (current is Schema && current._value.containsKey(decodedPart)) {
        current = current._value[decodedPart];
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
}

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
  }) =>
      ObjectSchema.fromMap({
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

  Map<String, Schema>? get properties => _mapToSchema(kProperties);
  Map<String, Schema>? get patternProperties =>
      _mapToSchema(kPatternProperties);
  List<String>? get required => (_value[kRequired] as List?)?.cast<String>();
  Map<String, List<String>>? get dependentRequired {
    final value = _value[kDependentRequired];
    if (value is Map) {
      return value.map(
        (key, value) => MapEntry(
          key as String,
          (value as List).cast<String>(),
        ),
      );
    }
    return null;
  }

  Object? get additionalProperties => _schemaOrBool(kAdditionalProperties);
  Object? get unevaluatedProperties =>
      _schemaOrBool(kUnevaluatedProperties);
  Schema? get propertyNames => _schemaOrBool(kPropertyNames);
  int? get minProperties => (_value[kMinProperties] as num?)?.toInt();
  int? get maxProperties => (_value[kMaxProperties] as num?)?.toInt();

  void _validateObject(
    Map<String, Object?> data,
    List<String> currentPath,
    HashSet<ValidationError> accumulatedFailures,
  ) {
    if (minProperties case final min? when data.keys.length < min) {
      accumulatedFailures.add(
        ValidationError(
          ValidationErrorType.minPropertiesNotMet,
          path: currentPath,
          details:
              'There should be at least $min properties. Only ${data.keys.length} were found',
        ),
      );
    }

    if (maxProperties case final max? when data.keys.length > max) {
      accumulatedFailures.add(
        ValidationError(
          ValidationErrorType.maxPropertiesExceeded,
          path: currentPath,
          details: 'Exceeded maxProperties limit of $max (${data.keys.length})',
        ),
      );
    }

    for (final reqProp in required ?? const []) {
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

    if (dependentRequired case final dr?) {
      for (final entry in dr.entries) {
        if (data.containsKey(entry.key)) {
          for (final requiredProp in entry.value) {
            if (!data.containsKey(requiredProp)) {
              accumulatedFailures.add(
                ValidationError(
                  ValidationErrorType.dependentRequiredMissing,
                  path: currentPath,
                  details:
                      'Property "$requiredProp" is required because property "${entry.key}" is present.',
                ),
              );
            }
          }
        }
      }
    }

    final evaluatedKeys = <String>{};
    if (properties case final props?) {
      for (final entry in props.entries) {
        if (data.containsKey(entry.key)) {
          currentPath.add(entry.key);
          evaluatedKeys.add(entry.key);
          entry.value._validateSchema(
            data[entry.key],
            currentPath,
            accumulatedFailures,
            this,
          );
          currentPath.removeLast();
        }
      }
    }

    if (patternProperties case final patternProps?) {
      for (final entry in patternProps.entries) {
        final pattern = RegExp(entry.key);
        for (final dataKey in data.keys) {
          if (pattern.hasMatch(dataKey)) {
            currentPath.add(dataKey);
            evaluatedKeys.add(dataKey);
            entry.value._validateSchema(
              data[dataKey],
              currentPath,
              accumulatedFailures,
              this,
            );
            currentPath.removeLast();
          }
        }
      }
    }

    if (propertyNames case final propNamesSchema?) {
      for (final key in data.keys) {
        propNamesSchema._validateSchema(
          key,
          currentPath,
          accumulatedFailures,
          this,
        );
      }
    }

    for (final dataKey in data.keys) {
      if (evaluatedKeys.contains(dataKey)) continue;

      if (additionalProperties case final ap?) {
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
          (ap as Schema)._validateSchema(
            data[dataKey],
            currentPath,
            accumulatedFailures,
            this,
          );
        }
        currentPath.removeLast();
      } else if (unevaluatedProperties case final up? when up is bool && !up) {
        // Only applies if additionalProperties is not defined
        currentPath.add(dataKey);
        accumulatedFailures.add(
          ValidationError(
            ValidationErrorType.unevaluatedPropertyNotAllowed,
            path: currentPath,
            details: 'Unevaluated property "$dataKey" is not allowed',
          ),
        );
        currentPath.removeLast();
      }
    }
  }
}

/// A JSON Schema definition for a String.
extension type const StringSchema.fromMap(Map<String, Object?> _value)
    implements Schema {
  factory StringSchema({
    // Core keywords
    String? title,
    String? description,
    List<Object?>? enumValues,
    Object? constValue,
    // String-specific keywords
    int? minLength,
    int? maxLength,
    String? pattern,
    String? format,
  }) =>
      StringSchema.fromMap({
        'type': JsonType.string.typeName,
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (enumValues != null) 'enum': enumValues,
        if (constValue != null) 'const': constValue,
        if (minLength != null) 'minLength': minLength,
        if (maxLength != null) 'maxLength': maxLength,
        if (pattern != null) 'pattern': pattern,
        if (format != null) 'format': format,
      });

  int? get minLength => (_value[kMinLength] as num?)?.toInt();
  int? get maxLength => (_value[kMaxLength] as num?)?.toInt();
  String? get pattern => _value['pattern'] as String?;
  String? get format => _value['format'] as String?;

  void _validateString(
    String data,
    List<String> currentPath,
    HashSet<ValidationError> accumulatedFailures,
  ) {
    if (minLength case final minLen?
        when data.characters.length < minLen) {
      accumulatedFailures.add(
        ValidationError(
          ValidationErrorType.minLengthNotMet,
          path: currentPath,
          details: 'String "$data" is not at least $minLen characters long',
        ),
      );
    }
    if (maxLength case final maxLen?
        when data.characters.length > maxLen) {
      accumulatedFailures.add(
        ValidationError(
          ValidationErrorType.maxLengthExceeded,
          path: currentPath,
          details: 'String "$data" is more than $maxLen characters long',
        ),
      );
    }
    if (pattern case final p? when !RegExp(p).hasMatch(data)) {
      accumulatedFailures.add(
        ValidationError(
          ValidationErrorType.patternMismatch,
          path: currentPath,
          details: 'String "$data" doesn\'t match the pattern "$p"',
        ),
      );
    }
    if (format case final f?) {
      final regex = _getFormatRegex(f);
      if (regex != null && !regex.hasMatch(data)) {
        accumulatedFailures.add(
          ValidationError(
            ValidationErrorType.formatInvalid,
            path: currentPath,
            details: 'String does not match format "$f"',
          ),
        );
      }
    }
  }

  RegExp? _getFormatRegex(String format) {
    return switch (format) {
      'date-time' => RegExp(
          r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})$'),
      'email' => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$'),
      'ipv4' => RegExp(
          r'^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)\.){3}(25[0-5]|(2[0-4]|1\d|[1-9]|)\d)$'),
      _ => null,
    };
  }
}

/// A JSON Schema definition for a [num].
extension type NumberSchema.fromMap(Map<String, Object?> _value)
    implements Schema {
  factory NumberSchema({
    // Core keywords
    String? title,
    String? description,
    // Number-specific keywords
    num? minimum,
    num? maximum,
    num? exclusiveMinimum,
    num? exclusiveMaximum,
    num? multipleOf,
  }) =>
      NumberSchema.fromMap({
        'type': JsonType.num.typeName,
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (minimum != null) 'minimum': minimum,
        if (maximum != null) 'maximum': maximum,
        if (exclusiveMinimum != null) 'exclusiveMinimum': exclusiveMinimum,
        if (exclusiveMaximum != null) 'exclusiveMaximum': exclusiveMaximum,
        if (multipleOf != null) 'multipleOf': multipleOf,
      });

  num? get minimum => _value['minimum'] as num?;
  num? get maximum => _value['maximum'] as num?;
  num? get exclusiveMinimum => _value['exclusiveMinimum'] as num?;
  num? get exclusiveMaximum => _value['exclusiveMaximum'] as num?;
  num? get multipleOf => _value['multipleOf'] as num?;

  void _validateNumber(
    num data,
    List<String> currentPath,
    HashSet<ValidationError> accumulatedFailures,
  ) {
    if (minimum case final min? when data < min) {
      accumulatedFailures.add(
        ValidationError(
          ValidationErrorType.minimumNotMet,
          path: currentPath,
          details: 'Value $data is not at least $min',
        ),
      );
    }
    if (maximum case final max? when data > max) {
      accumulatedFailures.add(
        ValidationError(
          ValidationErrorType.maximumExceeded,
          path: currentPath,
          details: 'Value $data is larger than $max',
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
      if ((remainder - remainder.truncate()).abs() > 1e-9) {
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
  }) =>
      IntegerSchema.fromMap({
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
  int? get maximum => _value['maximum'] as int?;
  int? get exclusiveMinimum => _value['exclusiveMinimum'] as int?;
  int? get exclusiveMaximum => _value['exclusiveMaximum'] as int?;
  num? get multipleOf => _value['multipleOf'] as num?;

  void _validateInteger(
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
    if (multipleOf case final multOf?
        when multOf != 0 && (data % multOf != 0)) {
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

/// A JSON Schema definition for a [bool].
extension type BooleanSchema.fromMap(Map<String, Object?> _value)
    implements Schema {
  factory BooleanSchema({String? title, String? description}) =>
      BooleanSchema.fromMap({
        'type': JsonType.boolean.typeName,
        if (title != null) 'title': title,
        if (description != null) 'description': description,
      });
}

/// A JSON Schema definition for `null`.
extension type NullSchema.fromMap(Map<String, Object?> _value)
    implements Schema {
  factory NullSchema({String? title, String? description}) =>
      NullSchema.fromMap({
        'type': JsonType.nil.typeName,
        if (title != null) 'title': title,
        if (description != null) 'description': description,
      });
}

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
  }) =>
      ListSchema.fromMap({
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

  Schema? get items => _schemaOrBool(kItems);
  List<Schema>? get prefixItems =>
      (_value[kPrefixItems] as List?)?.cast<Schema>();
  Object? get unevaluatedItems => _schemaOrBool(kUnevaluatedItems);
  Schema? get contains => _schemaOrBool(kContains);
  int? get minContains => (_value[kMinContains] as num?)?.toInt();
  int? get maxContains => (_value[kMaxContains] as num?)?.toInt();
  int? get minItems => (_value[kMinItems] as num?)?.toInt();
  int? get maxItems => (_value[kMaxItems] as num?)?.toInt();
  bool? get uniqueItems => _value[kUniqueItems] as bool?;

  void _validateList(
    List data,
    List<String> currentPath,
    HashSet<ValidationError> accumulatedFailures,
  ) {
    if (minItems case final min? when data.length < min) {
      accumulatedFailures.add(
        ValidationError(
          ValidationErrorType.minItemsNotMet,
          path: currentPath,
          details: 'List has ${data.length} items, but must have at least $min',
        ),
      );
    }

    if (maxItems case final max? when data.length > max) {
      accumulatedFailures.add(
        ValidationError(
          ValidationErrorType.maxItemsExceeded,
          path: currentPath,
          details:
              'List has ${data.length} items, but must have less than $max',
        ),
      );
    }

    if (uniqueItems == true) {
      final seenItems = HashSet<Object?>(
        equals: _deepEquals,
        hashCode: _deepHashCode,
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

    if (contains case final containsSchema?) {
      final matches = data.where((item) {
        final tempFailures = _createHashSet();
        _validateSubSchema(
            containsSchema, item, currentPath, tempFailures, this);
        return tempFailures.isEmpty;
      }).length;

      if (minContains == 0 && data.isEmpty) {
        // This is a valid case.
      } else if (matches == 0) {
        accumulatedFailures.add(
          ValidationError(
            ValidationErrorType.containsInvalid,
            path: currentPath,
            details: 'Array does not contain a valid item',
          ),
        );
      }
      if (minContains case final min? when matches < min) {
        accumulatedFailures.add(
          ValidationError(
            ValidationErrorType.minContainsNotMet,
            path: currentPath,
            details:
                'Array must contain at least $min valid items, but found $matches',
          ),
        );
      }
      if (maxContains case final max? when matches > max) {
        accumulatedFailures.add(
          ValidationError(
            ValidationErrorType.maxContainsExceeded,
            path: currentPath,
            details:
                'Array must contain at most $max valid items, but found $matches',
          ),
        );
      }
    }

    final evaluatedItems = List<bool>.filled(data.length, false);
    if (prefixItems case final pItems?) {
      for (var i = 0; i < pItems.length && i < data.length; i++) {
        evaluatedItems[i] = true;
        currentPath.add(i.toString());
        _validateSubSchema(
          pItems[i],
          data[i],
          currentPath,
          accumulatedFailures,
          this,
        );
        currentPath.removeLast();
      }
    }
    if (items case final itemSchema?) {
      final startIndex = prefixItems?.length ?? 0;
      for (var i = startIndex; i < data.length; i++) {
        evaluatedItems[i] = true;
        currentPath.add(i.toString());
        _validateSubSchema(
          itemSchema,
          data[i],
          currentPath,
          accumulatedFailures,
          this,
        );
        currentPath.removeLast();
      }
    }
    if (unevaluatedItems case final ui?) {
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
            (ui as Schema)._validateSchema(
              data[i],
              currentPath,
              accumulatedFailures,
              this,
            );
          }
          currentPath.removeLast();
        }
      }
    }
  }
}

bool _deepEquals(Object? a, Object? b) {
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || !_deepEquals(a[key], b[key])) {
        return false;
      }
    }
    return true;
  } else if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_deepEquals(a[i], b[i])) {
        return false;
      }
    }
    return true;
  }
  return a == b;
}

int _deepHashCode(Object? o) {
  if (o == null) return 0;
  if (o is Map) {
    // Order-independent hash for maps
    if (o.isEmpty) return 0;
    return o.entries
        .map((e) => Object.hash(_deepHashCode(e.key), _deepHashCode(e.value)))
        .fold(0, (value, element) => value ^ element);
  }
  if (o is List) {
    return Object.hashAll(o.map(_deepHashCode));
  }
  return o.hashCode;
}

HashSet<ValidationError> _createHashSet() {
  return HashSet<ValidationError>(
    equals: (ValidationError a, ValidationError b) {
      return const ListEquality<String>().equals(a.path, b.path) &&
          a.details == b.details &&
          a.error == b.error;
    },
    hashCode: (ValidationError error) {
      return Object.hashAll([...error.path, error.details, error.error]);
    },
  );
}