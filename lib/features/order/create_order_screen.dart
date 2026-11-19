import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../core/network/odoo_api_client.dart";
import "../checkout/moyasar_checkout_screen.dart";

class CreateOrderScreen extends ConsumerStatefulWidget {
  final bool isPotable;
  const CreateOrderScreen({super.key, required this.isPotable});

  @override
  ConsumerState<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends ConsumerState<CreateOrderScreen> {
  bool _isOrderNow = true;
  int _selectedCapacity = 18;
  bool _isSubmitting = false;

  final Map<int, int> _capacityToOdooVariantId = {
    5: 101,
    12: 102,
    18: 103,
    19: 104,
    20: 105,
  };

  Future<void> _submitOrder() async {
    setState(() => _isSubmitting = true);
    try {
      final api = ref.read(odooApiProvider);
      final response = await api.postOrder(
        productVariantId: _capacityToOdooVariantId[_selectedCapacity]!,
        lat: 24.7654,
        lng: 46.6123,
        district: "الرياض، حطين",
        scheduledDatetime: _isOrderNow ? null : DateTime.now().add(const Duration(hours: 3)),
      );

      if (!mounted) return;
      final data = response.data as Map<String, dynamic>;
      final orderId = data["order_id"] as int;
      final orderNumber = data["order_number"] as String;
      final totalAmount = (data["total_amount"] as num).toDouble();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MoyasarCheckoutScreen(
            orderId: orderId,
            orderNumber: orderNumber,
            amountSar: totalAmount,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("فشل إنشاء الطلب: \$e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final capacities = [5, 12, 18, 19, 20];

    return Scaffold(
      appBar: AppBar(
        title: const Text("إنشاء طلب", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _ToggleTab(
                      label: "اطلب الآن",
                      isSelected: _isOrderNow,
                      onTap: () => setState(() => _isOrderNow = true),
                    ),
                  ),
                  Expanded(
                    child: _ToggleTab(
                      label: "جدولة الطلب",
                      isSelected: !_isOrderNow,
                      onTap: () => setState(() => _isOrderNow = false),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Icon(Icons.local_shipping_rounded,
                  size: 120, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              widget.isPotable ? "مياه صالحة للشرب" : "مياه غير صالحة للشرب",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              widget.isPotable
                  ? "توفير مياه شرب نظيفة للاستخدام اليومي في المنازل والمرافق."
                  : "مياه مخصصة لأعمال البناء والري والاستخدامات العامة.",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 24),
            const Text("أحجام الصهاريج",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 84,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: capacities.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final cap = capacities[index];
                  final selected = cap == _selectedCapacity;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCapacity = cap),
                    child: Container(
                      width: 72,
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFF1A438A) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected ? const Color(0xFF1A438A) : Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "\$cap م³",
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "صهريج",
                            style: TextStyle(
                              color: selected ? Colors.white70 : Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A438A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isSubmitting ? null : _submitOrder,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("متابعة إلى الدفع",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleTab({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? const Color(0xFF1A438A) : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
