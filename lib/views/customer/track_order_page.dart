import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class TrackOrderPage extends StatefulWidget {
  const TrackOrderPage({super.key});

  @override
  State<TrackOrderPage> createState() => _TrackOrderPageState();
}

class _TrackOrderPageState extends State<TrackOrderPage> {
  final supabase = Supabase.instance.client;

  bool isLoading = true;
  List orders = [];

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) return;

      final data = await supabase
          .from('orders')
          .select('''
            *,
            order_items(*)
          ''')
          .eq('customer_id', user.id)
          .neq('status', 'delivered')
          .neq('status', 'rejected')
          .neq('status', 'cancelled')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          orders = data;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("TRACK ORDER ERROR : $e");

      if (mounted) {
        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      await supabase
          .from('orders')
          .update({'status': 'cancelled'})
          .eq('id', orderId)
          .eq('status', 'pending');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Order cancelled successfully"),
        ),
      );

      fetchOrders();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<Map<String, dynamic>?> getDeliveryBoy(String deliveryBoyId) async {
    final data = await supabase
        .from('delivery_boys')
        .select('name, phone, email')
        .eq('id', deliveryBoyId)
        .maybeSingle();

    return data;
  }

  Future<void> callDeliveryBoy(String phone) async {
    final uri = Uri.parse("tel:$phone");

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Could not open dialer"),
        ),
      );
    }
  }

  String statusText(String status) {
    if (status == 'pending') {
      return "Waiting for supplier approval";
    }

    if (status == 'accepted') {
      return "Order accepted, delivery boy not assigned yet";
    }

    if (status == 'assigned') {
      return "Delivery boy assigned";
    }

    if (status == 'out_for_delivery') {
      return "Your order is out for delivery";
    }

    if (status == 'delivered') {
      return "Delivered";
    }

    if (status == 'rejected') {
      return "Rejected";
    }

    if (status == 'cancelled') {
      return "Order cancelled";
    }

    return status;
  }

  int statusStep(String status) {
    if (status == 'pending') return 0;
    if (status == 'accepted') return 1;
    if (status == 'assigned') return 2;
    if (status == 'out_for_delivery') return 3;
    if (status == 'delivered') return 4;
    return 0;
  }

  Widget statusTimeline(String status) {
    final step = statusStep(status);

    Widget circle(
        int index,
        IconData icon,
        String label,
        ) {
      final active = step >= index;

      return Expanded(
        child: Column(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: active
                  ? Colors.cyanAccent
                  : Colors.white24,
              child: Icon(
                icon,
                color: active
                    ? Colors.black
                    : Colors.white70,
                size: 17,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: active
                    ? Colors.cyanAccent
                    : Colors.white.withOpacity(0.55),
                fontSize: 10,
                fontWeight: active
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        circle(
          0,
          Icons.receipt_long,
          "Placed",
        ),
        circle(
          1,
          Icons.check_circle,
          "Accepted",
        ),
        circle(
          2,
          Icons.delivery_dining,
          "Assigned",
        ),
        circle(
          3,
          Icons.local_shipping,
          "Out",
        ),
        circle(
          4,
          Icons.home,
          "Delivered",
        ),
      ],
    );
  }

  Widget deliveryBoySection(
      Map order,
      String status,
      ) {
    final deliveryBoyId =
    order['delivery_boy_id'];

    if (deliveryBoyId == null ||
        !(status == 'assigned' ||
            status == 'out_for_delivery')) {
      return const SizedBox();
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: getDeliveryBoy(
        deliveryBoyId.toString(),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return Text(
            "Loading delivery boy details...",
            style: TextStyle(
              color: Colors.white.withOpacity(0.70),
            ),
          );
        }

        final deliveryBoy = snapshot.data;

        if (deliveryBoy == null) {
          return const SizedBox();
        }

        final phone =
            deliveryBoy['phone']?.toString() ?? '';

        return Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              const Text(
                "Delivery Boy Details",
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Name: ${deliveryBoy['name'] ?? '-'}",
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),

              Text(
                "Phone: ${phone.isEmpty ? 'Not added' : phone}",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                ),
              ),

              if (phone.isNotEmpty) ...[
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      Colors.cyanAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      callDeliveryBoy(phone);
                    },
                    icon: const Icon(Icons.call),
                    label: const Text(
                      "CALL DELIVERY BOY",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> showCancelDialog(
      String orderId,
      ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Cancel Order"),
          content: const Text(
            "Are you sure you want to cancel this order?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text("No"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text("Yes, Cancel"),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      cancelOrder(orderId);
    }
  }

  Widget orderCard(Map order) {
    final items =
        order['order_items'] as List? ?? [];

    final status =
        order['status'] ?? 'pending';

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
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_shipping,
                color: Colors.cyanAccent,
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  "Order #${order['id'].toString().substring(0, 8)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Text(
                status.toString().toUpperCase(),
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          statusTimeline(status),

          const SizedBox(height: 14),

          Text(
            statusText(status),
            style: const TextStyle(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.bold,
            ),
          ),

          if (status == 'pending') ...[
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                  Colors.redAccent,
                  side: const BorderSide(
                    color: Colors.redAccent,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  showCancelDialog(order['id']);
                },
                icon: const Icon(Icons.cancel),
                label: const Text(
                  "CANCEL ORDER",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],

          deliveryBoySection(
            order,
            status,
          ),

          const Divider(
            color: Colors.white24,
          ),

          Text(
            "Address: ${order['delivery_address'] ?? '-'}",
            style: TextStyle(
              color:
              Colors.white.withOpacity(0.75),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "Payment: ${order['payment_method'] ?? '-'}",
            style: TextStyle(
              color:
              Colors.white.withOpacity(0.75),
            ),
          ),

          const SizedBox(height: 12),

          ...items.map((item) {
            return Padding(
              padding:
              const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "${item['product_name'] ?? '-'} x${item['quantity']}",
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    "₹ ${item['price']}",
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                    ),
                  ),
                ],
              ),
            );
          }),

          const Divider(
            color: Colors.white24,
          ),

          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              Text(
                "₹ ${order['total_amount']}",
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
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
          // BACKGROUND
          Container(
            decoration:
            const BoxDecoration(
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
                  padding:
                  const EdgeInsets.all(16),
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
                            "Track Order",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      IconButton(
                        onPressed: fetchOrders,
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
                    child:
                    CircularProgressIndicator(
                      color:
                      Colors.cyanAccent,
                    ),
                  )
                      : orders.isEmpty
                      ? const Center(
                    child: Text(
                      "No active orders found",
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  )
                      : RefreshIndicator(
                    onRefresh: fetchOrders,
                    child:
                    ListView.builder(
                      padding:
                      const EdgeInsets.all(
                        20,
                      ),
                      itemCount: orders.length,
                      itemBuilder:
                          (context, index) {
                        return orderCard(
                          orders[index],
                        );
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