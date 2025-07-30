# TODO

The `dart_schema_builder` package is being updated to be compliant with the [JSON Schema Draft 2020-12 specification](https://json-schema.org/draft/2020-12). The primary method for ensuring compliance is by passing the official JSON Schema Test Suite.

## Current Status

- **Refactoring Complete:** The core validation logic has been refactored to return `ValidationResult` objects, encapsulating validation outcomes, errors, and annotations. This addresses the fundamental issues with state management that were blocking progress on `unevaluatedProperties` and `unevaluatedItems`.
- **Increased Test Pass Rate:** A significant number of previously failing tests for various keywords are now passing due to the refactoring.
- **`unevaluatedProperties` and `unevaluatedItems` Still Failing:** While the refactoring has laid the groundwork for a correct implementation, these keywords are still failing. The annotation collection logic needs to be further refined to correctly track evaluated properties and items across all applicator keywords.
- **`$dynamicRef` Still Failing:** The `$dynamicRef` implementation is still incorrect. The logic for resolving dynamic anchors within the dynamic scope needs to be fixed.
- **Remote References Disabled:** The remote reference tests are currently disabled to allow for focused debugging of the core validation logic.

## Next Steps

The main focus is now on fixing the remaining failing keywords, which are the most complex parts of the JSON Schema specification.

1.  **Fix `$dynamicRef` Scope Resolution:** This is the highest priority. The current implementation is not correctly resolving dynamic anchors in all cases.
2.  **Fix `unevaluatedProperties` and `unevaluatedItems`:** The annotation collection logic needs to be revisited to ensure that it is correctly collecting and using annotations from all subschemas, including nested applicators.
3.  **Re-enable Remote Reference Tests:** Once the local tests are passing, the remote reference tests will be re-enabled and any issues that arise will be fixed.
4.  **Format Vocabulary:** Implement the vocabulary check for the `format` keyword to enable assertion behavior based on the schema's `$vocabulary`.