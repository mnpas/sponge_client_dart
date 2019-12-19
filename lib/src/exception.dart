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

/// A base Sponge exception.
class SpongeException implements Exception {
  const SpongeException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// A Sponge client exception.
class SpongeClientException extends SpongeException {
  const SpongeClientException([
    this.errorCode,
    String errorMessage,
    this.detailedErrorMessage,
  ]) : super(errorMessage);

  final String errorCode;
  String get errorMessage => super.message;
  final String detailedErrorMessage;

  @override
  String toString() => errorMessage ?? 'Sponge error, code: $errorCode';
}

/// A Sponge client exception for invalid knowledge base version.
class InvalidKnowledgeBaseVersionException extends SpongeClientException {
  const InvalidKnowledgeBaseVersionException([
    String errorCode,
    String errorMessage,
    String detailedErrorMessage,
  ]) : super(errorCode, errorMessage, detailedErrorMessage);
}

/// A Sponge client exception for invalid auth token.
class InvalidAuthTokenException extends SpongeClientException {
  const InvalidAuthTokenException([
    String errorCode,
    String errorMessage,
    String detailedErrorMessage,
  ]) : super(errorCode, errorMessage, detailedErrorMessage);
}

/// A Sponge client exception for invalid username or password version.
class InvalidUsernamePasswordException extends SpongeClientException {
  const InvalidUsernamePasswordException([
    String errorCode,
    String errorMessage,
    String detailedErrorMessage,
  ]) : super(errorCode, errorMessage, detailedErrorMessage);
}

/// A Sponge client exception for inactive action.
class InactiveActionException extends SpongeClientException {
  const InactiveActionException([
    String errorCode,
    String errorMessage,
    String detailedErrorMessage,
  ]) : super(errorCode, errorMessage, detailedErrorMessage);
}
