# TODO

The `dart_schema_builder` package is being updated to be compliant with the [JSON Schema Draft 2020-12 specification](https://json-schema.org/draft/2020-12). The primary method for ensuring compliance is by passing the official JSON Schema Test Suite.

## Current Status

- **`defs.json` and `not.json` Passing:** The `defs.json` and `not.json` test suites are now passing, indicating that local reference resolution and basic applicator logic are stable.
- **`unevaluatedProperties` In Progress:** Work was done to address the `unevaluatedProperties` failures. Several approaches were attempted to correctly manage the `evaluatedKeys` across different applicator keywords (`if/then/else`, `anyOf`, `oneOf`, `not`, `allOf`). These changes involved creating isolated validation contexts for subschemas to prevent incorrect propagation of evaluated keys. While these changes fixed some tests, they caused regressions in others, indicating a more fundamental issue in the applicator interaction logic. All changes have been reverted to restore the baseline. The core of the issue remains correctly tracking evaluated properties across complex, nested applicator schemas.
- **`unevaluatedItems` Failing:** The `unevaluatedItems.json` test suite was enabled and shows widespread failures. These failures are likely related to the same core issues blocking `unevaluatedProperties`.
- **Identified Failure Areas:** The primary blockers are the resolution of remote references and the complex interaction of applicator keywords (`if/then/else`, `anyOf`, etc.) with `unevaluatedProperties` and `unevaluatedItems`.
  - **Relative Remote References:** The logic for resolving a relative URI against the current schema's base URI (defined by its `$id` or file location) is incorrect.
  - **`$dynamicRef` and `$dynamicAnchor`:** The dynamic scope resolution is not fully correct. This is likely blocked by the reference resolution issues.

## Next Steps

The main focus remains on resolving the fundamental reference and applicator mechanisms, as these are critical blockers for a large portion of the failing tests.

1. **Fix `unevaluatedProperties`:** This remains the highest priority. A deeper investigation into the JSON Schema specification for applicator interaction and annotation collection is needed to correctly implement the `evaluatedKeys` propagation logic.
2. **Fix Relative Remote Reference Resolution:** As the applicator logic is proving difficult, switching focus to fixing remote reference resolution (`refRemote.json`) may be a more productive path forward and could unblock other test suites.
3. **Address `unevaluatedItems`:** This is blocked pending the resolution of the `unevaluatedProperties` and reference resolution issues.
4. **`$dynamicRef` Scope Resolution:** This is likely blocked by the reference resolution issues.
5. **Remote and Complex References:** Full support for remote references (including HTTP and URNs) and more complex resolution scenarios needs to be completed.
6. **Format Vocabulary:** Implement the vocabulary check for the `format` keyword to enable assertion behavior based on the schema's `$vocabulary`.
