import 'dart:ui';

import 'package:flutter/material.dart';

import 'place_order_page.dart';

class PaymentMethodPage extends StatefulWidget {
  final double totalAmount;
  final String deliveryAddress;
  final double latitude;
  final double longitude;

  const PaymentMethodPage({
    super.key,
    required this.totalAmount,
    required this.deliveryAddress,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<PaymentMethodPage> createState() =>
      _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<PaymentMethodPage> {
  String selectedPayment = "cash";

  Widget paymentOption({
    required String value,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = selectedPayment == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPayment = value;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.cyanAccent.withOpacity(0.18)
              : Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? Colors.cyanAccent
                : Colors.white.withOpacity(0.18),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor:
              isSelected ? Colors.cyanAccent : Colors.white,
              child: Icon(
                icon,
                color: Colors.black,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.70),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            Radio<String>(
              value: value,
              groupValue: selectedPayment,
              activeColor: Colors.cyanAccent,
              onChanged: (value) {
                setState(() {
                  selectedPayment = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void goToPlaceOrderPage() {
    final paymentMethod = selectedPayment == "upi"
        ? "UPI on Delivery"
        : "Cash on Delivery";

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlaceOrderPage(
          totalAmount: widget.totalAmount,
          deliveryAddress: widget.deliveryAddress,
          latitude: widget.latitude,
          longitude: widget.longitude,
          paymentMethod: paymentMethod,
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
              padding: const EdgeInsets.fromLTRB(
                20,
                16,
                20,
                30,
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
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
                            "Payment Method",
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

                  const SizedBox(height: 25),

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
                              "Choose Payment",
                              style: TextStyle(
                                color: Colors.cyanAccent,
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              "Select how you want to pay for your water order.",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.70),
                                fontSize: 14,
                              ),
                            ),

                            const SizedBox(height: 22),

                            paymentOption(
                              value: "upi",
                              icon: Icons.qr_code_2,
                              title: "UPI Payment",
                              subtitle:
                              "Pay via UPI when delivery boy arrives",
                            ),

                            paymentOption(
                              value: "cash",
                              icon: Icons.money,
                              title: "Cash on Delivery",
                              subtitle:
                              "Pay when water can is delivered",
                            ),

                            const SizedBox(height: 20),

                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.10),
                                borderRadius:
                                BorderRadius.circular(18),
                                border: Border.all(
                                  color:
                                  Colors.white.withOpacity(0.18),
                                ),
                              ),
                              child: Row(
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
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(18),
                                  ),
                                ),
                                onPressed: goToPlaceOrderPage,
                                child: const Text(
                                  "CONTINUE",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
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

                  const SizedBox(height: 18),

                  Text(
                    "Delivery Address",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    widget.deliveryAddress,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.65),
                      fontSize: 13,
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