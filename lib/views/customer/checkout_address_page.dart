import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'payment_method_page.dart';
class CheckoutAddressPage extends StatefulWidget {
  final double totalAmount;

  const CheckoutAddressPage({
    super.key,
    required this.totalAmount,
  });

  @override
  State<CheckoutAddressPage> createState() =>
      _CheckoutAddressPageState();
}

class _CheckoutAddressPageState extends State<CheckoutAddressPage> {
  final addressController = TextEditingController();

  MapboxMap? mapboxMap;

  Point selectedPoint = Point(
    coordinates: Position(74.2369, 16.6913),
  );

  bool isLoading = false;
  bool isLocationLoading = true;
  bool isMapTouching = false;

  bool isInsideKarveerArea(double lat, double lng) {
    return lat >= 16.55 &&
        lat <= 16.85 &&
        lng >= 74.05 &&
        lng <= 74.40;
  }

  Future<void> getCurrentLocation() async {
    try {
      final serviceEnabled =
      await geo.Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        setState(() {
          isLocationLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please turn on location/GPS"),
          ),
        );
        return;
      }

      geo.LocationPermission permission =
      await geo.Geolocator.checkPermission();

      if (permission == geo.LocationPermission.denied) {
        permission =
        await geo.Geolocator.requestPermission();
      }

      if (permission == geo.LocationPermission.denied ||
          permission == geo.LocationPermission.deniedForever) {
        setState(() {
          isLocationLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Location permission denied"),
          ),
        );
        return;
      }

      final position =
      await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.high,
      );

      final lat = position.latitude;
      final lng = position.longitude;

      selectedPoint = Point(
        coordinates: Position(lng, lat),
      );

      await mapboxMap?.flyTo(
        CameraOptions(
          center: selectedPoint,
          zoom: 16,
        ),
        MapAnimationOptions(
          duration: 1200,
        ),
      );

      await getAddress(lat, lng);

      if (mounted) {
        setState(() {
          isLocationLoading = false;
        });
      }
    } catch (e) {
      debugPrint("LOCATION ERROR : $e");

      if (mounted) {
        setState(() {
          isLocationLoading = false;
        });
      }
    }
  }

  Future<void> updateAddressFromCenter() async {
    try {
      final cameraState =
      await mapboxMap?.getCameraState();

      if (cameraState == null) return;

      final lng =
      cameraState.center.coordinates.lng.toDouble();

      final lat =
      cameraState.center.coordinates.lat.toDouble();

      selectedPoint = Point(
        coordinates: Position(lng, lat),
      );

      await getAddress(lat, lng);

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint("CENTER ADDRESS ERROR : $e");
    }
  }

  Future<void> getAddress(
      double lat,
      double lng,
      ) async {
    try {
      final places =
      await placemarkFromCoordinates(
        lat,
        lng,
      );

      if (places.isNotEmpty) {
        final p = places.first;

        final fullAddress =
            "${p.street}, ${p.subLocality}, ${p.locality}, "
            "${p.subAdministrativeArea}, ${p.administrativeArea}, "
            "${p.postalCode}";

        addressController.text = fullAddress;
      }
    } catch (e) {
      debugPrint("GEOCODING ERROR : $e");
    }
  }

  Future<void> zoomMap(double value) async {
    final camera =
    await mapboxMap?.getCameraState();

    if (camera == null) return;

    await mapboxMap?.flyTo(
      CameraOptions(
        center: camera.center,
        zoom: camera.zoom + value,
      ),
      MapAnimationOptions(
        duration: 400,
      ),
    );

    await updateAddressFromCenter();
  }

  Future<void> confirmAddress() async {
    if (addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter delivery address"),
        ),
      );
      return;
    }

    final lng = selectedPoint.coordinates.lng.toDouble();
    final lat = selectedPoint.coordinates.lat.toDouble();

    final allowed = isInsideKarveerArea(lat, lng);

    if (!allowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Delivery is available only in Karveer Taluka, Kolhapur.",
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentMethodPage(
          totalAmount: widget.totalAmount,
          deliveryAddress: addressController.text.trim(),
          latitude: lat,
          longitude: lng,
        ),
      ),
    );
  }

  Widget addressBox() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.18),
        ),
      ),
      child: TextField(
        controller: addressController,
        maxLines: 4,
        style: const TextStyle(
          color: Colors.white,
        ),
        decoration: InputDecoration(
          hintText:
          "Move map pin or enter full address in Karveer Taluka, Kolhapur",
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.65),
          ),
          border: InputBorder.none,
          prefixIcon: const Icon(
            Icons.location_on,
            color: Colors.cyanAccent,
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget areaStatusBox() {
    final lng = selectedPoint.coordinates.lng.toDouble();
    final lat = selectedPoint.coordinates.lat.toDouble();

    final allowed = isInsideKarveerArea(lat, lng);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: allowed
            ? Colors.green.withOpacity(0.18)
            : Colors.red.withOpacity(0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: allowed ? Colors.greenAccent : Colors.redAccent,
        ),
      ),
      child: Row(
        children: [
          Icon(
            allowed ? Icons.check_circle : Icons.error,
            color: allowed ? Colors.greenAccent : Colors.redAccent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              allowed
                  ? "This location is inside delivery area."
                  : "Outside delivery area. Select location inside Karveer.",
              style: TextStyle(
                color: allowed ? Colors.greenAccent : Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget mapBox() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 380,
        child: Listener(
          onPointerDown: (_) {
            setState(() {
              isMapTouching = true;
            });
          },
          onPointerUp: (_) async {
            setState(() {
              isMapTouching = false;
            });

            await updateAddressFromCenter();
          },
          onPointerCancel: (_) {
            setState(() {
              isMapTouching = false;
            });
          },
          child: Stack(
            children: [
              MapWidget(
                key: const ValueKey("mapbox_map"),
                cameraOptions: CameraOptions(
                  center: selectedPoint,
                  zoom: 16,
                ),
                onMapCreated: (controller) async {
                  mapboxMap = controller;
                  await getCurrentLocation();
                },
                onMapIdleListener: (eventData) async {
                  await updateAddressFromCenter();
                },
              ),

              IgnorePointer(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_pin,
                        color: Colors.redAccent,
                        size: 50,
                      ),
                      Container(
                        height: 8,
                        width: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.35),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    "Drag / zoom map to place pin accurately",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),

              Positioned(
                right: 12,
                bottom: 85,
                child: Column(
                  children: [
                    FloatingActionButton.small(
                      heroTag: "zoom_in",
                      backgroundColor: Colors.white,
                      onPressed: () {
                        zoomMap(1);
                      },
                      child: const Icon(
                        Icons.add,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: "zoom_out",
                      backgroundColor: Colors.white,
                      onPressed: () {
                        zoomMap(-1);
                      },
                      child: const Icon(
                        Icons.remove,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: "current_location",
                      backgroundColor: Colors.cyanAccent,
                      onPressed: () async {
                        setState(() {
                          isLocationLoading = true;
                        });

                        await getCurrentLocation();
                      },
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),

              if (isLocationLoading)
                Container(
                  color: Colors.black.withOpacity(0.35),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.cyanAccent,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lng = selectedPoint.coordinates.lng.toDouble();
    final lat = selectedPoint.coordinates.lat.toDouble();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xff021B33),
                  Color(0xff004E92),
                  Color(0xff000428),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: -70,
            left: -40,
            right: -40,
            child: Container(
              height: 240,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(220),
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withOpacity(0.25),
                    Colors.cyan.withOpacity(0.12),
                  ],
                ),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 50,
                  sigmaY: 50,
                ),
                child: const SizedBox(),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: isMapTouching
                  ? const NeverScrollableScrollPhysics()
                  : const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                20,
                16,
                20,
                30,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                        ),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            "Delivery Address",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),

                  const SizedBox(height: 20),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 18,
                        sigmaY: 18,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.18),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Service Area",
                              style: TextStyle(
                                color: Colors.cyanAccent,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              "Delivery is available only in Karveer Taluka, Kolhapur district, Maharashtra.",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.75),
                                fontSize: 14,
                              ),
                            ),

                            const SizedBox(height: 18),

                            addressBox(),

                            const SizedBox(height: 18),

                            mapBox(),

                            const SizedBox(height: 12),

                            areaStatusBox(),

                            const SizedBox(height: 8),

                            Text(
                              "Selected: ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.65),
                                fontSize: 12,
                              ),
                            ),

                            const SizedBox(height: 12),

                            SizedBox(
                              width: double.infinity,
                              height: 45,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Colors.cyanAccent,
                                  ),
                                  foregroundColor:
                                  Colors.cyanAccent,
                                ),
                                onPressed: () async {
                                  setState(() {
                                    isLocationLoading = true;
                                  });

                                  await getCurrentLocation();
                                },
                                icon: const Icon(
                                  Icons.my_location,
                                ),
                                label: const Text(
                                  "Use Current Location",
                                ),
                              ),
                            ),

                            const SizedBox(height: 18),

                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Total Amount",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                  ),
                                ),
                                Text(
                                  "₹ ${widget.totalAmount.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    color: Colors.cyanAccent,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                  Colors.cyanAccent,
                                  foregroundColor: Colors.black,
                                  shape:
                                  RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(18),
                                  ),
                                ),
                                onPressed: isLoading
                                    ? null
                                    : confirmAddress,
                                child: isLoading
                                    ? const CircularProgressIndicator(
                                  color: Colors.black,
                                )
                                    : const Text(
                                  "CONFIRM ADDRESS",
                                  style: TextStyle(
                                    fontWeight:
                                    FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}