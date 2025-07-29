# TODO

The `dart_schema_builder` package is being updated to be compliant with the JSON Schema Draft 2020-12 specification. The primary method for ensuring compliance is by passing the official JSON Schema Test Suite.

## Current Status

- The `uniqueItems` validation is still failing. The logic in `_validateList` appears correct, but it is not producing the expected validation errors. After fixing the cast errors, this is now the highest priority item to fix.
- The boolean schema handling has been fixed by introducing a `_schemaOrBool` helper function and a `Schema.fromBoolean` factory. The cast errors in `ListSchema` and `ObjectSchema` have been resolved.
- The `_getFormatRegex` method in `StringSchema` is still missing and needs to be re-implemented.
- There are many failures related to `$ref`, `$anchor`, and `$dynamicRef` that need to be addressed.

## Next Steps

1.  Re-evaluate the `uniqueItems` issue.
2.  Re-implement the `_getFormatRegex` method in `StringSchema`.
3.  Begin implementing support for `$ref`, `$anchor`, and `$dynamicRef`.