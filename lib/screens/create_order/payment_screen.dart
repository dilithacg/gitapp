import 'package:flutter/material.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';

import '../../const/colors.dart';

class PaymentScreen extends StatefulWidget {
  final double totalCost;

  const PaymentScreen({Key? key, required this.totalCost}) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController _cardController = TextEditingController(
    text: '4242424242424242',
  );
  final TextEditingController _expiryController = TextEditingController(
    text: '12/30',
  );
  final TextEditingController _cvcController = TextEditingController(
    text: '123',
  );

  bool _isLoading = false;

  Future<void> _makePayment() async {
    setState(() => _isLoading = true);
    await Future.delayed(Duration(seconds: 2));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Payment Successful"),
        content: Text("Your payment has been processed successfully!"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment', style: const TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: AppColors.primaryColor,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Wrapping the CreditCardWidget in a Container to adjust width
            Container(
              width: 500, // Set the desired width here
              child: CreditCardWidget(
                cardNumber: _cardController.text,
                expiryDate: _expiryController.text,
                cardHolderName: "Your Name",
                cvvCode: _cvcController.text,
                showBackView: false,
                onCreditCardWidgetChange: (CreditCardBrand brand) {},
              ),
            ),
            SizedBox(height: 15),
            // Card Number Input Field
            TextField(
              controller: _cardController,
              decoration: InputDecoration(
                labelText: 'Card Number',
                hintText: '4242 4242 4242 4242',
                prefixIcon: Icon(Icons.credit_card),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 15),
            // Expiry and CVC Input Fields
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _expiryController,
                    decoration: InputDecoration(
                      labelText: 'Expiry (MM/YY)',
                      hintText: '12/30',
                      prefixIcon: Icon(Icons.date_range),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _cvcController,
                    decoration: InputDecoration(
                      labelText: 'CVC',
                      hintText: '123',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            // Display Total Cost
            Center(
              child: Text(
                'Total: Rs ${widget.totalCost.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.thirdColor,
                ),
              ),
            ),
            SizedBox(height: 30),
            // Payment Button or Loading Indicator
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _makePayment,
                child: Text(
                  'Pay Now',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  backgroundColor: AppColors.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
