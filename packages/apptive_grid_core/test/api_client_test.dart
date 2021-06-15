import 'dart:convert';

import 'package:apptive_grid_core/apptive_grid_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pedantic/pedantic.dart';

import 'mocks.dart';

void main() {
  final httpClient = MockHttpClient();
  late ApptiveGridClient apptiveGridClient;

  setUpAll(() {
    registerFallbackValue<BaseRequest>(Request('GET', Uri()));
    registerFallbackValue<Uri>(Uri());
    registerFallbackValue<Map<String, String>>(<String, String>{});
  });

  setUp(() {
    apptiveGridClient = ApptiveGridClient.fromClient(httpClient);
  });

  tearDown(() {
    apptiveGridClient.dispose();
  });

  group('loadForm', () {
    final rawResponse = {
      'schema': {
        'type': 'object',
        'properties': {
          '4zc4l48ffin5v8pa2emyx9s15': {'type': 'string'},
        },
        'required': []
      },
      'actions': [
        {'uri': '/api/a/3ojhtqiltc0kiylfp8nddmxmk', 'method': 'POST'}
      ],
      'components': [
        {
          'property': 'TextC',
          'value': null,
          'required': false,
          'options': {
            'multi': false,
            'placeholder': '',
            'description': '',
            'label': null
          },
          'type': 'textfield',
          'fieldId': '4zc4l48ffin5v8pa2emyx9s15'
        },
      ],
      'title': 'Form'
    };

    test('Success', () async {
      final response = Response(json.encode(rawResponse), 200);

      when(() => httpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => response);

      final formData = await apptiveGridClient.loadForm(
          formUri: RedirectFormUri(form: 'FormId'));

      expect(formData.title, 'Form');
      expect(formData.components.length, 1);
      expect(formData.components[0].runtimeType, StringFormComponent);
      expect(formData.actions.length, 1);
    });

    test('DirectUri checks authentication', () async {
      final response = Response(json.encode(rawResponse), 200);
      final authenticator = MockApptiveGridAuthenticator();
      final client = ApptiveGridClient.fromClient(httpClient,
          authenticator: authenticator);

      when(() => httpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => response);
      when(() => authenticator.checkAuthentication())
          .thenAnswer((_) => Future.value());

      unawaited(client.loadForm(
          formUri: DirectFormUri(
              user: 'user', space: 'space', grid: 'grid', form: 'FormId')));
      verify(() => authenticator.checkAuthentication()).called(1);
    });

    test('400+ Response throws Response', () async {
      final response = Response(json.encode(rawResponse), 400);

      when(() => httpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => response);

      expect(
          () => apptiveGridClient.loadForm(
              formUri: RedirectFormUri(form: 'FormId')),
          throwsA(isInstanceOf<Response>()));
    });
  });

  group('Load Grid', () {
    final rawResponse = {
      'fieldNames': ['First Name', 'Last Name', 'imgUrl'],
      'entities': [
        {
          'fields': [
            'Julia',
            'Arnold',
            'https://ca.slack-edge.com/T02TE01SG-U9AJEEH7Z-19c78728dca3-512'
          ],
          '_id': '2ozv8sbju97gk1ukfbl3f3fl1'
        },
      ],
      'fieldIds': [
        '2ozv8saj00bdp85gr8r9wc5up',
        '2ozv8scn6q8gnhivpmhn5u875',
        '2ozv8sai5hc0pzdd2c2ifs64g'
      ],
      'schema': {
        'type': 'object',
        'properties': {
          'fields': {
            'type': 'array',
            'items': [
              {'type': 'string'},
              {'type': 'string'},
              {'type': 'string'}
            ]
          },
          '_id': {'type': 'string'}
        }
      },
      'name': 'Contacts'
    };
    test('Success', () async {
      final user = 'user';
      final space = 'space';
      final gridId = 'grid';

      final response = Response(json.encode(rawResponse), 200);

      when(() => httpClient.get(
          Uri.parse(
              '${ApptiveGridEnvironment.production.url}/api/users/$user/spaces/$space/grids/$gridId'),
          headers: any(named: 'headers'))).thenAnswer((_) async => response);

      final grid = await apptiveGridClient.loadGrid(
          gridUri: GridUri(user: user, space: space, grid: gridId));

      expect(grid, isNot(null));
    });

    test('400 Status throws Response', () async {
      final user = 'user';
      final space = 'space';
      final gridId = 'grid';

      final response = Response(json.encode(rawResponse), 400);

      when(() => httpClient.get(
          Uri.parse(
              '${ApptiveGridEnvironment.production.url}/api/users/$user/spaces/$space/grids/$gridId'),
          headers: any(named: 'headers'))).thenAnswer((_) async => response);

      expect(
          () => apptiveGridClient.loadGrid(
              gridUri: GridUri(user: user, space: space, grid: gridId)),
          throwsA(isInstanceOf<Response>()));
    });
  });

  group('performAction', () {
    test('Successful', () async {
      final action = FormAction('/uri', 'POST');
      final property = 'Checkbox';
      final id = 'id';
      final component = BooleanFormComponent(
        fieldId: id,
        property: property,
        data: BooleanDataEntity(true),
        options: FormComponentOptions.fromJson({}),
        required: false,
      );
      final schema = {
        'type': 'object',
        'properties': {
          id: {'type': 'boolean'},
        },
        'required': []
      };
      final formData = FormData('Title', [component], [action], schema);

      final request = Request(
          'POST', Uri.parse('${ApptiveGridEnvironment.production.url}/uri}'));
      request.body = jsonEncode(jsonEncode(formData.toRequestObject()));

      late BaseRequest calledRequest;

      when(() => httpClient.send(any())).thenAnswer((realInvocation) async {
        calledRequest = realInvocation.positionalArguments[0];
        return StreamedResponse(Stream.value([]), 200);
      });

      await apptiveGridClient.performAction(action, formData);

      expect(calledRequest.method, action.method);
      expect(calledRequest.url.toString(),
          '${ApptiveGridEnvironment.production.url}${action.uri}');
      expect(calledRequest.headers[HttpHeaders.contentTypeHeader],
          ContentType.json);
    });
  });

  group('Environment', () {
    test('Check Urls', () {
      expect(ApptiveGridEnvironment.alpha.url, 'https://alpha.apptivegrid.de');
      expect(ApptiveGridEnvironment.beta.url, 'https://beta.apptivegrid.de');
      expect(
          ApptiveGridEnvironment.production.url, 'https://app.apptivegrid.de');
    });

    test('Check Auth Realm', () {
      expect(ApptiveGridEnvironment.alpha.authRealm, 'apptivegrid-test');
      expect(ApptiveGridEnvironment.beta.authRealm, 'apptivegrid-test');
      expect(ApptiveGridEnvironment.production.authRealm, 'apptivegrid');
    });
  });

  group('Headers', () {
    test('No Authentication empty headers', () {
      final client = ApptiveGridClient();
      expect(client.headers, {});
    });

    test('With Authentication has headers', () {
      final authenticator = MockApptiveGridAuthenticator();
      when(() => authenticator.header)
          .thenReturn('Bearer dXNlcm5hbWU6cGFzc3dvcmQ=');
      final client = ApptiveGridClient.fromClient(httpClient,
          authenticator: authenticator);
      expect(client.headers,
          {HttpHeaders.authorizationHeader: 'Bearer dXNlcm5hbWU6cGFzc3dvcmQ='});
    });
  });

  group('Authorization', () {
    test('Authorize calls Authenticator', () {
      final authenticator = MockApptiveGridAuthenticator();
      when(() => authenticator.authenticate())
          .thenAnswer((_) async => MockCredential());
      final client = ApptiveGridClient.fromClient(httpClient,
          authenticator: authenticator);
      client.authenticate();

      verify(() => authenticator.authenticate()).called(1);
    });
  });

  group('/user/me', () {
    final rawResponse = {
      'id': 'id',
      'firstName': 'Jane',
      'lastName': 'Doe',
      'email': 'jane.doe@zweidenker.de',
      'spaceUris': [
        '/api/users/id/spaces/spaceId',
      ]
    };
    test('Success', () async {
      final response = Response(json.encode(rawResponse), 200);

      when(() => httpClient.get(
          Uri.parse('${ApptiveGridEnvironment.production.url}/api/users/me'),
          headers: any(named: 'headers'))).thenAnswer((_) async => response);

      final user = await apptiveGridClient.getMe();

      expect(user, isNot(null));
    });

    test('400 Status throws Response', () async {
      final response = Response(json.encode(rawResponse), 400);

      when(() => httpClient.get(
          Uri.parse('${ApptiveGridEnvironment.production.url}/api/users/me'),
          headers: any(named: 'headers'))).thenAnswer((_) async => response);

      expect(
          () => apptiveGridClient.getMe(), throwsA(isInstanceOf<Response>()));
    });
  });

  group('get Space', () {
    final userId = 'userId';
    final spaceId = 'spaceId';
    final spaceUri = SpaceUri(user: userId, space: spaceId);
    final rawResponse = {
      'id': spaceId,
      'name': 'TestSpace',
      'gridUris': [
        '/api/users/id/spaces/spaceId/grids/gridId',
      ]
    };
    test('Success', () async {
      final response = Response(json.encode(rawResponse), 200);

      when(() => httpClient.get(
          Uri.parse(
              '${ApptiveGridEnvironment.production.url}/api/users/$userId/spaces/$spaceId'),
          headers: any(named: 'headers'))).thenAnswer((_) async => response);

      final space = await apptiveGridClient.getSpace(spaceUri: spaceUri);

      expect(space, isNot(null));
    });

    test('400 Status throws Response', () async {
      final response = Response(json.encode(rawResponse), 400);

      when(() => httpClient.get(
          Uri.parse(
              '${ApptiveGridEnvironment.production.url}/api/users/$userId/spaces/$spaceId'),
          headers: any(named: 'headers'))).thenAnswer((_) async => response);

      expect(() => apptiveGridClient.getSpace(spaceUri: spaceUri),
          throwsA(isInstanceOf<Response>()));
    });
  });

  group('get Forms', () {
    final userId = 'userId';
    final spaceId = 'spaceId';
    final gridId = 'gridId';
    final form0 = 'formId0';
    final form1 = 'formId1';
    final gridUri = GridUri(user: userId, space: spaceId, grid: gridId);
    final rawResponse = [
      '/api/users/id/spaces/spaceId/grids/gridId/forms/$form0',
      '/api/users/id/spaces/spaceId/grids/gridId/forms/$form1',
    ];
    test('Success', () async {
      final response = Response(json.encode(rawResponse), 200);

      when(() => httpClient.get(
          Uri.parse(
              '${ApptiveGridEnvironment.production.url}/api/users/$userId/spaces/$spaceId/grids/$gridId/forms'),
          headers: any(named: 'headers'))).thenAnswer((_) async => response);

      final forms = await apptiveGridClient.getForms(gridUri: gridUri);

      expect(forms.length, 2);
      expect(forms[0].uriString,
          '/api/users/id/spaces/spaceId/grids/gridId/forms/$form0');
      expect(forms[1].uriString,
          '/api/users/id/spaces/spaceId/grids/gridId/forms/$form1');
    });

    test('400 Status throws Response', () async {
      final response = Response(json.encode(rawResponse), 400);

      when(() => httpClient.get(
          Uri.parse(
              '${ApptiveGridEnvironment.production.url}/api/users/$userId/spaces/$spaceId/grids/$gridId/forms'),
          headers: any(named: 'headers'))).thenAnswer((_) async => response);

      expect(() => apptiveGridClient.getForms(gridUri: gridUri),
          throwsA(isInstanceOf<Response>()));
    });
  });
}