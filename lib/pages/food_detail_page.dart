import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'map_page.dart';

class FoodDetailPage extends StatelessWidget {
  final String foodId;

  const FoodDetailPage({
    super.key,
    required this.foodId,
  });

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFFE8F5E9);
  static const Color backgroundColor = Color(0xFFF8FBF8);
  static const Color darkText = Color(0xFF1F2937);
  static const Color grayText = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFDC2626);

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  String _toText(dynamic value, {String defaultValue = '-'}) {
    if (value == null) return defaultValue;
    final text = value.toString().trim();
    return text.isEmpty ? defaultValue : text;
  }

  Color _getStatusColor(String status) {
    if (status == 'เหมาะสม') return primaryGreen;
    if (status == 'ควรระวัง') return warningOrange;
    if (status == 'ไม่แนะนำ') return dangerRed;
    return warningOrange;
  }

  Widget _buildAssetOrNetworkImage({
    required String imageUrl,
    required double height,
    required double width,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    IconData placeholderIcon = Icons.restaurant_menu_rounded,
    double placeholderIconSize = 70,
  }) {
    Widget imageWidget;

    if (imageUrl.isEmpty) {
      imageWidget = Container(
        height: height,
        width: width,
        color: lightGreen,
        child: Icon(
          placeholderIcon,
          color: primaryGreen,
          size: placeholderIconSize,
        ),
      );
    } else {
      final bool isNetworkImage =
          imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

      imageWidget = isNetworkImage
          ? Image.network(
              imageUrl,
              height: height,
              width: width,
              fit: fit,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: height,
                  width: width,
                  color: lightGreen,
                  child: Icon(
                    placeholderIcon,
                    color: primaryGreen,
                    size: placeholderIconSize,
                  ),
                );
              },
            )
          : Image.asset(
              imageUrl,
              height: height,
              width: width,
              fit: fit,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: height,
                  width: width,
                  color: lightGreen,
                  child: Icon(
                    placeholderIcon,
                    color: primaryGreen,
                    size: placeholderIconSize,
                  ),
                );
              },
            );
    }

    if (borderRadius == null) return imageWidget;

    return ClipRRect(
      borderRadius: borderRadius,
      child: imageWidget,
    );
  }

  Widget _infoBox({
    required IconData icon,
    required String title,
    required String value,
    Color color = primaryGreen,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: grayText,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: darkText,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _nutritionGrid(Map<String, dynamic> data) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.85,
      children: [
        _infoBox(
          icon: Icons.local_fire_department_rounded,
          title: 'พลังงาน',
          value: '${_toInt(data['calories'])} kcal',
          color: warningOrange,
        ),
        _infoBox(
          icon: Icons.rice_bowl_rounded,
          title: 'คาร์โบไฮเดรต',
          value: '${_toInt(data['carb'])} g',
        ),
        _infoBox(
          icon: Icons.cake_rounded,
          title: 'น้ำตาล',
          value: '${_toInt(data['sugar'])} g',
          color: dangerRed,
        ),
        _infoBox(
          icon: Icons.water_drop_rounded,
          title: 'โซเดียม',
          value: '${_toInt(data['sodium'])} mg',
          color: warningOrange,
        ),
        _infoBox(
          icon: Icons.fitness_center_rounded,
          title: 'โปรตีน',
          value: '${_toInt(data['protein'])} g',
        ),
        _infoBox(
          icon: Icons.opacity_rounded,
          title: 'ไขมัน',
          value: '${_toInt(data['fat'])} g',
          color: warningOrange,
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: darkText,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _textCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: darkText,
          fontSize: 14,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildStatusAndScore({
    required String status,
    required int suitableScore,
  }) {
    final Color statusColor = _getStatusColor(status);

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'สถานะความเหมาะสม',
                  style: TextStyle(
                    color: grayText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Text(
                  '$suitableScore',
                  style: const TextStyle(
                    color: primaryGreen,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Suitable Score',
                  style: TextStyle(
                    color: grayText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDiseaseBadge(String disease) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        'แนะนำสำหรับ: $disease',
        style: const TextStyle(
          color: primaryGreen,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRestaurantSection({
    required BuildContext context,
    required Map<String, dynamic> foodData,
  }) {
    final String restaurantId = _toText(
      foodData['restaurantId'],
      defaultValue: '',
    );

    if (restaurantId.isEmpty) {
      final String restaurantName = _toText(
        foodData['restaurantName'],
        defaultValue: 'ไม่ระบุร้าน',
      );

      return _textCard('ร้านอาหาร: $restaurantName');
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: primaryGreen,
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'กำลังโหลดข้อมูลร้าน...',
                  style: TextStyle(color: grayText),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _textCard(
            'ร้านอาหาร: ${_toText(foodData['restaurantName'], defaultValue: 'ไม่ระบุร้าน')}',
          );
        }

        final restaurantData =
            snapshot.data!.data() as Map<String, dynamic>? ?? {};

        final String name = _toText(
          restaurantData['name'],
          defaultValue: _toText(foodData['restaurantName']),
        );
        final String address = _toText(
          restaurantData['address'],
          defaultValue: 'ไม่ระบุที่อยู่',
        );
        final String distance = _toText(
          restaurantData['distance'],
          defaultValue: '-',
        );
        final String phone = _toText(
          restaurantData['phone'],
          defaultValue: '-',
        );
        final String imageUrl = _toText(
          restaurantData['imageUrl'],
          defaultValue: '',
        );
        final double rating = _toDouble(restaurantData['rating']);
        final double latitude = _toDouble(restaurantData['latitude']);
        final double longitude = _toDouble(restaurantData['longitude']);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _buildAssetOrNetworkImage(
                    imageUrl: imageUrl,
                    height: 74,
                    width: 74,
                    borderRadius: BorderRadius.circular(16),
                    placeholderIcon: Icons.storefront_rounded,
                    placeholderIconSize: 34,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: darkText,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: grayText,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '$distance • Rating $rating • โทร $phone',
                          style: const TextStyle(
                            color: grayText,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: latitude == 0 || longitude == 0
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MapPage(
                                focusLatitude: latitude,
                                focusLongitude: longitude,
                                focusRestaurantName: name,
                              ),
                            ),
                          );
                        },
                  icon: const Icon(Icons.map_rounded),
                  label: const Text('ดูตำแหน่งร้านบนแผนที่'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFD1D5DB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFoodDetail(Map<String, dynamic> data, BuildContext context) {
    final String name = _toText(data['name'], defaultValue: 'ไม่มีชื่ออาหาร');
    final String restaurantName = _toText(
      data['restaurantName'],
      defaultValue: 'ไม่ระบุร้าน',
    );
    final String imageUrl = _toText(data['imageUrl'], defaultValue: '');
    final String status = _toText(data['status'], defaultValue: 'ควรระวัง');
    final String disease = _toText(
      data['recommendedForDisease'],
      defaultValue: 'สุขภาพทั่วไป',
    );
    final int suitableScore = _toInt(data['suitableScore']);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAssetOrNetworkImage(
            imageUrl: imageUrl,
            height: 230,
            width: double.infinity,
            placeholderIcon: Icons.restaurant_menu_rounded,
            placeholderIconSize: 80,
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: darkText,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.storefront_rounded,
                      color: grayText,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        restaurantName,
                        style: const TextStyle(
                          color: grayText,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildStatusAndScore(
                  status: status,
                  suitableScore: suitableScore,
                ),
                const SizedBox(height: 12),
                _buildDiseaseBadge(disease),
                _sectionTitle('ข้อมูลโภชนาการ'),
                _nutritionGrid(data),
                _sectionTitle('ข้อมูลร้านอาหาร'),
                _buildRestaurantSection(
                  context: context,
                  foodData: data,
                ),
                _sectionTitle('ส่วนประกอบ'),
                _textCard(_toText(data['ingredients'])),
                _sectionTitle('คำแนะนำ'),
                _textCard(_toText(data['recommendation'])),
                _sectionTitle('หมายเหตุความเสี่ยง'),
                _textCard(_toText(data['riskNote'])),
                _sectionTitle('คำเตือนทางการแพทย์'),
                _textCard(
                  _toText(
                    data['medicalDisclaimer'],
                    defaultValue:
                        'ข้อมูลนี้เป็นการประเมินเบื้องต้น ไม่ใช่คำวินิจฉัยทางการแพทย์ ผู้ป่วยควรปรึกษาแพทย์หรือนักโภชนาการ',
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('รายละเอียดอาหาร'),
        backgroundColor: Colors.white,
        foregroundColor: darkText,
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('foods').doc(foodId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryGreen),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('โหลดรายละเอียดอาหารไม่สำเร็จ'),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('ไม่พบข้อมูลอาหารนี้'),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

          return _buildFoodDetail(data, context);
        },
      ),
    );
  }
}