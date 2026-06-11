import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/login_page.dart';
import '../customer/customer_home.dart';
import '../delivery/delivery_dashboard.dart';
import '../supplier/supplier_dashboard.dart';

class SplashScreen extends StatefulWidget {

  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState
    extends State<SplashScreen> {

  final supabase =
      Supabase.instance.client;

  @override
  void initState() {

    super.initState();

    checkSession();
  }

  Future<void> checkSession() async {

    await Future.delayed(
      const Duration(seconds: 2),
    );

    final session =
        supabase.auth.currentSession;

    if(session == null){

      debugPrint(
        "NO SESSION FOUND",
      );

      if(!mounted) return;

      Navigator.pushReplacement(

        context,

        MaterialPageRoute(

          builder: (_) =>
          const LoginPage(),
        ),
      );

      return;
    }

    debugPrint(
      "SESSION FOUND",
    );

    try {

      final userId =
          session.user.id;

      final data =
      await supabase
          .from('users')
          .select('role')
          .eq('id', userId)
          .single();

      final role =
      data['role'];

      debugPrint(
        "USER ROLE : $role",
      );

      if(!mounted) return;

      WidgetsBinding.instance
          .addPostFrameCallback((_) {

        if(role == 'supplier'){

          Navigator.pushReplacement(

            context,

            MaterialPageRoute(

              builder: (_) =>
              const SupplierDashboard(),
            ),
          );

        } else if(role == 'delivery'){

          Navigator.pushReplacement(

            context,

            MaterialPageRoute(

              builder: (_) =>
              const DeliveryDashboard(),
            ),
          );

        } else {

          Navigator.pushReplacement(

            context,

            MaterialPageRoute(

              builder: (_) =>
              const CustomerHome(),
            ),
          );
        }
      });

    } catch (e) {

      debugPrint(
        "SESSION ERROR : $e",
      );

      if(!mounted) return;

      Navigator.pushReplacement(

        context,

        MaterialPageRoute(

          builder: (_) =>
          const LoginPage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return const Scaffold(

      body: Center(

        child: CircularProgressIndicator(),
      ),
    );
  }
}