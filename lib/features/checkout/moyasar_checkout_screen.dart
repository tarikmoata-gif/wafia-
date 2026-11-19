import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:moyasar/moyasar.dart";
import "../../core/network/odoo_api_client.dart";
import "../tracking/tracking_screen.dart";

class MoyasarCheckoutScreen extends ConsumerStatefulWidget {
  final int orderId;
  final String orderNumber;
  final double amountSar;

  const MoyasarCheckoutScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
    required this.amountSar,
  });

  @override
  ConsumerState<MoyasarCheckoutScreen> createState() => _MoyasarCheckoutScreenState();
}

class _MoyasarCheckoutScreenState extends ConsumerState<MoyasarCheckoutScreen> {
  static const String _publishableKey = "pk_test_YOUR_MOYASAR_PUBLISHABLE_KEY";
  static const String _applePayMerchantId = "merchant.sa.meyah.app";

  bool _verifyingWithOdoo = false;

  PaymentConfig get _paymentConfig => PaymentConfig(
        publishableApiKey: _publishableKey,
        amount: (widget.amountSar * 100).round(),
        description: "طلب صهريج مياه ${widget.orderNumber}",
        metadata: {
          "odoo_order_id": "${widget.orderId}",
          "order_number": widget.orderNumber,
        },
        applePay: ApplePayConfig(
          merchantId: _applePayMerchantId,
          label: "مياه Meyah",
          manual: false,
          saveCard: false,
        ),
      );

  Future<void> _handlePaymentResult(dynamic result) async {
    if (result is PaymentResponse) {
      if (result.status == PaymentStatus.paid) {
        setState(() => _verifyingWithOdoo = true);
        try {
          await ref.read(odooApiProvider).confirmOrderPayment(
                orderId: widget.orderId,
                moyasarPaymentId: result.id,
              );
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => TrackingScreen(
                orderId: widget.orderId,
                orderNumber: widget.orderNumber,
              ),
            ),
          );
        } catch (e) {
          _showSnack("تم الدفع ولكن تعذر تحديث حالة الطلب: $e");
        } finally {
          if (mounted) setState(() => _verifyingWithOdoo = false);
        }
      } else if (result.status == PaymentStatus.failed) {
        _showSnack("فشلت عملية الدفع، يرجى المحاولة مرة أخرى");
      }
      return;
    }

    if (result is PaymentCanceledError) {
      _showSnack("تم إلغاء عملية الدفع");
    } else if (result is ValidationError) {
      _showSnack("يرجى التحقق من بيانات البطاقة");
    } else if (result is NetworkError || result is TimeoutError) {
      _showSnack("مشكلة في الاتصال، يرجى التحقق من حالة الطلب قبل إعادة المحاولة");
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("إتمام الدفع"), centerTitle: true),
      body: _verifyingWithOdoo
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("رقم الطلب: ${widget.orderNumber}"),
                          Text(
                            "${widget.amountSar.toStringAsFixed(2)} ر.س",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A438A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ApplePay(
                    config: _paymentConfig,
                    onPaymentResult: _handlePaymentResult,
                  ),
                  const SizedBox(height: 16),
                  const Center(child: Text("أو الدفع عبر مدى / البطاقة الائتمانية")),
                  const SizedBox(height: 16),
                  CreditCard(
                    config: _paymentConfig,
                    onPaymentResult: _handlePaymentResult,
                  ),
                ],
              ),
            ),
    );
  }
}
