/*
 * Created by Alfonso Cejudo, Thursday, July 25th 2019.
 */

import 'package:fluster/fluster.dart';
import 'package:meta/meta.dart';

class MapMarker extends Clusterable {
  String locationName;
  String thumbnailSrc;

  MapMarker(
      {@required this.locationName,
      @required latitude,
      @required longitude,
      this.thumbnailSrc,
      isCluster = false,
      clusterId,
      pointsSize,
      markerId,
      childMarkerId})
      : super(
            latitude: latitude,
            longitude: longitude,
            isCluster: isCluster,
            clusterId: clusterId,
            pointsSize: pointsSize,
            markerId: markerId,
            childMarkerId: childMarkerId);
}
