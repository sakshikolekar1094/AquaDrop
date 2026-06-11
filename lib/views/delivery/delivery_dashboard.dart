import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'delivery_profile_page.dart';
import 'delivery_assigned_orders_page.dart';
import 'delivery_route_page.dart';

import '../../services/auth_service.dart';
import '../auth/login_page.dart';

class DeliveryDashboard extends StatefulWidget {
  const DeliveryDashboard({super.key});

  @override
  State<DeliveryDashboard> createState() =>
      _DeliveryDashboardState();
}

class _DeliveryDashboardState extends State<DeliveryDashboard> {
  final supabase = Supabase.instance.client;

  String deliveryBoyName = "Delivery Boy";

  int assignedCount = 0;
  int deliveredCount = 0;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) return;

      final deliveryBoy = await supabase
          .from('delivery_boys')
          .select('id, name')
          .eq('email', user.email ?? '')
          .maybeSingle();

      if (deliveryBoy == null) {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        return;
      }

      final allOrders = await supabase
          .from('orders')
          .select('id, status')
          .eq('delivery_boy_id', deliveryBoy['id']);

      int active = 0;
      int delivered = 0;

      for (var order in allOrders) {
        if (order['status'] == 'assigned' ||
            order['status'] == 'out_for_delivery') {
          active++;
        }

        if (order['status'] == 'delivered') {
          delivered++;
        }
      }

      if (mounted) {
        setState(() {
          deliveryBoyName = deliveryBoy['name'] ?? "Delivery Boy";
          assignedCount = active;
          deliveredCount = delivered;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("DELIVERY DASHBOARD ERROR : $e");

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> logout(BuildContext context) async {
    final authService = AuthService();

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Logout"),
          content: const Text("Are you sure you want to logout?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text("Logout"),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await authService.logout();

      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const LoginPage(),
          ),
              (route) => false,
        );
      }
    }
  }

  Widget statCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 15,
            sigmaY: 15,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withOpacity(0.18),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: Colors.cyanAccent,
                  size: 30,
                ),

                const SizedBox(height: 10),

                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.70),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        tileColor: Colors.white.withOpacity(0.10),
        leading: CircleAvatar(
          backgroundColor: Colors.cyanAccent,
          child: Icon(
            icon,
            color: Colors.black,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withOpacity(0.65),
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // BACKGROUND
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
            top: -80,
            right: -60,
            child: Container(
              height: 220,
              width: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.lightBlueAccent.withOpacity(0.18),
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
            child: isLoading
                ? const Center(
              child: CircularProgressIndicator(
                color: Colors.cyanAccent,
              ),
            )
                : RefreshIndicator(
              onRefresh: fetchDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  30,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADER
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Delivery Panel",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        IconButton(
                          onPressed: () {
                            logout(context);
                          },
                          icon: const Icon(
                            Icons.logout,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // WELCOME CARD
                    ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 18,
                          sigmaY: 18,
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.18),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                height: 70,
                                width: 70,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.cyanAccent,
                                ),
                                child: const Icon(
                                  Icons.delivery_dining,
                                  color: Colors.black,
                                  size: 38,
                                ),
                              ),

                              const SizedBox(width: 16),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Welcome, $deliveryBoyName 👋",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 21,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(height: 6),

                                    Text(
                                      "Manage your assigned water deliveries",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.70),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        statCard(
                          icon: Icons.assignment,
                          title: "Active",
                          value: assignedCount.toString(),
                        ),

                        const SizedBox(width: 12),

                        statCard(
                          icon: Icons.check_circle,
                          title: "Delivered",
                          value: deliveredCount.toString(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 26),

                    const Text(
                      "Delivery Actions",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 14),

                    actionTile(
                      icon: Icons.local_shipping,
                      title: "Assigned Orders",
                      subtitle: "View orders assigned to you",
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const DeliveryAssignedOrdersPage(),
                          ),
                        );

                        fetchDashboardData();
                      },
                    ),

                    actionTile(
                      icon: Icons.route,
                      title: "Delivery Route",
                      subtitle: "Open map route for delivery",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const DeliveryRoutePage(),
                          ),
                        );
                      },
                    ),

                    actionTile(
                      icon: Icons.person,
                      title: "My Profile",
                      subtitle:
                      "View and update your delivery account details",
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const DeliveryProfilePage(),
                          ),
                        );

                        fetchDashboardData();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}