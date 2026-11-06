import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../components/app_bottom_nav_bar.dart';
import 'analyze_food_page.dart';
import 'grab_mock_order_page.dart';
import 'profile_page.dart';

class MapPage extends StatefulWidget {
  final double? focusLatitude;
  final double? focusLongitude;
  final String? focusRestaurantName;
  final String? focusRestaurantId;
  final String? focusFoodId;

  const MapPage({
    super.key,
    this.focusLatitude,
    this.focusLongitude,
    this.focusRestaurantName,
    this.focusRestaurantId,
    this.focusFoodId,
  });

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFFE8F5E9);
  static const Color backgroundColor = Color(0xFFF8FBF8);
  static const Color darkText = Color(0xFF1F2937);
  static const Color grayText = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color grabGreen = Color(0xFF00B14F);

  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  List<_RestaurantDistance> _allRestaurants = [];
  List<_RestaurantDistance> _filteredRestaurants = [];

  bool _isLoading = true;
  bool _locationAllowed = false;
  bool _alreadyOpenedFocusRestaurant = false;

  Position? _userPosition;
  _RestaurantDistance? _selectedRestaurant;

  LatLng get _startPosition {
    if (widget.focusLatitude != null && widget.focusLongitude != null) {
      return LatLng(widget.focusLatitude!, widget.focusLongitude!);
    }

    if (_userPosition != null) {
      return LatLng(_userPosition!.latitude, _userPosition!.longitude);
    }

    return const LatLng(14.8810, 102.0187);
  }

  double get _startZoom {
    if (widget.focusLatitude != null && widget.focusLongitude != null) {
      return 16;
    }

    if (_userPosition != null) {
      return 15;
    }

    return 14;
  }

  @override
  void initState() {
    super.initState();
    _loadMapData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadMapData() async {
    try {
      final Position? position = await _getCurrentPosition();

      final snapshot = await FirebaseFirestore.instance
          .collection('restaurants')
          .where('isActive', isEqualTo: true)
          .get();

      final List<_RestaurantDistance> restaurants = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final double latitude = _toDouble(data['latitude']);
        final double longitude = _toDouble(data['longitude']);

        if (latitude == 0 || longitude == 0) {
          continue;
        }

        final String name = _toText(
          data['name'],
          defaultValue: 'ไม่มีชื่อร้าน',
        );

        final String address = _toText(
          data['address'],
          defaultValue: 'ไม่ระบุที่อยู่',
        );

        double? distanceKm;

        if (position != null) {
          final double distanceMeters = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            latitude,
            longitude,
          );

          distanceKm = distanceMeters / 1000;
        }

        restaurants.add(
          _RestaurantDistance(
            id: doc.id,
            name: name,
            address: address,
            imageUrl: _toText(data['imageUrl'], defaultValue: ''),
            latitude: latitude,
            longitude: longitude,
            distanceKm: distanceKm,
            foodCategories:
                data['foodCategories'] is List ? data['foodCategories'] : [],
            rawData: data,
          ),
        );
      }

      restaurants.sort((a, b) {
        final double aDistance = a.distanceKm ?? 999999;
        final double bDistance = b.distanceKm ?? 999999;
        return aDistance.compareTo(bDistance);
      });

      if (!mounted) return;

      setState(() {
        _userPosition = position;
        _locationAllowed = position != null;
        _allRestaurants = restaurants;
        _filteredRestaurants = restaurants;
        _selectedRestaurant = null;
        _polylines = {};
        _markers = _buildMarkers(restaurants);
        _isLoading = false;
      });

      _moveCameraToStart();
      _openFocusRestaurantIfNeeded(restaurants);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('โหลดแผนที่ไม่สำเร็จ: $e'),
        ),
      );
    }
  }

  void _openFocusRestaurantIfNeeded(List<_RestaurantDistance> restaurants) {
    if (_alreadyOpenedFocusRestaurant) return;

    if (widget.focusRestaurantId == null || widget.focusRestaurantId!.isEmpty) {
      return;
    }

    final matchedRestaurants = restaurants.where(
      (restaurant) => restaurant.id == widget.focusRestaurantId,
    );

    if (matchedRestaurants.isEmpty) return;

    _alreadyOpenedFocusRestaurant = true;

    final restaurant = matchedRestaurants.first;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _selectRestaurant(restaurant);
      _showRestaurantDetailSheet(restaurant);
    });
  }

  Set<Marker> _buildMarkers(List<_RestaurantDistance> restaurants) {
    final Set<Marker> markers = {};

    if (_userPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(_userPosition!.latitude, _userPosition!.longitude),
          infoWindow: const InfoWindow(
            title: 'ตำแหน่งของคุณ',
            snippet: 'คุณอยู่บริเวณนี้',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }

    for (final restaurant in restaurants) {
      final bool isSelected = _selectedRestaurant?.id == restaurant.id;

      markers.add(
        Marker(
          markerId: MarkerId(restaurant.id),
          position: LatLng(restaurant.latitude, restaurant.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isSelected ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(
            title: restaurant.name,
            snippet: restaurant.distanceKm == null
                ? restaurant.address
                : '${restaurant.distanceKm!.toStringAsFixed(1)} km จากคุณ',
          ),
          onTap: () {
            _selectRestaurant(restaurant);
            _showRestaurantDetailSheet(restaurant);
          },
        ),
      );
    }

    return markers;
  }

  Future<Position?> _getCurrentPosition() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      return null;
    }
  }

  void _moveCameraToStart() {
    if (_mapController == null) return;

    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(_startPosition, _startZoom),
    );
  }

  void _focusRestaurant(_RestaurantDistance restaurant) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(restaurant.latitude, restaurant.longitude),
        16,
      ),
    );
  }

  void _selectRestaurant(_RestaurantDistance restaurant) {
    setState(() {
      _selectedRestaurant = restaurant;
      _polylines = _buildRouteLine(restaurant);
      _markers = _buildMarkers(_filteredRestaurants);
    });

    _focusRestaurant(restaurant);
  }

  Set<Polyline> _buildRouteLine(_RestaurantDistance restaurant) {
    if (_userPosition == null) {
      return {};
    }

    return {
      Polyline(
        polylineId: const PolylineId('route_to_restaurant'),
        points: [
          LatLng(_userPosition!.latitude, _userPosition!.longitude),
          LatLng(restaurant.latitude, restaurant.longitude),
        ],
        color: primaryGreen,
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      ),
    };
  }

  void _searchRestaurants(String keyword) {
    final String searchText = keyword.trim().toLowerCase();

    if (searchText.isEmpty) {
      setState(() {
        _filteredRestaurants = _allRestaurants;
        _markers = _buildMarkers(_allRestaurants);
      });
      return;
    }

    final List<_RestaurantDistance> results = _allRestaurants.where((item) {
      final String name = item.name.toLowerCase();
      final String address = item.address.toLowerCase();
      final String categories = item.foodCategories.join(', ').toLowerCase();

      return name.contains(searchText) ||
          address.contains(searchText) ||
          categories.contains(searchText);
    }).toList();

    setState(() {
      _filteredRestaurants = results;
      _markers = _buildMarkers(results);
    });

    if (results.isNotEmpty) {
      _focusRestaurant(results.first);
    }
  }

  void _handleBottomNavTap(int index) {
    if (index == 0) {
      Navigator.pop(context);
      return;
    }

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AnalyzeFoodPage(),
        ),
      );
      return;
    }

    if (index == 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ชาเลนจ์อยู่ในหน้าเมนูหลัก'),
        ),
      );
      return;
    }

    if (index == 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('แชทอยู่ในหน้าเมนูหลัก'),
        ),
      );
      return;
    }

    if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ProfilePage(),
        ),
      );
    }
  }

  void _openGrabMockOrderPage({
    required String foodId,
    required Map<String, dynamic> foodData,
    required _RestaurantDistance restaurant,
  }) {
    final Map<String, dynamic> mergedFoodData = {
      ...foodData,
      'restaurantId': restaurant.id,
      'restaurantName': restaurant.name,
      'restaurantAddress': restaurant.address,
      'restaurantLatitude': restaurant.latitude,
      'restaurantLongitude': restaurant.longitude,
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GrabMockOrderPage(
          foodId: foodId,
          foodData: mergedFoodData,
        ),
      ),
    );
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String _toText(dynamic value, {String defaultValue = '-'}) {
    if (value == null) return defaultValue;
    final text = value.toString().trim();
    return text.isEmpty ? defaultValue : text;
  }

  Widget _buildRestaurantImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return _buildRestaurantImagePlaceholder();
    }

    final bool isNetworkImage =
        imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: isNetworkImage
          ? Image.network(
              imageUrl,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildRestaurantImagePlaceholder();
              },
            )
          : Image.asset(
              imageUrl,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildRestaurantImagePlaceholder();
              },
            ),
    );
  }

  Widget _buildRestaurantImagePlaceholder() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.storefront_rounded,
        color: primaryGreen,
        size: 32,
      ),
    );
  }

  Widget _buildFoodImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return _buildFoodImagePlaceholder();
    }

    final bool isNetworkImage =
        imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: isNetworkImage
          ? Image.network(
              imageUrl,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildFoodImagePlaceholder();
              },
            )
          : Image.asset(
              imageUrl,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildFoodImagePlaceholder();
              },
            ),
    );
  }

  Widget _buildFoodImagePlaceholder() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.restaurant_menu_rounded,
        color: primaryGreen,
        size: 30,
      ),
    );
  }

  Widget _buildSearchBox() {
    return Positioned(
      left: 16,
      right: 16,
      top: 14,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            _searchRestaurants(value);
            setState(() {});
          },
          decoration: InputDecoration(
            border: InputBorder.none,
            icon: const Icon(
              Icons.search_rounded,
              color: primaryGreen,
            ),
            hintText: 'ค้นหาร้านอาหาร / ประเภทอาหาร',
            hintStyle: const TextStyle(
              color: grayText,
              fontSize: 14,
            ),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      _searchController.clear();
                      _searchRestaurants('');
                      setState(() {});
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                      color: grayText,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildRestaurantList() {
    if (_filteredRestaurants.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
        ),
        child: const Row(
          children: [
            Icon(Icons.storefront_rounded, color: primaryGreen),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'ไม่พบร้านอาหารที่ค้นหา',
                style: TextStyle(
                  color: grayText,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 135,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filteredRestaurants.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final restaurant = _filteredRestaurants[index];

          final String distanceText = restaurant.distanceKm == null
              ? 'ยังไม่ได้เปิดตำแหน่ง'
              : '${restaurant.distanceKm!.toStringAsFixed(1)} km จากคุณ';

          final bool isSelected = _selectedRestaurant?.id == restaurant.id;

          return InkWell(
            onTap: () {
              _selectRestaurant(restaurant);
              _showRestaurantDetailSheet(restaurant);
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 292,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? primaryGreen : borderColor,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _buildRestaurantImage(restaurant.imageUrl),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          restaurant.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: darkText,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          restaurant.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: grayText,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.route_rounded,
                              color: primaryGreen,
                              size: 15,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                distanceText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: primaryGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          restaurant.foodCategories.isEmpty
                              ? 'ร้านอาหาร'
                              : restaurant.foodCategories.join(', '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: grayText,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              _selectedRestaurant != null
                  ? 'แสดงเส้นทางไปยัง ${_selectedRestaurant!.name}'
                  : _filteredRestaurants.isEmpty
                      ? 'ไม่พบร้านอาหาร'
                      : _locationAllowed
                          ? 'พบร้านอาหาร ${_filteredRestaurants.length} ร้าน เรียงจากใกล้คุณที่สุด'
                          : 'พบร้านอาหาร ${_filteredRestaurants.length} ร้าน กรุณาเปิดตำแหน่งเพื่อคำนวณระยะทาง',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: darkText,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildRestaurantList(),
        ],
      ),
    );
  }

  void _showRestaurantDetailSheet(_RestaurantDistance restaurant) {
    final String distanceText = restaurant.distanceKm == null
        ? 'ยังไม่ได้เปิดตำแหน่ง'
        : '${restaurant.distanceKm!.toStringAsFixed(1)} km จากคุณ';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
              decoration: const BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 46,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1D5DB),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRestaurantImage(restaurant.imageUrl),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                restaurant.name,
                                style: const TextStyle(
                                  color: darkText,
                                  fontSize: 21,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                restaurant.address,
                                style: const TextStyle(
                                  color: grayText,
                                  fontSize: 13.5,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.route_rounded,
                                    color: primaryGreen,
                                    size: 17,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'ระยะทางโดยประมาณ $distanceText',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: primaryGreen,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: restaurant.foodCategories.isEmpty
                          ? [_buildCategoryChip('ร้านอาหาร')]
                          : restaurant.foodCategories
                              .map((item) => _buildCategoryChip(item.toString()))
                              .toList(),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _selectRestaurant(restaurant);
                        },
                        icon: const Icon(Icons.route_rounded),
                        label: const Text('แสดงเส้นทางไปร้านนี้'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'เมนูอาหารของร้านนี้',
                      style: TextStyle(
                        color: darkText,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildRestaurantFoods(restaurant),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: primaryGreen,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildRestaurantFoods(_RestaurantDistance restaurant) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurant.id)
          .collection('foods')
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(18),
            child: Center(
              child: CircularProgressIndicator(color: primaryGreen),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildFoodEmptyCard(
            'โหลดเมนูของร้านไม่สำเร็จ\n${snapshot.error}',
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildFoodEmptyCard(
            'ยังไม่มีเมนูอาหารของร้านนี้ใน Firebase\nPath: restaurants/${restaurant.id}/foods',
          );
        }

        final List<QueryDocumentSnapshot> foods = snapshot.data!.docs.toList();

        if (widget.focusFoodId != null && widget.focusFoodId!.isNotEmpty) {
          foods.sort((a, b) {
            final bool aIsFocus = a.id == widget.focusFoodId;
            final bool bIsFocus = b.id == widget.focusFoodId;

            if (aIsFocus && !bIsFocus) return -1;
            if (!aIsFocus && bIsFocus) return 1;

            return 0;
          });
        }

        return Column(
          children: foods.map((doc) {
            final food = doc.data() as Map<String, dynamic>? ?? {};

            return _buildFoodCard(
              restaurant: restaurant,
              foodId: doc.id,
              foodData: food,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildFoodCard({
    required _RestaurantDistance restaurant,
    required String foodId,
    required Map<String, dynamic> foodData,
  }) {
    final bool shouldExpand = widget.focusFoodId == foodId;

    final String name = _toText(
      foodData['name'],
      defaultValue: 'ไม่มีชื่อเมนู',
    );

    final String imageUrl = _toText(
      foodData['imageUrl'],
      defaultValue: '',
    );

    final String disease = _toText(
      foodData['recommendedForDisease'],
      defaultValue: 'สุขภาพทั่วไป',
    );

    final int calories = _toInt(foodData['calories']);
    final int carb = _toInt(foodData['carb']);
    final int sugar = _toInt(foodData['sugar']);
    final int protein = _toInt(foodData['protein']);
    final int fat = _toInt(foodData['fat']);
    final int sodium = _toInt(foodData['sodium']);
    final int price = _getFoodPrice(foodData);

    final String ingredients = _toText(
      foodData['ingredients'],
      defaultValue: 'ไม่ระบุวัตถุดิบ',
    );

    final String recommendation = _toText(
      foodData['recommendation'],
      defaultValue: 'ไม่ระบุคำแนะนำ',
    );

    final String riskNote = _toText(
      foodData['riskNote'],
      defaultValue: 'ไม่มีข้อควรระวังเพิ่มเติม',
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: shouldExpand ? lightGreen.withOpacity(0.55) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: shouldExpand ? primaryGreen : borderColor,
          width: shouldExpand ? 1.5 : 1,
        ),
      ),
      child: ExpansionTile(
        key: ValueKey<String>('food_$foodId'),
        initiallyExpanded: shouldExpand,
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 10),
        shape: const Border(),
        collapsedShape: const Border(),
        leading: _buildFoodImage(imageUrl),
        title: Row(
          children: [
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: darkText,
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '฿$price',
              style: const TextStyle(
                color: grabGreen,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            '$calories kcal • $disease',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: grayText,
              fontSize: 12.5,
            ),
          ),
        ),
        trailing: const Icon(
          Icons.expand_more_rounded,
          color: primaryGreen,
        ),
        children: [
          _buildNutritionGrid(
            carb: carb,
            sugar: sugar,
            protein: protein,
            fat: fat,
            sodium: sodium,
          ),
          const SizedBox(height: 12),
          _buildInfoBox(
            icon: Icons.restaurant_rounded,
            title: 'วัตถุดิบ',
            text: ingredients,
          ),
          const SizedBox(height: 10),
          _buildInfoBox(
            icon: Icons.check_circle_rounded,
            title: 'คำแนะนำ',
            text: recommendation,
          ),
          const SizedBox(height: 10),
          _buildInfoBox(
            icon: Icons.warning_amber_rounded,
            title: 'ข้อควรระวัง',
            text: riskNote,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () {
                _openGrabMockOrderPage(
                  foodId: foodId,
                  foodData: foodData,
                  restaurant: restaurant,
                );
              },
              icon: const Icon(Icons.delivery_dining_rounded),
              label: const Text('ดูรายละเอียดและสั่งอาหารจำลอง'),
              style: ElevatedButton.styleFrom(
                backgroundColor: grabGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getFoodPrice(Map<String, dynamic> foodData) {
    final dynamic value = foodData['price'] ??
        foodData['foodPrice'] ??
        foodData['menuPrice'] ??
        foodData['cost'];

    final int price = _toInt(value);

    if (price > 0) return price;

    return 59;
  }

  Widget _buildNutritionGrid({
    required int carb,
    required int sugar,
    required int protein,
    required int fat,
    required int sodium,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildNutritionItem('คาร์บ', '$carb g')),
            const SizedBox(width: 8),
            Expanded(child: _buildNutritionItem('น้ำตาล', '$sugar g')),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildNutritionItem('โปรตีน', '$protein g')),
            const SizedBox(width: 8),
            Expanded(child: _buildNutritionItem('ไขมัน', '$fat g')),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildNutritionItem('โซเดียม', '$sodium mg')),
            const SizedBox(width: 8),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  Widget _buildNutritionItem(String label, String value) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.circle,
            color: primaryGreen,
            size: 9,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: grayText,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: darkText,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox({
    required IconData icon,
    required String title,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: primaryGreen,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: darkText,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    color: grayText,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodEmptyCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: grayText,
          fontSize: 13,
          height: 1.45,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: darkText,
        elevation: 0,
        title: Text(
          widget.focusRestaurantName == null
              ? 'ร้านอาหารใกล้ฉัน'
              : widget.focusRestaurantName!,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              setState(() {
                _isLoading = true;
                _alreadyOpenedFocusRestaurant = false;
              });

              await _loadMapData();
            },
            icon: const Icon(
              Icons.refresh_rounded,
              color: primaryGreen,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _startPosition,
              zoom: _startZoom,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationButtonEnabled: true,
            myLocationEnabled: _locationAllowed,
            zoomControlsEnabled: false,
            mapToolbarEnabled: true,
            onMapCreated: (controller) {
              _mapController = controller;
              _moveCameraToStart();

              if (_allRestaurants.isNotEmpty) {
                _openFocusRestaurantIfNeeded(_allRestaurants);
              }
            },
          ),
          _buildSearchBox(),
          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.60),
              child: const Center(
                child: CircularProgressIndicator(color: primaryGreen),
              ),
            ),
          if (!_isLoading) _buildBottomPanel(),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 0,
        onTap: _handleBottomNavTap,
      ),
    );
  }
}

class _RestaurantDistance {
  final String id;
  final String name;
  final String address;
  final String imageUrl;
  final double latitude;
  final double longitude;
  final double? distanceKm;
  final List foodCategories;
  final Map<String, dynamic> rawData;

  const _RestaurantDistance({
    required this.id,
    required this.name,
    required this.address,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    required this.foodCategories,
    required this.rawData,
  });
}