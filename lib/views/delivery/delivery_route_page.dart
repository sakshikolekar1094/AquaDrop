import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class DeliveryRoutePage extends StatefulWidget {
  const DeliveryRoutePage({super.key});

  @override
  State<DeliveryRoutePage> createState() => _DeliveryRoutePageState();
}

class _DeliveryRoutePageState extends State<DeliveryRoutePage> {
  final supabase = Supabase.instance.client;

  bool isLoading = true;
  List orders = [];

  @override
  void initState() {
    super.initState();
    fetchAssignedOrders();
  }

  Future<void> fetchAssignedOrders() async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) return;

      final deliveryBoy = await supabase
          .from('delivery_boys')
          .select('id')
          .eq('email', user.email ?? '')
          .maybeSingle();

      if (deliveryBoy == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final data = await supabase
          .from('orders')
          .select('''
            *,
            order_items(*)
          ''')
          .eq('delivery_boy_id', deliveryBoy['id'])
          .inFilter('status', ['assigned', 'out_for_delivery'])
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          orders = data;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("ROUTE ORDER ERROR : $e");

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<geo.Position?> getCurrentLocation() async {
    final serviceEnabled =
    await geo.Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please turn on GPS/location"),
        ),
      );
      return null;
    }

    geo.LocationPermission permission =
    await geo.Geolocator.checkPermission();

    if (permission == geo.LocationPermission.denied) {
      permission =
      await geo.Geolocator.requestPermission();
    }

    if (permission == geo.LocationPermission.denied ||
        permission == geo.LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Location permission denied"),
        ),
      );
      return null;
    }

    return await geo.Geolocator.getCurrentPosition(
      desiredAccuracy: geo.LocationAccuracy.high,
    );
  }
  Future<void> openRoute(Map order) async {
    final position = await getCurrentLocation();

    if (position == null) return;

    final destinationLat = order['latitude'];
    final destinationLng = order['longitude'];

    if (destinationLat == null || destinationLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Customer location not found"),
        ),
      );
      return;
    }

    final googleMapsAppUrl = Uri.parse(
      "google.navigation:q=$destinationLat,$destinationLng&mode=d",
    );

    final googleMapsWebUrl = Uri.parse(
      "https://www.google.com/maps/dir/?api=1"
          "&origin=${position.latitude},${position.longitude}"
          "&destination=$destinationLat,$destinationLng"
          "&travelmode=driving",
    );

    try {
      final openedApp = await launchUrl(
        googleMapsAppUrl,
        mode: LaunchMode.externalApplication,
      );

      if (!openedApp) {
        await launchUrl(
          googleMapsWebUrl,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      final openedWeb = await launchUrl(
        googleMapsWebUrl,
        mode: LaunchMode.externalApplication,
      );

      if (!openedWeb && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Could not open Google Maps"),
          ),
        );
      }
    }
  }

  Widget orderCard(Map order) {
    final items = order['order_items'] as List? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Order #${order['id'].toString().substring(0, 8)}",
            style: const TextStyle(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            "Address: ${order['delivery_address'] ?? '-'}",
            style: const TextStyle(
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 10),

          ...items.map((item) {
            return Text(
              "${item['product_name'] ?? '-'} x${item['quantity']}",
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
              ),
            );
          }),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                openRoute(order);
              },
              icon: const Icon(Icons.navigation),
              label: const Text(
                "OPEN ROUTE",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xff021B33),
                  Color(0xff004E92),
                  Color(0xff000428),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
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
                            "Delivery Route",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: fetchAssignedOrders,
                        icon: const Icon(
                          Icons.refresh,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: isLoading
                      ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.cyanAccent,
                    ),
                  )
                      : orders.isEmpty
                      ? const Center(
                    child: Text(
                      "No assigned route found",
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  )
                      : RefreshIndicator(
                    onRefresh: fetchAssignedOrders,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        return orderCard(orders[index]);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}