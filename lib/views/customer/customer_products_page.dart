import 'package:flutter/material.dart';

import '../../services/product_service.dart';

class CustomerProductsPage
    extends StatefulWidget {

  const CustomerProductsPage({super.key});

  @override
  State<CustomerProductsPage>
  createState() =>
      _CustomerProductsPageState();
}

class _CustomerProductsPageState
    extends State<CustomerProductsPage> {

  final productService =
  ProductService();

  List products = [];

  bool isLoading = true;

  @override
  void initState() {

    super.initState();

    loadProducts();
  }

  Future<void> loadProducts() async {

    final data =
    await productService.getProducts();

    setState(() {

      products = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: const Text(
          "Water Products",
        ),
      ),

      body: isLoading

          ? const Center(
        child:
        CircularProgressIndicator(),
      )

          : GridView.builder(

        padding:
        const EdgeInsets.all(10),

        gridDelegate:
        const SliverGridDelegateWithFixedCrossAxisCount(

          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.7,
        ),

        itemCount: products.length,

        itemBuilder: (context, index) {

          final product =
          products[index];

          return Card(

            child: Padding(

              padding:
              const EdgeInsets.all(10),

              child: Column(

                children: [

                  Expanded(

                    child: Image.network(

                      product['image_url'],

                      fit: BoxFit.cover,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(

                    product['product_name'],

                    style: const TextStyle(

                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  Text(
                    "₹ ${product['price']}",
                  ),

                  Text(
                    product['can_size'],
                  ),

                  Text(
                    "Stock: ${product['quantity']}",
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}