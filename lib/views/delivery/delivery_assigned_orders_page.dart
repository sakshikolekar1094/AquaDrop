import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class DeliveryAssignedOrdersPage extends StatefulWidget {
  const DeliveryAssignedOrdersPage({super.key});

  @override
  State<DeliveryAssignedOrdersPage> createState() =>
      _DeliveryAssignedOrdersPageState();
}

class _DeliveryAssignedOrdersPageState
    extends State<DeliveryAssignedOrdersPage> {

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
            profiles:customer_id(name,email,phone),
            order_items(*)
          ''')
          .eq('delivery_boy_id', deliveryBoy['id'])
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          orders = data;
          isLoading = false;
        });
      }

    } catch (e) {

      debugPrint("ERROR : $e");

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // 📞 CALL CUSTOMER
  Future<void> callCustomer(String phone) async {
    final uri = Uri.parse("tel:$phone");

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Could not open dialer"),
        ),
      );
    }
  }

  // 🚚 START DELIVERY
  Future<void> startDelivery(String orderId) async {
    await supabase
        .from('orders')
        .update({'status': 'out_for_delivery'})
        .eq('id', orderId);

    fetchAssignedOrders();
  }

  // ✅ MARK DELIVERED
  Future<void> markDelivered(String orderId) async {
    await supabase
        .from('orders')
        .update({'status': 'delivered'})
        .eq('id', orderId);

    fetchAssignedOrders();
  }

  Widget orderCard(Map order) {

    final customer = order['profiles'];
    final items = order['order_items'] as List? ?? [];
    final status = order['status'] ?? 'assigned';

    final phone = customer?['phone']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// ORDER HEADER
          Row(
            children: [
              const Icon(Icons.receipt_long, color: Colors.cyanAccent),
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
                status.toUpperCase(),
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          /// CUSTOMER DETAILS
          Text(
            "Customer: ${customer?['name'] ?? '-'}",
            style: const TextStyle(color: Colors.white),
          ),

          Text(
            "Phone: ${phone.isEmpty ? 'Not added' : phone}",
            style: TextStyle(color: Colors.white.withOpacity(0.75)),
          ),

          /// 📞 CALL BUTTON
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  callCustomer(phone);
                },
                icon: const Icon(Icons.call),
                label: const Text(
                  "CALL CUSTOMER",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],

          const SizedBox(height: 10),

          Text(
            "Address: ${order['delivery_address'] ?? '-'}",
            style: TextStyle(color: Colors.white.withOpacity(0.75)),
          ),

          Text(
            "Payment: ${order['payment_method'] ?? '-'}",
            style: TextStyle(color: Colors.white.withOpacity(0.75)),
          ),

          const Divider(color: Colors.white24),

          /// ITEMS
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                "${item['product_name']} x${item['quantity']} - ₹${item['price']}",
                style: const TextStyle(color: Colors.white),
              ),
            );
          }),

          const Divider(color: Colors.white24),

          /// TOTAL
          Text(
            "Total: ₹ ${order['total_amount']}",
            style: const TextStyle(
              color: Colors.cyanAccent,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 14),

          /// BUTTON LOGIC
          if (status == 'assigned')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  startDelivery(order['id']);
                },
                child: const Text("START DELIVERY"),
              ),
            ),

          if (status == 'out_for_delivery')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  markDelivered(order['id']);
                },
                child: const Text("MARK DELIVERED"),
              ),
            ),

          if (status == 'delivered')
            const Text(
              "Delivered",
              style: TextStyle(
                color: Colors.greenAccent,
                fontWeight: FontWeight.bold,
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

          /// BACKGROUND
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

                /// HEADER
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [

                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                        ),
                      ),

                      const Expanded(
                        child: Center(
                          child: Text(
                            "Assigned Orders",
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

                /// BODY
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
                      "No assigned orders",
                      style: TextStyle(color: Colors.white),
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