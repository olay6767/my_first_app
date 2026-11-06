import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FoodCard extends StatelessWidget {
  final String foodId;
  final String restaurantId;

  final String name;
  final String restaurantName;
  final String imageUrl;
  final String disease;
  final String status;

  final int calories;
  final int carb;
  final int sugar;
  final int protein;
  final int fat;
  final int sodium;
  final int suitableScore;

  final String ingredients;
  final String recommendation;
  final String riskNote;
  final String medicalDisclaimer;

  final VoidCallback? onTap;

  const FoodCard({
    super.key,
    required this.foodId,
    required this.restaurantId,
    required this.name,
    required this.restaurantName,
    required this.imageUrl,
    required this.disease,
    required this.status,
    required this.calories,
    required this.carb,
    required this.sugar,
    required this.protein,
    required this.fat,
    required this.sodium,
    required this.suitableScore,
    required this.ingredients,
    required this.recommendation,
    required this.riskNote,
    required this.medicalDisclaimer,
    this.onTap,
  });

  factory FoodCard.fromFirestore({
    required DocumentSnapshot doc,
    VoidCallback? onTap,
  }) {
    final Map<String, dynamic> data =
        doc.data() as Map<String, dynamic>? ?? {};

    return FoodCard(
      foodId: doc.id,
      restaurantId: _toText(data['restaurantId'], defaultValue: ''),
      name: _toText(data['name'], defaultValue: 'ไม่มีชื่อเมนู'),
      restaurantName: _toText(
        data['restaurantName'],
        defaultValue: 'ไม่ระบุร้าน',
      ),
      imageUrl: _toText(data['imageUrl'], defaultValue: ''),
      disease: _toText(
        data['recommendedForDisease'],
        defaultValue: 'สุขภาพทั่วไป',
      ),
      status: _toText(data['status'], defaultValue: 'ควรระวัง'),
      calories: _toInt(data['calories']),
      carb: _toInt(data['carb']),
      sugar: _toInt(data['sugar']),
      protein: _toInt(data['protein']),
      fat: _toInt(data['fat']),
      sodium: _toInt(data['sodium']),
      suitableScore: _toInt(data['suitableScore']),
      ingredients: _toText(
        data['ingredients'],
        defaultValue: 'ไม่ระบุวัตถุดิบ',
      ),
      recommendation: _toText(
        data['recommendation'],
        defaultValue: 'ไม่มีคำแนะนำเพิ่มเติม',
      ),
      riskNote: _toText(
        data['riskNote'],
        defaultValue: 'ไม่มีข้อควรระวังเพิ่มเติม',
      ),
      medicalDisclaimer: _toText(
        data['medicalDisclaimer'],
        defaultValue:
            'ข้อมูลนี้เป็นการประเมินเบื้องต้น ไม่ใช่คำวินิจฉัยทางการแพทย์',
      ),
      onTap: onTap,
    );
  }

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFFE8F5E9);
  static const Color backgroundColor = Color(0xFFF8FBF8);
  static const Color darkText = Color(0xFF1F2937);
  static const Color grayText = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFDC2626);

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String _toText(dynamic value, {String defaultValue = '-'}) {
    if (value == null) return defaultValue;
    final String text = value.toString().trim();
    return text.isEmpty ? defaultValue : text;
  }

  Color _getStatusColor() {
    if (status == 'เหมาะสม') return primaryGreen;
    if (status == 'ควรระวัง') return warningOrange;
    if (status == 'ไม่แนะนำ') return dangerRed;
    return warningOrange;
  }

  Widget _buildFoodImage({
    double width = 76,
    double height = 76,
    double radius = 17,
  }) {
    if (imageUrl.isEmpty) {
      return _buildFoodPlaceholder(
        width: width,
        height: height,
        radius: radius,
      );
    }

    final bool isNetworkImage =
        imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: isNetworkImage
          ? Image.network(
              imageUrl,
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildFoodPlaceholder(
                  width: width,
                  height: height,
                  radius: radius,
                );
              },
            )
          : Image.asset(
              imageUrl,
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildFoodPlaceholder(
                  width: width,
                  height: height,
                  radius: radius,
                );
              },
            ),
    );
  }

  Widget _buildFoodPlaceholder({
    required double width,
    required double height,
    required double radius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: const Icon(
        Icons.restaurant_menu_rounded,
        color: primaryGreen,
        size: 32,
      ),
    );
  }

  void _showFoodDetail(BuildContext context) {
    final Color statusColor = _getStatusColor();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
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
                    const SizedBox(height: 18),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFoodImage(
                          width: 90,
                          height: 90,
                          radius: 20,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  color: darkText,
                                  fontSize: 21,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                restaurantName,
                                style: const TextStyle(
                                  color: grayText,
                                  fontSize: 13.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 7,
                                runSpacing: 7,
                                children: [
                                  _buildChip(
                                    text: status,
                                    textColor: statusColor,
                                    backgroundColor:
                                        statusColor.withOpacity(0.10),
                                  ),
                                  _buildChip(
                                    text: disease,
                                    textColor: primaryGreen,
                                    backgroundColor: lightGreen,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    _buildSectionTitle('ข้อมูลโภชนาการ'),
                    const SizedBox(height: 10),
                    _buildNutritionGrid(),

                    const SizedBox(height: 18),

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
                    const SizedBox(height: 10),
                    _buildInfoBox(
                      icon: Icons.info_rounded,
                      title: 'หมายเหตุ',
                      text: medicalDisclaimer,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: darkText,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildChip({
    required String text,
    required Color textColor,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildNutritionGrid() {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 2.75,
      mainAxisSpacing: 9,
      crossAxisSpacing: 9,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildNutritionItem('แคลอรี', '$calories kcal'),
        _buildNutritionItem('คาร์บ', '$carb g'),
        _buildNutritionItem('น้ำตาล', '$sugar g'),
        _buildNutritionItem('โปรตีน', '$protein g'),
        _buildNutritionItem('ไขมัน', '$fat g'),
        _buildNutritionItem('โซเดียม', '$sodium mg'),
      ],
    );
  }

  Widget _buildNutritionItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.circle,
            color: primaryGreen,
            size: 9,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: grayText,
                fontSize: 12.5,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: darkText,
              fontSize: 12.5,
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
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: primaryGreen,
            size: 21,
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
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    color: grayText,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color statusColor = _getStatusColor();

    return InkWell(
      onTap: onTap ?? () => _showFoodDetail(context),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildFoodImage(),
            const SizedBox(width: 13),

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

                  const SizedBox(height: 4),

                  Text(
                    restaurantName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: grayText,
                      fontSize: 12.5,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    '$calories kcal • $disease',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: grayText,
                      fontSize: 12.5,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'คาร์บ $carb g • น้ำตาล $sugar g • โซเดียม $sodium mg',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: grayText,
                      fontSize: 11.5,
                    ),
                  ),

                  const SizedBox(height: 7),

                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11.5,
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
      ),
    );
  }
}