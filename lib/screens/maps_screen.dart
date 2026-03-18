import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  MapController? _mapController;
  final List<Marker> _markers = [];
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadFriendsLocations();
    // Initialize map controller and move to current location when available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAndMoveToCurrentLocation();
    });
  }

  Future<void> _initializeAndMoveToCurrentLocation() async {
    if (!mounted) return;

    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );

    // Wait a bit for location to be available
    for (int i = 0; i < 10; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return; // Check if still mounted during wait

      if (locationProvider.currentLocation != null) {
        _addCurrentUserMarker();
        break;
      }
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadFriendsLocations() async {
    try {
      // Load friends and their locations
      QuerySnapshot friendsSnapshot = await FirebaseFirestore.instance
          .collection('friends')
          .where('userId', isEqualTo: _authService.currentUser?.uid)
          .where('status', isEqualTo: 'accepted')
          .get();

      for (var doc in friendsSnapshot.docs) {
        String friendId = doc['friendId'];

        DocumentSnapshot friendDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(friendId)
            .get();

        if (friendDoc.exists) {
          UserModel friend = UserModel.fromMap(
            friendDoc.data() as Map<String, dynamic>,
          );

          if (friend.location != null && friend.isOnline) {
            _addFriendMarker(friend);
          }
        }
      }
    } catch (e) {
      print('Error loading friends locations: $e');
    }
  }

  void _addFriendMarker(UserModel friend) {
    if (!mounted) return;

    final marker = Marker(
      point: LatLng(friend.location!.latitude, friend.location!.longitude),
      width: 40,
      height: 40,
      child: Column(
        children: [
          Icon(
            Icons.person_pin_circle,
            color: friend.isOnline ? Colors.green : Colors.red,
            size: 30,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              friend.name,
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
        ],
      ),
    );

    if (mounted) {
      setState(() {
        _markers.add(marker);
      });
    }
  }

  void _addCurrentUserMarker() {
    if (!mounted) return;

    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );
    if (locationProvider.currentLocation != null) {
      final marker = Marker(
        point: LatLng(
          locationProvider.currentLocation!.latitude!,
          locationProvider.currentLocation!.longitude!,
        ),
        width: 40,
        height: 40,
        child: const Column(
          children: [
            Icon(Icons.my_location, color: Colors.blue, size: 30),
            Icon(Icons.circle, color: Colors.blue, size: 8),
          ],
        ),
      );

      if (mounted) {
        setState(() {
          _markers.add(marker);
        });
      }

      // Move map to current location immediately
      if (_mapController != null) {
        _mapController!.move(
          LatLng(
            locationProvider.currentLocation!.latitude!,
            locationProvider.currentLocation!.longitude!,
          ),
          15.0,
        );
      }

      // Also try to move after a short delay to ensure map is ready
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && _mapController != null) {
          _mapController!.move(
            LatLng(
              locationProvider.currentLocation!.latitude!,
              locationProvider.currentLocation!.longitude!,
            ),
            15.0,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);

    // Add current user marker when location is available
    if (locationProvider.currentLocation != null &&
        !_markers.any(
          (m) =>
              m.point.latitude == locationProvider.currentLocation!.latitude! &&
              m.point.longitude == locationProvider.currentLocation!.longitude!,
        )) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _addCurrentUserMarker();
        }
      });
    }

    // Auto move to current location when location updates
    if (locationProvider.currentLocation != null && _mapController != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _mapController != null) {
          _mapController!.move(
            LatLng(
              locationProvider.currentLocation!.latitude!,
              locationProvider.currentLocation!.longitude!,
            ),
            15.0,
          );
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends Location'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              locationProvider.isTracking
                  ? Icons.location_on
                  : Icons.location_off,
              color: locationProvider.isTracking ? Colors.green : Colors.white,
            ),
            onPressed: () {
              if (locationProvider.isTracking) {
                locationProvider.stopLocationTracking();
              } else {
                locationProvider.startLocationTracking();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (mounted) {
                setState(() {
                  _markers.clear();
                });
                _loadFriendsLocations();
                _addCurrentUserMarker();
              }
            },
          ),
        ],
      ),
      body: locationProvider.currentLocation == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (locationProvider.error != null)
                    Column(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Location Error',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          locationProvider.error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            locationProvider.refreshLocation();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    )
                  else
                    const Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Getting your location...'),
                      ],
                    ),
                ],
              ),
            )
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(
                  locationProvider.currentLocation!.latitude!,
                  locationProvider.currentLocation!.longitude!,
                ),
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.share_location',
                ),
                MarkerLayer(markers: _markers),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      'OpenStreetMap contributors',
                      textStyle: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (locationProvider.currentLocation != null &&
              _mapController != null) {
            // Move to current location with animation
            _mapController!.move(
              LatLng(
                locationProvider.currentLocation!.latitude!,
                locationProvider.currentLocation!.longitude!,
              ),
              15.0,
            );

            // Also refresh the marker
            _addCurrentUserMarker();
          } else {
            // Try to get location if not available
            locationProvider.refreshLocation();
          }
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
