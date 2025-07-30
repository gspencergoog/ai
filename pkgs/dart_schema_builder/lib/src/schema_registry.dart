// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'schema.dart';
import 'schema_cache.dart';

class SchemaRegistry {
  final SchemaCache _schemaCache;
  final Map<Uri, Schema> _schemas = {};

  SchemaRegistry({SchemaCache? schemaCache})
      : _schemaCache = schemaCache ?? SchemaCache();

  Future<Schema?> resolve(Uri uri) async {
    final uriWithoutFragment = uri.removeFragment();
    if (_schemas.containsKey(uriWithoutFragment)) {
      return _getSchemaFromFragment(uri, _schemas[uriWithoutFragment]!);
    }

    final schema = await _schemaCache.get(uriWithoutFragment);
    if (schema == null) {
      return null;
    }
    _schemas[uriWithoutFragment] = schema;
    _registerIds(schema, uriWithoutFragment);

    return _getSchemaFromFragment(uri, schema);
  }

  void _registerIds(Schema schema, Uri baseUri) {
    final id = schema.$id;
    if (id != null) {
      final newUri = baseUri.resolve(id);
      _schemas[newUri] = schema;
      baseUri = newUri;
    }

    if (schema.value.values.whereType<Map<String, Object?>>().isNotEmpty) {
      for (final value in schema.value.values) {
        if (value is Map<String, Object?>) {
          _registerIds(Schema.fromMap(value), baseUri);
        } else if (value is List) {
          for (final item in value) {
            if (item is Map<String, Object?>) {
              _registerIds(Schema.fromMap(item), baseUri);
            }
          }
        }
      }
    }
  }

  Schema? _getSchemaFromFragment(Uri uri, Schema schema) {
    if (!uri.hasFragment) {
      return schema;
    }

    final fragment = uri.fragment;
    if (fragment.startsWith('/')) {
      return _resolveJsonPointer(schema, fragment);
    } else {
      return _findAnchor(fragment, schema);
    }
  }

  Schema? _resolveJsonPointer(Schema schema, String pointer) {
    final parts = pointer.substring(1).split('/');
    dynamic current = schema;
    for (final part in parts) {
      final decodedPart = Uri.decodeComponent(
        part,
      ).replaceAll('~1', '/').replaceAll('~0', '~');
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
}
