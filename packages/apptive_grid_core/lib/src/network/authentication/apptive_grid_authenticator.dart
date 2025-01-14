import 'dart:async';
import 'dart:convert';

import 'package:apptive_grid_core/apptive_grid_core.dart';
import 'package:apptive_grid_core/src/network/authentication/authentication_storage.dart';
import 'package:apptive_grid_core/src/network/authentication/io_authenticator.dart'
    if (dart.library.html) 'package:apptive_grid_core/src/network/authentication/web_authenticator.dart';
import 'package:apptive_grid_core/src/network/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:openid_client/openid_client.dart';
import 'package:uni_links/uni_links.dart' as uni_links;
import 'package:universal_platform/universal_platform.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// Class for handling authentication related methods for ApptiveGrid
class ApptiveGridAuthenticator {
  /// Create a new [ApptiveGridAuthenticator] for [apptiveGridClient]
  ApptiveGridAuthenticator({
    required this.client,
    this.httpClient,
    AuthenticationStorage? authenticationStorage,
    VoidCallback? onAuthenticationChanged,
  }) {
    _onAuthenticationChanged = onAuthenticationChanged;
    _authenticationStorage = authenticationStorage;
    performSetup();
  }

  /// The [ApptiveGridClient] used to retrieve [ApptiveGridClient.options]
  final ApptiveGridClient client;

  /// Http Client that should be used for Auth Requests
  final http.Client? httpClient;

  Client? _authClient;

  TokenResponse? _token;
  Credential? _credential;

  AuthenticationStorage? _authenticationStorage;

  late final VoidCallback? _onAuthenticationChanged;

  late Completer _setupCompleter;

  /// Performs general Authenticator Setup tasks
  /// like checking for saved credentials
  /// and listening to authentication callbacks
  Future<void> performSetup() async {
    _setupCompleter = Completer();
    if (!kIsWeb) {
      _authCallbackSubscription?.cancel();
      _authCallbackSubscription = uni_links.uriLinkStream
          .where(
            (event) =>
                event != null &&
                event.scheme ==
                    client.options.authenticationOptions.redirectScheme
                        ?.toLowerCase(),
          )
          .listen((event) => _handleAuthRedirect(event!));
    }

    if (client.options.authenticationOptions.persistCredentials) {
      _authenticationStorage ??= const FlutterSecureStorageCredentialStorage();
      await checkAuthentication(requestNewToken: false)
          .then((_) => _setupCompleter.complete());
    } else {
      _setupCompleter.complete();
    }
  }

  /// Override the token for testing purposes
  @visibleForTesting
  Future<void> setToken(TokenResponse? token) async {
    if (token != null) {
      _token = token;
      final client = await _client;
      final credential = Credential.fromJson({
        'issuer': client.issuer.metadata.toJson(),
        'client_id': client.clientId,
        'client_secret': client.clientSecret,
        'token': token.toJson(),
      });
      await setCredential(credential);
    } else {
      _token = null;
      await setCredential(null);
    }
  }

  /// Authenticates by setting a token
  /// [tokenResponse] needs to be a JWT
  Future<void> setUserToken(Map<String, dynamic> tokenResponse) async {
    final token = TokenResponse.fromJson(tokenResponse);
    setToken(token);
  }

  /// Override the Credential for testing purposes
  @visibleForTesting
  Future<void> setCredential(Credential? credential) async {
    await _authenticationStorage?.saveCredential(
      credential != null ? jsonEncode(credential.toJson()) : null,
    );
    _credential = credential;
    _onAuthenticationChanged?.call();
  }

  /// Override the [Client] for testing purposes
  @visibleForTesting
  void setAuthClient(Client client) => _authClient = client;

  /// Override the [Authenticator] for testing purposes
  @visibleForTesting
  Authenticator? testAuthenticator;

  StreamSubscription<Uri?>? _authCallbackSubscription;

  /// Creates an openid issuer for the provided options
  static Issuer getIssuerWithUri(ApptiveGridOptions options) {
    final baseUriString =
        '${options.environment.url}/auth/${options.authenticationOptions.authGroup}';
    return Issuer(
      OpenIdProviderMetadata.fromJson({
        'issuer': baseUriString,
        'authorization_endpoint': '$baseUriString/authorize',
        'token_endpoint': '$baseUriString/token',
        'introspection_endpoint':
            '$baseUriString/protocol/openid-connect/token/introspect',
        'userinfo_endpoint': '$baseUriString/protocol/openid-connect/userinfo',
        'end_session_endpoint': '$baseUriString/logout',
        'jwks_uri': '$baseUriString/protocol/openid-connect/certs',
        'check_session_iframe':
            '$baseUriString/protocol/openid-connect/login-status-iframe.html',
        'grant_types_supported':
            '[authorization_code, implicit, refresh_token, password, client_credentials]',
        'response_types_supported':
            '[code, none, id_token, token, id_token token, code id_token, code token, code id_token token]',
        'subject_types_supported': '[public, pairwise]',
        'id_token_signing_alg_values_supported':
            '[PS384, ES384, RS384, HS256, HS512, ES256, RS256, HS384, ES512, PS256, PS512, RS512]',
        'id_token_encryption_alg_values_supported':
            '[RSA-OAEP, RSA-OAEP-256, RSA1_5]',
        'id_token_encryption_enc_values_supported':
            '[A256GCM, A192GCM, A128GCM, A128CBC-HS256, A192CBC-HS384, A256CBC-HS512]',
        'userinfo_signing_alg_values_supported':
            '[PS384, ES384, RS384, HS256, HS512, ES256, RS256, HS384, ES512, PS256, PS512, RS512, none]',
        'request_object_signing_alg_values_supported':
            '[PS384, ES384, RS384, HS256, HS512, ES256, RS256, HS384, ES512, PS256, PS512, RS512, none]',
        'response_modes_supported': '[query, fragment, form_post]',
        'registration_endpoint':
            '$baseUriString/clients-registrations/openid-connect',
        'token_endpoint_auth_methods_supported': [
          'private_key_jwt',
          'client_secret_basic',
          'client_secret_post',
          'tls_client_auth',
          'client_secret_jwt',
        ],
        'token_endpoint_auth_signing_alg_values_supported':
            '[PS384, ES384, RS384, HS256, HS512, ES256, RS256, HS384, ES512, PS256, PS512, RS512]',
        'claims_supported':
            '[aud, sub, iss, auth_time, name, given_name, family_name, preferred_username, email, acr]',
        'claim_types_supported': '[normal]',
        'claims_parameter_supported': 'true',
        'scopes_supported':
            '[openid, offline_access, profile, email, address, phone, roles, web-origins, microprofile-jwt]',
        'request_parameter_supported': 'true',
        'request_uri_parameter_supported': 'true',
        'require_request_uri_registration': 'true',
        'code_challenge_methods_supported': '[plain, S256]',
        'tls_client_certificate_bound_access_tokens': 'true',
        'revocation_endpoint': '$baseUriString/protocol/openid-connect/revoke',
        'revocation_endpoint_auth_methods_supported':
            '[private_key_jwt, client_secret_basic, client_secret_post, tls_client_auth, client_secret_jwt]',
        'revocation_endpoint_auth_signing_alg_values_supported':
            '[PS384, ES384, RS384, HS256, HS512, ES256, RS256, HS384, ES512, PS256, PS512, RS512]',
        'backchannel_logout_supported': 'true',
        'backchannel_logout_session_supported': 'true',
      }),
    );
  }

  Future<Client> get _client async {
    Future<Client> createClient() async {
      final issuer = getIssuerWithUri(client.options);
      return Client(issuer, 'web', httpClient: httpClient, clientSecret: '');
    }

    return _authClient ??= await createClient();
  }

  /// Returns the current authentication token if available and valid.
  String? getAuthToken() {
    // Here, you can add logic to check if the token is expired or not.
    // For simplicity, we're directly returning the accessToken,
    // but consider checking the token's validity first.
    return _token?.accessToken;
  }

  /// Used to test implementation of get _client
  @visibleForTesting
  Future<Client> get authClient => _client;

  /// Open the Authentication Webpage
  ///
  /// Returns [Credential] from the authentication call
  Future<Credential?> authenticate() async {
    final authClient = await _client;

    final authenticator = testAuthenticator ??
        Authenticator(
          authClient,
          scopes: [],
          urlLauncher: _launchUrl,
          redirectUri: client.options.authenticationOptions.redirectScheme !=
                  null
              ? Uri(
                  scheme: client.options.authenticationOptions.redirectScheme,
                  host: Uri.parse(client.options.environment.url).host,
                )
              : null,
        );
    final token = await authenticator.authorize();

    await setToken(await token?.getTokenResponse());

    try {
      await closeInAppWebView();
    } on MissingPluginException {
      debugPrint('closeWebView is not available on this platform');
    } on UnimplementedError {
      debugPrint('closeWebView is not available on this platform');
    }

    return _credential;
  }

  Future<void> _handleAuthRedirect(Uri uri) async {
    final authClient = await _client;
    authClient.createCredential(
      refreshToken: _token?.refreshToken,
    );
    final authenticator = testAuthenticator ??
        Authenticator(
          authClient, // coverage:ignore-line
          redirectUri: client.options.authenticationOptions.redirectScheme !=
                  null
              ? Uri(
                  scheme: client.options.authenticationOptions.redirectScheme,
                  host: Uri.parse(client.options.environment.url).host,
                )
              : null,
          urlLauncher: _launchUrl,
        );

    await authenticator.processResult(uri.queryParameters);
  }

  /// Dispose any resources in the Authenticator
  void dispose() {
    _authCallbackSubscription?.cancel();
  }

  /// Checks the authentication status and performs actions depending on the status
  ///
  /// If [requestNewToken] is true this might open the login page for the user
  /// This is used for the creation of this authenticator to not present the login page when checking for saved tokens
  ///
  /// If there is a [ApptiveGridAuthenticationOptions.apiKey] is set in [options] this will return without any Action
  ///
  /// If the User is not authenticated and [ApptiveGridAuthenticationOptions.autoAuthenticate] is true this will call [authenticate]
  ///
  /// If the token is expired it will refresh the token using the refresh token
  Future<void> checkAuthentication({bool requestNewToken = true}) async {
    if (_token == null) {
      await Future.value(
        _authenticationStorage?.credential,
      ).then((credentialString) async {
        final jsonCredential = jsonDecode(credentialString ?? 'null');
        if (jsonCredential != null) {
          final credential = Credential.fromJson(
            jsonCredential,
            httpClient: httpClient,
          );
          if (credential.client.issuer.metadata.tokenEndpoint ==
              (await _client).issuer.metadata.tokenEndpoint) {
            setCredential(credential);
            try {
              final token = await credential.getTokenResponse(true);
              setToken(token);
              return;
            } on OpenIdException catch (openIdError) {
              setCredential(null);
              debugPrint('Could not refresh saved token: $openIdError');
            } catch (error) {
              debugPrint('Error refreshing token: $error');
            }
          } else {
            setCredential(null);
          }
        }
        if (client.options.authenticationOptions.apiKey != null) {
          // User has ApiKey provided
          return;
        } else if (requestNewToken &&
            client.options.authenticationOptions.autoAuthenticate) {
          await authenticate();
        }
      });
    } else if ((_token?.expiresAt?.difference(DateTime.now()).inSeconds ?? 0) <
        70) {
      final newToken = await _credential?.getTokenResponse(true);
      await setToken(newToken);
    }
  }

  /// Performs a call to Logout the User
  ///
  /// even if the Call Fails the token and credential will be cleared
  Future<http.Response?> logout() async {
    http.Response? response;
    try {
      final logoutUrl = _credential?.generateLogoutUrl();
      if (logoutUrl != null) {
        response = await (httpClient ?? http.Client()).get(
          logoutUrl,
          headers: {
            HttpHeaders.authorizationHeader: header!,
          },
        );
      }
    } catch (_) {
    } finally {
      _token = null;
      await setCredential(null);
      _authClient = null;
    }
    return response;
  }

  /// If there is a authenticated User this will return the authentication header
  ///
  /// User Authentication is prioritized over ApiKey Authentication
  String? get header {
    if (_token != null) {
      final token = _token!;
      return '${token.tokenType} ${token.accessToken}';
    }
    if (client.options.authenticationOptions.apiKey != null) {
      final apiKey = client.options.authenticationOptions.apiKey!;
      return 'Basic ${base64Encode(utf8.encode('${apiKey.authKey}:${apiKey.password}'))}';
    }
    return null;
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrlString(url)) {
      try {
        await launchUrlString(
          url,
          mode: UniversalPlatform.isAndroid
              ? LaunchMode.externalApplication
              : LaunchMode.inAppWebView,
        );
        // coverage:ignore-start
      } on PlatformException catch (_) {
        // coverage:ignore-end
        // Could not launch Url
      }
    }
  }

  /// Checks if the User is Authenticated
  Future<bool> get isAuthenticated => _setupCompleter.future.then(
        (_) =>
            client.options.authenticationOptions.apiKey != null ||
            _token != null,
      );

  /// Checks if the User is Authenticated via a Token
  /// Returns true if the user is logged in as a user.
  /// Will return false if there is no authentication set or if the authentication is done using a [ApptiveGridApiKey]
  Future<bool> get isAuthenticatedWithToken => _setupCompleter.future.then((_) {
        return _token != null;
      });
}

/// Interface to provide common functionality for authorization operations
abstract class IAuthenticator {
  /// Authorizes the User against the Auth Server
  Future<Credential?> authorize();
}
