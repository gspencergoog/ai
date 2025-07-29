# TODO

The `dart_schema_builder` package is being updated to be compliant with the [JSON Schema Draft 2020-12 specification](https://json-schema.org/draft/2020-12). The primary method for ensuring compliance is by passing the official JSON Schema Test Suite.

## Current Status

- **Test Suite Enabled:** All non-optional, non-remote tests from the official JSON Schema Test Suite for Draft 2020-12 have been enabled. This provides a clear view of the remaining compliance gaps.
- **Reference Resolution Progress:** Significant progress has been made on `$ref` and `$dynamicRef` resolution. The implementation now handles local, file-based, and anchor-based (`$id`, `$anchor`) references. Most `refResolutionError` failures have been eliminated.
- **Identified Failure Areas:** While direct resolution errors are mostly fixed, numerous tests for `$ref` and `$dynamicRef` still fail. The failures now point to incorrect validation logic *after* the reference has been resolved, especially concerning how sibling keywords and applicator keywords (`allOf`, `anyOf`, etc.) interact with the resolved schema. The primary areas of failure include:
  - **`$dynamicRef` and `$dynamicAnchor`:** The dynamic scope resolution is not fully correct, leading to false positives and negatives where data is incorrectly validated against the wrong schema.
  - **`$ref` with Sibling Keywords:** The logic for applying keywords alongside a `$ref` is causing infinite recursion or incorrect validation outcomes.
  - **`unevaluatedProperties` and `unevaluatedItems`:** These keywords are still largely failing, likely blocked by the remaining issues in reference resolution and applicator logic.

## Next Steps

The main focus remains on resolving the fundamental reference and applicator mechanisms, as these are critical blockers for a large portion of the failing tests.

1.  **`$ref` with Sibling Keyword Validation:** This is the highest priority. The current implementation that merges a referenced schema with sibling keywords is causing infinite recursion. This needs to be fixed to correctly handle validation for keywords that appear alongside a `$ref`.
2.  **`$dynamicRef` Scope Resolution:** Systematically debug the remaining `dynamicRef.json` test failures to correct the dynamic scope resolution and ensure the correct schema is used for validation in all scenarios.
3.  **`unevaluatedProperties` and `unevaluatedItems`:** Once reference resolution and applicator logic are stable, revisit the implementation for tracking evaluated properties and items to ensure it is spec-compliant.
4.  **Remote and Complex References:** Full support for remote references (including HTTP and URNs) and more complex resolution scenarios needs to be completed.
5.  **Format Vocabulary:** Implement the vocabulary check for the `format` keyword to enable assertion behavior based on the schema's `$vocabulary`.