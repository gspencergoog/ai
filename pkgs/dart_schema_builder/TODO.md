# TODO

The `dart_schema_builder` package is being updated to be compliant with the [JSON Schema Draft 2020-12 specification](https://json-schema.org/draft/2020-12). The primary method for ensuring compliance is by passing the official JSON Schema Test Suite.

## Current Status

- **Refactoring Complete:** The core validation logic has been refactored to return `ValidationResult` objects, encapsulating validation outcomes, errors, and annotations. This addresses the fundamental issues with state management that were blocking progress on `unevaluatedProperties` and `unevaluatedItems`.
- **Increased Test Pass Rate:** A significant number of previously failing tests for various keywords are now passing due to the refactoring. The number of failing tests has been reduced from 34 to 16.
- **`$dynamicRef` Still Partially Failing:** The `$dynamicRef` implementation has been significantly improved, but is still not fully correct. The logic for resolving dynamic anchors within the dynamic scope needs to be fixed, specifically in how the outermost schema resource is identified.
- **`unevaluatedProperties` and `unevaluatedItems` Still Failing:** While the refactoring has laid the groundwork for a correct implementation, these keywords are still failing. The annotation collection logic needs to be further refined to correctly track evaluated properties and items across all applicator keywords.
- **Logging Added:** A logging feature has been added to the validation process to aid in debugging complex schema interactions.
- **Remote References Enabled in Tests:** The test suite now pre-loads remote schemas, allowing for more comprehensive testing of `$ref` and `$dynamicRef`.

## Next Steps

The main focus is now on fixing the remaining failing keywords, which are the most complex parts of the JSON Schema specification.

1.  **Fix `$dynamicRef` Scope Resolution:** This is the highest priority. The current implementation is not correctly resolving dynamic anchors in all cases. The logic for identifying the correct schema resource URI within the dynamic scope, particularly for nested resources, needs to be corrected.
2.  **Fix `unevaluatedProperties` and `unevaluatedItems`:** The annotation collection logic needs to be revisited to ensure that it is correctly collecting and using annotations from all subschemas, including nested applicators.
3.  **Re-enable All Remote Reference Tests:** Once the local tests are passing, the remaining remote reference tests will be re-enabled and any issues that arise will be fixed.
4.  **Format Vocabulary:** Implement the vocabulary check for the `format` keyword to enable assertion behavior based on the schema's `$vocabulary`.