import 'package:flutter/material.dart';
import 'package:location/location.dart' as loc;
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import '../services/auth_service.dart';

class LocationProvider extends ChangeNotifier {
  final loc.Location _location = loc.Location();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  loc.LocationData? _currentLocation;
  bool _isTracking = false;
  String? _error;
  StreamSubscription<loc.LocationData>? _locationSubscription;

  loc.LocationData? get currentLocation => _currentLocation;
  bool get isTracking => _isTracking;
  String? get error => _error;

  Future<void> initializeLocation() async {
    try {
      print('Initializing location provider...');
      await _requestPermissions();
      await _getCurrentLocation();
      print('Location provider initialized successfully');
    } catch (e) {
      print('Error initializing location: $e');
      _error = 'Failed to initialize location: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> _requestPermissions() async {
    // Request location permissions
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _error = 'Location services are disabled.';
      notifyListeners();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _error = 'Location permissions are denied';
        notifyListeners();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _error = 'Location permissions are permanently denied';
      notifyListeners();
      return;
    }

    // Request location permission for Android
    var status = await Permission.location.request();
    if (status.isDenied) {
      _error = 'Location permission denied';
      notifyListeners();
      return;
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      print('Getting current location...');

      // Use Geolocator instead of Location package for more reliable location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      _currentLocation = loc.LocationData.fromMap({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': position.timestamp.millisecondsSinceEpoch,
      });

      print(
        'Location obtained: ${_currentLocation?.latitude}, ${_currentLocation?.longitude}',
      );
      notifyListeners();

      // Update user location in Firestore
      if (_authService.currentUser != null && _currentLocation != null) {
        await _updateUserLocation();
      }
    } catch (e) {
      print('Error getting location: $e');
      _error = 'Failed to get location: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> startLocationTracking() async {
    if (_isTracking) return;

    try {
      // Check if location service is enabled
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          _error = 'Location service is disabled.';
          notifyListeners();
          return;
        }
      }

      // Start location tracking
      _locationSubscription = _location.onLocationChanged.listen((
        loc.LocationData locationData,
      ) {
        _currentLocation = locationData;
        notifyListeners();
        _updateUserLocation();
      });

      _isTracking = true;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> stopLocationTracking() async {
    if (!_isTracking) return;

    await _locationSubscription?.cancel();
    _locationSubscription = null;
    _isTracking = false;
    notifyListeners();
  }

  Future<void> _updateUserLocation() async {
    try {
      if (_authService.currentUser != null && _currentLocation != null) {
        GeoPoint geoPoint = GeoPoint(
          _currentLocation!.latitude!,
          _currentLocation!.longitude!,
        );

        await _firestore
            .collection('users')
            .doc(_authService.currentUser!.uid)
            .update({'location': geoPoint, 'lastSeen': DateTime.now()});
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<double> getDistanceToFriend(String friendUid) async {
    try {
      DocumentSnapshot friendDoc = await _firestore
          .collection('users')
          .doc(friendUid)
          .get();

      if (!friendDoc.exists || _currentLocation == null) return 0.0;

      Map<String, dynamic> friendData =
          friendDoc.data() as Map<String, dynamic>;
      GeoPoint? friendLocation = friendData['location'] as GeoPoint?;

      if (friendLocation == null) return 0.0;

      double distance = Geolocator.distanceBetween(
        _currentLocation!.latitude!,
        _currentLocation!.longitude!,
        friendLocation.latitude,
        friendLocation.longitude,
      );

      return distance;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return 0.0;
    }
  }

  Future<void> refreshLocation() async {
    print('Refreshing location...');
    _error = null;
    notifyListeners();

    await _getCurrentLocation();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
