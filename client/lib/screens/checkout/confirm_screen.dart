import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../auth/login_screen.dart';

// Define the server IP address
const String serverBaseUrl = 'http://192.168.228.1:5000';

class ConfirmScreen extends StatefulWidget {
  final String fullName;
  final String shippingAddress;
  final String city;
  final String postalCode;
  final String phoneNumber;

  const ConfirmScreen({
    super.key,
    required this.fullName,
    required this.shippingAddress,
    required this.city,
    required this.postalCode,
    required this.phoneNumber,
  });

  @override
  _ConfirmScreenState createState() => _ConfirmScreenState();
}

class _ConfirmScreenState extends State<ConfirmScreen> {
  String? _paymentStatus;
  String? _txRef;
  late AppLinks _appLinks;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _initDeepLinkListener();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinkListener() async {
    print('Initializing deep link listener...');
    _sub = _appLinks.uriLinkStream.listen(
      (Uri? uri) {
        print('Deep link received: $uri');
        if (uri != null &&
            uri.scheme == 'myapp' &&
            uri.host == 'payment-callback') {
          _verifyPayment(uri.queryParameters);
        } else {
          print('Invalid deep link: $uri');
        }
      },
      onError: (err) {
        print('Deep link error: $err');
        setState(() {
          _paymentStatus = 'Error handling deep link: $err';
        });
      },
    );

    final initialUri = await _appLinks.getInitialLink();
    print('Initial deep link: $initialUri');
    if (initialUri != null &&
        initialUri.scheme == 'myapp' &&
        initialUri.host == 'payment-callback') {
      _verifyPayment(initialUri.queryParameters);
    } else {
      print('No initial deep link or invalid: $initialUri');
    }
  }

  Future<void> _verifyPayment(Map<String, String> params) async {
    if (params['status'] != 'success' || params['tx_ref'] == null) {
      setState(() {
        _paymentStatus = 'Payment failed or was cancelled.';
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
          '$serverBaseUrl/api/payments/verify?tx_ref=${params['tx_ref']}&status=${params['status']}',
        ),
      );

      if (response.statusCode != 200) {
        setState(() {
          _paymentStatus =
              'Payment verification failed: Server returned ${response.statusCode}';
        });
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] == 'success') {
        await _finalizeOrder();
        setState(() {
          _paymentStatus = 'Payment successful! Order placed.';
        });
      } else {
        setState(() {
          _paymentStatus =
              'Payment verification failed: ${data['message'] ?? 'Unknown error'}';
        });
      }
    } catch (e) {
      setState(() {
        _paymentStatus = 'Error verifying payment: $e';
      });
      print('Verification error: $e');
    }
  }

  Future<void> _finalizeOrder() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.user == null) {
      setState(() {
        _paymentStatus = 'Error: User not logged in. Please log in again.';
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      return;
    }

    final order = {
      'userId': authProvider.user!.id,
      'items':
          cartProvider.cartItems
              .map(
                (item) => {
                  'id': item.productId,
                  'name': item.name,
                  'price': item.price,
                  'quantity': item.quantity,
                  'image': item.image,
                },
              )
              .toList(),
      'totalPrice': cartProvider.totalPrice,
      'shippingName': widget.fullName,
      'shippingAddress': widget.shippingAddress,
      'city': widget.city,
      'postalCode': widget.postalCode,
      'shippingPhone': widget.phoneNumber,
    };

    try {
      final response = await http.post(
        Uri.parse('$serverBaseUrl/api/orders'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(order),
      );

      if (response.statusCode == 201) {
        await cartProvider.clearCart();
        print('Order saved and cart cleared');
      } else {
        setState(() {
          _paymentStatus =
              'Error: Failed to save order (Status: ${response.statusCode}, Message: ${response.body})';
        });
        print('Order save failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      setState(() {
        _paymentStatus = 'Error: Exception while saving order - $e';
      });
      print('Order save exception: $e');
    }
  }

  Future<void> _initiatePayment() async {
    print('Initiating payment...');
    setState(() {
      _paymentStatus = 'Processing payment...';
    });

    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.user == null) {
        setState(() {
          _paymentStatus = 'Error: User not logged in. Please log in again.';
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
        return;
      }

      final phoneNumber =
          widget.phoneNumber.startsWith('+')
              ? widget.phoneNumber
              : '+251${widget.phoneNumber}';
      print('Formatted phone number: $phoneNumber');

      final totalPrice = cartProvider.totalPrice;
      print('Cart items: ${cartProvider.cartItems}');
      print('Calculated totalPrice: $totalPrice');
      if (totalPrice <= 0) {
        setState(() {
          _paymentStatus = 'Error: Invalid total price: $totalPrice';
        });
        return;
      }

      final nameParts = widget.fullName.trim().split(RegExp(r'\s+'));
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName = nameParts.length > 1 ? nameParts.last : '';
      print('First name: $firstName, Last name: $lastName');

      final payload = {
        'userId': authProvider.user!.id,
        'amount': totalPrice,
        'currency': 'ETB',
        'email': authProvider.user!.email ?? 'test@example.com',
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
      };
      print('Sending to backend: $payload');

      final response = await http.post(
        Uri.parse('$serverBaseUrl/api/payments/initialize'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Parsed response data: $data');

        if (data['checkoutUrl'] != null) {
          _txRef = data['txRef'];
          final url = Uri.parse(data['checkoutUrl']);
          print('Attempting to launch URL: $url');
          try {
            if (await canLaunchUrl(url)) {
              bool launched = await launchUrl(
                url,
                mode: LaunchMode.externalApplication,
              );
              if (!launched) {
                launched = await launchUrl(
                  url,
                  mode: LaunchMode.platformDefault,
                );
              }
              if (launched) {
                print('URL launched successfully');
              } else {
                setState(() {
                  _paymentStatus = 'Error: Could not launch URL: $url';
                });
                print('Could not launch URL: $url');
              }
            } else {
              // Fallback to in-app web view
              try {
                await launchUrl(url, mode: LaunchMode.inAppWebView);
                print('URL launched in in-app web view');
              } catch (e) {
                setState(() {
                  _paymentStatus =
                      'Error: Failed to launch URL in web view: $e';
                });
                print('In-app web view launch exception: $e');
              }
            }
          } catch (e) {
            setState(() {
              _paymentStatus = 'Error: Failed to launch URL: $e';
            });
            print('Launch URL exception: $e');
          }
        } else {
          setState(() {
            _paymentStatus = 'Error: No checkout URL in response.';
          });
          print('No checkoutUrl in response: $data');
        }
      } else {
        setState(() {
          _paymentStatus =
              'Error: Failed to initiate payment (Status: ${response.statusCode}, Message: ${response.body})';
        });
        print('Server error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      setState(() {
        _paymentStatus = 'Error: Exception during payment initiation - $e';
      });
      print('Exception caught: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Confirm Order',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Order Summary',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cartProvider.cartItems.length,
                itemBuilder: (context, index) {
                  final item = cartProvider.cartItems[index];
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.image,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
                            ),
                      ),
                    ),
                    title: Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text('Qty: ${item.quantity}'),
                    trailing: Text(
                      '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '\$${cartProvider.totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Shipping Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Name: ${widget.fullName}'),
                      Text('Address: ${widget.shippingAddress}'),
                      Text('City: ${widget.city}'),
                      Text('Postal Code: ${widget.postalCode}'),
                      Text('Phone: ${widget.phoneNumber}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_paymentStatus != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _paymentStatus!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color:
                          _paymentStatus!.startsWith('Error') ||
                                  _paymentStatus!.contains('failed')
                              ? Colors.red
                              : _paymentStatus!.contains('successful')
                              ? Colors.green
                              : Colors.black,
                    ),
                  ),
                ),
              ElevatedButton(
                onPressed: () {
                  print('Pay with Chapa button pressed');
                  _initiatePayment();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  'Pay with Chapa',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
