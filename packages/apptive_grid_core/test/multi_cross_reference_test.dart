import 'package:apptive_grid_core/apptive_grid_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Grid', () {
    final rawResponse = {
      'fieldNames': ['name'],
      'entities': [
        {
          'fields': [
            [
              {
                'displayValue': 'Yeah!',
                'uri':
                    '/api/users/609bc536dad545d1af7e82db/spaces/60d036dc0edfa83071816e00/grids/60d036f00edfa83071816e07/entities/60d036ff0edfa83071816e0d'
              }
            ]
          ],
          '_id': '60d0370e0edfa83071816e12'
        }
      ],
      'fieldIds': ['3ftoqhqbct15h5o730uknpvp5'],
      'filter': {},
      'schema': {
        'type': 'object',
        'properties': {
          'fields': {
            'type': 'array',
            'items': [
              {
                'type': 'array',
                'items': {
                  'type': 'object',
                  'properties': {
                    'displayValue': {'type': 'string'},
                    'uri': {'type': 'string'}
                  },
                  'required': ['uri'],
                  'objectType': 'entityreference',
                  'gridUri':
                      '/api/users/609bc536dad545d1af7e82db/spaces/60d036dc0edfa83071816e00/grids/60d036f00edfa83071816e07/views/60d036f00edfa83071816e06'
                }
              }
            ]
          },
          '_id': {'type': 'string'}
        }
      },
      'name': 'New grid view'
    };

    test('Grid Parses Correctly', () {
      final grid = Grid.fromJson(rawResponse);

      expect(grid.fields.length, equals(1));
      expect(
        grid.rows[0].entries[0].data,
        MultiCrossReferenceDataEntity.fromJson(
          jsonValue: [
            {
              'displayValue': 'Yeah!',
              'uri':
                  '/api/users/609bc536dad545d1af7e82db/spaces/60d036dc0edfa83071816e00/grids/60d036f00edfa83071816e07/entities/60d036ff0edfa83071816e0d'
            }
          ],
          gridUri:
              '/api/users/609bc536dad545d1af7e82db/spaces/60d036dc0edfa83071816e00/grids/60d036f00edfa83071816e07/views/60d036f00edfa83071816e06',
        ),
      );
    });

    test('Grid serializes back to original Response', () {
      final fromJson = Grid.fromJson(rawResponse);

      expect(fromJson.toJson(), equals(rawResponse));
    });

    test('GridUri is parsed Correctly', () {
      final dataEntity = Grid.fromJson(rawResponse).rows[0].entries[0].data
          as MultiCrossReferenceDataEntity;

      expect(
        dataEntity.gridUri.uriString,
        (rawResponse['schema'] as Map)['properties']['fields']['items'][0]
            ['items']['gridUri'],
      );
    });
  });

  group('DataEntity', () {
    test('Equality', () {
      final a = MultiCrossReferenceDataEntity.fromJson(
        jsonValue: [
          {
            'displayValue': 'Yeah!',
            'uri':
                '/api/users/609bc536dad545d1af7e82db/spaces/60d036dc0edfa83071816e00/grids/60d036f00edfa83071816e07/entities/60d036ff0edfa83071816e0d'
          }
        ],
        gridUri:
            '/api/users/609bc536dad545d1af7e82db/spaces/60d036dc0edfa83071816e00/grids/60d036f00edfa83071816e07/views/60d036f00edfa83071816e06',
      );
      final b = MultiCrossReferenceDataEntity.fromJson(
        jsonValue: [
          {
            'displayValue': 'Yeah!',
            'uri':
                '/api/users/609bc536dad545d1af7e82db/spaces/60d036dc0edfa83071816e00/grids/60d036f00edfa83071816e07/entities/60d036ff0edfa83071816e0d'
          }
        ],
        gridUri:
            '/api/users/609bc536dad545d1af7e82db/spaces/60d036dc0edfa83071816e00/grids/60d036f00edfa83071816e07/views/60d036f00edfa83071816e06',
      );
      final c = MultiCrossReferenceDataEntity.fromJson(
        jsonValue: null,
        gridUri:
            '/api/users/609bc536dad545d1af7e82db/spaces/60d036dc0edfa83071816e00/grids/60d036f00edfa83071816e07/views/60d036f00edfa83071816e06',
      );
      expect(a, equals(b));
      expect(a, isNot(c));

      expect(a.hashCode, equals(b.hashCode));
      expect(a.hashCode, isNot(c.hashCode));
    });
  });

  group('FormComponent', () {
    test('Direct equals from Json', () {
      final responseWithMultiCrossReference = {
        'schema': {
          'type': 'object',
          'properties': {
            '3ftoqhqbct15h5o730uknpvp5': {
              'type': 'array',
              'items': {
                'type': 'object',
                'properties': {
                  'displayValue': {'type': 'string'},
                  'uri': {'type': 'string'}
                },
                'required': ['uri'],
                'objectType': 'entityreference',
                'gridUri':
                    '/api/users/609bc536dad545d1af7e82db/spaces/60d036dc0edfa83071816e00/grids/60d036f00edfa83071816e07/views/60d036f00edfa83071816e06'
              }
            }
          },
          'required': []
        },
        'schemaObject':
            '/api/users/609bc536dad545d1af7e82db/spaces/60d036dc0edfa83071816e00/grids/60d036e50edfa83071816e03',
        'components': [
          {
            'property': 'name',
            'value': [
              {
                'displayValue': 'Yeah!',
                'uri':
                    '/api/users/609bc536dad545d1af7e82db/spaces/60d036dc0edfa83071816e00/grids/60d036f00edfa83071816e07/entities/60d036ff0edfa83071816e0d',
              }
            ],
            'required': false,
            'options': {'label': null, 'description': null},
            'fieldId': '3ftoqhqbct15h5o730uknpvp5',
            'type': 'multiSelectDropdown'
          }
        ],
        'name': 'New Name',
        'title': 'New title',
      };

      final formData = FormData.fromJson(responseWithMultiCrossReference);

      final fromJson =
          formData.components[0] as MultiCrossReferenceFormComponent;

      final directEntity = MultiCrossReferenceDataEntity.fromJson(
        jsonValue: [
          {
            'displayValue': 'Yeah!',
            'uri':
                '/api/users/609bc536dad545d1af7e82db/spaces/60d036dc0edfa83071816e00/grids/60d036f00edfa83071816e07/entities/60d036ff0edfa83071816e0d'
          }
        ],
        gridUri:
            '/api/users/609bc536dad545d1af7e82db/spaces/60d036dc0edfa83071816e00/grids/60d036f00edfa83071816e07/views/60d036f00edfa83071816e06',
      );

      final direct = MultiCrossReferenceFormComponent(
        property: 'name',
        data: directEntity,
        fieldId: '3ftoqhqbct15h5o730uknpvp5',
      );

      expect(fromJson, equals(direct));
      expect(fromJson.hashCode, equals(direct.hashCode));
    });
  });
}
