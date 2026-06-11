import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/cart_service.dart';

class PlaceOrderPage extends StatefulWidget {
  final double totalAmount;
  final String deliveryAddress;
  final double latitude;
  final double longitude;
  final String paymentMethod;

  const PlaceOrderPage({
    super.key,
    required this.totalAmount,
    required this.deliveryAddress,
    required this.latitude,
    required this.longitude,
    required this.paymentMethod,
  });

  @override
  State<PlaceOrderPage> createState() => _PlaceOrderPageState();
}

class _PlaceOrderPageState extends State<PlaceOrderPage> {
  final supabase = Supabase.instance.client;
  final cartService = CartService();

  bool isLoading = true;
  bool isPlacing = false;

  List cartItems = [];
  Map<String, dynamic>? customer;

  @override
  void initState() {
    super.initState();
    loadDetails();
  }

  String getCustomerPhone() {
    final phone = customer?['phone'];
    if (phone == null || phone.toString().trim().isEmpty) {
      return "Not added";
    }
    return phone.toString();
  }

  Future<void> loadDetails() async {
    final user = supabase.auth.currentUser;

    final cartData = await cartService.getCartItems();

    final profile = await supabase
        .from('profiles')
        .select()
        .eq('id', user!.id)
        .maybeSingle();

    setState(() {
      cartItems = cartData;
      customer = profile;
      isLoading = false;
    });
  }

  Future<void> placeOrder() async {
    try {
      if (cartItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cart is empty")),
        );
        return;
      }

      setState(() {
        isPlacing = true;
      });

      final user = supabase.auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      /// 🔥 IMPORTANT: GET SUPPLIER ID FROM PRODUCT
      final firstProduct = cartItems.first['products'];
      final supplierId = firstProduct['supplier_id'];

      if (supplierId == null) {
        throw Exception("Supplier not found");
      }

      /// 🔥 CREATE ORDER
      final order = await supabase
          .from('orders')
          .insert({
        'customer_id': user.id,
        'supplier_id': supplierId,
        'delivery_address': widget.deliveryAddress,
        'latitude': widget.latitude,
        'longitude': widget.longitude,
        'payment_method': widget.paymentMethod,
        'total_amount': widget.totalAmount,
        'status': 'pending',
      })
          .select()
          .single();

      /// 🔥 INSERT ORDER ITEMS
      for (var item in cartItems) {
        final product = item['products'];

        await supabase.from('order_items').insert({
          'order_id': order['id'],
          'product_id': product['id'],
          'product_name': product['product_name'],
          'product_image': product['image_url'],
          'can_size': product['can_size'],
          'quantity': item['quantity'],
          'price': product['price'],
        });
      }

      /// 🔥 CLEAR CART
      for (var item in cartItems) {
        await cartService.removeFromCart(item['id']);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Order placed successfully")),
      );

      Navigator.popUntil(context, (route) => route.isFirst);

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );

    } finally {

      if (mounted) {
        setState(() {
          isPlacing = false;
        });
      }
    }
  }

  Widget detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Text(
            "$title: ",
            style: const TextStyle(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.white.withOpacity(0.82)),
            ),
          ),
        ],
      ),
    );
  }

  Widget productCard(Map item) {
    final product = item['products'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: product['image_url'] != null
                ? Image.network(
              product['image_url'],
              height: 70,
              width: 70,
              fit: BoxFit.cover,
            )
                : const Icon(
              Icons.water_drop,
              color: Colors.cyanAccent,
              size: 55,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['product_name'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Size: ${product['can_size'] ?? '-'}",
                  style: TextStyle(color: Colors.white.withOpacity(0.65)),
                ),
                Text(
                  "Qty: ${item['quantity']}",
                  style: TextStyle(color: Colors.white.withOpacity(0.65)),
                ),
              ],
            ),
          ),
          Text(
            "₹ ${product['price']}",
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
            child: isLoading
                ? const Center(
              child: CircularProgressIndicator(
                color: Colors.cyanAccent,
              ),
            )
                : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [

                  const SizedBox(height: 10),

                  const Text(
                    "Place Order",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// CUSTOMER DETAILS
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Customer Details",
                            style: TextStyle(
                                color: Colors.cyanAccent,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        detailRow("Name", customer?['name'] ?? '-'),
                        detailRow("Phone", getCustomerPhone()),
                        detailRow("Address", widget.deliveryAddress),
                        detailRow("Payment", widget.paymentMethod),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// PRODUCTS
                  ...cartItems.map((item) => productCard(item)),

                  const SizedBox(height: 20),

                  /// TOTAL
                  Text(
                    "Total: ₹ ${widget.totalAmount}",
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// BUTTON
                  ElevatedButton(
                    onPressed: isPlacing ? null : placeOrder,
                    child: isPlacing
                        ? const CircularProgressIndicator()
                        : const Text("PLACE ORDER"),
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