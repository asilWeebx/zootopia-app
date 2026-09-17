import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../config/theme.dart';
import '../services/geo_service.dart';

/// Xarita picker natijasi.
class MapPickResult {
  final LatLng point;
  final String? address;
  const MapPickResult(this.point, this.address);
}

/// Yetkazish joyini xaritada belgilash. Markazdagi pin turadi, xarita
/// suriladi — markaz koordinatasi reverse-geocode qilinadi. "Shu yerni
/// tanlash" bosilganda [MapPickResult] qaytaradi.
class MapPickerScreen extends StatefulWidget {
  final LatLng? initial;
  const MapPickerScreen({super.key, this.initial});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final _map = MapController();
  late LatLng _center;
  String? _address;
  bool _loading = false;
  bool _locating = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _center = widget.initial ?? GeoService.tashkent;
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve(_center));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onMove(LatLng c) {
    _center = c;
    _debounce?.cancel();
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 650), () => _resolve(c));
  }

  Future<void> _resolve(LatLng c) async {
    final addr = await GeoService.reverseGeocode(c.latitude, c.longitude);
    if (!mounted) return;
    setState(() {
      _address = addr;
      _loading = false;
    });
  }

  Future<void> _locateMe() async {
    setState(() => _locating = true);
    try {
      final p = await GeoService.currentPosition();
      if (!mounted) return;
      _map.move(p, 17);
      _center = p;
      await _resolve(p);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: kRed),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(children: [
        FlutterMap(
          mapController: _map,
          options: MapOptions(
            initialCenter: _center,
            initialZoom: 16,
            minZoom: 4,
            maxZoom: 19,
            onPositionChanged: (camera, hasGesture) {
              if (hasGesture) _onMove(camera.center);
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'uz.dukonline.store',
              maxZoom: 19,
            ),
            const RichAttributionWidget(attributions: [
              TextSourceAttribution('© OpenStreetMap'),
            ]),
          ],
        ),

        // Markazdagi qo'zg'almas pin (xarita ostidan suriladi)
        IgnorePointer(
          child: Center(
            child: Transform.translate(
              offset: const Offset(0, -18),
              child: const Icon(Icons.location_on, size: 44, color: kAccentDark),
            ),
          ),
        ),

        // Yopish
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 12,
          child: _RoundBtn(icon: Icons.close, onTap: () => Navigator.pop(context)),
        ),
        // Zoom
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 12,
          child: Column(children: [
            _RoundBtn(icon: Icons.add, onTap: () => _map.move(_center, _map.camera.zoom + 1)),
            const SizedBox(height: 10),
            _RoundBtn(icon: Icons.remove, onTap: () => _map.move(_center, _map.camera.zoom - 1)),
          ]),
        ),
        // Meni topish
        Positioned(
          right: 12,
          bottom: 190,
          child: _RoundBtn(
            icon: _locating ? Icons.hourglass_top : Icons.my_location,
            onTap: _locating ? null : _locateMe,
          ),
        ),

        // Pastki panel: tanlangan joy + tugma
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.fromLTRB(20, 18, 20, MediaQuery.of(context).padding.bottom + 16),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('TANLANGAN JOY',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kTextSub, letterSpacing: .6)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(12)),
                child: _loading
                    ? const Text('Aniqlanmoqda...', style: TextStyle(fontSize: 15, color: kTextMuted))
                    : Text(_address ?? 'Manzil aniqlanmadi (koordinata saqlanadi)',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kText)),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => Navigator.pop(context, MapPickResult(_center, _address)),
                child: Container(
                  height: 52,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: kAccent,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: kAccent.withAlpha(100), blurRadius: 16, offset: const Offset(0, 4))],
                  ),
                  child: const Center(
                    child: Text('Shu yerni tanlash',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black)),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _RoundBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(28), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Icon(icon, size: 22, color: kText),
        ),
      );
}
