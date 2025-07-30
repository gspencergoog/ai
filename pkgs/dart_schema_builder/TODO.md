# TODO

The `dart_schema_builder` package is being updated to be compliant with the [JSON Schema Draft 2020-12 specification](https://json-schema.org/draft/2020-12). The primary method for ensuring compliance is by passing the official JSON Schema Test Suite.

## Current Status

- **`$dynamicRef` Fixed:** The `$dynamicRef` implementation has been corrected to properly resolve the outermost dynamic anchor in the dynamic scope, aligning with the specification.
- **Vocabulary Checks Implemented:** The validator now respects the `$vocabulary` keyword in meta-schemas, ensuring that validation keywords are only applied when the appropriate vocabulary is declared.
- **Improved Annotation Propagation:** The logic for collecting annotations from subschemas has been improved, particularly for `if/then/else`, `allOf`, and `anyOf` constructs. This has fixed several failures related to `unevaluatedProperties` and `unevaluatedItems`.
- **`$anchor` Resolution Fixed:** The resolution of `$anchor` keywords now correctly respects schema resource boundaries, preventing incorrect resolutions when multiple anchors with the same name exist in different schema resources.
- **`refRemote.json` Failures Fixed:** The `refRemote.json` tests are now passing, indicating that the issue with relative URI resolution in the `SchemaRegistry` has been fixed.
- **All Tests Passing:** All tests in the JSON Schema Test Suite are now passing.

## Next Steps

The main focus is now on a final review of the code to remove any debugging code that was added and to ensure that the code is clean and readable.