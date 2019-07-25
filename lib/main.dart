/*
 * Created by Alfonso Cejudo, Thursday, July 25th 2019.
 */

import 'package:flutter/material.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import 'main_bloc.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Provider<MainBloc>(
      builder: (context) => MainBloc(),
      dispose: (context, mainBloc) => mainBloc.dispose(),
      child: MaterialApp(
        title: 'Fluster Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: MyHomePage(title: 'Fluster Demo'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  MainBloc _bloc;

  // Map vars.
  GoogleMapController _mapController;
  static final CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(40.730183, -73.990793),
    zoom: 12.0,
  );

  @override
  void didChangeDependencies() {
    _bloc = Provider.of<MainBloc>(context);

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: StreamBuilder<Map<MarkerId, Marker>>(
        stream: _bloc.markers,
        builder: (context, snapshot) {
          return GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _initialCameraPosition,
            onMapCreated: _onMapCreated,
            onCameraIdle: _onCameraIdle,
            myLocationEnabled: false,
            markers:
                (snapshot.data != null) ? Set.of(snapshot.data.values) : Set(),
          );
        },
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onCameraIdle() async {
    var latLngBounds = await _mapController.getVisibleRegion();
    _bloc.setCameraBounds(latLngBounds);
  }
}
