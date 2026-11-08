import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../config/store.dart';
import '../config/theme.dart';
import '../l10n/strings.dart';
import '../services/geo_service.dart';
import '../widgets/ui/button.dart';

class MapPickResult {
  final LatLng point;
  final String? address;
  const MapPickResult(this.point, this.address);
}

/// To'liq ekran xarita, markazda qo'zg'almas pin: mijoz xaritani uning ostidan
/// suradi. Oxirgi markaz keyingi ochilishda eslab qolinadi.
class MapPickerScreen extends StatefulWidget {
  final LatLng? initial;
  const MapPickerScreen({super.key, this.initial});

  /// Oxirgi tanlangan markaz (ilova ochiq turganda).
  static LatLng? lastCenter;

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final _map = MapController();
  late LatLng _center;
  String? _address;
  bool _loading = true;
  bool _locating = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _center = widget.initial ?? MapPickerScreen.lastCenter ?? const LatLng(kMapCenterLat, kMapCenterLng);
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve(_center));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onMove(LatLng c) {
    _center = c;
    MapPickerScreen.lastCenter = c;
    _debounce?.cancel();
    if (!_loading) setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 350), () => _resolve(c));
  }

  Future<void> _resolve(LatLng c) async {
    final address = await GeoService.reverseGeocode(c.latitude, c.longitude);
    if (!mounted || c != _center) return;
    setState(() {
      _address = address;
      _loading = false;
    });
  }

  Future<void> _locateMe() async {
    setState(() => _locating = true);
    try {
      final p = await GeoService.currentPosition();
      if (!mounted) return;
      _map.move(p, 17);
      _onMove(p);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: kDanger));
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
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
                userAgentPackageName: 'com.mirsolioptom.store_app',
                maxZoom: 19,
              ),
              const RichAttributionWidget(attributions: [TextSourceAttribution('© OpenStreetMap')]),
            ],
          ),
          // Markazdagi qo'zg'almas pin: uchi aynan markazda.
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 40),
                child: Icon(Icons.location_on_rounded, size: 44, color: kAccent),
              ),
            ),
          ),
          Positioned(
            top: pad.top + kSpace4,
            left: kSpace4,
            child: _Round(icon: LucideIcons.x, size: 44, label: tr.mapClose, onTap: () => Navigator.pop(context)),
          ),
          Positioned(
            top: pad.top + kSpace4,
            right: kSpace4,
            child: Column(
              children: [
                _Round(icon: LucideIcons.plus, label: tr.zoomIn, onTap: () => _map.move(_map.camera.center, _map.camera.zoom + 1)),
                const SizedBox(height: kSpace2),
                _Round(icon: LucideIcons.minus, label: tr.zoomOut, onTap: () => _map.move(_map.camera.center, _map.camera.zoom - 1)),
              ],
            ),
          ),
          Positioned(
            right: kSpace4,
            bottom: 200 + pad.bottom,
            child: _Round(
              icon: _locating ? LucideIcons.loader : LucideIcons.crosshair,
              label: tr.mapLocate,
              onTap: _locating ? null : _locateMe,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(kSpace5, kSpace5, kSpace5, kSpace5 + pad.bottom),
              decoration: const BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(kRadiusXl)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(tr.mapPicked.toUpperCase(), style: eyebrow(color: kMuted)),
                  const SizedBox(height: kSpace2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: kSpace4, vertical: kSpace3),
                    decoration: BoxDecoration(color: kSurfaceMuted, borderRadius: BorderRadius.circular(kRadiusSm)),
                    child: Text(
                      _loading ? tr.locating : (_address ?? tr.mapNoAddress),
                      style: sans(kTextMd, weight: FontWeight.w600, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: kSpace4),
                  AppButton(
                    label: tr.mapConfirm,
                    size: ButtonSize.lg,
                    block: true,
                    onPressed: () => Navigator.pop(context, MapPickResult(_center, _loading ? null : _address)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Round extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final double size;
  const _Round({required this.icon, required this.label, this.onTap, this.size = 46});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(color: kSurface, shape: BoxShape.circle, boxShadow: kShadowMd),
            child: Icon(icon, size: 20, color: kInk),
          ),
        ),
      );
}
