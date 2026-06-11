import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupplierOrdersPage extends StatefulWidget {
  const SupplierOrdersPage({super.key});

  @override
  State<SupplierOrdersPage> createState() =>
      _SupplierOrdersPageState();
}

class _SupplierOrdersPageState extends State<SupplierOrdersPage> {
  final supabase = Supabase.instance.client;

  bool isLoading = true;
  List orders = [];
  List deliveryBoys = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) return;

      final orderData = await supabase
          .from('orders')
          .select('*, order_items(*)')
          .eq('supplier_id', user.id)
          .order('created_at', ascending: false);

      final boysData = await supabase
          .from('delivery_boys')
          .select()
          .eq('supplier_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          orders = orderData;
          deliveryBoys = boysData;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("SUPPLIER ORDER ERROR : $e");

      if (mounted) {
        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
          ),
        );
      }
    }
  }

  Future<Map<String, dynamic>?> getCustomer(String id) async {
    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', id)
        .maybeSingle();

    return data;
  }

  Future<void> updateOrderStatus(
      String orderId,
      String status,
      ) async {
    await supabase
        .from('orders')
        .update({'status': status})
        .eq('id', orderId);

    fetchData();
  }

  Future<void> assignDeliveryBoy(Map order) async {
    if (deliveryBoys.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No delivery boys found"),
        ),
      );
      return;
    }

    Map? selectedBoy;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Assign Delivery Boy"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: deliveryBoys.length,
              itemBuilder: (context, index) {
                final boy = deliveryBoys[index];

                return ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.delivery_dining),
                  ),
                  title: Text(boy['name'] ?? '-'),
                  subtitle: Text(
                    boy['phone'] ??
                        boy['email'] ??
                        '-',
                  ),
                  onTap: () {
                    selectedBoy = boy;
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );

    if (selectedBoy == null) return;

    await supabase.from('orders').update({
      'delivery_boy_id': selectedBoy!['id'],
      'status': 'assigned',
    }).eq('id', order['id']);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Assigned to ${selectedBoy!['name']}",
        ),
      ),
    );

    fetchData();
  }

  Widget customerDetails(String customerId) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: getCustomer(customerId),
      builder: (context, snapshot) {
        final customer = snapshot.data;

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return Text(
            "Loading customer...",
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Customer: ${customer?['name'] ?? '-'}",
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
            Text(
              "Phone: ${customer?['phone'] ?? 'Not added'}",
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
              ),
            ),
            Text(
              "Email: ${customer?['email'] ?? '-'}",
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget orderCard(Map order) {
    final items = order['order_items'] as List? ?? [];

    final String customerId =
        order['customer_id']?.toString() ?? '';

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
                Icons.receipt_long,
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
                order['status'] ?? 'pending',
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const Divider(
            color: Colors.white24,
          ),

          if (customerId.isNotEmpty)
            customerDetails(customerId)
          else
            const Text(
              "Customer: -",
              style: TextStyle(color: Colors.white),
            ),

          const SizedBox(height: 10),

          Text(
            "Address: ${order['delivery_address'] ?? '-'}",
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
            ),
          ),

          Text(
            "Payment: ${order['payment_method'] ?? '-'}",
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            "Order Items",
            style: TextStyle(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
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
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          if (order['status'] == 'pending')
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      updateOrderStatus(
                        order['id'],
                        'accepted',
                      );
                    },
                    child: const Text("ACCEPT"),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      updateOrderStatus(
                        order['id'],
                        'rejected',
                      );
                    },
                    child: const Text("REJECT"),
                  ),
                ),
              ],
            ),

          if (order['status'] == 'accepted')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  assignDeliveryBoy(order);
                },
                icon: const Icon(
                  Icons.delivery_dining,
                ),
                label: const Text(
                  "ASSIGN DELIVERY BOY",
                ),
              ),
            ),

          if (order['status'] == 'assigned')
            const Text(
              "Delivery boy assigned",
              style: TextStyle(
                color: Colors.greenAccent,
                fontWeight: FontWeight.bold,
              ),
            ),

          if (order['status'] == 'rejected')
            const Text(
              "Order rejected",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),

          if (order['status'] == 'delivered')
            const Text(
              "Order delivered",
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
          // BACKGROUND
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
                        onPressed: () =>
                            Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                        ),
                      ),

                      const Expanded(
                        child: Center(
                          child: Text(
                            "Supplier Orders",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      IconButton(
                        onPressed: fetchData,
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
                      "No orders found",
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  )
                      : RefreshIndicator(
                    onRefresh: fetchData,
                    child: ListView.builder(
                      padding:
                      const EdgeInsets.all(20),
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