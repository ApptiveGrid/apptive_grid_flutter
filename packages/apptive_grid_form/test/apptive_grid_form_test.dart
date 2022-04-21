import 'dart:async';
import 'dart:convert';

import 'package:apptive_grid_form/apptive_grid_form.dart';
import 'package:apptive_grid_form/widgets/apptive_grid_form_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:mocktail/mocktail.dart';

import 'common.dart';

void main() {
  late ApptiveGridClient client;

  setUpAll(() {
    registerFallbackValue(RedirectFormUri(components: ['components']));
    registerFallbackValue(http.Request('POST', Uri()));
    registerFallbackValue(
      ActionItem(
        action: FormAction('', ''),
        data: FormData(title: '', components: [], schema: null),
      ),
    );
  });

  setUp(() {
    client = MockApptiveGridClient();
    when(() => client.sendPendingActions()).thenAnswer((_) async {});
  });

  group('Title', () {
    testWidgets('Title Displays', (tester) async {
      final target = TestApp(
        client: client,
        child: ApptiveGridForm(
          formUri: RedirectFormUri(
            components: ['form'],
          ),
        ),
      );

      when(
        () => client.loadForm(formUri: RedirectFormUri(components: ['form'])),
      ).thenAnswer(
        (realInvocation) async => FormData(
          name: 'Form Name',
          title: 'Form Title',
          components: [],
          actions: [],
          schema: {},
        ),
      );

      await tester.pumpWidget(target);
      await tester.pumpAndSettle();

      expect(find.text('Form Title'), findsOneWidget);
    });

    testWidgets('Title do not displays', (tester) async {
      final target = TestApp(
        client: client,
        child: ApptiveGridForm(
          formUri: RedirectFormUri(
            components: ['form'],
          ),
          hideTitle: true,
        ),
      );

      when(
        () => client.loadForm(formUri: RedirectFormUri(components: ['form'])),
      ).thenAnswer(
        (realInvocation) async => FormData(
          name: 'Form Name',
          title: 'Form Title',
          components: [],
          actions: [],
          schema: {},
        ),
      );

      await tester.pumpWidget(target);
      await tester.pumpAndSettle();

      expect(find.text('Form Title'), findsNothing);
    });
  });

  testWidgets('OnLoadedCallback gets called', (tester) async {
    final form = FormData(
      name: 'Form Name',
      title: 'Form Title',
      components: [],
      actions: [],
      schema: {},
    );
    final completer = Completer<FormData>();
    final target = TestApp(
      client: client,
      child: ApptiveGridForm(
        formUri: RedirectFormUri(
          components: ['form'],
        ),
        onFormLoaded: (data) {
          completer.complete(data);
        },
      ),
    );

    when(() => client.loadForm(formUri: RedirectFormUri(components: ['form'])))
        .thenAnswer((realInvocation) async => form);

    await tester.pumpWidget(target);
    await tester.pumpAndSettle();

    final result = await completer.future;
    expect(result, equals(form));
  });

  group('Loading', () {
    testWidgets('Initial shows Loading', (tester) async {
      final target = TestApp(
        client: client,
        child: ApptiveGridForm(
          formUri: RedirectFormUri(
            components: ['form'],
          ),
        ),
      );
      final form = FormData(
        name: 'Form Name',
        title: 'Form Title',
        components: [],
        actions: [],
        schema: {},
      );
      when(
        () => client.loadForm(formUri: RedirectFormUri(components: ['form'])),
      ).thenAnswer((realInvocation) async => form);

      await tester.pumpWidget(target);

      expect(
        find.byType(
          CircularProgressIndicator,
        ),
        findsOneWidget,
      );
    });
  });

  group('Success', () {
    testWidgets('Shows Success', (tester) async {
      final target = TestApp(
        client: client,
        child: ApptiveGridForm(
          formUri: RedirectFormUri(
            components: ['form'],
          ),
        ),
      );
      final action = FormAction('uri', 'method');
      final formData = FormData(
        name: 'Form Name',
        title: 'Form Title',
        components: [],
        actions: [action],
        schema: {},
      );

      when(
        () => client.loadForm(formUri: RedirectFormUri(components: ['form'])),
      ).thenAnswer((realInvocation) async => formData);
      when(() => client.performAction(action, formData))
          .thenAnswer((_) async => http.Response('', 200));

      await tester.pumpWidget(target);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ActionButton));
      await tester.pumpAndSettle();

      expect(find.byType(Lottie), findsOneWidget);
      expect(find.text('Thank You!', skipOffstage: false), findsOneWidget);
      expect(find.byType(TextButton, skipOffstage: false), findsOneWidget);
    });

    testWidgets('Send Additional Click reloads Form', (tester) async {
      final target = TestApp(
        client: client,
        child: ApptiveGridForm(
          formUri: RedirectFormUri(
            components: ['form'],
          ),
        ),
      );
      final action = FormAction('uri', 'method');
      final formData = FormData(
        name: 'Form Name',
        title: 'Form Title',
        components: [],
        actions: [action],
        schema: {},
      );

      when(
        () => client.loadForm(formUri: RedirectFormUri(components: ['form'])),
      ).thenAnswer((realInvocation) async => formData);
      when(() => client.performAction(action, formData))
          .thenAnswer((_) async => http.Response('', 200));

      await tester.pumpWidget(target);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ActionButton));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.byType(TextButton), 100);
      await tester.tap(find.byType(TextButton, skipOffstage: false));
      await tester.pumpAndSettle();

      verify(
        () => client.loadForm(formUri: RedirectFormUri(components: ['form'])),
      ).called(2);
    });
  });

  group('Error', () {
    group('Initial Call', () {
      testWidgets('Initial Error Shows', (tester) async {
        final target = TestApp(
          client: client,
          child: ApptiveGridForm(
            formUri: RedirectFormUri(
              components: ['form'],
            ),
          ),
        );

        when(
          () => client.loadForm(formUri: RedirectFormUri(components: ['form'])),
        ).thenAnswer((_) => Future.error(''));

        await tester.pumpWidget(target);
        await tester.pumpAndSettle(const Duration(seconds: 30));

        expect(find.byType(Lottie), findsOneWidget);
        expect(find.text('Oops! - Error', skipOffstage: false), findsOneWidget);
        expect(find.byType(TextButton, skipOffstage: false), findsOneWidget);
      });

      testWidgets('Initial Error Reloads Form', (tester) async {
        final target = TestApp(
          client: client,
          child: ApptiveGridForm(
            formUri: RedirectFormUri(
              components: ['form'],
            ),
          ),
        );
        when(
          () => client.loadForm(formUri: RedirectFormUri(components: ['form'])),
        ).thenAnswer((_) => Future.error(''));

        await tester.pumpWidget(target);
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(find.byType(TextButton), 100);
        await tester.tap(find.byType(TextButton, skipOffstage: false));
        await tester.pumpAndSettle();

        verify(
          () => client.loadForm(formUri: RedirectFormUri(components: ['form'])),
        ).called(2);
      });
    });

    group('Action Error', () {
      testWidgets('Shows Error', (tester) async {
        final target = TestApp(
          client: client,
          child: ApptiveGridForm(
            formUri: RedirectFormUri(
              components: ['form'],
            ),
          ),
        );
        final action = FormAction('uri', 'method');
        final formData = FormData(
          name: 'Form Name',
          title: 'Form Title',
          components: [],
          actions: [action],
          schema: {},
        );

        when(
          () => client.loadForm(formUri: RedirectFormUri(components: ['form'])),
        ).thenAnswer((realInvocation) async => formData);
        when(() => client.performAction(action, formData))
            .thenAnswer((_) => Future.error(''));

        await tester.pumpWidget(target);
        await tester.pumpAndSettle();
        await tester.tap(find.byType(ActionButton));
        await tester.pumpAndSettle();

        expect(find.byType(Lottie), findsOneWidget);
        expect(find.text('Oops! - Error', skipOffstage: false), findsOneWidget);
        expect(find.byType(TextButton, skipOffstage: false), findsOneWidget);
      });

      testWidgets('Server Error shows Error', (tester) async {
        final target = TestApp(
          client: client,
          child: ApptiveGridForm(
            formUri: RedirectFormUri(
              components: ['form'],
            ),
          ),
        );
        final action = FormAction('uri', 'method');
        final formData = FormData(
          name: 'Form Name',
          title: 'Form Title',
          components: [],
          actions: [action],
          schema: {},
        );

        when(
          () => client.loadForm(formUri: RedirectFormUri(components: ['form'])),
        ).thenAnswer((realInvocation) async => formData);
        when(() => client.performAction(action, formData))
            .thenAnswer((_) => Future.error(''));

        await tester.pumpWidget(target);
        await tester.pumpAndSettle();
        await tester.tap(find.byType(ActionButton));
        await tester.pumpAndSettle();

        expect(find.byType(Lottie), findsOneWidget);
        expect(find.text('Oops! - Error', skipOffstage: false), findsOneWidget);
        expect(find.byType(TextButton, skipOffstage: false), findsOneWidget);
      });

      testWidgets('Back to Form shows Form', (tester) async {
        final formUri = RedirectFormUri(
          components: ['form'],
        );
        final target = TestApp(
          client: client,
          child: ApptiveGridForm(
            formUri: formUri,
          ),
        );
        final action = FormAction('uri', 'method');
        final formData = FormData(
          name: 'Form Name',
          title: 'Form Title',
          components: [],
          actions: [action],
          schema: {},
        );

        when(
          () => client.loadForm(formUri: formUri),
        ).thenAnswer((realInvocation) async => formData);
        when(() => client.performAction(action, formData))
            .thenAnswer((_) => Future.error(''));

        await tester.pumpWidget(target);
        await tester.pumpAndSettle();
        await tester.tap(find.byType(ActionButton));
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(find.byType(TextButton), 100);
        await tester.tap(find.byType(TextButton, skipOffstage: false));
        await tester.pumpAndSettle();

        expect(find.text('Form Title'), findsOneWidget);
        // Don't reload here
        verify(() => client.loadForm(formUri: formUri)).called(1);
      });

      testWidgets('Cache Response. Additional Answer shows Form',
          (tester) async {
        final cacheMap = <ActionItem>{};
        final cache = MockApptiveGridCache();
        when(() => cache.addPendingActionItem(any())).thenAnswer(
          (invocation) => cacheMap.add(invocation.positionalArguments[0]),
        );
        when(() => cache.removePendingActionItem(any())).thenAnswer(
          (invocation) => cacheMap.remove(invocation.positionalArguments[0]),
        );
        when(() => cache.getPendingActionItems())
            .thenAnswer((invocation) => cacheMap.toList());
        when(() => client.options)
            .thenAnswer((invocation) => ApptiveGridOptions(cache: cache));
        final target = TestApp(
          client: client,
          child: ApptiveGridForm(
            formUri: RedirectFormUri(
              components: ['form'],
            ),
          ),
        );
        final action = FormAction('uri', 'method');
        final formData = FormData(
          name: 'Form Name',
          title: 'Form Title',
          components: [],
          actions: [action],
          schema: {},
        );

        when(
          () => client.loadForm(formUri: RedirectFormUri(components: ['form'])),
        ).thenAnswer((realInvocation) async => formData);
        when(() => client.performAction(action, formData))
            .thenAnswer((_) async => http.Response('', 500));

        await tester.pumpWidget(target);
        await tester.pumpAndSettle();
        await tester.tap(find.byType(ActionButton));
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(find.byType(TextButton), 100);
        await tester.tap(find.byType(TextButton, skipOffstage: false));
        await tester.pumpAndSettle();

        expect(find.text('Form Title'), findsOneWidget);
        verify(() => client.loadForm(formUri: any(named: 'formUri'))).called(2);
      });
    });

    group('Error Message', () {
      testWidgets('Error shows to String Error', (tester) async {
        final target = TestApp(
          client: client,
          child: ApptiveGridForm(
            formUri: RedirectFormUri(
              components: ['form'],
            ),
          ),
        );
        final action = FormAction('uri', 'method');
        final formData = FormData(
          name: 'Form Name',
          title: 'Form Title',
          components: [],
          actions: [action],
          schema: {},
        );

        when(
          () => client.loadForm(formUri: RedirectFormUri(components: ['form'])),
        ).thenAnswer((realInvocation) async => formData);
        when(() => client.performAction(action, formData))
            .thenAnswer((_) => Future.error(Exception('Testing Errors')));

        await tester.pumpWidget(target);
        await tester.pumpAndSettle();
        await tester.tap(find.byType(ActionButton));
        await tester.pumpAndSettle();
        expect(
          find.text('Exception: Testing Errors', skipOffstage: false),
          findsOneWidget,
        );
      });

      testWidgets('Response shows Status Code and Body', (tester) async {
        final target = TestApp(
          client: client,
          child: ApptiveGridForm(
            formUri: RedirectFormUri(
              components: ['form'],
            ),
          ),
        );
        final action = FormAction('uri', 'method');
        final formData = FormData(
          name: 'Form Name',
          title: 'Form Title',
          components: [],
          actions: [action],
          schema: {},
        );

        when(
          () => client.loadForm(formUri: RedirectFormUri(components: ['form'])),
        ).thenAnswer((realInvocation) async => formData);
        when(() => client.performAction(action, formData)).thenAnswer(
          (_) => Future.error(http.Response('Testing Errors', 400)),
        );

        await tester.pumpWidget(target);
        await tester.pumpAndSettle();
        await tester.tap(find.byType(ActionButton));
        await tester.pumpAndSettle();
        expect(
          find.text('400: Testing Errors', skipOffstage: false),
          findsOneWidget,
        );
      });
    });
  });

  group('Skip Custom Builder', () {
    testWidgets('Shows Success', (tester) async {
      final target = TestApp(
        client: client,
        child: ApptiveGridForm(
          formUri: RedirectFormUri(
            components: ['form'],
          ),
          onActionSuccess: (action, data) async {
            return false;
          },
        ),
      );
      final action = FormAction('uri', 'method');
      final formData = FormData(
        name: 'Form Name',
        title: 'Form Title',
        components: [],
        actions: [action],
        schema: {},
      );

      when(
        () => client.loadForm(formUri: RedirectFormUri(components: ['form'])),
      ).thenAnswer((realInvocation) async => formData);
      when(() => client.performAction(action, formData))
          .thenAnswer((_) async => http.Response('', 200));

      await tester.pumpWidget(target);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ActionButton));
      await tester.pumpAndSettle();

      expect(find.byType(Lottie), findsNothing);
    });

    testWidgets('Shows Error', (tester) async {
      final target = TestApp(
        client: client,
        child: ApptiveGridForm(
          formUri: RedirectFormUri(
            components: ['form'],
          ),
          onError: (error) async {
            return false;
          },
        ),
      );
      final action = FormAction('uri', 'method');
      final formData = FormData(
        name: 'Form Name',
        title: 'Form Title',
        components: [],
        actions: [action],
        schema: {},
      );

      when(
        () => client.loadForm(formUri: RedirectFormUri(components: ['form'])),
      ).thenAnswer((realInvocation) async => formData);
      when(() => client.performAction(action, formData))
          .thenAnswer((_) => Future.error(''));

      await tester.pumpWidget(target);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ActionButton));
      await tester.pumpAndSettle();

      expect(find.byType(Lottie), findsNothing);
    });
  });

  group('Cache', () {
    late http.Client httpClient;

    final action = FormAction('actionUri', 'POST');
    final data = FormData(
      name: 'Form Name',
      title: 'Title',
      components: [],
      actions: [action],
      schema: {},
    );

    final formUri = RedirectFormUri(components: ['form']);
    const env = ApptiveGridEnvironment.production;

    setUpAll(() {
      registerFallbackValue(http.Request('POST', Uri()));
      registerFallbackValue(ActionItem(action: action, data: data));
    });

    setUp(() {
      httpClient = MockHttpClient();

      when(
        () => httpClient.get(
          Uri.parse(env.url + formUri.uri.toString()),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async => http.Response(jsonEncode(data.toJson()), 200),
      );
      when(() => httpClient.send(any())).thenAnswer(
        (invocation) async => http.StreamedResponse(Stream.value([]), 400),
      );
    });

    testWidgets('No Cache, Error, Shows Error Screen', (tester) async {
      final client = ApptiveGridClient(httpClient: httpClient);

      final target = TestApp(
        client: client,
        child: ApptiveGridForm(
          formUri: formUri,
        ),
      );

      await tester.pumpWidget(target);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ActionButton));
      await tester.pumpAndSettle();

      expect(find.byType(Lottie), findsOneWidget);
      expect(find.text('Oops! - Error', skipOffstage: false), findsOneWidget);
      expect(find.byType(TextButton, skipOffstage: false), findsOneWidget);
    });

    testWidgets('Cache, Error, Shows Saved Screen', (tester) async {
      final cacheMap = <ActionItem>{};
      final cache = MockApptiveGridCache();
      when(() => cache.addPendingActionItem(any())).thenAnswer(
        (invocation) => cacheMap.add(invocation.positionalArguments[0]),
      );
      when(() => cache.removePendingActionItem(any())).thenAnswer(
        (invocation) => cacheMap.remove(invocation.positionalArguments[0]),
      );
      when(() => cache.getPendingActionItems())
          .thenAnswer((invocation) => cacheMap.toList());

      final client = ApptiveGridClient(
        httpClient: httpClient,
        options: ApptiveGridOptions(
          cache: cache,
        ),
      );

      final target = TestApp(
        client: client,
        child: ApptiveGridForm(
          formUri: formUri,
        ),
      );

      await tester.pumpWidget(target);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ActionButton));
      await tester.pumpAndSettle();

      verify(() => httpClient.send(any())).called(1);

      expect(
        find.text(
          'The form was saved and will be sent at the next opportunity',
          skipOffstage: false,
        ),
        findsOneWidget,
      );
    });
  });

  group('Current Data', () {
    testWidgets('Current Data returns data', (tester) async {
      final key = GlobalKey<ApptiveGridFormDataState>();
      final form = FormData(
        name: 'Form Name',
        title: 'Form Title',
        components: [],
        actions: [],
        schema: {},
      );
      final target = TestApp(
        client: client,
        child: ApptiveGridForm(
          key: key,
          formUri: RedirectFormUri(
            components: ['form'],
          ),
        ),
      );

      when(
        () => client.loadForm(formUri: RedirectFormUri(components: ['form'])),
      ).thenAnswer((realInvocation) async => form);

      await tester.pumpWidget(target);
      await tester.pumpAndSettle();

      expect(
        (tester.state(find.byType(ApptiveGridForm)) as ApptiveGridFormState)
            .currentData,
        equals(form),
      );
    });

    testWidgets(
        'Action Success '
        'Current Data returns null', (tester) async {
      final key = GlobalKey<ApptiveGridFormDataState>();
      final action = FormAction('uri', 'method');
      final formData = FormData(
        name: 'Form Name',
        title: 'Form Title',
        components: [],
        actions: [action],
        schema: {},
      );
      final target = TestApp(
        client: client,
        child: ApptiveGridForm(
          key: key,
          formUri: RedirectFormUri(
            components: ['form'],
          ),
        ),
      );

      when(
        () => client.loadForm(formUri: RedirectFormUri(components: ['form'])),
      ).thenAnswer((realInvocation) async => formData);
      when(() => client.performAction(action, formData))
          .thenAnswer((_) async => http.Response('', 200));

      await tester.pumpWidget(target);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ActionButton));
      await tester.pumpAndSettle();

      expect(
        (tester.state(find.byType(ApptiveGridForm)) as ApptiveGridFormState)
            .currentData,
        equals(null),
      );
    });

    testWidgets(
        'Action Error '
        'Current Data data', (tester) async {
      final key = GlobalKey<ApptiveGridFormDataState>();
      final action = FormAction('uri', 'method');
      final formData = FormData(
        name: 'Form Name',
        title: 'Form Title',
        components: [],
        actions: [action],
        schema: {},
      );
      final target = TestApp(
        client: client,
        options: const ApptiveGridOptions(
          cache: null,
        ),
        child: ApptiveGridForm(
          key: key,
          formUri: RedirectFormUri(
            components: ['form'],
          ),
        ),
      );

      when(
        () => client.loadForm(formUri: RedirectFormUri(components: ['form'])),
      ).thenAnswer((realInvocation) async => formData);
      when(() => client.performAction(action, formData))
          .thenAnswer((_) async => http.Response('', 400));

      await tester.pumpWidget(target);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ActionButton));
      await tester.pumpAndSettle();

      expect(
        (tester.state(find.byType(ApptiveGridForm)) as ApptiveGridFormState)
            .currentData,
        equals(formData),
      );
    });
  });

  group('Action', () {
    testWidgets('Click on Button shows Loading Indicator', (tester) async {
      final target = TestApp(
        client: client,
        child: ApptiveGridForm(
          formUri: RedirectFormUri(
            components: ['form'],
          ),
        ),
      );
      final action = FormAction('uri', 'method');
      final formData = FormData(
        name: 'Form Name',
        title: 'Form Title',
        components: [],
        actions: [action],
        schema: {},
      );

      final actionCompleter = Completer<http.Response>();
      when(
        () => client.loadForm(formUri: RedirectFormUri(components: ['form'])),
      ).thenAnswer((realInvocation) async => formData);
      when(() => client.performAction(action, formData))
          .thenAnswer((_) => actionCompleter.future);

      await tester.pumpWidget(target);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ActionButton));
      await tester.pump();

      expect(find.byType(ActionButton), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      actionCompleter.complete(http.Response('', 200));
      await tester.pump();

      expect(find.byType(Lottie), findsOneWidget);
      expect(find.text('Thank You!', skipOffstage: false), findsOneWidget);
      expect(find.byType(TextButton, skipOffstage: false), findsOneWidget);
    });
  });

  group('User Reference', () {
    testWidgets('UserReference Form Widget is build without padding',
        (tester) async {
      final formData = FormData(
        title: 'Form Data',
        components: [
          UserReferenceFormComponent(
            property: 'Created By',
            data: UserReferenceDataEntity(),
            fieldId: 'field3',
          ),
        ],
        schema: {
          'properties': {
            'field3': {
              'type': 'object',
              'properties': {
                'displayValue': {'type': 'string'},
                'id': {'type': 'string'},
                'type': {'type': 'string'},
                'name': {'type': 'string'}
              },
              'objectType': 'userReference'
            },
          },
        },
      );

      final target = TestApp(
        client: client,
        child: ApptiveGridForm(
          formUri: RedirectFormUri(
            components: ['form'],
          ),
        ),
      );
      when(
        () => client.loadForm(formUri: RedirectFormUri(components: ['form'])),
      ).thenAnswer((realInvocation) async => formData);

      await tester.pumpWidget(target);
      await tester.pumpAndSettle();

      expect(
        find.ancestor(
          of: find.byType(UserReferenceFormWidget),
          matching: find.byType(Padding),
        ),
        findsNothing,
      );
    });
  });

  group('Reload', () {
    testWidgets('Changing Form Uri triggers reload', (tester) async {
      final firstForm = FormUri.fromUri('/form1');
      final secondForm = FormUri.fromUri('/form2');

      final globalKey = GlobalKey<_ChangingFormWidgetState>();
      final client = MockApptiveGridClient();

      when(client.sendPendingActions).thenAnswer((_) async {});
      when(() => client.loadForm(formUri: any(named: 'formUri'))).thenAnswer(
        (_) async => FormData(
          title: 'title',
          components: [],
          schema: {},
        ),
      );

      final target = TestApp(
        client: client,
        child: _ChangingFormWidget(
          key: globalKey,
          form1: firstForm,
          form2: secondForm,
        ),
      );

      await tester.pumpWidget(target);
      await tester.pump();

      globalKey.currentState?._changeForm();
      await tester.pump();

      verify(() => client.loadForm(formUri: firstForm)).called(1);
      verify(() => client.loadForm(formUri: secondForm)).called(1);
    });
  });
}

class _ChangingFormWidget extends StatefulWidget {
  const _ChangingFormWidget({
    Key? key,
    required this.form1,
    required this.form2,
  }) : super(key: key);

  final FormUri form1;
  final FormUri form2;

  @override
  _ChangingFormWidgetState createState() => _ChangingFormWidgetState();
}

class _ChangingFormWidgetState extends State<_ChangingFormWidget> {
  late FormUri _displayingUri;

  @override
  void initState() {
    super.initState();
    _displayingUri = widget.form1;
  }

  void _changeForm() {
    setState(() {
      _displayingUri =
          _displayingUri == widget.form1 ? widget.form2 : widget.form1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ApptiveGridForm(formUri: _displayingUri);
  }
}
