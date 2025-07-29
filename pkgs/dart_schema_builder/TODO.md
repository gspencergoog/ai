# TODO

The `dart_schema_builder` package is being updated to be compliant with the [JSON Schema Draft 2020-12 specification](https://json-schema.org/draft/2020-12). The primary method for ensuring compliance is by passing the official JSON Schema Test Suite.

## Current Status

- **Refactoring:** The `dart_schema_builder` library has been refactored into smaller, more manageable files to improve maintainability.
- **`uniqueItems`:** The `uniqueItems` validation failures have been resolved. The fix involved correctly handling boolean schemas and the `unevaluatedItems` keyword.
- **`dependentSchemas`:** The implementation for `dependentSchemas` has been corrected to handle boolean subschemas properly.
- **`multipleOf`:** The `multipleOf` validation now correctly handles cases involving division by zero and infinity.
- **`patternProperties`:** The `patternProperties` keyword now correctly handles boolean schemas.
- **`format` Keyword:** The `format` keyword's behavior is now aligned with the specification. It is treated as an annotation by default and as an assertion only when `strictFormat: true` is specified.
- **`$ref` Resolution:** Local `$ref` resolution has been improved to correctly handle JSON pointers with escaped characters.
- **Broad Keyword Support:** A wide range of keywords are now passing the test suite, including `anyOf`, `const`, `contains`, `if-then-else`, `items`, `maximum`, `maxItems`, `maxLength`, `maxProperties`, `minimum`, `minItems`, `minLength`, `minProperties`, `oneOf`, `pattern`, `patternProperties`, `prefixItems`, `properties`, `propertyNames`, and `required`.
- **Bug Fixes:** Corrected several bugs related to type casting (e.g., `double` vs. `int`) and handling of boolean schemas within `properties` and `prefixItems`.

## Next Steps

1. **`$dynamicRef` and `$dynamicAnchor`:** This remains the highest priority. The current implementation is causing infinite recursion in some test cases. A new approach is needed to correctly manage the dynamic scope and prevent re-validation of the same schema.
2. **`not` and `unevaluatedItems` Failures:** The tests for `not` and `unevaluatedItems` are still failing in complex scenarios, particularly when used with other applicator keywords like `allOf`, `if/then/else`, and `anyOf`. The logic for tracking evaluated items across these keywords needs to be revisited.
3. **Remote References:** Implement support for remote references (i.e., `$ref` pointing to other files or URLs).
4. **Format Vocabulary:** Implement the vocabulary check for the `format` keyword to enable assertion behavior based on the schema's `$vocabulary`.
5. **Remaining Test Failures:** Continue to systematically address the remaining failures in the official JSON Schema Test Suite to achieve full compliance.
