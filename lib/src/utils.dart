// Copyright 2018 The Sponge authors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:io';

import 'package:http/http.dart';
import 'package:sponge_client_dart/src/constants.dart';
import 'package:sponge_client_dart/src/meta.dart';
import 'package:sponge_client_dart/src/type.dart';
import 'package:sponge_client_dart/src/type_value.dart';
import 'package:sponge_client_dart/src/util/type_utils.dart';
import 'package:timezone/timezone.dart';

/// A set of utility methods.
class SpongeUtils {
  /// Obfuscates a password in the JSON text of a request or response.
  static String obfuscatePassword(String text) =>
      text?.replaceAll(RegExp(r'"password":".*?"'), '"password":"***"');

  /// Returns `true` if the HTTP [code] is success.
  static bool isHttpSuccess(int code) => 200 <= code && code <= 299;

  /// Returns `true` if the HTTP response content type is `application/json`.
  static bool isJson(Response httpResponse) {
    if (httpResponse == null) {
      return false;
    }

    var contentType = httpResponse.headers.entries
        .firstWhere(
            (entry) =>
                entry.key?.toLowerCase() == HttpHeaders.contentTypeHeader,
            orElse: () => null)
        ?.value;

    if (contentType == null) {
      return false;
    }

    return contentType.startsWith('application/json');
  }

  /// Returns `true` if the Sponge server version [serverVersion] is compatible with the client.
  static bool isServerVersionCompatible(String serverVersion) =>
      serverVersion.startsWith(
          '${SpongeClientConstants.SUPPORTED_SPONGE_VERSION_MAJOR_MINOR}.');

  /// Formats a timezoned date/time to a Java compatible format.
  static String formatIsoDateTimeZone(TZDateTime tzDateTime) {
    var result = tzDateTime.toIso8601String();
    return '${result.substring(0, result.length - 2)}:${result.substring(result.length - 2)}[${tzDateTime.location.name}]';
  }

  /// Parses a Java compatible timezoned date/time format as `TZDateTime` or `DateTime` if the location is not present
  /// in the `tzDateTimeString`.
  static DateTime parseIsoDateTimeZone(String tzDateTimeString) {
    var locationIndex = tzDateTimeString.indexOf('[');
    var location = locationIndex > -1
        ? tzDateTimeString.substring(
            locationIndex + 1, tzDateTimeString.indexOf(']'))
        : null;
    return location != null
        ? TZDateTime.parse(
            getLocation(location), tzDateTimeString.substring(0, locationIndex))
        : DateTime.parse(tzDateTimeString);
  }

  static bool supportsElementValueSet(DataType dataType) =>
      dataType is ListType;

  static bool isAnnotatedValueMap(dynamic value) {
    return value is Map &&
        AnnotatedValue.FIELDS.length == value.length &&
        AnnotatedValue.FIELDS.containsAll(value.keys);
  }

  /// Traverses the action argument types.
  static void traverseActionArguments(
      ActionMeta actionMeta, void Function(QualifiedDataType _) onType,
      {bool namedOnly = true}) {
    actionMeta.args?.forEach((argType) => DataTypeUtils.traverseDataType(
        QualifiedDataType(argType.name, argType), onType,
        namedOnly: namedOnly));
  }
}
