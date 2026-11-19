import "dart:async";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:google_maps_flutter/google_maps_flutter.dart";
import "../../core/network/odoo_api_client.dart";

class TrackingScreen extends ConsumerStatefulWidget {
  final int orderId;
  final String orderNumber;

  const TrackingScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
  });

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  Timer? _pollingTimer;
  String _deliveryStage = "confirmed";
  LatLng _driverPosition = const LatLng(24.7742, 46.6385);
  final LatLng _customerPosition = const LatLng(24.7654, 46.6123);

  @override
  void initState() {
    super.initState();
    _fetchTracking();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchTracking());
  }

  Future<void> _fetchTracking() async {
    try {
      final data = await ref.read(odooApiProvider).getOrderTracking(widget.orderId);
      if (!mounted) return;
      setState(() {
        _deliveryStage = data["delivery_stage"] ?? "confirmed";
        final driver = data["driver"];
        if (driver != null && driver["lat"] != null && driver["lng"] != null) {
          _driverPosition = LatLng(
            (driver["lat"] as num).toDouble(),
            (driver["lng"] as num).toDouble(),
          );
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _customerPosition, zoom: 13.5),
            markers: {
              Marker(
                markerId: const MarkerId("destination"),
                position: _customerPosition,
                infoWindow: const InfoWindow(title: "موقع التسليم"),
              ),
              Marker(
                markerId: const MarkerId("tanker"),
                position: _driverPosition,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                infoWindow: const InfoWindow(title: "صهريج المياه"),
              ),
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1A438A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("طلب: ${widget.orderNumber}",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            _ActionCircle(icon: Icons.chat, color: Colors.green, onTap: () {}),
                            const SizedBox(width: 8),
                            _ActionCircle(icon: Icons.phone, color: Colors.white, onTap: () {}),
                            const SizedBox(width: 8),
                            _ActionCircle(
                                icon: Icons.headset_mic, color: Colors.white, onTap: () {}),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF1FF),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _stageLabel(_deliveryStage),
                                style: const TextStyle(
                                    color: Color(0xFF1A438A), fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text("طلب رقم ${widget.orderNumber}",
                                style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        LinearProgressIndicator(
                          value: _stageProgress(_deliveryStage),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(8),
                          backgroundColor: Colors.grey.shade200,
                          color: const Color(0xFF1A438A),
                        ),
                      ],
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

  String _stageLabel(String stage) {
    switch (stage) {
      case "assigned":
        return "تم تعيين السائق";
      case "en_route":
        return "في الطريق";
      case "delivered":
        return "تم التوصيل";
      default:
        return "قيد التأكيد";
    }
  }

  double _stageProgress(String stage) {
    switch (stage) {
      case "assigned":
        return 0.45;
      case "en_route":
        return 0.75;
      case "delivered":
        return 1.0;
      default:
        return 0.25;
    }
  }
}

class _ActionCircle extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCircle({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: Colors.white.withOpacity(0.15),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 18, color: color),
        onPressed: onTap,
      ),
    );
  }
}
