library apptive_grid_client;

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:apptive_grid_core/apptive_grid_model.dart';
import 'package:apptive_grid_core/apptive_grid_network.dart';
import 'package:apptive_grid_core/apptive_grid_options.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:mime/mime.dart';
import 'package:openid_client/openid_client.dart';
import 'package:universal_file/universal_file.dart';
import 'package:uuid/uuid.dart';

part 'attachment_processor.dart';

/// Api Client to communicate with the ApptiveGrid Backend
class ApptiveGridClient {
  /// Creates an ApiClient
  ApptiveGridClient({
    this.options = const ApptiveGridOptions(),
    http.Client? httpClient,
    ApptiveGridAuthenticator? authenticator,
  }) : _client = httpClient ?? http.Client() {
    _authenticator = authenticator ??
        ApptiveGridAuthenticator(options: options, httpClient: _client);
    _attachmentProcessor =
        AttachmentProcessor(options, _authenticator, httpClient: _client);
  }

  /// Configurations
  ApptiveGridOptions options;

  late final ApptiveGridAuthenticator _authenticator;

  final http.Client _client;

  late AttachmentProcessor _attachmentProcessor;

  /// Processor for Attachments.
  /// Handles uploading attachments, creating attachments, scaling images
  AttachmentProcessor get attachmentProcessor => _attachmentProcessor;

  /// Close the connection on the httpClient
  void dispose() {
    _client.close();
    _authenticator.dispose();
  }

  /// Headers that are used for multiple Calls
  @visibleForTesting
  Map<String, String> get defaultHeaders => (<String, String?>{
        HttpHeaders.authorizationHeader: _authenticator.header,
        HttpHeaders.contentTypeHeader: ContentType.json,
      }..removeWhere((key, value) => value == null))
          .map((key, value) => MapEntry(key, value!));

  Map<String, String> _createHeadersWithDefaults(
    Map<String, String> customHeader,
  ) {
    final newHeader = defaultHeaders;
    newHeader.addAll(customHeader);
    return newHeader;
  }

  Uri _generateApptiveGridUri(Uri baseUri) {
    return baseUri.replace(
      scheme: 'https',
      host: Uri.parse(options.environment.url).host,
    );
  }

  /// Loads a [FormData] represented by [formUri]
  ///
  /// [headers] will be added in addition to [ApptiveGridClient.defaultHeaders]
  ///
  /// Based on [formUri] this might require Authentication
  /// throws [Response] if the request fails
  Future<FormData> loadForm({
    Uri? uri,
    // ignore: deprecated_member_use_from_same_package
    @Deprecated('Use `uri` instead') FormUri? formUri,
    Map<String, String> headers = const {},
    bool isRetry = false,
  }) async {
    assert(uri != null || formUri != null);
    final url = _generateApptiveGridUri(uri ?? formUri!.uri);
    final sanitizedUrl =
        url.replace(path: url.path.replaceAll(RegExp('/r/'), '/a/'));
    final response = await _client.get(
      sanitizedUrl,
      headers: _createHeadersWithDefaults(headers),
    );
    if (response.statusCode >= 400) {
      if (response.statusCode == 401 && !isRetry) {
        await _authenticator.checkAuthentication();
        return loadForm(
          formUri: formUri,
          uri: uri,
          headers: headers,
          isRetry: true,
        );
      } else {
        throw response;
      }
    }
    return FormData.fromJson(json.decode(response.body));
  }

  /// Calls [submitForm] here for compatibility
  /// [headers] will be added in addition to [ApptiveGridClient.defaultHeaders]
  @Deprecated('Use submitForm with ApptiveLink instead')
  Future<http.Response?> performAction(
    FormAction action,
    FormData formData, {
    bool saveToPendingItems = true,
    Map<String, String> headers = const {},
  }) =>
      submitForm(
        ApptiveLink(uri: Uri.parse(action.uri), method: action.method),
        formData,
        saveToPendingItems: saveToPendingItems,
        headers: headers,
      );

  /// Submits [formData] against [link]
  ///
  /// [headers] will be added in addition to [ApptiveGridClient.defaultHeaders]
  ///
  /// This will return a Stream of [SubmitFormProgressEvent]s to indicate the current step of the submission
  Stream<SubmitFormProgressEvent> submitFormWithProgress(
    ApptiveLink link,
    FormData formData, {
    bool saveToPendingItems = true,
    Map<String, String> headers = const {},
  }) async* {
    final actionItem = ActionItem(link: link, data: formData);

    final controller = StreamController<SubmitFormProgressEvent>();

    _performAttachmentActions(
      formData.attachmentActions,
      fromForm: true,
      headers: headers,
      statusController: controller,
    );

    SubmitFormProgressEvent? attachmentActions;
    yield* controller.stream.map((event) {
      if (event is AttachmentCompleteProgressEvent ||
          event is ErrorProgressEvent) {
        attachmentActions ??= event;
      }
      return event;
    }).handleError((error) async {
      if (error is http.Response) {
        attachmentActions ??= AttachmentCompleteProgressEvent(error);
      } else {
        attachmentActions ??= ErrorProgressEvent(error);
      }
    });

    if ((attachmentActions is ErrorProgressEvent) ||
        (attachmentActions is AttachmentCompleteProgressEvent &&
            ((attachmentActions as AttachmentCompleteProgressEvent)
                        .response
                        ?.statusCode ??
                    400) >=
                400)) {
      late final dynamic error;
      if (attachmentActions is ErrorProgressEvent) {
        error = (attachmentActions as ErrorProgressEvent).error;
      } else {
        error = (attachmentActions as AttachmentCompleteProgressEvent).response;
      }
      if (saveToPendingItems && error != null) {
        yield SubmitCompleteProgressEvent(
          await _handleActionError(
            error,
            actionItem: actionItem,
            saveToPendingItems: saveToPendingItems,
          ),
        );
      } else {
        yield ErrorProgressEvent(error);
      }

      return;
    }

    yield UploadFormProgressEvent(formData);
    late http.Response? response;
    try {
      response = await performApptiveLink<http.Response>(
        link: link,
        body: formData.toRequestObject(),
        headers: headers,
        parseResponse: (response) async => response,
      );
    } catch (error) {
      // Catch all Exception for compatibility Reasons between Web and non Web Apps

      if (saveToPendingItems) {
        yield SubmitCompleteProgressEvent(
          await _handleActionError(
            error,
            actionItem: actionItem,
            saveToPendingItems: saveToPendingItems,
          ),
        );
      } else {
        yield ErrorProgressEvent(error);
      }
      return;
    }
    if (response != null && response.statusCode < 400) {
      // Action was performed successfully. Remove it from pending Actions
      await options.cache?.removePendingActionItem(actionItem);
    }
    yield SubmitCompleteProgressEvent(response);
  }

  /// Submits [formData] against [link]
  ///
  /// [headers] will be added in addition to [ApptiveGridClient.defaultHeaders]
  ///
  /// if this returns a [http.Response] with a [http.Response.statusCode] >= 400 it means that the Item was saved in [options.cache]
  /// throws [Response] if the request fails
  Future<http.Response?> submitForm(
    ApptiveLink link,
    FormData formData, {
    bool saveToPendingItems = true,
    Map<String, String> headers = const {},
  }) async {
    final eventWithResponse = await submitFormWithProgress(
      link,
      formData,
      saveToPendingItems: false, // Saving is handled below
      headers: headers,
    )
        .firstWhere(
      (element) =>
          element is SubmitCompleteProgressEvent ||
          element is ErrorProgressEvent,
    )
        .catchError((error) {
      throw error;
    });

    if (eventWithResponse is SubmitCompleteProgressEvent) {
      return eventWithResponse.response;
    } else if (eventWithResponse is ErrorProgressEvent) {
      final error = eventWithResponse.error;
      return _handleActionError(
        error,
        actionItem: ActionItem(link: link, data: formData),
        saveToPendingItems: saveToPendingItems,
      );
    } else {
      return null;
    }
  }

  Future<http.Response?> _handleActionError(
    Object error, {
    required ActionItem actionItem,
    required bool saveToPendingItems,
  }) async {
    // TODO: Filter out Errors that happened because the Input was not correct
    // in that case don't save the Action and throw the error
    if (saveToPendingItems && options.cache != null) {
      await options.cache!.addPendingActionItem(actionItem);
      if (error is http.Response) {
        return error;
      } else {
        return http.Response(error.toString(), 400);
      }
    }
    throw error;
  }

  Future<http.Response> _performAttachmentActions(
    Map<Attachment, AttachmentAction> actions, {
    bool fromForm = false,
    Map<String, String> headers = const {},
    StreamController<SubmitFormProgressEvent>? statusController,
  }) async {
    try {
      for (final chunkedActions in actions.values.slices(2)) {
        await Future.wait(
          chunkedActions.map((action) {
            switch (action.type) {
              case AttachmentActionType.add:
                return _attachmentProcessor
                    .uploadAttachment(
                  action as AddAttachmentAction,
                )
                    .then((response) {
                  statusController?.add(
                    ProcessedAttachmentProgressEvent(
                      action.attachment,
                    ),
                  );
                  return response;
                }).catchError((error) {
                  throw error;
                });
              case AttachmentActionType.delete:
                debugPrint('Delete Attachment ${action.attachment}');
                return Future.value().then((response) {
                  statusController?.add(
                    ProcessedAttachmentProgressEvent(
                      action.attachment,
                    ),
                  );
                  return response;
                });
              case AttachmentActionType.rename:
                debugPrint(
                  'Rename Attachment ${action.attachment} to "${action.attachment.name}"',
                );
                return Future.value().then((response) {
                  statusController?.add(
                    ProcessedAttachmentProgressEvent(
                      action.attachment,
                    ),
                  );
                  return response;
                });
            }
          }),
        );
      }
      final response = http.Response('AttachmentActionSuccess', 200);
      statusController?.add(AttachmentCompleteProgressEvent(response));
      statusController?.close();
      return response;
    } catch (error) {
      statusController?.addError(error);
      statusController?.close();
      final response = http.Response('AttachmentActionError', 400);
      return response;
    }
  }

  /// Loads a [Grid] represented by [gridUri]
  ///
  /// [sorting] defines the order in which items will be returned
  /// The order of [ApptiveGridSorting] in [sorting] will rank the order in which values should be sorted
  /// [headers] will be added in addition to [ApptiveGridClient.defaultHeaders]
  ///
  /// If [loadEntities] is `true` and there is a [ApptiveLinkType.entities] Link it will also fetch the entities
  /// Requires Authorization
  /// throws [Response] if the request fails
  Future<Grid> loadGrid({
    // ignore: deprecated_member_use_from_same_package
    @Deprecated('Use `uri` instead') GridUri? gridUri,
    Uri? uri,
    List<ApptiveGridSorting>? sorting,
    ApptiveGridFilter? filter,
    bool isRetry = false,
    Map<String, String> headers = const {},
    bool loadEntities = true,
  }) async {
    assert(uri != null || gridUri != null);
    final gridViewUrl = _generateApptiveGridUri(uri ?? gridUri!.uri);

    final gridHeaders = _createHeadersWithDefaults(headers);
    gridHeaders['Accept'] = 'application/vnd.apptivegrid.hal;version=2';
    final gridViewResponse =
        await _client.get(gridViewUrl, headers: gridHeaders);
    if (gridViewResponse.statusCode >= 400) {
      if (gridViewResponse.statusCode == 401 && !isRetry) {
        await _authenticator.checkAuthentication();
        return loadGrid(
          uri: uri,
          gridUri: gridUri,
          sorting: sorting,
          filter: filter,
          isRetry: true,
        );
      }
      throw gridViewResponse;
    }

    final gridToParse = jsonDecode(gridViewResponse.body);
    final grid = Grid.fromJson(gridToParse);
    if (loadEntities && grid.links.containsKey(ApptiveLinkType.entities)) {
      final entitiesResponse = await this.loadEntities(
        uri: grid.links[ApptiveLinkType.entities]!.uri,
        layout: ApptiveGridLayout.indexed,
        filter: filter,
        sorting: sorting,
      );

      final entities = entitiesResponse.items;

      gridToParse['entities'] = entities;
      return Grid.fromJson(gridToParse);
    } else {
      return grid;
    }
  }

  /// Load Entities of a Grid that are accessed by [uri]
  /// the layout in which the entities will be returned is determined by [layout]
  ///
  /// [sorting] allows to apply custom sorting
  /// [filter] allows to get custom filters
  /// [headers] will be added in addition to [ApptiveGridClient.defaultHeaders]
  Future<EntitiesResponse<T>> loadEntities<T>({
    required Uri uri,
    ApptiveGridLayout layout = ApptiveGridLayout.field,
    List<ApptiveGridSorting>? sorting,
    ApptiveGridFilter? filter,
    bool isRetry = false,
    Map<String, String> headers = const {},
  }) async {
    final baseUrl = Uri.parse(options.environment.url);
    final requestUri = uri.replace(
      scheme: baseUrl.scheme,
      host: baseUrl.host,
      queryParameters: {
        ...uri.queryParameters,
        'layout': layout.queryParameter,
        if (sorting != null)
          'sorting':
              jsonEncode(sorting.map((e) => e.toRequestObject()).toList()),
        if (filter != null) 'filter': jsonEncode(filter.toJson()),
      },
    );

    final response = await _client.get(
      requestUri,
      headers: _createHeadersWithDefaults(headers),
    );

    if (response.statusCode >= 400) {
      if (response.statusCode == 401 && !isRetry) {
        await _authenticator.checkAuthentication();
        return loadEntities<T>(
          uri: uri,
          layout: layout,
          sorting: sorting,
          filter: filter,
          isRetry: true,
        );
      }
      throw response;
    }

    final decodedResponse = jsonDecode(response.body);
    if (decodedResponse is List) {
      return EntitiesResponse(items: decodedResponse.cast<T>());
    } else {
      // Preparation for Paging
      return EntitiesResponse(items: decodedResponse['items']);
    }
  }

  /// Get the [User] that is authenticated
  ///
  /// [headers] will be added in addition to [ApptiveGridClient.defaultHeaders]
  ///
  /// Requires Authorization
  /// throws [Response] if the request fails
  Future<User> getMe({
    Map<String, String> headers = const {},
  }) async {
    await _authenticator.checkAuthentication();

    final url = Uri.parse('${options.environment.url}/api/users/me');
    final response =
        await _client.get(url, headers: _createHeadersWithDefaults(headers));
    if (response.statusCode >= 400) {
      throw response;
    }
    return User.fromJson(json.decode(response.body));
  }

  /// Get the [Space] represented by [spaceUri]
  ///
  /// [headers] will be added in addition to [ApptiveGridClient.defaultHeaders]
  ///
  /// Requires Authorization
  /// throws [Response] if the request fails
  Future<Space> getSpace({
    // ignore: deprecated_member_use_from_same_package
    @Deprecated('Use `uri` instead') SpaceUri? spaceUri,
    Uri? uri,
    Map<String, String> headers = const {},
  }) async {
    assert(uri != null || spaceUri != null);
    await _authenticator.checkAuthentication();

    final url = _generateApptiveGridUri(uri ?? spaceUri!.uri);
    final response =
        await _client.get(url, headers: _createHeadersWithDefaults(headers));
    if (response.statusCode >= 400) {
      throw response;
    }
    return Space.fromJson(json.decode(response.body));
  }

  /// Get all [FormUri]s that are contained in a [Grid] represented by [gridUri]
  ///
  /// [headers] will be added in addition to [ApptiveGridClient.defaultHeaders]
  ///
  /// Requires Authorization
  /// throws [Response] if the request fails
  @Deprecated(
    'Consider using the `ApptiveLinkType.forms` link of a `Grid` and call `performApptiveLink` instead. This function will be removed in the future',
  )
  Future<List<FormUri>> getForms({
    required GridUri gridUri,
    Map<String, String> headers = const {},
  }) async {
    await _authenticator.checkAuthentication();

    final baseUrl = _generateApptiveGridUri(gridUri.uri);
    final url = baseUrl.replace(
      pathSegments: [...baseUrl.pathSegments, 'forms'],
    );

    final response =
        await _client.get(url, headers: _createHeadersWithDefaults(headers));
    if (response.statusCode >= 400) {
      throw response;
    }
    return (json.decode(response.body) as List)
        .map((e) => FormUri.fromUri(e))
        .toList();
  }

  /// Get all [GridViewUri]s that are contained in a [Grid] represented by [gridUri]
  ///
  /// [headers] will be added in addition to [ApptiveGridClient.defaultHeaders]
  ///
  /// Requires Authorization
  /// throws [Response] if the request fails
  @Deprecated(
    'Consider using the `ApptiveLinkType.views` link of a `Grid` and call `performApptiveLink` instead. This function will be removed in the future',
  )
  Future<List<GridViewUri>> getGridViews({
    required GridUri gridUri,
    Map<String, String> headers = const {},
  }) async {
    await _authenticator.checkAuthentication();

    final baseUrl = _generateApptiveGridUri(gridUri.uri);
    final url = baseUrl.replace(
      pathSegments: [...baseUrl.pathSegments, 'views'],
    );

    final response =
        await _client.get(url, headers: _createHeadersWithDefaults(headers));
    if (response.statusCode >= 400) {
      throw response;
    }
    return (json.decode(response.body) as List)
        .map((e) => GridViewUri.fromUri(e))
        .toList();
  }

  /// Creates and returns a [Uri] pointing to a Form filled with the Data represented for a given entitiy
  ///
  /// [headers] will be added in addition to [ApptiveGridClient.defaultHeaders]
  ///
  /// Requires Authorization
  /// throws [Response] if the request fails
  Future<Uri> getEditLink({
    @Deprecated('Use `uri` instead. This Uri should be taken from the `ApptiveLinkType.addEditionLink`')
        // ignore: deprecated_member_use_from_same_package
        EntityUri? entityUri,
    Uri? uri,
    required String formId,
    Map<String, String> headers = const {},
  }) async {
    assert(uri != null || entityUri != null);
    await _authenticator.checkAuthentication();

    final url = _generateApptiveGridUri(uri ?? entityUri!.uri);

    final response = await _client.post(
      url,
      headers: _createHeadersWithDefaults(headers),
      body: jsonEncode({
        'formId': formId,
      }),
    );

    if (response.statusCode >= 400) {
      throw response;
    }

    return Uri.parse(
      ((json.decode(response.body) as Map)['uri'] as String)
          .replaceAll(RegExp('/r/'), '/a/'),
    );
  }

  /// Get a specific entity via a [uri]
  ///
  /// [headers] will be added in addition to [ApptiveGridClient.defaultHeaders]
  ///
  /// This will return a Map of fieldIds and the respective values
  /// To know what [DataType] they are you need to Load a Grid via [loadGrid] and compare [Grid.fields] with the ids
  ///
  /// The entity will be layed out according to [layout]
  /// The id of the entity can be accessed via `['_id']`
  Future<dynamic> getEntity({
    // ignore: deprecated_member_use_from_same_package
    @Deprecated('Use `uri` instead') EntityUri? entityUri,
    Uri? uri,
    Map<String, String> headers = const {},
    ApptiveGridLayout layout = ApptiveGridLayout.field,
  }) async {
    assert(uri != null || entityUri != null);
    await _authenticator.checkAuthentication();

    final url = _generateApptiveGridUri(uri ?? entityUri!.uri);

    final response = await _client.get(
      url.replace(
        queryParameters: {
          'layout': layout.queryParameter,
        },
      ),
      headers: _createHeadersWithDefaults(headers),
    );

    if (response.statusCode >= 400) {
      throw response;
    }

    return jsonDecode(response.body);
  }

  /// Authenticate the User
  ///
  /// This will open a Webpage for the User Auth
  Future<Credential?> authenticate() {
    return _authenticator.authenticate();
  }

  /// Logs out the user
  Future<void> logout() {
    return _authenticator.logout();
  }

  /// Checks if the User is currently authenticated
  Future<bool> get isAuthenticated => _authenticator.isAuthenticated;

  /// Checks if the User is currently authenticated with a Token.
  /// Returns true if the user is logged in as a user.
  /// Will return false if there is no authentication set or if the authentication is done using a [ApptiveGridApiKey]
  Future<bool> get isAuthenticatedWithToken =>
      _authenticator.isAuthenticatedWithToken;

  /// Authenticates by setting a token
  /// [tokenResponse] needs to be a JWT
  Future<void> setUserToken(Map<String, dynamic> tokenResponse) async {
    return _authenticator.setUserToken(tokenResponse);
  }

  /// Updates the Environment for the client and handle necessary changes in the Authenticator
  Future<void> updateEnvironment(ApptiveGridEnvironment environment) async {
    final currentRealm = options.environment.authRealm;

    if (currentRealm != environment.authRealm) {
      await _authenticator.logout();
    }

    options = options.copyWith(environment: environment);
    _authenticator.options = options;
    _attachmentProcessor =
        AttachmentProcessor(options, _authenticator, httpClient: _client);
  }

  /// Tries to send pending [ActionItem]s that are stored in [options.cache]
  Future sendPendingActions() async {
    final pendingActions = await options.cache?.getPendingActionItems() ?? [];

    for (final action in pendingActions) {
      try {
        await submitForm(
          action.link,
          action.data,
          saveToPendingItems: false, // don't resubmit this to pending items
        );
      } on http.Response catch (_) {
        // Was not able to submit this action
      }
    }
  }

  String get _attachmentApiEndpoint {
    final endpoint = options
        .attachmentConfigurations[options.environment]?.attachmentApiEndpoint;
    if (endpoint != null) {
      return endpoint;
    } else {
      throw ArgumentError(
        'In order to use Attachments you need to specify AttachmentConfigurations in ApptiveGridOptions',
      );
    }
  }

  /// Creates an url where an attachment should be saved
  /// Deprecated: use [ApptiveGridClient.attachmentProcessor.createAttachment]
  @Deprecated('Use attachmentProcessor.createAttachment')
  Uri createAttachmentUrl(String name) {
    return Uri.parse(
      '$_attachmentApiEndpoint$name?${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  /// Uploads [bytes] as the Profile Picture for the logged in user
  Future<http.Response> uploadProfilePicture({required Uint8List bytes}) async {
    final user = await getMe();

    final signedUri = Uri.parse(
      'https://6csgir6rcj.execute-api.eu-central-1.amazonaws.com/uploads',
    ).replace(
      queryParameters: {
        'fileName': user.id,
        'fileType': 'image/jpeg',
      },
    );

    final signedResponse =
        await _client.get(signedUri, headers: defaultHeaders);

    if (signedResponse.statusCode >= 400) {
      throw signedResponse;
    }

    final uploadUrl = Uri.parse(jsonDecode(signedResponse.body)['uploadURL']);

    final uploadResponse = await _client.put(
      uploadUrl,
      headers: {
        HttpHeaders.contentTypeHeader: 'image/jpeg',
      },
      body: bytes,
    );

    if (uploadResponse.statusCode >= 400) {
      throw uploadResponse;
    } else {
      return uploadResponse;
    }
  }

  /// Perform a action represented by [link]
  /// [body] is the body of the request
  /// [headers] will be added in addition to [ApptiveGridClient.defaultHeaders]
  /// [queryParameters] will override any [queryParameters] in [ApptiveLink.uri]
  /// [parseResponse] will be called with [http.Response] if the request has been successful
  Future<T?> performApptiveLink<T>({
    required ApptiveLink link,
    bool isRetry = false,
    dynamic body,
    Map<String, String> headers = const {},
    Map<String, String>? queryParameters,
    required Future<T?> Function(http.Response response) parseResponse,
  }) async {
    final request = http.Request(
      link.method,
      _generateApptiveGridUri(link.uri).replace(
        queryParameters: queryParameters ?? link.uri.queryParameters,
      ),
    );

    if (body != null) {
      request.body = json.encode(body);
    }

    request.headers.addAll(_createHeadersWithDefaults(headers));

    final streamResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamResponse);

    if (response.statusCode >= 400) {
      if (response.statusCode == 401 && !isRetry) {
        await _authenticator.checkAuthentication();
        return performApptiveLink(
          link: link,
          body: body,
          headers: headers,
          queryParameters: queryParameters,
          isRetry: true,
          parseResponse: parseResponse,
        );
      } else {
        throw response;
      }
    }

    return parseResponse(response);
  }
}
