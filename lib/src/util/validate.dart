// Copyright 2019 The Sponge authors.
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

import 'package:sponge_client_dart/src/exception.dart';

class Validate {
  static void isTrue(bool expression, String message) {
    if (!expression) {
      throw SpongeException(message);
    }
  }

  static T notNull<T>(T value, [String message = 'The value is null']) {
    if (value == null) {
      throw SpongeException(message);
    }

    return value;
  }
}
