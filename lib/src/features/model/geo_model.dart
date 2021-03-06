// Copyright 2020 The Sponge authors.
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

import 'package:meta/meta.dart';
import 'package:sponge_client_dart/src/util/validate.dart';

class GeoPosition {
  GeoPosition({
    @required this.latitude,
    @required this.longitude,
  });

  double latitude;
  double longitude;

  factory GeoPosition.fromJson(Map<String, dynamic> json) => json != null
      ? GeoPosition(
          latitude: (json['latitude'] as num)?.toDouble(),
          longitude: (json['longitude'] as num)?.toDouble(),
        )
      : null;

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
      };
}

class GeoCrs {
  GeoCrs({
    @required this.code,
    this.projection,
    List<double> resolutions,
  }) : resolutions = resolutions ?? [];

  String code;
  String projection;
  List<double> resolutions;

  factory GeoCrs.fromJson(Map<String, dynamic> json) => json != null
      ? GeoCrs(
          code: json['code'],
          projection: json['projection'],
          resolutions: List.from(json['resolutions'] ?? [])
              .map((r) => (r as num)?.toDouble())
              .toList(),
        )
      : null;

  Map<String, dynamic> toJson() => {
        'code': code,
        'projection': projection,
        'resolutions': resolutions,
      };
}

enum GeoLayerType { TILE, MARKER, WMS }

abstract class GeoLayer {
  GeoLayer(
    this.type, {
    this.name,
    this.label,
    this.description,
    Map<String, Object> features,
  }) : features = features ?? {};

  final GeoLayerType type;
  String name;
  String label;
  String description;

  /// The geo layer features as a map of names to values.
  Map<String, Object> features;

  @protected
  static GeoLayer fromJsonBase(GeoLayer layer, Map<String, dynamic> json) {
    layer.name = json['name'];
    layer.label = json['label'];
    layer.description = json['description'];
    (json['features'] as Map)
        ?.forEach((name, value) => layer.features[name] = value);
    return layer;
  }

  static GeoLayer _geoLayerFromJson(Map<String, dynamic> json) {
    var type = GeoLayer.fromJsonGeoLayerType(json['type']);
    switch (type) {
      case GeoLayerType.TILE:
        return GeoTileLayer.fromJson(json);
      case GeoLayerType.MARKER:
        return GeoMarkerLayer.fromJson(json);
      case GeoLayerType.WMS:
        return GeoWmsLayer.fromJson(json);
    }

    throw Exception('Unsupported geo layer type $type');
  }

  factory GeoLayer.fromJson(Map<String, dynamic> json) =>
      json != null ? _geoLayerFromJson(json) : null;

  static GeoLayerType fromJsonGeoLayerType(String jsonGeoLayerType) {
    var type = GeoLayerType.values.firstWhere(
        (t) => _getGeoLayerTypeValue(t) == jsonGeoLayerType,
        orElse: () => null);
    return Validate.notNull(
        type, 'Unsupported geo layer type $jsonGeoLayerType');
  }

  static String _getGeoLayerTypeValue(GeoLayerType type) =>
      type.toString().split('.')[1];
}

class GeoTileLayer extends GeoLayer {
  GeoTileLayer({
    @required this.urlTemplate,
    String name,
    String label,
    String description,
    List<String> subdomains,
    Map<String, String> options,
    Map<String, Object> features,
  })  : subdomains = subdomains ?? [],
        options = options ?? {},
        super(
          GeoLayerType.TILE,
          name: name,
          label: label,
          description: description,
          features: features,
        );

  String urlTemplate;
  List<String> subdomains;
  Map<String, String> options;

  factory GeoTileLayer.fromJson(Map<String, dynamic> json) => json != null
      ? GeoLayer.fromJsonBase(
          GeoTileLayer(
            urlTemplate: json['urlTemplate'],
            subdomains: List.from(json['subdomains'] ?? []),
            options: (json['options'] as Map)?.map(
                (name, valueJson) => MapEntry(name, valueJson?.toString())),
          ),
          json)
      : null;
}

class GeoMarkerLayer extends GeoLayer {
  GeoMarkerLayer({
    String name,
    String label,
    String description,
    Map<String, Object> features,
  }) : super(
          GeoLayerType.MARKER,
          name: name,
          label: label,
          description: description,
          features: features,
        );

  factory GeoMarkerLayer.fromJson(Map<String, dynamic> json) =>
      json != null ? GeoLayer.fromJsonBase(GeoMarkerLayer(), json) : null;
}

class GeoWmsLayer extends GeoLayer {
  GeoWmsLayer({
    @required this.baseUrl,
    String name,
    String label,
    String description,
    List<String> layers,
    this.crs,
    this.format,
    this.version,
    List<String> styles,
    this.transparent,
    Map<String, String> otherParameters,
    Map<String, Object> features,
  })  : layers = layers ?? [],
        styles = styles ?? [],
        otherParameters = otherParameters ?? {},
        super(
          GeoLayerType.WMS,
          name: name,
          label: label,
          description: description,
          features: features,
        );

  String baseUrl;
  List<String> layers;
  GeoCrs crs;
  String format;
  String version;
  List<String> styles;
  bool transparent;
  Map<String, String> otherParameters;

  factory GeoWmsLayer.fromJson(Map<String, dynamic> json) => json != null
      ? GeoLayer.fromJsonBase(
          GeoWmsLayer(
            baseUrl: json['baseUrl'],
            layers: List.from(json['layers'] ?? []),
            crs: GeoCrs.fromJson(json['crs']),
            format: json['format'],
            version: json['version'],
            styles: List.from(json['styles'] ?? []),
            transparent: json['transparent'],
            otherParameters: (json['otherParameters'] as Map)?.map(
                (name, valueJson) => MapEntry(name, valueJson?.toString())),
          ),
          json)
      : null;
}

class GeoMap {
  GeoMap({
    @required this.center,
    @required this.zoom,
    @required this.minZoom,
    @required this.maxZoom,
    @required this.crs,
    List<GeoLayer> layers,
    Map<String, Object> features,
  })  : layers = layers ?? [],
        features = features ?? {};

  GeoPosition center;
  double zoom;
  double minZoom;
  double maxZoom;

  /// Coordinate Reference System.
  GeoCrs crs;

  List<GeoLayer> layers;

  /// The geo map features as a map of names to values.
  Map<String, Object> features;

  factory GeoMap.fromJson(Map<String, dynamic> json) => json != null
      ? GeoMap(
          center: GeoPosition.fromJson(json['center']),
          zoom: (json['zoom'] as num)?.toDouble(),
          minZoom: (json['minZoom'] as num)?.toDouble(),
          maxZoom: (json['maxZoom'] as num)?.toDouble(),
          crs: GeoCrs.fromJson(json['crs']),
          layers: (json['layers'] as List)
              ?.map((layer) => GeoLayer.fromJson(layer))
              ?.toList(),
          features: Map.of(json['features'] as Map ?? {}),
        )
      : null;
}
