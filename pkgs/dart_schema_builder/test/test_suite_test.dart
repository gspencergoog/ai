// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:test/test.dart';

void main() {
  final testSuiteDir = Directory('test/JSON-Schema-Test-Suite/tests/draft2020-12');

  // Optional tests are not required to pass for full compliance.
  final optionalTestSuiteDir = Directory('${testSuiteDir.path}/optional');

  final testFiles = testSuiteDir
      .listSync(recursive: true)
      .where((entity) => entity is File && entity.path.endsWith('.json'))
      .cast<File>();

  final optionalTestFiles = optionalTestSuiteDir
      .listSync(recursive: true)
      .where((entity) => entity is File && entity.path.endsWith('.json'))
      .cast<File>();

  final testFilePaths = testFiles.map((f) => f.path).toSet();
  final optionalTestFilePaths = optionalTestFiles.map((f) => f.path).toSet();

  // Exclude optional tests from the main suite.
  testFilePaths.removeAll(optionalTestFilePaths);

  for (final file in testFilePaths.map((path) => File(path))) {
    final content = file.readAsStringSync();
    final tests = jsonDecode(content) as List;

    for (final testGroup in tests) {
      final groupDescription = testGroup['description'] as String;
      final schemaMap = testGroup['schema'];
      final Schema schema;
      if (schemaMap is bool) {
        schema = Schema.fromMap({if (!schemaMap) 'not': {}});
      } else {
        schema = Schema.fromMap(schemaMap as Map<String, Object?>);
      }

      group('$groupDescription - ${file.path}', () {
        final testCases = testGroup['tests'] as List;
        for (final testCase in testCases) {
          final testDescription = testCase['description'] as String;
          final data = testCase['data'];
          final expectedValidity = testCase['valid'] as bool;

          test(testDescription, () {
            final errors = schema.validate(data);
            if (expectedValidity) {
              expect(errors, isEmpty,
                  reason:
                      'Expected data to be valid, but got errors: ${errors.map((e) => e.toErrorString()).join(', ')}');
            } else {
              expect(errors, isNotEmpty,
                  reason: 'Expected data to be invalid, but it was valid.');
            }
          });
        }
      });
    }
  }
}
