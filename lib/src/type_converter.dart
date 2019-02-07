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

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:sponge_client_dart/src/utils.dart';
import 'package:timezone/timezone.dart';
import 'package:intl/intl.dart';

import 'package:logging/logging.dart';
import 'package:quiver/check.dart';
import 'package:sponge_client_dart/src/type.dart';
import 'package:sponge_client_dart/src/type_value.dart';

/// A type converter.
abstract class TypeConverter {
  static final Logger _logger = Logger('TypeConverter');
  final Map<DataTypeKind, UnitTypeConverter> _registry = Map();

  /// Marshals the [value] as [type].
  Future<dynamic> marshal<T, D extends DataType>(D type, T value) async =>
      value != null
          ? await _getUnitConverter(type).marshal(this, type, value)
          : null;

  /// Unmarshals the [value] as [type].
  Future<T> unmarshal<T, D extends DataType>(D type, dynamic value) async =>
      value != null
          ? await _getUnitConverter(type).unmarshal(this, type, value)
          : null;

  /// Registers the unit type converter.
  void register(UnitTypeConverter unitConverter) {
    _logger.finest(
        'Registering ${unitConverter.typeKind} converter: $unitConverter');
    _registry[unitConverter.typeKind] = unitConverter;
  }

  /// Registers the unit type converters.
  void registerAll(List<UnitTypeConverter> unitConverters) =>
      unitConverters.forEach(register);

  /// Unregisters a unit type converter for the [typeKind]. Returns the previously registered unit type converter.
  UnitTypeConverter unregister(DataTypeKind typeKind) =>
      _registry.remove(typeKind);

  UnitTypeConverter<T, D> _getUnitConverter<T, D extends DataType>(D type) =>
      checkNotNull(_registry[type.kind],
          message: 'Unsupported type ${type.kind}');
}

/// A default type converter.
class DefaultTypeConverter extends TypeConverter {
  DefaultTypeConverter() {
    // Register default unit converters.
    registerAll([
      AnnotatedTypeUnitConverter(),
      AnyTypeUnitConverter(),
      BinaryTypeUnitConverter(),
      BooleanTypeUnitConverter(),
      DateTimeTypeUnitConverter(),
      DynamicTypeUnitConverter(),
      IntegerTypeUnitConverter(),
      ListTypeUnitConverter(),
      MapTypeUnitConverter(),
      NumberTypeUnitConverter(),
      ObjectTypeUnitConverter(),
      StringTypeUnitConverter(),
      TypeTypeUnitConverter(),
      VoidTypeUnitConverter(),
    ]);
  }
}

/// An unit type converter. All implementations should be stateless because one instance is shared
/// by different invocations of [marshal] and [unmarshal] methods.
abstract class UnitTypeConverter<T, D extends DataType> {
  UnitTypeConverter(this.typeKind);

  /// The data type kind.
  final DataTypeKind typeKind;

  /// Marshals the [value] as [type].
  ///
  /// The [value] will never be null here.
  Future<dynamic> marshal(TypeConverter converter, D type, T value) async =>
      value;

  /// Unmarshals the [value] as [type].
  ///
  /// The [value] will never be null here.
  Future<T> unmarshal(TypeConverter converter, D type, dynamic value) async =>
      value;
}

class AnnotatedTypeUnitConverter
    extends UnitTypeConverter<AnnotatedValue, AnnotatedType> {
  AnnotatedTypeUnitConverter() : super(DataTypeKind.ANNOTATED);

  @override
  Future<dynamic> marshal(TypeConverter converter, AnnotatedType type,
          AnnotatedValue value) async =>
      AnnotatedValue(await converter.marshal(type.valueType, value.value),
              label: value.label,
              description: value.description,
              features: value.features)
          .toJson();

  @override
  Future<AnnotatedValue> unmarshal(
      TypeConverter converter, AnnotatedType type, dynamic value) async {
    var result = AnnotatedValue.fromJson(value);
    result.value = await converter.unmarshal(type.valueType, result.value);
    return result;
  }
}

class AnyTypeUnitConverter extends UnitTypeConverter<dynamic, AnyType> {
  AnyTypeUnitConverter() : super(DataTypeKind.ANY);
}

class BinaryTypeUnitConverter extends UnitTypeConverter<Uint8List, BinaryType> {
  BinaryTypeUnitConverter() : super(DataTypeKind.BINARY);

  @override
  Future<dynamic> marshal(
          TypeConverter converter, BinaryType type, Uint8List value) async =>
      base64.encode(value);

  @override
  Future<Uint8List> unmarshal(
          TypeConverter converter, BinaryType type, dynamic value) async =>
      base64.decode(value);
}

class BooleanTypeUnitConverter extends UnitTypeConverter<bool, BooleanType> {
  BooleanTypeUnitConverter() : super(DataTypeKind.BOOLEAN);
}

class DateTimeTypeUnitConverter
    extends UnitTypeConverter<dynamic, DateTimeType> {
  DateTimeTypeUnitConverter() : super(DataTypeKind.DATE_TIME);

  @override
  Future<dynamic> marshal(
      TypeConverter converter, DateTimeType type, dynamic value) async {
    if (type.format != null) {
      return DateFormat(type.format).format(value as DateTime);
    }
    switch (type.dateTimeKind) {
      case DateTimeKind.DATE_TIME:
        return (value as DateTime).toIso8601String();
      case DateTimeKind.DATE_TIME_ZONE:
        return SpongeUtils.formatIsoDateTimeZone(value as TZDateTime);
      case DateTimeKind.DATE:
      case DateTimeKind.TIME:
        throw Exception(
            'The Dart implementation of ${type.dateTimeKind} requires format');
    }

    throw Exception('Unsupported DateTime kind ${type.dateTimeKind}');
  }

  @override
  Future<dynamic> unmarshal(
      TypeConverter converter, DateTimeType type, dynamic value) async {
    String stringValue = value as String;
    switch (type.dateTimeKind) {
      case DateTimeKind.DATE_TIME:
        return type.format != null
            ? DateFormat(type.format).parse(stringValue)
            : DateTime.parse(stringValue);
      case DateTimeKind.DATE_TIME_ZONE:
        checkArgument(type.format == null,
            message:
                'Format is not supported for the Dart implementation of ${type.dateTimeKind}');
        return SpongeUtils.parseIsoDateTimeZone(stringValue);
      case DateTimeKind.DATE:
      case DateTimeKind.TIME:
              checkArgument(type.format != null,
            message:
                'The Dart implementation of ${type.dateTimeKind} requires format');
        return DateFormat(type.format).parse(stringValue);
    }

    DynamicValue result = DynamicValue.fromJson(value);
    result.value = await converter.unmarshal(result.type, result.value);
    return result;
  }
}

class DynamicTypeUnitConverter
    extends UnitTypeConverter<DynamicValue, DynamicType> {
  DynamicTypeUnitConverter() : super(DataTypeKind.DYNAMIC);

  @override
  Future<dynamic> marshal(TypeConverter converter, DynamicType type,
          DynamicValue value) async =>
      DynamicValue(await converter.marshal(value.type, value.value), value.type)
          .toJson();

  @override
  Future<DynamicValue> unmarshal(
      TypeConverter converter, DynamicType type, dynamic value) async {
    DynamicValue result = DynamicValue.fromJson(value);
    result.value = await converter.unmarshal(result.type, result.value);
    return result;
  }
}

class IntegerTypeUnitConverter extends UnitTypeConverter<int, IntegerType> {
  IntegerTypeUnitConverter() : super(DataTypeKind.INTEGER);
}

class ListTypeUnitConverter extends UnitTypeConverter<List, ListType> {
  ListTypeUnitConverter() : super(DataTypeKind.LIST);

  @override
  Future<dynamic> marshal(
      TypeConverter converter, ListType type, List value) async {
    List result = [];
    for (var element in value) {
      result.add(await converter.marshal(type.elementType, element));
    }
    return result;
  }

  @override
  Future<List> unmarshal(
      TypeConverter converter, ListType type, dynamic value) async {
    List result = [];
    for (var element in (value as List)) {
      result.add(await converter.unmarshal(type.elementType, element));
    }
    return result;
  }
}

class MapTypeUnitConverter extends UnitTypeConverter<Map, MapType> {
  MapTypeUnitConverter() : super(DataTypeKind.MAP);

  @override
  Future<dynamic> marshal(
      TypeConverter converter, MapType type, Map value) async {
    Map result = {};
    for (var entry in value.entries) {
      result[await converter.marshal(type.keyType, entry.key)] =
          await converter.marshal(type.valueType, entry.value);
    }
    return result;
  }

  @override
  Future<Map> unmarshal(
      TypeConverter converter, MapType type, dynamic value) async {
    Map result = {};
    for (var entry in (value as Map).entries) {
      result[await converter.unmarshal(type.keyType, entry.key)] =
          await converter.unmarshal(type.valueType, entry.value);
    }
    return result;
  }
}

class NumberTypeUnitConverter extends UnitTypeConverter<num, NumberType> {
  NumberTypeUnitConverter() : super(DataTypeKind.NUMBER);
}

typedef Future<dynamic> ObjectUnitTypeMarshallerCallback(
    TypeConverter converter, dynamic value);

typedef Future<dynamic> ObjectUnitTypeUnmarshallerCallback(
    TypeConverter converter, dynamic value);

class ObjectTypeUnitConverter extends UnitTypeConverter<dynamic, ObjectType> {
  ObjectTypeUnitConverter([this._useTransparentIfNotFound = false])
      : super(DataTypeKind.OBJECT);

  final bool _useTransparentIfNotFound;
  final Map<String, ObjectUnitTypeMarshallerCallback> marshallers = Map();
  final Map<String, ObjectUnitTypeUnmarshallerCallback> unmarshallers = Map();

  @override
  Future<dynamic> marshal(
      TypeConverter converter, ObjectType type, dynamic value) async {
    if (!marshallers.containsKey(type.className)) {
      if (_useTransparentIfNotFound) {
        return value;
      } else {
        throw Exception('Unsupported object type class name ${type.className}');
      }
    }
    return marshallers[type.className](converter, value);
  }

  @override
  Future<dynamic> unmarshal(
      TypeConverter converter, ObjectType type, dynamic value) async {
    if (!unmarshallers.containsKey(type.className)) {
      throw Exception('Unsupported object type class name ${type.className}');
    }
    return unmarshallers[type.className](converter, value);
  }

  void addMarshaller(
          String className, ObjectUnitTypeMarshallerCallback callback) =>
      marshallers[className] = callback;

  void addUnmarshaller(
          String className, ObjectUnitTypeUnmarshallerCallback callback) =>
      unmarshallers[className] = callback;
}

class StringTypeUnitConverter extends UnitTypeConverter<String, StringType> {
  StringTypeUnitConverter() : super(DataTypeKind.STRING);
}

class TypeTypeUnitConverter extends UnitTypeConverter<DataType, TypeType> {
  TypeTypeUnitConverter() : super(DataTypeKind.TYPE);

  /// Note that the `value` is modified in this method.
  @override
  Future<dynamic> marshal(
          TypeConverter converter, TypeType type, DataType value) async =>
      value..defaultValue = await converter.marshal(value, value.defaultValue);

  @override
  Future<DataType> unmarshal(
      TypeConverter converter, TypeType type, dynamic value) async {
    DataType result = DataType.fromJson(value);
    result.defaultValue =
        await converter.unmarshal(result, result.defaultValue);
    return result;
  }
}

class VoidTypeUnitConverter extends UnitTypeConverter<Null, VoidType> {
  VoidTypeUnitConverter() : super(DataTypeKind.VOID);
}
