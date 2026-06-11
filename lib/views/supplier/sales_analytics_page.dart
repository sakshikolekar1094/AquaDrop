import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SalesAnalyticsPage extends StatefulWidget {
  const SalesAnalyticsPage({super.key});

  @override
  State<SalesAnalyticsPage> createState() => _SalesAnalyticsPageState();
}

class _SalesAnalyticsPageState extends State<SalesAnalyticsPage> {
  final supabase = Supabase.instance.client;

  bool isLoading = true;

  double totalSales = 0;
  int totalOrders = 0;
  int pendingOrders = 0;
  int acceptedOrders = 0;
  int assignedOrders = 0;
  int outForDeliveryOrders = 0;
  int deliveredOrders = 0;
  int rejectedOrders = 0;

  List<Map<String, dynamic>> productSales = [];

  @override
  void initState() {
    super.initState();
    fetchAnalytics();
  }

  Future<void> fetchAnalytics() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final orders = await supabase
          .from('orders')
          .select('''
            *,
            order_items(*)
          ''')
          .eq('supplier_id', user.id)
          .order('created_at', ascending: false);

      double sales = 0;
      int pending = 0;
      int accepted = 0;
      int assigned = 0;
      int outForDelivery = 0;
      int delivered = 0;
      int rejected = 0;

      final Map<String, Map<String, dynamic>> productMap = {};

      for (var order in orders) {
        final status = order['status'];

        if (status == 'pending') pending++;
        if (status == 'accepted') accepted++;
        if (status == 'assigned') assigned++;
        if (status == 'out_for_delivery') outForDelivery++;
        if (status == 'delivered') delivered++;
        if (status == 'rejected') rejected++;

        if (status == 'delivered') {
          final amount =
              double.tryParse(order['total_amount'].toString()) ?? 0;
          sales += amount;
        }

        final items = order['order_items'] as List? ?? [];

        for (var item in items) {
          final productName = item['product_name'] ?? 'Unknown Product';
          final qty = int.tryParse(item['quantity'].toString()) ?? 0;
          final price = double.tryParse(item['price'].toString()) ?? 0;

          if (!productMap.containsKey(productName)) {
            productMap[productName] = {
              'name': productName,
              'quantity': 0,
              'sales': 0.0,
            };
          }

          productMap[productName]!['quantity'] += qty;

          if (status == 'delivered') {
            productMap[productName]!['sales'] += qty * price;
          }
        }
      }

      if (mounted) {
        setState(() {
          totalOrders = orders.length;
          totalSales = sales;
          pendingOrders = pending;
          acceptedOrders = accepted;
          assignedOrders = assigned;
          outForDeliveryOrders = outForDelivery;
          deliveredOrders = delivered;
          rejectedOrders = rejected;
          productSales = productMap.values.toList();
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("SALES ANALYTICS ERROR : $e");

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

  Widget summaryCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.18),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.cyanAccent,
            child: Icon(icon, color: Colors.black),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget smallStat(String title, int value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withOpacity(0.16),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.cyanAccent, size: 25),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.65),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget productCard(Map<String, dynamic> product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.16),
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.cyanAccent,
            child: Icon(Icons.water_drop, color: Colors.black),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'].toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Sold Qty: ${product['quantity']}",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            "₹ ${product['sales'].toStringAsFixed(2)}",
            style: const TextStyle(
              color: Colors.cyanAccent,
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
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                        ),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            "Sales Analytics",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: fetchAnalytics,
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
                      : RefreshIndicator(
                    onRefresh: fetchAnalytics,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          summaryCard(
                            icon: Icons.currency_rupee,
                            title: "Total Sales",
                            value:
                            "₹ ${totalSales.toStringAsFixed(2)}",
                          ),

                          const SizedBox(height: 14),

                          summaryCard(
                            icon: Icons.shopping_bag,
                            title: "Total Orders",
                            value: totalOrders.toString(),
                          ),

                          const SizedBox(height: 20),

                          const Text(
                            "Order Status",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              smallStat(
                                "Pending",
                                pendingOrders,
                                Icons.pending_actions,
                              ),
                              const SizedBox(width: 10),
                              smallStat(
                                "Accepted",
                                acceptedOrders,
                                Icons.check_circle,
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          Row(
                            children: [
                              smallStat(
                                "Assigned",
                                assignedOrders,
                                Icons.delivery_dining,
                              ),
                              const SizedBox(width: 10),
                              smallStat(
                                "Out",
                                outForDeliveryOrders,
                                Icons.local_shipping,
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          Row(
                            children: [
                              smallStat(
                                "Delivered",
                                deliveredOrders,
                                Icons.done_all,
                              ),
                              const SizedBox(width: 10),
                              smallStat(
                                "Rejected",
                                rejectedOrders,
                                Icons.cancel,
                              ),
                            ],
                          ),

                          const SizedBox(height: 22),

                          const Text(
                            "Product Sales",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 12),

                          productSales.isEmpty
                              ? Text(
                            "No product sales yet",
                            style: TextStyle(
                              color:
                              Colors.white.withOpacity(0.70),
                            ),
                          )
                              : Column(
                            children: productSales
                                .map((product) =>
                                productCard(product))
                                .toList(),
                          ),
                        ],
                      ),
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