import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:light0/models/userData.dart';
import 'package:light0/models/userLocation.dart';
import 'package:light0/services/Db/game/init_game.dart';
import 'package:light0/screens/in_game/playingGame.dart';
import 'package:light0/models/user.dart';
import 'package:light0/services/location.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GameSettings extends StatefulWidget {
  @override
  _GameSettingsState createState() => _GameSettingsState();

  final double remainingPlayers;
  final InitGame initGameService;

  GameSettings({this.remainingPlayers, @required this.initGameService});
}

class _GameSettingsState extends State<GameSettings> {
  GoogleMapController _mapController;
  Set<Marker> _markers = HashSet<Marker>();
  Set<Circle> _circles = HashSet<Circle>();

  UserLocation _myLocation;
  double _boundaryRadius;
  LatLng _boundaryPosition;

  @override
  void initState() {
    _boundaryRadius = 100;
    _getLocation();
    super.initState();
  }

  _getLocation() async {
    await LocationService().getLocation().then((value) {
      setState(() {
        _myLocation = value;
      });
      _setBoundaryPosition(LatLng(value.latitude, value.longitude));
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    // _setMapStyle();
  }

  // void _setMapStyle() async {
  // String style = await DefaultAssetBundle.of(context)
  //     .loadString("assets/map_style.json");
  // _mapController.setMapStyle(style);
  // }
  void _setBoundaryRadius(double radius) {
    Set<Circle> newBoundary = HashSet<Circle>();
    Set<Marker> newMarkers = HashSet<Marker>();
    newBoundary.add(
      Circle(
        circleId: CircleId("0"),
        center: _boundaryPosition,
        radius: radius,
        strokeWidth: 3,
        strokeColor: Color.fromRGBO(102, 51, 153, 1),
        fillColor: Color.fromRGBO(102, 51, 153, 0.3),
        zIndex: 1,
      ),
    );

    newMarkers.add(
      Marker(
        markerId: MarkerId("1"),
        position: _boundaryPosition,
        draggable: true,
        zIndex: 2,
        onDragEnd: ((value) {
          //set new boundary location
          Set<Circle> newCircles = HashSet<Circle>();

          final LatLng newBoundaryPosition =
              LatLng(value.latitude, value.longitude);

          newCircles.add(
            Circle(
              circleId: CircleId("0"),
              center: newBoundaryPosition,
              radius: radius,
              strokeWidth: 3,
              strokeColor: Color.fromRGBO(102, 51, 153, 1),
              fillColor: Color.fromRGBO(102, 51, 153, 0.3),
              zIndex: 1,
            ),
          );
          setState(() {
            _circles = newCircles;
            _boundaryPosition = newBoundaryPosition;
          });
        }),
      ),
    );
    setState(() {
      _circles = newBoundary;
      _markers = newMarkers;
    });
  }

  void _setBoundaryPosition(LatLng location) {
    Set<Circle> initialBoundary = HashSet<Circle>();
    initialBoundary.add(
      Circle(
        circleId: CircleId("0"),
        center: location,
        radius: _boundaryRadius,
        strokeWidth: 3,
        strokeColor: Color.fromRGBO(102, 51, 153, 1),
        fillColor: Color.fromRGBO(102, 51, 153, 0.3),
        zIndex: 1,
      ),
    );
    setState(() {
      _circles = initialBoundary;
    });
    _markers.add(
      Marker(
        markerId: MarkerId("1"),
        position: location,
        draggable: true,
        zIndex: 2,
        onDragEnd: ((value) {
          //set new boundary location
          Set<Circle> newCircles = HashSet<Circle>();

          final LatLng newBoundaryPosition =
              LatLng(value.latitude, value.longitude);

          newCircles.add(
            Circle(
              circleId: CircleId("0"),
              center: newBoundaryPosition,
              radius: _boundaryRadius,
              strokeWidth: 3,
              strokeColor: Color.fromRGBO(102, 51, 153, 1),
              fillColor: Color.fromRGBO(102, 51, 153, 0.3),
              zIndex: 1,
            ),
          );
          setState(() {
            _circles = newCircles;
            _boundaryPosition = newBoundaryPosition;
          });
        }),
      ),
    );
  }

  Future<void> _showMyDialog(String userId, LatLng boundaryPosition,
      double boundaryRadius, double playerCount) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap back
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Are you ready?'),
          actions: <Widget>[
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 100, 0),
                    child: RaisedButton(
                      child: Text("Start game"),
                      onPressed: () async {
                        await widget.initGameService
                            .initialiseGame(playerCount);
                        await widget.initGameService
                            .setBoundary(boundaryPosition, boundaryRadius);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlayingGame(),
                          ),
                        );
                      },
                    ),
                  ),
                  FlatButton(
                    child: Text("Cancel"),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ])
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final _user = Provider.of<User>(context);
    if (_user != null)
      return Scaffold(
        appBar: AppBar(
          title: Text("Game settings"),
          actions: <Widget>[],
        ),
        body: Container(
          child: Column(
            children: <Widget>[
              Container(
                height: 350,
                child: GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _myLocation != null
                        ? LatLng(_myLocation.latitude, _myLocation.longitude)
                        : LatLng(0, 0),
                    zoom: 16,
                  ),
                  circles: _circles,
                  markers: _markers,
                  myLocationEnabled: true,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                child: Container(
                  child: Text("Hold and drag marker to move boundary"),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                child: Container(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text("Set boundary size: "),
                      Slider(
                        min: 25,
                        max: 250,
                        value: _boundaryRadius,
                        divisions: 45,
                        label: "$_boundaryRadius m",
                        onChanged: (value) {
                          if (value != _boundaryRadius) {
                            print(value);
                            setState(() {
                              _boundaryRadius = value;
                            });
                          }
                        },
                        onChangeEnd: (newRadius) {
                          print("updating radius $newRadius");
                          _setBoundaryRadius(newRadius);
                          // Set<Circle> updatedRadiusCircles = HashSet<Circle>();
                          // updatedRadiusCircles.add(
                          //   Circle(
                          //     circleId: CircleId("oosh"),
                          //     center: _boundaryPosition,
                          //     radius: newRadius,
                          //     strokeWidth: 3,
                          //     strokeColor: Color.fromRGBO(102, 51, 153, 1),
                          //     fillColor: Color.fromRGBO(102, 51, 153, 0.3),
                          //     zIndex: 1,
                          //   ),
                          // );
                          // setState(() {
                          //   _circles = updatedRadiusCircles;
                          // });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(0, 20, 0, 20),
                  child: RaisedButton(
                    onPressed: () {
                      _showMyDialog(_user.userId, _boundaryPosition,
                          _boundaryRadius, widget.remainingPlayers);
                    },
                    child: Text("start game"),
                  ),
                ),
              )
            ],
          ),
        ),
      );
  }
}
