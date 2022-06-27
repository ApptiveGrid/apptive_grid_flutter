import 'package:apptive_grid_core/apptive_grid_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Equality', () {
    test('From Json == Direct', () {
      const field = GridField(
        id: 'id',
        name: 'name',
        type: DataType.text,
        schema: {
          'properties': [
            {'type': 'string'}
          ]
        },
      );
      const value = 'value';

      final direct = GridEntry(field, StringDataEntity(value));
      final fromJson = GridEntry.fromJson(
        value,
        field,
      );

      expect(fromJson, equals(direct));
      expect(fromJson.hashCode, equals(direct.hashCode));
    });

    test('UnEqual', () {
      const field = GridField(id: 'id', name: 'name', type: DataType.text);
      const value = 'value';

      final single = GridEntry(field, StringDataEntity(value));
      final double = GridEntry(field, StringDataEntity(value + value));

      expect(single, isNot(double));
      expect(single.hashCode, isNot(double.hashCode));
    });
  });
}
