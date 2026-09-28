import 'dart:async';

import 'dart:convert';

import 'dart:math';

import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_map/flutter_map.dart';

import 'package:latlong2/latlong.dart';

import 'package:geolocator/geolocator.dart';

import 'package:http/http.dart' as http;

import 'dead_reckoning.dart';
import 'ai_speed_model.dart';

import 'mechanical_help_page.dart';

import 'pulsing_marker.dart';

void main() {

  runApp(const MyApp());

}

class MyApp extends StatelessWidget {

  const MyApp({super.key});

  @override

  Widget build(BuildContext context) {

    final baseTheme = ThemeData(

      useMaterial3: true,

      colorScheme: ColorScheme.fromSeed(

        seedColor: const Color(0xFF2563EB),

        brightness: Brightness.light,

      ),

    );

    return MaterialApp(

      title: 'SIH Navigation - Live Map',

      theme: baseTheme.copyWith(

        textTheme: GoogleFonts.poppinsTextTheme(baseTheme.textTheme),

        elevatedButtonTheme: ElevatedButtonThemeData(

          style: ElevatedButton.styleFrom(

            elevation: 0,

            shape: RoundedRectangleBorder(

                borderRadius: BorderRadius.circular(14)),

            padding:

                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),

          ),

        ),

        outlinedButtonTheme: OutlinedButtonThemeData(

          style: OutlinedButton.styleFrom(

            shape: RoundedRectangleBorder(

                borderRadius: BorderRadius.circular(14)),

            padding:

                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),

            side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.4),

          ),

        ),

      ),

      home: const MapTrackingPage(),

    );

  }

}

enum MapStyle { street, satellite, dark }

class MapTrackingPage extends StatefulWidget {

  const MapTrackingPage({super.key});

  @override

  State<MapTrackingPage> createState() => _MapTrackingPageState();

}

class _MapTrackingPageState extends State<MapTrackingPage> {

  final DeadReckoningTracker _tracker = DeadReckoningTracker();
  final AISpeedModel _aiSpeedModel = AISpeedModel();

  final MapController _mapController = MapController();

  final TextEditingController _searchController = TextEditingController();

  LatLng _currentLocation = const LatLng(31.6340, 74.8723);

  LatLng _lastKnownGpsLocation = const LatLng(31.6340, 74.8723);

  double _currentHeading = 0.0;

  double _currentSpeed = 0.0;

  double _totalDistanceMeters = 0.0;

  bool _isLoadingLocation = true;

  String _locationStatus = 'GPS dhoondh rahe hain...';

  MapStyle _mapStyle = MapStyle.street;

  bool isStationary = false;

  bool _usingGps = true;

  double _mapRotation = 0.0;

  // Search & Directions state

  bool _isSearchMode = false;

  bool _isSearching = false;

  List<Map<String, dynamic>> _searchResults = [];

  LatLng? _destination;

  String? _destinationName;

  List<LatLng> _routePoints = [];

  double? _routeDistanceKm;

  double? _routeDurationMin;

  bool _isFetchingRoute = false;

  List<LatLng> _pathHistory = [];

  StreamSubscription<Position>? _gpsStreamSubscription;

  Timer? _gpsTimeoutTimer;

  Timer? _searchDebounce;

  static const double _metersPerDegreeLat = 111000.0;

  @override

  void initState() {

    super.initState();

    _loadAIModel();
    _startLiveTracking();

    _tracker.onPositionUpdate = (x, y, heading, stationary) {

      if (_usingGps) return;

      setState(() {

        isStationary = stationary;

        _currentSpeed =

            stationary ? 0.0 : (_tracker.velocityX.abs() + _tracker.velocityY.abs());

        double latOffset = y / _metersPerDegreeLat;

        double lngOffset = x /

            (_metersPerDegreeLat * _cosApprox(_lastKnownGpsLocation.latitude));

        final newLoc = LatLng(

          _lastKnownGpsLocation.latitude + latOffset,

          _lastKnownGpsLocation.longitude + lngOffset,

        );

        _updateDistance(newLoc);

        _currentLocation = newLoc;

        _currentHeading = heading * 180 / pi;

        _pathHistory.add(_currentLocation);

        if (_pathHistory.length > 2000) _pathHistory.removeAt(0);

      });

      _mapController.move(_currentLocation, _mapController.camera.zoom);

    };

  }

  void _updateDistance(LatLng newLoc) {

    if (_pathHistory.isNotEmpty) {

      final last = _pathHistory.last;

      _totalDistanceMeters += Geolocator.distanceBetween(

          last.latitude, last.longitude, newLoc.latitude, newLoc.longitude);

    }

  }

  Future<void> _loadAIModel() async {

    try {

      await _aiSpeedModel.loadModel();

      print('AI SPEED MODEL READY');

    } catch (e) {

      print('AI SPEED MODEL ERROR: $e');

    }

  }

  Future<void> _startLiveTracking() async {

    try {

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {

        _switchToDeadReckoning('GPS band hai! Dead-reckoning mode active.');

        return;

      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {

        permission = await Geolocator.requestPermission();

      }

      if (permission == LocationPermission.denied ||

          permission == LocationPermission.deniedForever) {

        _switchToDeadReckoning('Permission nahi mili. Dead-reckoning mode active.');

        return;

      }

      const locationSettings =

          LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 1);

      _gpsStreamSubscription =

          Geolocator.getPositionStream(locationSettings: locationSettings)

              .listen((Position position) {

        _resetGpsTimeout();

        final newLocation = LatLng(position.latitude, position.longitude);

        setState(() {

          _usingGps = true;

          _updateDistance(newLocation);

          _currentLocation = newLocation;

          _lastKnownGpsLocation = newLocation;

          _currentHeading = position.heading;

          _currentSpeed = position.speed;

          _isLoadingLocation = false;

          _locationStatus = 'Live GPS Tracking Active';

          isStationary = position.speed < 0.3;

          _pathHistory.add(newLocation);

          if (_pathHistory.length > 2000) _pathHistory.removeAt(0);

        });

        _mapController.move(newLocation, _mapController.camera.zoom);

      }, onError: (e) {

        _switchToDeadReckoning('GPS signal lost! Dead-reckoning mode active.');

      });

      _resetGpsTimeout();

    } catch (e) {

      _switchToDeadReckoning('GPS error. Dead-reckoning mode active.');

    }

  }

  void _resetGpsTimeout() {

    _gpsTimeoutTimer?.cancel();

    _gpsTimeoutTimer = Timer(const Duration(seconds: 5), () {

      _switchToDeadReckoning(

          'GPS signal lost (tunnel/GPS-denied zone)! Dead-reckoning active.');

    });

  }

  void _switchToDeadReckoning(String message) {

    if (!mounted) return;

    setState(() {

      _usingGps = false;

      _isLoadingLocation = false;

      _locationStatus = message;

    });

    _tracker.reset();

    _tracker.startTracking();

  }

  double _cosApprox(double degrees) {

    final radians = degrees * pi / 180;

    return 1 - (radians * radians) / 2 + (radians * radians * radians * radians) / 24;

  }

  void _resetPath() {

    setState(() {

      _tracker.reset();

      _pathHistory.clear();

      _totalDistanceMeters = 0.0;

      isStationary = false;

    });

  }

  void _zoomIn() =>

      _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);

  void _zoomOut() =>

      _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);

  void _resetNorth() {

    setState(() => _mapRotation = 0.0);

    _mapController.rotate(0);

  }

  String _tileUrlFor(MapStyle style) {

    switch (style) {

      case MapStyle.satellite:

        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';

      case MapStyle.dark:

      case MapStyle.street:

        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    }

  }

  // ---------------- SEARCH (Nominatim - free, no API key) ----------------

  void _onSearchChanged(String query) {

    _searchDebounce?.cancel();

    if (query.trim().length < 3) {

      setState(() => _searchResults = []);

      return;

    }

    _searchDebounce = Timer(const Duration(milliseconds: 500), () {

      _searchPlaces(query);

    });

  }

  Future<void> _searchPlaces(String query) async {

    setState(() => _isSearching = true);

    try {

      final url = Uri.parse(

          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=6');

      final response = await http.get(url, headers: {

        'User-Agent': 'sih_navigation_app (hackathon demo)',

      });

      if (response.statusCode == 200) {

        final List<dynamic> data = jsonDecode(response.body);

        setState(() {

          _searchResults = data

              .map((item) => {

                    'name': item['display_name'],

                    'lat': double.parse(item['lat']),

                    'lon': double.parse(item['lon']),

                  })

              .toList();

        });

      }

    } catch (e) {

      // Silently fail - koi internet na ho to search kaam nahi karega,

      // baaki app (dead-reckoning) offline chalta rahega.

    } finally {

      setState(() => _isSearching = false);

    }

  }

  void _selectDestination(Map<String, dynamic> place) {

    final dest = LatLng(place['lat'], place['lon']);

    setState(() {

      _destination = dest;

      _destinationName = place['name'];

      _isSearchMode = false;

      _searchResults = [];

      _searchController.text = place['name'];

    });

    _mapController.move(dest, 15.0);

    _fetchRoute();

  }

  // ---------------- ROUTING/DIRECTIONS (OSRM - free, no API key) ----------------

  Future<void> _fetchRoute() async {

    if (_destination == null) return;

    setState(() => _isFetchingRoute = true);

    try {

      final url = Uri.parse(

          'https://router.project-osrm.org/route/v1/driving/'

          '${_currentLocation.longitude},${_currentLocation.latitude};'

          '${_destination!.longitude},${_destination!.latitude}'

          '?overview=full&geometries=geojson');

      final response = await http.get(url);

      if (response.statusCode == 200) {

        final data = jsonDecode(response.body);

        if (data['routes'] != null && data['routes'].isNotEmpty) {

          final route = data['routes'][0];

          final coords = route['geometry']['coordinates'] as List;

          setState(() {

            _routePoints = coords

                .map<LatLng>((c) => LatLng(c[1] as double, c[0] as double))

                .toList();

            _routeDistanceKm = (route['distance'] as num) / 1000.0;

            _routeDurationMin = (route['duration'] as num) / 60.0;

          });

          // Poora route dikhne ke liye map fit karo

          if (_routePoints.isNotEmpty) {

            final bounds = LatLngBounds.fromPoints(_routePoints);

            _mapController.fitCamera(

              CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)),

            );

          }

        }

      }

    } catch (e) {

      // Internet na ho to route nahi milega

    } finally {

      setState(() => _isFetchingRoute = false);

    }

  }

  void _clearRoute() {

    setState(() {

      _destination = null;

      _destinationName = null;

      _routePoints = [];

      _routeDistanceKm = null;

      _routeDurationMin = null;

      _searchController.clear();

    });

    _mapController.move(_currentLocation, 17.0);

  }

  @override

  void dispose() {

    _gpsStreamSubscription?.cancel();

    _gpsTimeoutTimer?.cancel();

    _searchDebounce?.cancel();

    _tracker.stopTracking();

    _searchController.dispose();

    super.dispose();

  }

  @override

  Widget build(BuildContext context) {

    final statusColor =

        _usingGps ? Colors.blue : (isStationary ? Colors.green : Colors.deepOrange);

    return Scaffold(

      resizeToAvoidBottomInset: false,

      body: Stack(

        children: [

          // ---- FULLSCREEN MAP ----

          FlutterMap(

            mapController: _mapController,

            options: MapOptions(

              initialCenter: _currentLocation,

              initialZoom: 17.0,

              onPositionChanged: (pos, hasGesture) {

                if (hasGesture) setState(() => _mapRotation = pos.rotation);

              },

              onTap: (_, __) => setState(() => _isSearchMode = false),

            ),

            children: [

              _mapStyle == MapStyle.dark

                  ? ColorFiltered(

                      colorFilter: const ColorFilter.matrix(<double>[

                        -1, 0, 0, 0, 255,

                        0, -1, 0, 0, 255,

                        0, 0, -1, 0, 255,

                        0, 0, 0, 1, 0,

                      ]),

                      child: TileLayer(

                        urlTemplate: _tileUrlFor(_mapStyle),

                        userAgentPackageName: 'com.example.sih_navigation_app',

                      ),

                    )

                  : TileLayer(

                      urlTemplate: _tileUrlFor(_mapStyle),

                      userAgentPackageName: 'com.example.sih_navigation_app',

                    ),

              // Tracked (travelled) path

              PolylineLayer(

                polylines: [

                  Polyline(

                    points: _pathHistory,

                    strokeWidth: 5.0,

                    color: statusColor.withOpacity(0.85),

                  ),

                  // Route/direction line - distinct purple, dashed look

                  if (_routePoints.isNotEmpty)

                    Polyline(

                      points: _routePoints,

                      strokeWidth: 6.0,

                      color: Colors.purple,

                    ),

                ],

              ),

              MarkerLayer(

                markers: [

                  Marker(

                    point: _currentLocation,

                    width: 60,

                    height: 60,

                    child: PulsingLocationMarker(

                      color: statusColor,

                      heading: _currentHeading,

                    ),

                  ),

                  if (_destination != null)

                    Marker(

                      point: _destination!,

                      width: 46,

                      height: 46,

                      child: TweenAnimationBuilder<double>(

                        tween: Tween(begin: 0.0, end: 1.0),

                        duration: const Duration(milliseconds: 450),

                        curve: Curves.elasticOut,

                        builder: (context, value, child) => Transform.scale(

                          scale: value,

                          child: child,

                        ),

                        child: const Icon(Icons.location_on,

                            color: Colors.redAccent, size: 46),

                      ),

                    ),

                ],

              ),

            ],

          ),

          // ---- TOP FLOATING SEARCH BAR ----

          Positioned(

            top: MediaQuery.of(context).padding.top + 10,

            left: 16,

            right: 16,

            child: Column(

              children: [

                Container(

                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

                  decoration: BoxDecoration(

                    color: Colors.white,

                    borderRadius: BorderRadius.circular(28),

                    boxShadow: [

                      BoxShadow(

                          color: Colors.black.withOpacity(0.15),

                          blurRadius: 12,

                          offset: const Offset(0, 4)),

                    ],

                  ),

                  child: Row(

                    children: [

                      const SizedBox(width: 8),

                      Icon(Icons.search, color: Colors.grey.shade600),

                      const SizedBox(width: 8),

                      Expanded(

                        child: TextField(

                          controller: _searchController,

                          onTap: () => setState(() => _isSearchMode = true),

                          onChanged: _onSearchChanged,

                          decoration: const InputDecoration(

                            hintText: 'Search a place or destination',

                            border: InputBorder.none,

                            isDense: true,

                          ),

                        ),

                      ),

                      if (_isSearching)

                        const Padding(

                          padding: EdgeInsets.all(8.0),

                          child: SizedBox(

                            width: 16,

                            height: 16,

                            child: CircularProgressIndicator(strokeWidth: 2),

                          ),

                        )

                      else if (_searchController.text.isNotEmpty)

                        IconButton(

                          icon: const Icon(Icons.close),

                          onPressed: _clearRoute,

                        )

                      else

                        Container(

                          margin: const EdgeInsets.only(right: 6),

                          width: 12,

                          height: 12,

                          decoration:

                              BoxDecoration(shape: BoxShape.circle, color: statusColor),

                        ),

                    ],

                  ),

                ),

                // Search results dropdown

                if (_isSearchMode && _searchResults.isNotEmpty)

                  TweenAnimationBuilder<double>(

                    tween: Tween(begin: 0.0, end: 1.0),

                    duration: const Duration(milliseconds: 220),

                    curve: Curves.easeOut,

                    builder: (context, value, child) => Opacity(

                      opacity: value,

                      child: Transform.translate(

                        offset: Offset(0, (1 - value) * -8),

                        child: child,

                      ),

                    ),

                    child: Container(

                    margin: const EdgeInsets.only(top: 8),

                    constraints: const BoxConstraints(maxHeight: 260),

                    decoration: BoxDecoration(

                      color: Colors.white,

                      borderRadius: BorderRadius.circular(18),

                      boxShadow: [

                        BoxShadow(

                            color: Colors.black.withOpacity(0.15), blurRadius: 10),

                      ],

                    ),

                    child: ListView.separated(

                      shrinkWrap: true,

                      padding: EdgeInsets.zero,

                      itemCount: _searchResults.length,

                      separatorBuilder: (_, __) => const Divider(height: 1),

                      itemBuilder: (context, index) {

                        final place = _searchResults[index];

                        return ListTile(

                          leading: const Icon(Icons.place, color: Colors.redAccent),

                          title: Text(

                            place['name'],

                            maxLines: 2,

                            overflow: TextOverflow.ellipsis,

                            style: const TextStyle(fontSize: 13),

                          ),

                          onTap: () => _selectDestination(place),

                        );

                      },

                    ),

                  ),

                  ),

              ],

            ),

          ),

          // ---- RIGHT SIDE FLOATING CONTROLS ----

          Positioned(

            right: 16,

            bottom: 230,

            child: Column(

              children: [

                _circleButton(icon: Icons.add, onTap: _zoomIn),

                const SizedBox(height: 8),

                _circleButton(icon: Icons.remove, onTap: _zoomOut),

                const SizedBox(height: 16),

                _circleButton(

                    icon: Icons.explore, onTap: _resetNorth, rotation: _mapRotation),

                const SizedBox(height: 16),

                _circleButton(

                  icon: _mapStyle == MapStyle.satellite ? Icons.map : Icons.satellite_alt,

                  onTap: () {

                    setState(() {

                      _mapStyle =

                          _mapStyle == MapStyle.satellite ? MapStyle.street : MapStyle.satellite;

                    });

                  },

                ),

                const SizedBox(height: 8),

                _circleButton(

                  icon: _mapStyle == MapStyle.dark ? Icons.light_mode : Icons.dark_mode,

                  onTap: () {

                    setState(() {

                      _mapStyle = _mapStyle == MapStyle.dark ? MapStyle.street : MapStyle.dark;

                    });

                  },

                ),

                const SizedBox(height: 8),

                _circleButton(

                  icon: Icons.my_location,

                  onTap: () => _mapController.move(_currentLocation, 17.0),

                  filled: true,

                  color: statusColor,

                ),

              ],

            ),

          ),

          // ---- BOTTOM SLIDE-UP INFO CARD ----

          DraggableScrollableSheet(

            initialChildSize: _destination != null ? 0.30 : 0.20,

            minChildSize: 0.14,

            maxChildSize: 0.5,

            builder: (context, scrollController) {

              return Container(

                decoration: const BoxDecoration(

                  color: Colors.white,

                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),

                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 16)],

                ),

                child: ListView(

                  controller: scrollController,

                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),

                  children: [

                    Center(

                      child: Container(

                        width: 40,

                        height: 4,

                        decoration: BoxDecoration(

                            color: Colors.grey.shade300,

                            borderRadius: BorderRadius.circular(2)),

                      ),

                    ),

                    const SizedBox(height: 16),

                    // Route/Directions card - jab destination selected ho

                    if (_destination != null) ...[

                      Row(

                        children: [

                          const Icon(Icons.directions, color: Colors.purple),

                          const SizedBox(width: 8),

                          Expanded(

                            child: Text(

                              _destinationName ?? 'Destination',

                              maxLines: 1,

                              overflow: TextOverflow.ellipsis,

                              style: const TextStyle(

                                  fontWeight: FontWeight.bold, fontSize: 14),

                            ),

                          ),

                          IconButton(

                            icon: const Icon(Icons.close, size: 20),

                            onPressed: _clearRoute,

                          ),

                        ],

                      ),

                      if (_isFetchingRoute)

                        const Padding(

                          padding: EdgeInsets.symmetric(vertical: 8),

                          child: LinearProgressIndicator(),

                        )

                      else if (_routeDistanceKm != null)

                        Padding(

                          padding: const EdgeInsets.only(top: 8, bottom: 4),

                          child: Row(

                            children: [

                              Icon(Icons.route, size: 16, color: Colors.grey.shade700),

                              const SizedBox(width: 4),

                              Text('${_routeDistanceKm!.toStringAsFixed(1)} km',

                                  style: const TextStyle(fontWeight: FontWeight.w600)),

                              const SizedBox(width: 16),

                              Icon(Icons.access_time,

                                  size: 16, color: Colors.grey.shade700),

                              const SizedBox(width: 4),

                              Text('${_routeDurationMin!.toStringAsFixed(0)} min',

                                  style: const TextStyle(fontWeight: FontWeight.w600)),

                            ],

                          ),

                        ),

                      const Divider(height: 24),

                    ],

                    Row(

                      children: [

                        Icon(Icons.circle, color: statusColor, size: 14),

                        const SizedBox(width: 8),

                        Text(

                          _usingGps

                              ? 'GPS Mode - Live Satellite Tracking'

                              : (isStationary

                                  ? 'Offline - Stationary (Drift Correction)'

                                  : 'Offline - Dead Reckoning Active'),

                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),

                        ),

                      ],

                    ),

                    const SizedBox(height: 16),

                    Row(

                      mainAxisAlignment: MainAxisAlignment.spaceBetween,

                      children: [

                        _statTile('Speed', '${(_currentSpeed * 3.6).toStringAsFixed(1)} km/h',

                            Icons.speed),

                        _statTile('Distance', '${_totalDistanceMeters.toStringAsFixed(0)} m',

                            Icons.route),

                        _statTile('Heading', '${_currentHeading.toStringAsFixed(0)}°',

                            Icons.navigation),

                      ],

                    ),

                    const SizedBox(height: 16),

                    Container(

                      padding: const EdgeInsets.all(12),

                      decoration: BoxDecoration(

                        color: Colors.grey.shade100,

                        borderRadius: BorderRadius.circular(12),

                      ),

                      child: Row(

                        children: [

                          const Icon(Icons.location_on, size: 18, color: Colors.grey),

                          const SizedBox(width: 8),

                          Expanded(

                            child: Text(

                              '${_currentLocation.latitude.toStringAsFixed(5)}, '

                              '${_currentLocation.longitude.toStringAsFixed(5)}',

                              style: const TextStyle(fontSize: 13),

                            ),

                          ),

                        ],

                      ),

                    ),

                    const SizedBox(height: 16),

                    Row(

                      children: [

                        Expanded(

                          child: OutlinedButton.icon(

                            onPressed: _resetPath,

                            icon: const Icon(Icons.refresh),

                            label: const Text('Reset Path'),

                          ),

                        ),

                        const SizedBox(width: 12),

                        Expanded(

                          child: ElevatedButton.icon(

                            style: ElevatedButton.styleFrom(

                              backgroundColor: Colors.deepOrange,

                              foregroundColor: Colors.white,

                            ),

                            onPressed: () {

                              Navigator.push(

                                context,

                                MaterialPageRoute(

                                  builder: (context) => MechanicalHelpPage(

                                    currentLocationInfo:

                                        'Position: (${_currentLocation.latitude.toStringAsFixed(5)}, '

                                        '${_currentLocation.longitude.toStringAsFixed(5)})',

                                  ),

                                ),

                              );

                            },

                            icon: const Icon(Icons.build),

                            label: const Text('Need Help?'),

                          ),

                        ),

                      ],

                    ),

                    const SizedBox(height: 20),

                  ],

                ),

              );

            },

          ),

        ],

      ),

    );

  }

  Widget _statTile(String label, String value, IconData icon) {

    return Column(

      children: [

        Icon(icon, size: 20, color: Colors.grey.shade700),

        const SizedBox(height: 4),

        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),

        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),

      ],

    );

  }

  Widget _circleButton({

    required IconData icon,

    required VoidCallback onTap,

    bool filled = false,

    Color color = const Color(0xFF1E293B),

    double rotation = 0.0,

  }) {

    return Material(

      color: filled ? color : Colors.white,

      borderRadius: BorderRadius.circular(16),

      elevation: 3,

      shadowColor: Colors.black26,

      child: InkWell(

        onTap: onTap,

        borderRadius: BorderRadius.circular(16),

        child: Container(

          width: 44,

          height: 44,

          alignment: Alignment.center,

          child: Transform.rotate(

            angle: -rotation * pi / 180,

            child: Icon(icon, color: filled ? Colors.white : color, size: 21),

          ),

        ),

      ),

    );

  }

}