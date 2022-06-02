import 'dart:async';

import 'package:apptive_grid_form/apptive_grid_form.dart';
import 'package:apptive_grid_form/widgets/apptive_grid_form_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:mocktail/mocktail.dart';

import 'common.dart';

void main() {
  late ApptiveGridClient client;
  setUpAll(() {
    registerFallbackValue(
      FormData(
        id: 'formId',
        name: 'name',
        title: 'title',
        components: [],
        schema: {},
        links: {},
      ),
    );
  });

  setUp(() {
    client = MockApptiveGridClient();

    when(() => client.sendPendingActions()).thenAnswer((invocation) async {});
  });

  Map<String, dynamic> getSchema(
    String type, {
    String? format,
    List<String>? options,
  }) {
    final propertyMap = <String, dynamic>{'type': type};
    if (format != null) {
      propertyMap['format'] = format;
    }
    if (options != null) {
      propertyMap['enum'] = options;
    }
    return {
      'type': 'object',
      'properties': {
        'id': propertyMap,
      },
      'required': []
    };
  }

  group('Text', () {
    testWidgets('Value is send', (tester) async {
      final action = ApptiveLink(uri: Uri.parse('uri'), method: 'method');
      final component = StringFormComponent(
        fieldId: 'id',
        data: StringDataEntity(),
        property: 'Property',
        options: const TextComponentOptions(),
        required: false,
      );
      final formData = FormData(
        id: 'formId',
        name: 'Form Name',
        title: 'Form Title',
        components: [component],
        links: {ApptiveLinkType.submit: action},
        schema: getSchema('string'),
      );
      final target = TestApp(
        client: client,
        child: ApptiveGridForm(
          uri: Uri.parse('/api/a/formId'),
        ),
      );

      final completer = Completer<FormData>();
      when(
        () => client.loadForm(uri: Uri.parse('/api/a/formId')),
      ).thenAnswer((_) async => formData);
      when(() => client.submitForm(action, any()))
          .thenAnswer((realInvocation) async {
        completer.complete(realInvocation.positionalArguments[1]);
        return Response('', 200);
      });

      await tester.pumpWidget(target);
      await tester.pumpAndSettle();

      expect(find.byType(TextFormWidget), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'Value');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ActionButton));
      await tester.pumpAndSettle();

      final result = await completer.future;
      expect(result.components!.first.data.value, equals('Value'));
    });

    testWidgets('Required shows Error', (tester) async {
      final action = ApptiveLink(uri: Uri.parse('uri'), method: 'method');
      final component = StringFormComponent(
        fieldId: 'id',
        data: StringDataEntity(),
        property: 'Property',
        options: const TextComponentOptions(),
        required: true,
      );
      final formData = FormData(
        id: 'formId',
        name: 'Form Name',
        title: 'Form Title',
        components: [component],
        links: {ApptiveLinkType.submit: action},
        schema: getSchema('string'),
      );
      final target = TestApp(
        client: client,
        child: ApptiveGridForm(
          uri: Uri.parse('/api/a/formId'),
        ),
      );

      when(
        () => client.loadForm(uri: Uri.parse('/api/a/formId')),
      ).thenAnswer((_) async => formData);

      await tester.pumpWidget(target);
      await tester.pumpAndSettle();

      expect(find.byType(TextFormWidget), findsOneWidget);

      await tester.tap(find.byType(ActionButton));
      await tester.pumpAndSettle();

      verifyNever(() => client.submitForm(action, formData));
      expect(find.text('Property must not be empty'), findsOneWidget);
    });
  });

  group('DateTime', () {
    testWidgets('Value is send and used with Date Picker', (tester) async {
      final action = ApptiveLink(uri: Uri.parse('uri'), method: 'method');
      final component = DateTimeFormComponent(
        fieldId: 'id',
        data: DateTimeDataEntity(),
        property: 'Property',
        options: const FormComponentOptions(),
        required: false,
      );
      final formData = FormData(
        id: 'formId',
        name: 'Form Name',
        title: 'Form Title',
        components: [component],
        links: {ApptiveLinkType.submit: action},
        schema: getSchema('string', format: 'date-time'),
      );
      final target = TestApp(
        client: client,
        child: ApptiveGridForm(
          uri: Uri.parse('/api/a/formId'),
        ),
      );

      final completer = Completer<FormData>();
      when(
        () => client.loadForm(uri: Uri.parse('/api/a/formId')),
      ).thenAnswer((_) async => formData);
      when(() => client.submitForm(action, any()))
          .thenAnswer((realInvocation) async {
        completer.complete(realInvocation.positionalArguments[1]);
        return Response('', 200);
      });

      final now = DateTime.now();
      final date = DateTime(now.year, now.month, now.day, 0, 0);

      await tester.pumpWidget(target);
      await tester.pumpAndSettle();

      expect(find.byType(DateTimeFormWidget), findsOneWidget);

      await tester.tap(
        find.text('Date'),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.text('OK'),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ActionButton));
      await tester.pumpAndSettle();

      final result = await completer.future;
      expect(result.components!.first.data.value, equals(date));
    });

    testWidgets('Value is send and used with Time Picker', (tester) async {
      final action = ApptiveLink(uri: Uri.parse('uri'), method: 'method');
      final component = DateTimeFormComponent(
        fieldId: 'id',
        data: DateTimeDataEntity(),
        property: 'Property',
        options: const FormComponentOptions(),
        required: false,
      );
      final formData = FormData(
        id: 'formId',
        name: 'Form Name',
        title: 'Form Title',
        components: [component],
        links: {ApptiveLinkType.submit: action},
        schema: getSchema('string', format: 'date-time'),
      );
      final target = TestApp(
        client: client,
        child: ApptiveGridForm(
          uri: Uri.parse('/api/a/formId'),
        ),
      );

      final completer = Completer<FormData>();
      when(
        () => client.loadForm(uri: Uri.parse('/api/a/formId')),
      ).thenAnswer((_) async => formData);
      when(() => client.submitForm(action, any()))
          .thenAnswer((realInvocation) async {
        completer.complete(realInvocation.positionalArguments[1]);
        return Response('', 200);
      });

      final now = DateTime.now();
      final date = DateTime(now.year, now.month, now.day, now.hour, now.minute);

      await tester.pumpWidget(target);
      await tester.pumpAndSettle();

      expect(find.byType(DateTimeFormWidget), findsOneWidget);

      await tester.tap(
        find.text('Time'),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.text('OK'),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ActionButton));
      await tester.pumpAndSettle();

      final result = await completer.future
          .then((data) => data.components!.first.data.value as DateTime);
      expect(
        DateTime(
          result.year,
          result.month,
          result.day,
          result.hour,
          result.minute,
        ),
        date,
      );
    });

    testWidgets('Required shows Error', (tester) async {
      final action = ApptiveLink(uri: Uri.parse('uri'), method: 'method');
      final component = DateTimeFormComponent(
        fieldId: 'id',
        data: DateTimeDataEntity(),
        property: 'Property',
        options: const FormComponentOptions(),
        required: true,
      );
      final formData = FormData(
        id: 'formId',
        name: 'Form Name',
        title: 'Form Title',
        components: [component],
        links: {ApptiveLinkType.submit: action},
        schema: getSchema('string', format: 'date-time'),
      );
      final target = TestApp(
        client: client,
        child: ApptiveGridForm(
          uri: Uri.parse('/api/a/formId'),
        ),
      );

      when(
        () => client.loadForm(uri: Uri.parse('/api/a/formId')),
      ).thenAnswer((_) async => formData);

      await tester.pumpWidget(target);
      await tester.pumpAndSettle();

      expect(find.byType(DateTimeFormWidget), findsOneWidget);

      await tester.tap(find.byType(ActionButton));
      await tester.pumpAndSettle();

      verifyNever(() => client.submitForm(action, formData));
      expect(find.text('Property must not be empty'), findsOneWidget);
    });
  });

  group('Date', () {
    testWidgets('Value is send', (tester) async {
      final action = ApptiveLink(uri: Uri.parse('uri'), method: 'method');
      final component = DateFormComponent(
        fieldId: 'id',
        data: DateDataEntity(),
        property: 'Property',
        options: const FormComponentOptions(),
        required: false,
      );
      final formData = FormData(
        id: 'formId',
        name: 'Form Name',
        title: 'Form Title',
        components: [component],
        links: {ApptiveLinkType.submit: action},
        schema: getSchema('string', format: 'date'),
      );
      final target = TestApp(
        client: client,
        child: ApptiveGridForm(
          uri: Uri.parse('/api/a/formId'),
        ),
      );

      final completer = Completer<FormData>();
      when(
        () => client.loadForm(uri: Uri.parse('/api/a/formId')),
      ).thenAnswer((_) async => formData);
      when(() => client.submitForm(action, any()))
          .thenAnswer((realInvocation) async {
        completer.complete(realInvocation.positionalArguments[1]);
        return Response('', 200);
      });

      final now = DateTime.now();
      final date = DateTime(now.year, now.month, now.day, 0, 0);

      await tester.pumpWidget(target);
      await tester.pumpAndSettle();

      expect(find.byType(DateFormWidget), findsOneWidget);

      await tester.tap(
        find.byType(DateFormWidget),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.text('OK'),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ActionButton));
      await tester.pumpAndSettle();

      final result = await completer.future;
      expect(result.components!.first.data.value, equals(date));
    });

    testWidgets('Required shows Error', (tester) async {
      final action = ApptiveLink(uri: Uri.parse('uri'), method: 'method');
      final component = DateFormComponent(
        fieldId: 'id',
        data: DateDataEntity(),
        property: 'Property',
        options: const FormComponentOptions(),
        required: true,
      );
      final formData = FormData(
        id: 'formId',
        name: 'Form Name',
        title: 'Form Title',
        components: [component],
        links: {ApptiveLinkType.submit: action},
        schema: getSchema('string', format: 'date'),
      );
      final target = TestApp(
        client: client,
        child: ApptiveGridForm(
          uri: Uri.parse('/api/a/formId'),
        ),
      );

      when(
        () => client.loadForm(uri: Uri.parse('/api/a/formId')),
      ).thenAnswer((_) async => formData);

      await tester.pumpWidget(target);
      await tester.pumpAndSettle();

      expect(find.byType(DateFormWidget), findsOneWidget);

      await tester.tap(find.byType(ActionButton));
      await tester.pumpAndSettle();

      verifyNever(() => client.submitForm(action, formData));
      expect(find.text('Property must not be empty'), findsOneWidget);
    });
  });

  group('Number', () {
    testWidgets('Value is send', (tester) async {
      final action = ApptiveLink(uri: Uri.parse('uri'), method: 'method');
      final component = IntegerFormComponent(
        fieldId: 'id',
        data: IntegerDataEntity(),
        property: 'Property',
        options: const TextComponentOptions(),
        required: false,
      );
      final formData = FormData(
        id: 'formId',
        name: 'Form Name',
        title: 'Form Title',
        components: [component],
        links: {ApptiveLinkType.submit: action},
        schema: getSchema('integer'),
      );
      final target = TestApp(
        client: client,
        child: ApptiveGridForm(
          uri: Uri.parse('/api/a/formId'),
        ),
      );

      final completer = Completer<FormData>();
      when(
        () => client.loadForm(uri: Uri.parse('/api/a/formId')),
      ).thenAnswer((_) async => formData);
      when(() => client.submitForm(action, any()))
          .thenAnswer((realInvocation) async {
        completer.complete(realInvocation.positionalArguments[1]);
        return Response('', 200);
      });

      await tester.pumpWidget(target);
      await tester.pumpAndSettle();

      expect(find.byType(IntegerFormWidget), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), '12');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ActionButton));
      await tester.pumpAndSettle();

      final result = await completer.future;
      expect(result.components!.first.data.value, equals(12));
    });

    testWidgets('Prefilled Value gets displayed', (tester) async {
      final component = IntegerFormComponent(
        fieldId: 'id',
        data: IntegerDataEntity(123),
        property: 'Property',
        options: const TextComponentOptions(),
        required: false,
      );
      final formData = FormData(
        id: 'formId',
        name: 'Form Name',
        title: 'Form Title',
        components: [component],
        schema: getSchema('integer'),
        links: {},
      );
      final target = TestApp(
        client: client,
        child: ApptiveGridForm(
          uri: Uri.parse('/api/a/formId'),
        ),
      );

      when(
        () => client.loadForm(uri: Uri.parse('/api/a/formId')),
      ).thenAnswer((_) async => formData);

      await tester.pumpWidget(target);
      await tester.pumpAndSettle();

      expect(find.text('123'), findsOneWidget);
    });

    testWidgets('Required shows Error', (tester) async {
      final action = ApptiveLink(uri: Uri.parse('uri'), method: 'method');
      final component = IntegerFormComponent(
        fieldId: 'id',
        data: IntegerDataEntity(),
        property: 'Property',
        options: const TextComponentOptions(),
        required: true,
      );
      final formData = FormData(
        id: 'formId',
        name: 'Form Name',
        title: 'Form Title',
        components: [component],
        links: {ApptiveLinkType.submit: action},
        schema: getSchema('integer'),
      );
      final target = TestApp(
        client: client,
        child: ApptiveGridForm(
          uri: Uri.parse('/api/a/formId'),
        ),
      );

      when(
        () => client.loadForm(uri: Uri.parse('/api/a/formId')),
      ).thenAnswer((_) async => formData);

      await tester.pumpWidget(target);
      await tester.pumpAndSettle();

      expect(find.byType(IntegerFormWidget), findsOneWidget);

      await tester.tap(find.byType(ActionButton));
      await tester.pumpAndSettle();

      verifyNever(() => client.submitForm(action, formData));
      expect(find.text('Property must not be empty'), findsOneWidget);
    });
  });

  group('Decimal', () {
    testWidgets('Value is send', (tester) async {
      final action = ApptiveLink(uri: Uri.parse('uri'), method: 'method');
      final component = DecimalFormComponent(
        fieldId: 'id',
        data: DecimalDataEntity(),
        property: 'Property',
        options: const TextComponentOptions(),
        required: false,
      );
      final formData = FormData(
        id: 'formId',
        name: 'Form Name',
        title: 'Form Title',
        components: [component],
        links: {ApptiveLinkType.submit: action},
        schema: getSchema('number'),
      );
      final target = TestApp(
        client: client,
        child: ApptiveGridForm(
          uri: Uri.parse('/api/a/formId'),
        ),
      );

      final completer = Completer<FormData>();
      when(
        () => client.loadForm(uri: Uri.parse('/api/a/formId')),
      ).thenAnswer((_) async => formData);
      when(() => client.submitForm(action, any()))
          .thenAnswer((realInvocation) async {
        completer.complete(realInvocation.positionalArguments[1]);
        return Response('', 200);
      });

      await tester.pumpWidget(target);
      await tester.pumpAndSettle();

      expect(find.byType(DecimalFormWidget), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), '12');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ActionButton));
      await tester.pumpAndSettle();

      final result = await completer.future;
      expect(result.components!.first.data.value, equals(12));
    });

    testWidgets('Prefilled Value gets displayed', (tester) async {
      final component = DecimalFormComponent(
        fieldId: 'id',
        data: DecimalDataEntity(47.11),
        property: 'Property',
        options: const TextComponentOptions(),
        required: false,
      );
      final formData = FormData(
        id: 'formId',
        name: 'Form Name',
        title: 'Form Title',
        components: [component],
        schema: getSchema('number'),
        links: {},
      );
      final target = TestApp(
        client: client,
        child: ApptiveGridForm(
          uri: Uri.parse('/api/a/formId'),
        ),
      );

      when(
        () => client.loadForm(uri: Uri.parse('/api/a/formId')),
      ).thenAnswer((_) async => formData);

      await tester.pumpWidget(target);
      await tester.pumpAndSettle();

      expect(find.text('47.11'), findsOneWidget);
    });

    testWidgets('Required shows Error', (tester) async {
      final action = ApptiveLink(uri: Uri.parse('uri'), method: 'method');
      final component = DecimalFormComponent(
        fieldId: 'id',
        data: DecimalDataEntity(),
        property: 'Property',
        options: const TextComponentOptions(),
        required: true,
      );
      final formData = FormData(
        id: 'formId',
        name: 'Form Name',
        title: 'Form Title',
        components: [component],
        links: {ApptiveLinkType.submit: action},
        schema: getSchema('number'),
      );
      final target = TestApp(
        client: client,
        child: ApptiveGridForm(
          uri: Uri.parse('/api/a/formId'),
        ),
      );

      when(
        () => client.loadForm(uri: Uri.parse('/api/a/formId')),
      ).thenAnswer((_) async => formData);

      await tester.pumpWidget(target);
      await tester.pumpAndSettle();

      expect(find.byType(DecimalFormWidget), findsOneWidget);

      await tester.tap(find.byType(ActionButton));
      await tester.pumpAndSettle();

      verifyNever(() => client.submitForm(action, formData));
      expect(find.text('Property must not be empty'), findsOneWidget);
    });
  });

  group('CheckBox', () {
    testWidgets('Value is send', (tester) async {
      final action = ApptiveLink(uri: Uri.parse('uri'), method: 'method');
      final component = BooleanFormComponent(
        fieldId: 'id',
        data: BooleanDataEntity(),
        property: 'Property',
        options: const FormComponentOptions(),
        required: false,
      );
      final formData = FormData(
        id: 'formId',
        name: 'Form Name',
        title: 'Form Title',
        components: [component],
        links: {ApptiveLinkType.submit: action},
        schema: getSchema('boolean'),
      );
      final target = TestApp(
        client: client,
        child: ApptiveGridForm(
          uri: Uri.parse('/api/a/formId'),
        ),
      );

      final completer = Completer<FormData>();
      when(
        () => client.loadForm(uri: Uri.parse('/api/a/formId')),
      ).thenAnswer((_) async => formData);
      when(() => client.submitForm(action, any()))
          .thenAnswer((realInvocation) async {
        completer.complete(realInvocation.positionalArguments[1]);
        return Response('', 200);
      });

      await tester.pumpWidget(target);
      await tester.pumpAndSettle();

      expect(find.byType(CheckBoxFormWidget), findsOneWidget);

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ActionButton));
      await tester.pumpAndSettle();

      final result = await completer.future;
      expect(result.components!.first.data.value, equals(true));
    });

    testWidgets('Required shows Error', (tester) async {
      final action = ApptiveLink(uri: Uri.parse('uri'), method: 'method');
      final component = BooleanFormComponent(
        fieldId: 'id',
        data: BooleanDataEntity(),
        property: 'Property',
        options: const FormComponentOptions(),
        required: true,
      );
      final formData = FormData(
        id: 'formId',
        name: 'Form Name',
        title: 'Form Title',
        components: [component],
        links: {ApptiveLinkType.submit: action},
        schema: getSchema('boolean'),
      );
      final target = TestApp(
        client: client,
        child: ApptiveGridForm(
          uri: Uri.parse('/api/a/formId'),
        ),
      );

      when(
        () => client.loadForm(uri: Uri.parse('/api/a/formId')),
      ).thenAnswer((_) async => formData);

      await tester.pumpWidget(target);
      await tester.pumpAndSettle();

      expect(find.byType(CheckBoxFormWidget), findsOneWidget);

      await tester.tap(find.byType(ActionButton));
      await tester.pumpAndSettle();

      verifyNever(() => client.submitForm(action, formData));
      expect(find.text('Required'), findsOneWidget);
    });
  });

  group('Enum', () {
    testWidgets('Value is send', (tester) async {
      final action = ApptiveLink(uri: Uri.parse('uri'), method: 'method');
      final component = EnumFormComponent(
        fieldId: 'id',
        data: EnumDataEntity(value: 'value', options: {'value', 'newValue'}),
        property: 'Property',
        options: const FormComponentOptions(),
        required: false,
      );
      final formData = FormData(
        id: 'formId',
        name: 'Form Name',
        title: 'Form Title',
        components: [component],
        links: {ApptiveLinkType.submit: action},
        schema: getSchema('string', options: ['value', 'newValue']),
      );
      final target = TestApp(
        client: client,
        child: ApptiveGridForm(
          uri: Uri.parse('/api/a/formId'),
        ),
      );

      final completer = Completer<FormData>();
      when(
        () => client.loadForm(uri: Uri.parse('/api/a/formId')),
      ).thenAnswer((_) async => formData);
      when(() => client.submitForm(action, any()))
          .thenAnswer((realInvocation) async {
        completer.complete(realInvocation.positionalArguments[1]);
        return Response('', 200);
      });

      await tester.pumpWidget(target);
      await tester.pumpAndSettle();

      expect(find.byType(EnumFormWidget), findsOneWidget);

      await tester.tap(find.text('value'));
      await tester.pumpAndSettle();
      // Dropdown creates multiple instances. Use last inspired by original test
      // https://github.com/flutter/flutter/blob/fc9addb88b5262ce98e8f39b0eefa6fa9be2ca6a/packages/flutter/test/material/dropdown_test.dart#L356
      await tester.tap(find.text('newValue').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ActionButton));
      await tester.pumpAndSettle();

      final result = await completer.future;
      expect(result.components!.first.data.value, equals('newValue'));
    });

    testWidgets('Required shows Error', (tester) async {
      final action = ApptiveLink(uri: Uri.parse('uri'), method: 'method');
      final component = EnumFormComponent(
        fieldId: 'id',
        data: EnumDataEntity(options: {'value'}),
        property: 'Property',
        options: const FormComponentOptions(),
        required: true,
      );
      final formData = FormData(
        id: 'formId',
        name: 'Form Name',
        title: 'Form Title',
        components: [component],
        links: {ApptiveLinkType.submit: action},
        schema: getSchema(
          'string',
          options: [
            'value',
          ],
        ),
      );
      final target = TestApp(
        client: client,
        child: ApptiveGridForm(
          uri: Uri.parse('/api/a/formId'),
        ),
      );

      when(
        () => client.loadForm(uri: Uri.parse('/api/a/formId')),
      ).thenAnswer((_) async => formData);

      await tester.pumpWidget(target);
      await tester.pumpAndSettle();

      expect(find.byType(EnumFormWidget), findsOneWidget);

      await tester.tap(find.byType(ActionButton));
      await tester.pumpAndSettle();

      verifyNever(() => client.submitForm(action, formData));
      expect(find.text('Property must not be empty'), findsOneWidget);
    });
  });
}
