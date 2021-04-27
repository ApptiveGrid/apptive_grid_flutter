import 'package:active_grid_core/active_grid_model.dart';
import 'package:active_grid_form/widgets/active_grid_form_widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Mapping', () {
    test('TextComponent', () {
      final component = StringFormComponent(
        fieldId: 'id',
        data: StringDataEntity(),
        property: 'Property',
        required: false,
        options: TextComponentOptions(),
      );

      final widget = fromModel(component);

      expect(widget.runtimeType, TextFormWidget);
    });

    test('NumberComponent', () {
      final component = IntegerFormComponent(
        fieldId: 'id',
        data: IntegerDataEntity(),
        property: 'Property',
        required: false,
        options: TextComponentOptions(),
      );

      final widget = fromModel(component);

      expect(widget.runtimeType, NumberFormWidget);
    });

    test('DateComponent', () {
      final component = DateFormComponent(
        fieldId: 'id',
        data: DateDataEntity(),
        property: 'Property',
        required: false,
        options: FormComponentOptions(),
      );

      final widget = fromModel(component);

      expect(widget.runtimeType, DateFormWidget);
    });

    test('DateTimeComponent', () {
      final component = DateTimeFormComponent(
        fieldId: 'id',
        data: DateTimeDataEntity(),
        property: 'Property',
        required: false,
        options: FormComponentOptions(),
      );

      final widget = fromModel(component);

      expect(widget.runtimeType, DateTimeFormWidget);
    });

    test('CheckBoxComponent', () {
      final component = BooleanFormComponent(
        fieldId: 'id',
        data: BooleanDataEntity(),
        property: 'Property',
        required: false,
        options: FormComponentOptions(),
      );

      final widget = fromModel(component);

      expect(widget.runtimeType, CheckBoxFormWidget);
    });

    test('EnumComponent', () {
      final component = EnumFormComponent(
        fieldId: 'id',
        data: EnumDataEntity(),
        property: 'Property',
        required: false,
        options: FormComponentOptions(),
      );

      final widget = fromModel(component);

      expect(widget.runtimeType, EnumFormWidget);
    });

    test('ArgumentError', () {
      final component = UnknownComponent();

      expect(() => fromModel(component), throwsArgumentError);
    });
  });
}

class UnknownComponent extends FormComponent<UnknownDataEntity> {
  @override
  FormComponentOptions get options => FormComponentOptions();

  @override
  String get property => 'Property';

  @override
  bool get required => false;

  @override
  String get fieldId => 'id';

  @override
  UnknownDataEntity get data => UnknownDataEntity();
}

class UnknownDataEntity extends DataEntity<String, String> {
  @override
  String? get schemaValue => null;
}