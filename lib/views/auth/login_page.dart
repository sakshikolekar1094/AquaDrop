import 'dart:ui';

import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

import '../customer/customer_home.dart';
import '../delivery/delivery_dashboard.dart';
import '../supplier/supplier_dashboard.dart';

import 'register_page.dart';

class LoginPage extends StatefulWidget {

  const LoginPage({super.key});

  @override
  State<LoginPage> createState() =>
      _LoginPageState();
}

class _LoginPageState
    extends State<LoginPage>
    with SingleTickerProviderStateMixin {

  final emailController =
  TextEditingController();

  final passwordController =
  TextEditingController();

  final authService =
  AuthService();

  bool isLoading = false;

  bool obscurePassword = true;

  late AnimationController
  animationController;

  late Animation<double>
  fadeAnimation;

  late Animation<Offset>
  slideAnimation;

  @override
  void initState() {

    super.initState();

    animationController =
        AnimationController(

          vsync: this,

          duration: const Duration(
            seconds: 2,
          ),
        );

    fadeAnimation =
        Tween<double>(

          begin: 0.0,

          end: 1.0,
        ).animate(

          CurvedAnimation(

            parent:
            animationController,

            curve:
            Curves.easeInOut,
          ),
        );

    slideAnimation =
        Tween<Offset>(

          begin:
          const Offset(0, 0.3),

          end:
          Offset.zero,
        ).animate(

          CurvedAnimation(

            parent:
            animationController,

            curve:
            Curves.easeOutBack,
          ),
        );

    animationController.forward();
  }

  @override
  void dispose() {

    emailController.dispose();

    passwordController.dispose();

    animationController.dispose();

    super.dispose();
  }

  Future<void> login() async {

    if(emailController.text
        .trim()
        .isEmpty ||

        passwordController.text
            .trim()
            .isEmpty){

      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(

          content: Text(
            "Please fill all fields",
          ),
        ),
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    final result =
    await authService.loginUser(

      email:
      emailController.text.trim(),

      password:
      passwordController.text.trim(),
    );

    if(result == null){

      final role =
      await authService.getUserRole();

      if(!mounted) return;

      setState(() {
        isLoading = false;
      });

      Widget page;

      if(role == 'supplier'){

        page =
        const SupplierDashboard();

      } else if(role == 'delivery'){

        page =
        const DeliveryDashboard();

      } else {

        page =
        const CustomerHome();
      }

      Navigator.pushReplacement(

        context,

        MaterialPageRoute(

          builder: (_) => page,
        ),
      );

    } else {

      if(!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(
          content: Text(result),
        ),
      );
    }
  }

  Widget buildTextField({

    required TextEditingController
    controller,

    required String hint,

    required IconData icon,

    bool isPassword = false,
  }) {

    return Container(

      margin:
      const EdgeInsets.only(bottom: 20),

      decoration: BoxDecoration(

        borderRadius:
        BorderRadius.circular(18),

        color:
        Colors.white.withOpacity(0.08),

        border: Border.all(

          color:
          Colors.white.withOpacity(0.15),
        ),
      ),

      child: TextField(

        controller: controller,

        obscureText:
        isPassword
            ? obscurePassword
            : false,

        style: const TextStyle(
          color: Colors.white,
        ),

        decoration: InputDecoration(

          border:
          InputBorder.none,

          prefixIcon: Icon(
            icon,
            color: Colors.white,
          ),

          hintText: hint,

          hintStyle: TextStyle(

            color:
            Colors.white.withOpacity(0.6),
          ),

          suffixIcon:
          isPassword

              ? IconButton(

            onPressed: () {

              setState(() {

                obscurePassword =
                !obscurePassword;
              });
            },

            icon: Icon(

              obscurePassword

                  ? Icons.visibility_off

                  : Icons.visibility,

              color: Colors.white,
            ),
          )

              : null,

          contentPadding:
          const EdgeInsets.symmetric(
            vertical: 20,
          ),
        ),
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

                begin:
                Alignment.topCenter,

                end:
                Alignment.bottomCenter,

                colors: [

                  Color(0xff021B33),

                  Color(0xff004E92),

                  Color(0xff000428),
                ],
              ),
            ),
          ),

          /// WATER WAVES
          Positioned(

            bottom: -40,

            left: -20,

            right: -20,

            child: Container(

              height: 220,

              decoration: BoxDecoration(

                borderRadius:
                BorderRadius.circular(200),

                gradient:
                LinearGradient(

                  colors: [

                    Colors.blue
                        .withOpacity(0.25),

                    Colors.cyan
                        .withOpacity(0.12),
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

          Positioned(

            top: -80,

            right: -60,

            child: Container(

              height: 220,
              width: 220,

              decoration: BoxDecoration(

                shape:
                BoxShape.circle,

                color:
                Colors.lightBlueAccent
                    .withOpacity(0.18),
              ),

              child: BackdropFilter(

                filter: ImageFilter.blur(

                  sigmaX: 60,
                  sigmaY: 60,
                ),

                child: const SizedBox(),
              ),
            ),
          ),

          /// LOGIN CONTENT
          SafeArea(

            child: Center(

              child: SingleChildScrollView(

                padding:
                const EdgeInsets.all(24),

                child: FadeTransition(

                  opacity:
                  fadeAnimation,

                  child: SlideTransition(

                    position:
                    slideAnimation,

                    child: Column(

                      children: [

                        /// WATER DROP LOGO
                        Container(

                          height: 130,
                          width: 130,

                          decoration: BoxDecoration(

                            shape:
                            BoxShape.circle,

                            gradient:
                            LinearGradient(

                              colors: [

                                Colors.cyan
                                    .withOpacity(0.9),

                                Colors.blue,
                              ],
                            ),

                            boxShadow: [

                              BoxShadow(

                                color:
                                Colors.cyan
                                    .withOpacity(0.5),

                                blurRadius: 30,

                                spreadRadius: 5,
                              ),
                            ],
                          ),

                          child: const Icon(

                            Icons.water_drop,

                            color:
                            Colors.white,

                            size: 70,
                          ),
                        ),

                        const SizedBox(
                          height: 30,
                        ),

                        const Text(

                          "AquaDrop",

                          style: TextStyle(

                            color:
                            Colors.white,

                            fontSize: 34,

                            fontWeight:
                            FontWeight.bold,

                            letterSpacing: 1,
                          ),
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        Text(

                          "Fast & Safe Water Delivery",

                          style: TextStyle(

                            color:
                            Colors.white
                                .withOpacity(0.7),

                            fontSize: 15,
                          ),
                        ),

                        const SizedBox(
                          height: 40,
                        ),

                        /// GLASS CARD
                        ClipRRect(

                          borderRadius:
                          BorderRadius.circular(
                            28,
                          ),

                          child:
                          BackdropFilter(

                            filter:
                            ImageFilter.blur(

                              sigmaX: 18,
                              sigmaY: 18,
                            ),

                            child:
                            Container(

                              padding:
                              const EdgeInsets.all(
                                25,
                              ),

                              decoration:
                              BoxDecoration(

                                color: Colors
                                    .white
                                    .withOpacity(
                                  0.08,
                                ),

                                borderRadius:
                                BorderRadius.circular(
                                  28,
                                ),

                                border: Border.all(

                                  color: Colors
                                      .white
                                      .withOpacity(
                                    0.15,
                                  ),
                                ),
                              ),

                              child:
                              Column(

                                children: [

                                  buildTextField(

                                    controller:
                                    emailController,

                                    hint:
                                    "Email Address",

                                    icon:
                                    Icons.email_outlined,
                                  ),

                                  buildTextField(

                                    controller:
                                    passwordController,

                                    hint:
                                    "Password",

                                    icon:
                                    Icons.lock_outline,

                                    isPassword:
                                    true,
                                  ),

                                  const SizedBox(
                                    height: 10,
                                  ),

                                  SizedBox(

                                    width:
                                    double.infinity,

                                    height:
                                    58,

                                    child:
                                    ElevatedButton(

                                      onPressed:
                                      isLoading
                                          ? null
                                          : login,

                                      style:
                                      ElevatedButton.styleFrom(

                                        backgroundColor:
                                        Colors.cyanAccent,

                                        foregroundColor:
                                        Colors.black,

                                        elevation:
                                        12,

                                        shape:
                                        RoundedRectangleBorder(

                                          borderRadius:
                                          BorderRadius.circular(
                                            18,
                                          ),
                                        ),
                                      ),

                                      child:
                                      isLoading

                                          ? const SizedBox(

                                        height:
                                        24,

                                        width:
                                        24,

                                        child:
                                        CircularProgressIndicator(
                                          strokeWidth:
                                          2,
                                          color:
                                          Colors.black,
                                        ),
                                      )

                                          : const Text(

                                        "LOGIN",

                                        style:
                                        TextStyle(

                                          fontSize:
                                          16,

                                          fontWeight:
                                          FontWeight.bold,

                                          letterSpacing:
                                          1,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 20,
                                  ),

                                  Row(

                                    mainAxisAlignment:
                                    MainAxisAlignment.center,

                                    children: [

                                      Text(

                                        "New here?",

                                        style: TextStyle(

                                          color:
                                          Colors.white
                                              .withOpacity(
                                            0.7,
                                          ),
                                        ),
                                      ),

                                      TextButton(

                                        onPressed:
                                            () {

                                          Navigator.push(

                                            context,

                                            MaterialPageRoute(

                                              builder:
                                                  (_) =>

                                              const RegisterPage(),
                                            ),
                                          );
                                        },

                                        child:
                                        const Text(

                                          "Create Account",

                                          style:
                                          TextStyle(

                                            color:
                                            Colors.cyanAccent,

                                            fontWeight:
                                            FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}