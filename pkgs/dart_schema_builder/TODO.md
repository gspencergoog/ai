# TODO

The `dart_schema_builder` package is being updated to be compliant with the [JSON Schema Draft 2020-12 specification](https://json-schema.org/draft/2020-12). The primary method for ensuring compliance is by passing the official JSON Schema Test Suite.

## Current Status

- **Test Suite Enabled:** All non-optional, non-remote tests from the official JSON Schema Test Suite for Draft 2020-12 have been enabled. This provides a clear view of the remaining compliance gaps.
- **Initial Compliance:** A number of foundational keywords are passing in basic scenarios.
- **Identified Failure Areas:** The enabled test suite has confirmed that several key areas require significant work to become compliant. The primary areas of failure include:
  - `$dynamicRef` and `$dynamicAnchor` resolution.
  - `$ref` resolution, particularly with non-JSON pointer references and interaction with `$dynamicAnchor`.
  - `unevaluatedProperties` and `unevaluatedItems` when used with applicator keywords (`allOf`, `anyOf`, etc.).
  - `not` keyword in complex validation scenarios.

## Next Steps

The main focus is to resolve the fundamental reference resolution mechanisms, as these are critical blockers for a large portion of the failing tests.

1. **`$ref` and `$dynamicRef` Resolution:** This is the highest priority. The current implementation does not correctly handle the dynamic scope for `$dynamicRef` and fails to resolve non-pointer `$ref`s (e.g., by `$id` or `$anchor`). A robust and spec-compliant implementation is required.
2. **`unevaluatedProperties` and `unevaluatedItems`:** The logic for tracking evaluated properties and items across applicator keywords is incorrect. This will likely need to be addressed after the `$ref` and `$dynamicRef` resolution is fixed, as proper resolution is key to knowing which subschemas have been applied.
3. **`not` Keyword Failures:** Address failures related to the `not` keyword, especially in scenarios involving complex applicators.
4. **Remote References:** Implement support for remote references (i.e., `$ref` pointing to other files or URLs). This is a lower priority than fixing the local resolution logic.
5. **Format Vocabulary:** Implement the vocabulary check for the `format` keyword to enable assertion behavior based on the schema's `$vocabulary`.
