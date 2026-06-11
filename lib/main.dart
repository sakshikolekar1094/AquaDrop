import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/supabase_constants.dart';
import 'views/auth/login_page.dart';
import 'views/customer/customer_home.dart';
import 'views/delivery/delivery_dashboard.dart';
import 'views/supplier/supplier_dashboard.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  MapboxOptions.setAccessToken("");
  await Supabase.initialize(

    url: SupabaseConstants.supabaseUrl,

    anonKey:
    SupabaseConstants.supabaseAnonKey,
  );

  runApp(
    const MyApp(),
  );
}

class MyApp extends StatelessWidget {

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(

      debugShowCheckedModeBanner: false,

      title: 'Water App',

      theme: ThemeData(

        primarySwatch: Colors.blue,
      ),

      home: const SessionCheck(),
    );
  }
}

class SessionCheck extends StatefulWidget {

  const SessionCheck({super.key});

  @override
  State<SessionCheck> createState() =>
      _SessionCheckState();
}

class _SessionCheckState
    extends State<SessionCheck> {

  final supabase =
      Supabase.instance.client;

  @override
  void initState() {

    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback((_) {

      checkSession();
    });
  }

  Future<void> checkSession() async {

    try {

      final session =
          supabase.auth.currentSession;

      await Future.delayed(
        const Duration(seconds: 1),
      );

      // NO LOGIN
      if(session == null){

        print(
          "NO SESSION FOUND",
        );

        if(mounted){

          Navigator.pushReplacement(

            context,

            MaterialPageRoute(

              builder: (_) =>
              const LoginPage(),
            ),
          );
        }

        return;
      }

      print(
        "SESSION FOUND",
      );

      final user =
          supabase.auth.currentUser;

      if(user == null){

        if(mounted){

          Navigator.pushReplacement(

            context,

            MaterialPageRoute(

              builder: (_) =>
              const LoginPage(),
            ),
          );
        }

        return;
      }

      // CHECK PROFILE TABLE
      final profile =
      await supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      if(profile != null){

        final role =
        profile['role'];

        print(
          "ROLE : $role",
        );

        // SUPPLIER
        if(role == 'supplier'){

          if(mounted){

            Navigator.pushReplacement(

              context,

              MaterialPageRoute(

                builder: (_) =>
                const SupplierDashboard(),
              ),
            );
          }
        }

        // CUSTOMER
        else {

          if(mounted){

            Navigator.pushReplacement(

              context,

              MaterialPageRoute(

                builder: (_) =>
                const CustomerHome(),
              ),
            );
          }
        }

        return;
      }

      // CHECK DELIVERY TABLE
      final delivery =
      await supabase
          .from('delivery_boys')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      if(delivery != null){

        print(
          "ROLE : delivery",
        );

        if(mounted){

          Navigator.pushReplacement(

            context,

            MaterialPageRoute(

              builder: (_) =>
              const DeliveryDashboard(),
            ),
          );
        }

        return;
      }

      // DEFAULT LOGIN PAGE
      if(mounted){

        Navigator.pushReplacement(

          context,

          MaterialPageRoute(

            builder: (_) =>
            const LoginPage(),
          ),
        );
      }

    } catch (e) {

      print(
        "SESSION ERROR : $e",
      );

      if(mounted){

        Navigator.pushReplacement(

          context,

          MaterialPageRoute(

            builder: (_) =>
            const LoginPage(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return const Scaffold(

      body: Center(

        child:
        CircularProgressIndicator(),
      ),
    );
  }
}