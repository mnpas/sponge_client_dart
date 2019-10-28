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

import 'package:sponge_client_dart/src/type.dart';

abstract class DecoratedValue<T> {
  /// The value.
  T value;
}

class AnnotatedValue<T> implements DecoratedValue<T> {
  AnnotatedValue(
    this.value, {
    this.label,
    this.description,
    Map<String, Object> features,
  }) : this.features = features ?? {};

  /// The value.
  @override
  T value;

  /// The optional value label.
  String label;

  /// The optional value description.
  String description;

  /// The annotated type features as a map of names to values.
  Map<String, Object> features;

  factory AnnotatedValue.fromJson(Map<String, dynamic> json) => AnnotatedValue(
        json['value'],
        label: json['label'],
        description: json['description'],
        features: json['features'] ?? {},
      );

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'label': label,
      'description': description,
      'features': features,
    };
  }

  AnnotatedValue<T> copy() => AnnotatedValue(
        value,
        label: label,
        description: description,
        features: Map.from(features),
      );
}

/// A dynamic value that specifies its type.
class DynamicValue<T> implements DecoratedValue<T> {
  DynamicValue(this.value, this.type);

  /// The value.
  @override
  T value;

  /// The value type.
  DataType type;

  factory DynamicValue.fromJson(Map<String, dynamic> json) =>
      DynamicValue(json['value'], DataType.fromJson(json['type']));

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'type': type.toJson(),
    };
  }
}

/// A provided object value and a possible value set.
class ProvidedValue<T> {
  ProvidedValue({
    this.value,
    this.valuePresent,
    this.annotatedValueSet,
    this.annotatedElementValueSet,
    Map<String, Object> features,
  }) : this.features = features ?? {};

  /// The value.
  T value;

  /// If the value is present this flag is `true`.
  bool valuePresent;

  /// The possible value set with optional annotations. For example it may be a list of string values to choose from.
  /// If there is no value set, this property should is `null`.
  List<AnnotatedValue<T>> annotatedValueSet;

  /// The utility getter for the possible value set without labels.
  List<T> get valueSet => annotatedValueSet
      ?.map((annotatedValue) => annotatedValue.value)
      ?.toList();

  /// The possible element value set (with optional annotations) for a list type. For example it may be a list of string
  /// values to multiple choice. Applicable only for list types. If there is no element value set,
  /// this property is `null`.
  List<AnnotatedValue> annotatedElementValueSet;

  /// The optional provided features. Note that these features are not the same as those provided in annotated values.
  Map<String, Object> features;

  /// The utility getter for the possible element value set without labels.
  List get elementValueSet => annotatedElementValueSet
      ?.map((annotatedValue) => annotatedValue.value)
      ?.toList();

  factory ProvidedValue.fromJson(Map<String, dynamic> json) => ProvidedValue(
        value: json['value'],
        valuePresent: json['valuePresent'],
        annotatedValueSet: (json['annotatedValueSet'] as List)
            ?.map((arg) => AnnotatedValue.fromJson(arg))
            ?.toList(),
        annotatedElementValueSet: (json['annotatedElementValueSet'] as List)
            ?.map((arg) => AnnotatedValue.fromJson(arg))
            ?.toList(),
        features: json['features'] ?? {},
      );
}
