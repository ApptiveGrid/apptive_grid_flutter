library active_grid_network;

import 'dart:convert';

import 'package:active_grid_core/active_grid_model.dart';
import 'package:active_grid_core/active_grid_options.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:openid_client/openid_client.dart';
import 'network/stub_authenticator.dart'
    if (dart.library.io) 'package:openid_client/openid_client_io.dart'
    if (dart.library.html) 'package:openid_client/openid_client_browser.dart';

import 'package:url_launcher/url_launcher.dart';

part 'network/active_grid_client.dart';
part 'network/environment.dart';
part 'network/active_grid_authentication_options.dart';
part 'network/active_grid_authenticator.dart';
part 'network/constants.dart';