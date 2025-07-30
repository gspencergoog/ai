# TODO

The `dart_schema_builder` package is being updated to be compliant with the [JSON Schema Draft 2020-12 specification](https://json-schema.org/draft/2020-12). The primary method for ensuring compliance is by passing the official JSON Schema Test Suite.

## Current Status

- **Test Suite Enabled:** All non-optional, non-remote tests from the official JSON Schema Test Suite for Draft 2020-12 have been enabled. This provides a clear view of the remaining compliance gaps.
- **Reference Resolution Refactored:** The validation logic has been refactored to use a central `SchemaRegistry` for all `$ref` resolution. This has fixed a large number of local reference resolution failures (`#/...` pointers).
- **Identified Failure Areas:** The primary blocker is now the resolution of relative remote references. Tests in `defs.json` are failing because the validator cannot resolve URIs like `meta/core`. This points to an issue with how the base URI for resolution is being determined and applied, especially in the context of schemas loaded from the local test server. The key areas of failure are:
  - **Relative Remote References:** The logic for resolving a relative URI against the current schema's base URI (defined by its `$id` or file location) is incorrect.
  - **`$dynamicRef` and `$dynamicAnchor`:** The dynamic scope resolution is not fully correct, leading to false positives and negatives where data is incorrectly validated against the wrong schema. This is likely blocked by the reference resolution issues.
  - **`$ref` with Sibling Keywords:** The logic for applying keywords alongside a `$ref` is causing infinite recursion or incorrect validation outcomes.
  - **`unevaluatedProperties` and `unevaluatedItems`:** These keywords are still largely failing, likely blocked by the remaining issues in reference resolution and applicator logic.

## Next Steps

The main focus remains on resolving the fundamental reference and applicator mechanisms, as these are critical blockers for a large portion of the failing tests.

1. **Fix Relative Remote Reference Resolution:** This is the highest priority. The validator must correctly resolve relative URI references against the base URI of the schema they appear in. This will involve debugging the `defs.json` failures and ensuring the `sourceUri` and `$id` attributes are correctly managed in the `SchemaRegistry`.
2. **`$ref` with Sibling Keyword Validation:** The current implementation that merges a referenced schema with sibling keywords is causing infinite recursion. This needs to be fixed to correctly handle validation for keywords that appear alongside a `$ref`.
3. **`$dynamicRef` Scope Resolution:** Systematically debug the remaining `dynamicRef.json` test failures to correct the dynamic scope resolution and ensure the correct schema is used for validation in all scenarios.
4. **`unevaluatedProperties` and `unevaluatedItems`:** Once reference resolution and applicator logic are stable, revisit the implementation for tracking evaluated properties and items to ensure it is spec-compliant.
5. **Remote and Complex References:** Full support for remote references (including HTTP and URNs) and more complex resolution scenarios needs to be completed.
6. **Format Vocabulary:** Implement the vocabulary check for the `format` keyword to enable assertion behavior based on the schema's `$vocabulary`.
