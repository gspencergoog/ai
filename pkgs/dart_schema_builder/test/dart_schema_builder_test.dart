import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:test/test.dart';

void main() {
  test('validate schema', () {
    final schema = Schema.object(
      properties: {
        'name': Schema.string(),
        'age': Schema.int(),
      },
      required: ['name'],
    );

    final validData = {'name': 'John Doe', 'age': 30};
    final invalidData = {'age': 30};
    final invalidData2 = {'name': 'John Doe', 'age': 'thirty'};

    expect(schema.validate(validData), isEmpty);
    expect(schema.validate(invalidData), isNotEmpty);
    expect(schema.validate(invalidData2), isNotEmpty);
  });
}