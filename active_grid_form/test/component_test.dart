import 'dart:async';

import 'package:active_grid_core/active_grid_model.dart' as model;
import 'package:active_grid_form/active_grid_form.dart';
import 'package:active_grid_form/widgets/active_grid_form_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart';

import 'common.dart';

void main() {
  group('Text', () {
    testWidgets('Value is send', (tester) async {
      final action = model.FormAction(
        'uri',
        'method',
      );
      final component = model.FormComponentText(
        data: model.StringDataEntity(),
        property: 'Property',
        options: model.TextComponentOptions(),
        required: false,
      );
      final formData = model.FormData('Title', [
        component,
      ], [
        action,
      ], {});
      final client = MockActiveGridClient();
      final target = TestApp(
        client: client,
        child: ActiveGridForm(
          formId: 'formId',
        ),
      );

      final completer = Completer<model.FormData>();
      when(client.loadForm(formId: anyNamed('formId')))
          .thenAnswer((_) async => formData);
      when(client.performAction(action, any))
          .thenAnswer((realInvocation) async {
        completer.complete(realInvocation.positionalArguments[1]);
        return Response('', 200);
      });

      await tester.pumpWidget(target);
      await tester.pumpAndSettle();

      expect(find.byType(FormComponentText), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'Value');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ActionButton));
      await tester.pumpAndSettle();

      final result = await completer.future;
      expect(result.components.first.data.value, 'Value');
    });

    testWidgets('Required shows Error', (tester) async {
      final action = model.FormAction(
        'uri',
        'method',
      );
      final component = model.FormComponentText(
        data: model.StringDataEntity(),
        property: 'Property',
        options: model.TextComponentOptions(),
        required: true,
      );
      final formData = model.FormData('Title', [
        component,
      ], [
        action,
      ], {});
      final client = MockActiveGridClient();
      final target = TestApp(
        client: client,
        child: ActiveGridForm(
          formId: 'formId',
        ),
      );

      when(client.loadForm(formId: anyNamed('formId')))
          .thenAnswer((_) async => formData);

      await tester.pumpWidget(target);
      await tester.pumpAndSettle();

      expect(find.byType(FormComponentText), findsOneWidget);

      await tester.tap(find.byType(ActionButton));
      await tester.pumpAndSettle();

      verifyNever(client.performAction(action, formData));
      expect(find.text('Property is required'), findsOneWidget);
    });
  });

  group('DateTime', () {
    testWidgets('Value is send and used with Date Picker', (tester) async {
      final action = model.FormAction(
        'uri',
        'method',
      );
      final component = model.FormComponentDateTime(
        data: model.DateTimeDataEntity(),
        property: 'Property',
        options: model.StubComponentOptions(),
        required: false,
      );
      final formData = model.FormData('Title', [
        component,
      ], [
        action,
      ], {});
      final client = MockActiveGridClient();
      final target = TestApp(
        client: client,
        child: ActiveGridForm(
          formId: 'formId',
        ),
      );

      final completer = Completer<model.FormData>();
      when(client.loadForm(formId: anyNamed('formId')))
          .thenAnswer((_) async => formData);
      when(client.performAction(action, any))
          .thenAnswer((realInvocation) async {
        completer.complete(realInvocation.positionalArguments[1]);
        return Response('', 200);
      });

      final now = DateTime.now();
      final date = DateTime(now.year, now.month, now.day, 0, 0);

      await tester.pumpWidget(target);
      await tester.pumpAndSettle();

      expect(find.byType(FormComponentDateTime), findsOneWidget);

      await tester.tap(
        find.text('Date'),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.text('OK'),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ActionButton));
      await tester.pumpAndSettle();

      final result = await completer.future;
      expect(result.components.first.data.value, date);
    });

    testWidgets('Value is send and used with Time Picker', (tester) async {
      final action = model.FormAction(
        'uri',
        'method',
      );
      final component = model.FormComponentDateTime(
        data: model.DateTimeDataEntity(),
        property: 'Property',
        options: model.StubComponentOptions(),
        required: false,
      );
      final formData = model.FormData('Title', [
        component,
      ], [
        action,
      ], {});
      final client = MockActiveGridClient();
      final target = TestApp(
        client: client,
        child: ActiveGridForm(
          formId: 'formId',
        ),
      );

      final completer = Completer<model.FormData>();
      when(client.loadForm(formId: anyNamed('formId')))
          .thenAnswer((_) async => formData);
      when(client.performAction(action, any))
          .thenAnswer((realInvocation) async {
        completer.complete(realInvocation.positionalArguments[1]);
        return Response('', 200);
      });

      final now = DateTime.now();
      final date = DateTime(now.year, now.month, now.day, now.hour, now.minute);

      await tester.pumpWidget(target);
      await tester.pumpAndSettle();

      expect(find.byType(FormComponentDateTime), findsOneWidget);

      await tester.tap(
        find.text('Time'),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.text('OK'),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ActionButton));
      await tester.pumpAndSettle();

      final result = await completer.future
          .then((data) => data.components.first.data.value as DateTime);
      expect(
          DateTime(result.year, result.month, result.day, result.hour,
              result.minute),
          date);
    });

    testWidgets('Required shows Error', (tester) async {
      final action = model.FormAction(
        'uri',
        'method',
      );
      final component = model.FormComponentDateTime(
        data: model.DateTimeDataEntity(),
        property: 'Property',
        options: model.StubComponentOptions(),
        required: true,
      );
      final formData = model.FormData('Title', [
        component,
      ], [
        action,
      ], {});
      final client = MockActiveGridClient();
      final target = TestApp(
        client: client,
        child: ActiveGridForm(
          formId: 'formId',
        ),
      );

      when(client.loadForm(formId: anyNamed('formId')))
          .thenAnswer((_) async => formData);

      await tester.pumpWidget(target);
      await tester.pumpAndSettle();

      expect(find.byType(FormComponentDateTime), findsOneWidget);

      await tester.tap(find.byType(ActionButton));
      await tester.pumpAndSettle();

      verifyNever(client.performAction(action, formData));
      expect(find.text('Property is required'), findsOneWidget);
    });
  });

  group('Date', () {
    testWidgets('Value is send', (tester) async {
      final action = model.FormAction(
        'uri',
        'method',
      );
      final component = model.FormComponentDate(
        data: model.DateDataEntity(),
        property: 'Property',
        options: model.StubComponentOptions(),
        required: false,
      );
      final formData = model.FormData('Title', [
        component,
      ], [
        action,
      ], {});
      final client = MockActiveGridClient();
      final target = TestApp(
        client: client,
        child: ActiveGridForm(
          formId: 'formId',
        ),
      );

      final completer = Completer<model.FormData>();
      when(client.loadForm(formId: anyNamed('formId')))
          .thenAnswer((_) async => formData);
      when(client.performAction(action, any))
          .thenAnswer((realInvocation) async {
        completer.complete(realInvocation.positionalArguments[1]);
        return Response('', 200);
      });

      final now = DateTime.now();
      final date = DateTime(now.year, now.month, now.day, 0, 0);

      await tester.pumpWidget(target);
      await tester.pumpAndSettle();

      expect(find.byType(FormComponentDate), findsOneWidget);

      await tester.tap(
        find.byType(FormComponentDate),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.text('OK'),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ActionButton));
      await tester.pumpAndSettle();

      final result = await completer.future;
      expect(result.components.first.data.value, date);
    });

    testWidgets('Required shows Error', (tester) async {
      final action = model.FormAction(
        'uri',
        'method',
      );
      final component = model.FormComponentDate(
        data: model.DateDataEntity(),
        property: 'Property',
        options: model.StubComponentOptions(),
        required: true,
      );
      final formData = model.FormData('Title', [
        component,
      ], [
        action,
      ], {});
      final client = MockActiveGridClient();
      final target = TestApp(
        client: client,
        child: ActiveGridForm(
          formId: 'formId',
        ),
      );

      when(client.loadForm(formId: anyNamed('formId')))
          .thenAnswer((_) async => formData);

      await tester.pumpWidget(target);
      await tester.pumpAndSettle();

      expect(find.byType(FormComponentDate), findsOneWidget);

      await tester.tap(find.byType(ActionButton));
      await tester.pumpAndSettle();

      verifyNever(client.performAction(action, formData));
      expect(find.text('Property is required'), findsOneWidget);
    });
  });

  group('Number', () {
    testWidgets('Value is send', (tester) async {
      final action = model.FormAction(
        'uri',
        'method',
      );
      final component = model.FormComponentNumber(
        data: model.IntegerDataEntity(),
        property: 'Property',
        options: model.TextComponentOptions(),
        required: false,
      );
      final formData = model.FormData('Title', [
        component,
      ], [
        action,
      ], {});
      final client = MockActiveGridClient();
      final target = TestApp(
        client: client,
        child: ActiveGridForm(
          formId: 'formId',
        ),
      );

      final completer = Completer<model.FormData>();
      when(client.loadForm(formId: anyNamed('formId')))
          .thenAnswer((_) async => formData);
      when(client.performAction(action, any))
          .thenAnswer((realInvocation) async {
        completer.complete(realInvocation.positionalArguments[1]);
        return Response('', 200);
      });

      await tester.pumpWidget(target);
      await tester.pumpAndSettle();

      expect(find.byType(FormComponentNumber), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), '12');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ActionButton));
      await tester.pumpAndSettle();

      final result = await completer.future;
      expect(result.components.first.data.value, 12);
    });

    testWidgets('Required shows Error', (tester) async {
      final action = model.FormAction(
        'uri',
        'method',
      );
      final component = model.FormComponentNumber(
        data: model.IntegerDataEntity(),
        property: 'Property',
        options: model.TextComponentOptions(),
        required: true,
      );
      final formData = model.FormData('Title', [
        component,
      ], [
        action,
      ], {});
      final client = MockActiveGridClient();
      final target = TestApp(
        client: client,
        child: ActiveGridForm(
          formId: 'formId',
        ),
      );

      when(client.loadForm(formId: anyNamed('formId')))
          .thenAnswer((_) async => formData);

      await tester.pumpWidget(target);
      await tester.pumpAndSettle();

      expect(find.byType(FormComponentNumber), findsOneWidget);

      await tester.tap(find.byType(ActionButton));
      await tester.pumpAndSettle();

      verifyNever(client.performAction(action, formData));
      expect(find.text('Property is required'), findsOneWidget);
    });
  });

  group('CheckBox', () {
    testWidgets('Value is send', (tester) async {
      final action = model.FormAction(
        'uri',
        'method',
      );
      final component = model.FormComponentCheckBox(
        data: model.BooleanDataEntity(),
        property: 'Property',
        options: model.StubComponentOptions(),
        required: false,
      );
      final formData = model.FormData('Title', [
        component,
      ], [
        action,
      ], {});
      final client = MockActiveGridClient();
      final target = TestApp(
        client: client,
        child: ActiveGridForm(
          formId: 'formId',
        ),
      );

      final completer = Completer<model.FormData>();
      when(client.loadForm(formId: anyNamed('formId')))
          .thenAnswer((_) async => formData);
      when(client.performAction(action, any))
          .thenAnswer((realInvocation) async {
        completer.complete(realInvocation.positionalArguments[1]);
        return Response('', 200);
      });

      await tester.pumpWidget(target);
      await tester.pumpAndSettle();

      expect(find.byType(FormComponentCheckBox), findsOneWidget);

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ActionButton));
      await tester.pumpAndSettle();

      final result = await completer.future;
      expect(result.components.first.data.value, true);
    });

    testWidgets('Required shows Error', (tester) async {
      final action = model.FormAction(
        'uri',
        'method',
      );
      final component = model.FormComponentCheckBox(
        data: model.BooleanDataEntity(),
        property: 'Property',
        options: model.StubComponentOptions(),
        required: true,
      );
      final formData = model.FormData('Title', [
        component,
      ], [
        action,
      ], {});
      final client = MockActiveGridClient();
      final target = TestApp(
        client: client,
        child: ActiveGridForm(
          formId: 'formId',
        ),
      );

      when(client.loadForm(formId: anyNamed('formId')))
          .thenAnswer((_) async => formData);

      await tester.pumpWidget(target);
      await tester.pumpAndSettle();

      expect(find.byType(FormComponentCheckBox), findsOneWidget);

      await tester.tap(find.byType(ActionButton));
      await tester.pumpAndSettle();

      verifyNever(client.performAction(action, formData));
      expect(find.text('Required'), findsOneWidget);
    });
  });
}