/*
 * Created by Alfonso Cejudo, Thursday, July 25th 2019.
 */

import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/services.dart' show ByteData, rootBundle;

import 'package:fluster/fluster.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image/image.dart' as images;

import 'package:fluster_demo/map_marker.dart';

class MainBloc {
  static const maxZoom = 21;
  static const thumbnailWidth = 150;

  // Current pool of available media that can be displayed on the map.
  final Map<String, MapMarker> _mediaPool;

  /// Markers currently displayed on the map.
  final _markerController = StreamController<Map<MarkerId, Marker>>.broadcast();

  /// Camera position after user gestures / movement.
  final _cameraBounds = StreamController<LatLngBounds>.broadcast();

  /// Outputs.
  Stream<Map<MarkerId, Marker>> get markers => _markerController.stream;
  Stream<LatLngBounds> get cameraBounds => _cameraBounds.stream;

  /// Inputs.
  Function(Map<MarkerId, Marker>) get addMarkers => _markerController.sink.add;
  Function(LatLngBounds) get setCameraBounds => _cameraBounds.sink.add;

  /// Internal listener.
  StreamSubscription _cameraBoundsSubscription;

  /// Keep track of the current Google Maps zoom level.
  int _currentZoom = 12; // As per _initialCameraPosition in main.dart

  /// Fluster!
  Fluster<MapMarker> _fluster;

  MainBloc() : _mediaPool = LinkedHashMap<String, MapMarker>() {
    _buildMediaPool();

    _cameraBoundsSubscription = cameraBounds.listen((latLngBounds) {
      int previousZoom = _currentZoom;
      int nextZoom = _setCurrentZoom(latLngBounds);

      // If the zoom changes, the clusters to display may also change.
      if (previousZoom != nextZoom) {
        _displayMarkers(_mediaPool);
      }
    });
  }

  dispose() {
    _cameraBoundsSubscription.cancel();

    _markerController.close();
    _cameraBounds.close();
  }

  _buildMediaPool() async {
    var response = await _parsedApiResponse();

    _mediaPool.addAll(response);

    _fluster = Fluster<MapMarker>(
        minZoom: 0,
        maxZoom: maxZoom,
        radius: thumbnailWidth ~/ 2,
        extent: 2048,
        nodeSize: 32,
        points: _mediaPool.values.toList(),
        createCluster:
            (BaseCluster cluster, double longitude, double latitude) =>
                MapMarker(
                    locationName: null,
                    latitude: latitude,
                    longitude: longitude,
                    isCluster: true,
                    clusterId: cluster.id,
                    pointsSize: cluster.pointsSize,
                    markerId: cluster.id.toString(),
                    childMarkerId: cluster.childMarkerId));

    _displayMarkers(_mediaPool);
  }

  _displayMarkers(Map pool) async {
    if (_fluster == null) {
      return;
    }

    // Get the clusters at the current zoom level.
    List<MapMarker> clusters =
        _fluster.clusters([-180, -85, 180, 85], _currentZoom);

    // Finalize the markers to display on the map.
    Map<MarkerId, Marker> markers = Map();

    for (MapMarker feature in clusters) {
      BitmapDescriptor bitmapDescriptor;

      if (feature.isCluster) {
        bitmapDescriptor = await _createClusterBitmapDescriptor(feature);
      } else {
        bitmapDescriptor =
            await _createImageBitmapDescriptor(feature.thumbnailSrc);
      }

      var marker = Marker(
          markerId: MarkerId(feature.markerId),
          position: LatLng(feature.latitude, feature.longitude),
          infoWindow: InfoWindow(title: feature.locationName),
          icon: bitmapDescriptor);

      markers.putIfAbsent(MarkerId(feature.markerId), () => marker);
    }

    // Publish markers to subscribers.
    addMarkers(markers);
  }

  Future<BitmapDescriptor> _createClusterBitmapDescriptor(
      MapMarker feature) async {
    MapMarker childMarker = _mediaPool[feature.childMarkerId];

    var child = await _createImage(
        childMarker.thumbnailSrc, thumbnailWidth, thumbnailWidth);

    if (child == null) {
      return null;
    }

    images.brightness(child, -50);
    images.drawString(child, images.arial_48, 0, 0, '+${feature.pointsSize}');

    var resized =
        images.copyResize(child, width: thumbnailWidth, height: thumbnailWidth);

    var png = images.encodePng(resized);

    return BitmapDescriptor.fromBytes(png);
  }

  Future<BitmapDescriptor> _createImageBitmapDescriptor(
      String thumbnailSrc) async {
    var resized =
        await _createImage(thumbnailSrc, thumbnailWidth, thumbnailWidth);

    if (resized == null) {
      return null;
    }

    var png = images.encodePng(resized);

    return BitmapDescriptor.fromBytes(png);
  }

  Future<images.Image> _createImage(
      String imageFile, int width, int height) async {
    ByteData imageData;
    try {
      imageData = await rootBundle.load('assets/images/$imageFile');
    } catch (e) {
      print('caught $e');
      return null;
    }

    if (imageData == null) {
      return null;
    }

    List<int> bytes = Uint8List.view(imageData.buffer);
    var image = images.decodeImage(bytes);

    return images.copyResize(image, width: width, height: height);
  }

  /// Until the Flutter Google Maps exposes current display properties,
  /// calculate the zoom level manually.
  int _setCurrentZoom(LatLngBounds latLngBounds) {
    var southwest = latLngBounds.southwest;
    var northeast = latLngBounds.northeast;

    double latDelta = (southwest.latitude - northeast.latitude).abs();

    if (latDelta < 0.0004) {
      _currentZoom = 21;
    } else if (latDelta < 0.0008) {
      _currentZoom = 20;
    } else if (latDelta < 0.0015) {
      _currentZoom = 19;
    } else if (latDelta < 0.003) {
      _currentZoom = 18;
    } else if (latDelta < 0.0059) {
      _currentZoom = 17;
    } else if (latDelta < 0.0118) {
      _currentZoom = 16;
    } else if (latDelta < 0.0236) {
      _currentZoom = 15;
    } else if (latDelta < 0.0471) {
      _currentZoom = 14;
    } else if (latDelta < 0.0942) {
      _currentZoom = 13;
    } else if (latDelta < 0.189) {
      _currentZoom = 12;
    } else if (latDelta < 0.377) {
      _currentZoom = 11;
    } else if (latDelta < 0.753) {
      _currentZoom = 10;
    } else if (latDelta < 1.51) {
      _currentZoom = 9;
    } else if (latDelta < 3.03) {
      _currentZoom = 8;
    } else if (latDelta < 6.19) {
      _currentZoom = 7;
    } else if (latDelta < 12.7) {
      _currentZoom = 6;
    } else if (latDelta < 27) {
      _currentZoom = 5;
    } else if (latDelta < 54) {
      _currentZoom = 4;
    } else if (latDelta < 107) {
      _currentZoom = 3;
    } else if (latDelta < 160) {
      _currentZoom = 2;
    } else if (latDelta < 180) {
      _currentZoom = 1;
    } else {
      _currentZoom = 0;
    }

    return _currentZoom;
  }

  /// Hard-coded example of what could be returned from some API call.
  /// The item IDs should be different that possible cluster IDs since we're
  /// using a Map data structure where the keys are either these item IDs or
  /// the cluster IDs.
  Future<Map<String, MapMarker>> _parsedApiResponse() async {
    await Future.delayed(const Duration(milliseconds: 2000), () {});

    return {
      '9000000': MapMarker(
          locationName: 'Veselka',
          markerId: '9000000',
          latitude: 40.729053,
          longitude: -73.987142,
          thumbnailSrc: 'veselka.png'),
      '9000001': MapMarker(
          locationName: 'Artichoke Basille\'s Pizza',
          markerId: '9000001',
          latitude: 40.732130,
          longitude: -73.983891,
          thumbnailSrc: 'artichoke.png'),
      '9000002': MapMarker(
          locationName: 'Halal Guys',
          markerId: '9000002',
          latitude: 40.732327,
          longitude: -73.984414,
          thumbnailSrc: 'halalguys.png'),
      '9000003': MapMarker(
          locationName: 'Taco Bell',
          markerId: '9000003',
          latitude: 40.735525,
          longitude: -73.992725,
          thumbnailSrc: 'tacobell.png'),
    };
  }
}
