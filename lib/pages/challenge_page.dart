import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../components/app_bottom_nav_bar.dart';
import '../utils/smooth_route.dart';

import 'analyze_food_page.dart';
import 'expert_list_page.dart';
import 'home_page.dart';
import 'profile_page.dart';

class ChallengePage extends StatefulWidget {
  const ChallengePage({super.key});

  @override
  State<ChallengePage> createState() => _ChallengePageState();
}

class _ChallengePageState extends State<ChallengePage> {
  static const Color primaryGreen = Color(0xFF16A34A);
  static const Color deepGreen = Color(0xFF15803D);
  static const Color mintGreen = Color(0xFFDCFCE7);
  static const Color softGreen = Color(0xFFF0FDF4);
  static const Color backgroundColor = Color(0xFFF7FBF8);
  static const Color cardColor = Colors.white;
  static const Color darkText = Color(0xFF111827);
  static const Color grayText = Color(0xFF6B7280);
  static const Color lightText = Color(0xFF9CA3AF);
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color softOrange = Color(0xFFFFF7ED);
  static const Color blue = Color(0xFF0EA5E9);
  static const Color softBlue = Color(0xFFE0F2FE);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color softPurple = Color(0xFFF3E8FF);

  final TextEditingController titleController =
      TextEditingController(text: 'คุมอาหารวันนี้');
  final TextEditingController caloriesController =
      TextEditingController(text: '1800');
  final TextEditingController sugarController =
      TextEditingController(text: '100');
  final TextEditingController fatController =
      TextEditingController(text: '100');
  final TextEditingController proteinController =
      TextEditingController(text: '200');
  final TextEditingController carbController =
      TextEditingController(text: '300');
  final TextEditingController sodiumController =
      TextEditingController(text: '3000');

  String selectedPeriod = 'daily';
  bool isCreatingChallenge = false;
  bool isRegeneratingPlan = false;

  User? get currentUser => FirebaseAuth.instance.currentUser;

  final Map<String, int> pointsByPeriod = {
    'daily': 100,
    'weekly': 1000,
    'monthly': 5000,
  };

  final Map<String, String> periodLabels = {
    'daily': 'รายวัน',
    'weekly': 'รายสัปดาห์',
    'monthly': 'รายเดือน',
  };

  @override
  void dispose() {
    titleController.dispose();
    caloriesController.dispose();
    sugarController.dispose();
    fatController.dispose();
    proteinController.dispose();
    carbController.dispose();
    sodiumController.dispose();
    super.dispose();
  }

  void _handleNavTap(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        smoothRoute(const HomePage()),
      );
      return;
    }

    if (index == 1) {
      Navigator.pushReplacement(
        context,
        smoothRoute(const AnalyzeFoodPage()),
      );
      return;
    }

    if (index == 2) return;

    if (index == 3) {
      Navigator.pushReplacement(
        context,
        smoothRoute(const ExpertListPage()),
      );
      return;
    }

    if (index == 4) {
      Navigator.pushReplacement(
        context,
        smoothRoute(const ProfilePage()),
      );
    }
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  String _toText(dynamic value, {String defaultValue = '-'}) {
    if (value == null) return defaultValue;
    final String text = value.toString().trim();
    return text.isEmpty ? defaultValue : text;
  }

  void _showSnackBar(String message, {bool success = true}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? primaryGreen : dangerRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(14),
      ),
    );
  }

  DateTime _getEndDate(String period) {
    final DateTime now = DateTime.now();

    if (period == 'weekly') {
      return now.add(const Duration(days: 7));
    }

    if (period == 'monthly') {
      return DateTime(now.year, now.month + 1, now.day);
    }

    return now.add(const Duration(days: 1));
  }

  String _getPeriodText(String period) {
    return periodLabels[period] ?? 'รายวัน';
  }

  int _getRewardPoint(String period) {
    return pointsByPeriod[period] ?? 100;
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp is! Timestamp) return '-';

    final DateTime date = timestamp.toDate();
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString();

    return '$day/$month/$year';
  }

  bool _isFoodAllowedForUserDiseases({
    required Map<String, dynamic> foodData,
    required List<String> userDiseases,
  }) {
    return true;
  }

  double _calculateFoodScore({
    required Map<String, dynamic> foodData,
    required double targetCalories,
    required double targetSugar,
    required double targetFat,
    required double targetSodium,
    required double targetProtein,
    required double targetCarb,
  }) {
    final double calories = _toDouble(foodData['calories']);
    final double sugar = _toDouble(foodData['sugar']);
    final double fat = _toDouble(foodData['fat']);
    final double sodium = _toDouble(foodData['sodium']);
    final double protein = _toDouble(foodData['protein']);
    final double carb = _toDouble(foodData['carb']);

    double score = 0;

    score += (calories / max(targetCalories, 1)) * 35;
    score += (sugar / max(targetSugar, 1)) * 20;
    score += (fat / max(targetFat, 1)) * 15;
    score += (sodium / max(targetSodium, 1)) * 20;
    score += (carb / max(targetCarb, 1)) * 10;

    if (protein > 0) {
      score -= min(protein / max(targetProtein, 1), 1) * 10;
    }

    return score;
  }

  Future<void> _generateMealPlanForChallenge({
    required String challengeId,
    required String userId,
    required double targetCalories,
    required double targetSugar,
    required double targetFat,
    required double targetSodium,
    required double targetProtein,
    required double targetCarb,
    required List<String> userDiseases,
  }) async {
    final QuerySnapshot oldPlans = await FirebaseFirestore.instance
        .collection('challenge_meal_plans')
        .where('challengeId', isEqualTo: challengeId)
        .where('userId', isEqualTo: userId)
        .get();

    final WriteBatch deleteBatch = FirebaseFirestore.instance.batch();

    for (final doc in oldPlans.docs) {
      deleteBatch.delete(doc.reference);
    }

    await deleteBatch.commit();

    final QuerySnapshot foodSnapshot = await FirebaseFirestore.instance
        .collectionGroup('foods')
        .limit(300)
        .get();

    final List<QueryDocumentSnapshot> foodDocs = foodSnapshot.docs.where((doc) {
      final Map<String, dynamic> foodData =
          doc.data() as Map<String, dynamic>? ?? {};

      final bool isActive = foodData['isActive'] != false;
      if (!isActive) return false;

      final double calories = _toDouble(foodData['calories']);
      final double sugar = _toDouble(foodData['sugar']);
      final double fat = _toDouble(foodData['fat']);
      final double sodium = _toDouble(foodData['sodium']);
      final double carb = _toDouble(foodData['carb']);

      if (calories <= 0) return false;

      if (calories > targetCalories) return false;
      if (sugar > targetSugar) return false;
      if (fat > targetFat) return false;
      if (sodium > targetSodium) return false;
      if (carb > targetCarb) return false;

      return true;
    }).toList();

    if (foodDocs.isEmpty) {
      throw Exception('ไม่พบเมนูจากร้านค้าที่ตรงกับเป้าหมายโภชนาการนี้');
    }

    foodDocs.sort((a, b) {
      final Map<String, dynamic> dataA =
          a.data() as Map<String, dynamic>? ?? {};
      final Map<String, dynamic> dataB =
          b.data() as Map<String, dynamic>? ?? {};

      final double scoreA = _calculateFoodScore(
        foodData: dataA,
        targetCalories: targetCalories,
        targetSugar: targetSugar,
        targetFat: targetFat,
        targetSodium: targetSodium,
        targetProtein: targetProtein,
        targetCarb: targetCarb,
      );

      final double scoreB = _calculateFoodScore(
        foodData: dataB,
        targetCalories: targetCalories,
        targetSugar: targetSugar,
        targetFat: targetFat,
        targetSodium: targetSodium,
        targetProtein: targetProtein,
        targetCarb: targetCarb,
      );

      return scoreA.compareTo(scoreB);
    });

    final List<QueryDocumentSnapshot> selectedFoods = foodDocs.take(3).toList();

    final WriteBatch batch = FirebaseFirestore.instance.batch();

    for (int i = 0; i < selectedFoods.length; i++) {
      final QueryDocumentSnapshot foodDoc = selectedFoods[i];

      final Map<String, dynamic> foodData =
          foodDoc.data() as Map<String, dynamic>? ?? {};

      final DocumentReference? restaurantRef = foodDoc.reference.parent.parent;

      if (restaurantRef == null) continue;

      final DocumentSnapshot restaurantDoc = await restaurantRef.get();

      final Map<String, dynamic> restaurantData =
          restaurantDoc.data() as Map<String, dynamic>? ?? {};

      final String restaurantId = restaurantDoc.id;
      final String restaurantName = _toText(
        restaurantData['name'],
        defaultValue: 'ร้านอาหาร',
      );

      final String mealType = i == 0
          ? 'เช้า'
          : i == 1
              ? 'กลางวัน'
              : 'เย็น';

      final DocumentReference planRef =
          FirebaseFirestore.instance.collection('challenge_meal_plans').doc();

      batch.set(planRef, {
        'userId': userId,
        'challengeId': challengeId,
        'mealType': mealType,
        'restaurantId': restaurantId,
        'restaurantName': restaurantName,
        'foodId': foodDoc.id,
        'foodName': foodData['name'] ??
            foodData['foodName'] ??
            foodData['menuName'] ??
            'เมนูอาหาร',
        'foodImageUrl': foodData['imageUrl'] ??
            foodData['image'] ??
            foodData['photoUrl'] ??
            '',
        'calories': _toDouble(foodData['calories']),
        'protein': _toDouble(foodData['protein']),
        'carb': _toDouble(foodData['carb']),
        'sugar': _toDouble(foodData['sugar']),
        'fat': _toDouble(foodData['fat']),
        'sodium': _toDouble(foodData['sodium']),
        'userDiseases': const [],
        'riskFilter': 'general_nutrition_only',
        'isEaten': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<void> _createChallenge() async {
    final User? user = currentUser;

    if (user == null) {
      _showSnackBar('กรุณาเข้าสู่ระบบก่อนสร้างชาเลนจ์', success: false);
      return;
    }

    final String title = titleController.text.trim();
    final double targetCalories = _toDouble(caloriesController.text.trim());
    final double targetSugar = _toDouble(sugarController.text.trim());
    final double targetFat = _toDouble(fatController.text.trim());
    final double targetProtein = _toDouble(proteinController.text.trim());
    final double targetCarb = _toDouble(carbController.text.trim());
    final double targetSodium = _toDouble(sodiumController.text.trim());

    if (title.isEmpty) {
      _showSnackBar('กรุณากรอกชื่อชาเลนจ์', success: false);
      return;
    }

    if (targetCalories <= 0 ||
        targetSugar <= 0 ||
        targetFat <= 0 ||
        targetProtein <= 0 ||
        targetCarb <= 0 ||
        targetSodium <= 0) {
      _showSnackBar('กรุณากรอกเป้าหมายโภชนาการให้ครบ', success: false);
      return;
    }

    try {
      setState(() {
        isCreatingChallenge = true;
      });

      final DocumentReference challengeRef =
          FirebaseFirestore.instance.collection('nutrition_challenges').doc();

      final int rewardPoint = _getRewardPoint(selectedPeriod);
      final DateTime startDate = DateTime.now();
      final DateTime endDate = _getEndDate(selectedPeriod);

      await challengeRef.set({
        'userId': user.uid,
        'title': title,
        'periodType': selectedPeriod,
        'periodText': _getPeriodText(selectedPeriod),
        'targetCalories': targetCalories,
        'targetSugar': targetSugar,
        'targetFat': targetFat,
        'targetProtein': targetProtein,
        'targetCarb': targetCarb,
        'targetSodium': targetSodium,
        'pointsReward': rewardPoint,
        'status': 'active',
        'isRewardClaimed': false,
        'userDiseases': const [],
        'riskRule': 'general_nutrition_only',
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      bool mealPlanCreated = true;

      try {
        await _generateMealPlanForChallenge(
          challengeId: challengeRef.id,
          userId: user.uid,
          targetCalories: targetCalories,
          targetSugar: targetSugar,
          targetFat: targetFat,
          targetSodium: targetSodium,
          targetProtein: targetProtein,
          targetCarb: targetCarb,
          userDiseases: const [],
        );
      } catch (_) {
        mealPlanCreated = false;
      }

      if (!mounted) return;

      Navigator.pop(context);

      if (mealPlanCreated) {
        _showSnackBar('สร้างชาเลนจ์สำเร็จ และจัดเมนูให้แล้ว');
      } else {
        _showSnackBar(
          'สร้างชาเลนจ์สำเร็จ แต่ยังไม่พบเมนูที่ตรงกับเป้าหมาย',
          success: true,
        );
      }
    } catch (e) {
      _showSnackBar('สร้างชาเลนจ์ไม่สำเร็จ: $e', success: false);
    } finally {
      if (mounted) {
        setState(() {
          isCreatingChallenge = false;
        });
      }
    }
  }

  Future<void> _regenerateMealPlan({
    required String challengeId,
    required Map<String, dynamic> challengeData,
  }) async {
    final User? user = currentUser;

    if (user == null) {
      _showSnackBar('กรุณาเข้าสู่ระบบก่อน', success: false);
      return;
    }

    try {
      setState(() {
        isRegeneratingPlan = true;
      });

      await _generateMealPlanForChallenge(
        challengeId: challengeId,
        userId: user.uid,
        targetCalories: _toDouble(challengeData['targetCalories']),
        targetSugar: _toDouble(challengeData['targetSugar']),
        targetFat: _toDouble(challengeData['targetFat']),
        targetSodium: _toDouble(challengeData['targetSodium']),
        targetProtein: _toDouble(challengeData['targetProtein']),
        targetCarb: _toDouble(challengeData['targetCarb']),
        userDiseases: const [],
      );

      _showSnackBar('จัดเมนูใหม่สำเร็จ');
    } catch (e) {
      _showSnackBar('จัดเมนูใหม่ไม่สำเร็จ: $e', success: false);
    } finally {
      if (mounted) {
        setState(() {
          isRegeneratingPlan = false;
        });
      }
    }
  }

  Future<void> _cancelChallenge({
    required String challengeId,
  }) async {
    final User? user = currentUser;

    if (user == null) {
      _showSnackBar('กรุณาเข้าสู่ระบบก่อน', success: false);
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text('ยกเลิกชาเลนจ์'),
          content: const Text(
            'ต้องการยกเลิกชาเลนจ์นี้ใช่ไหม?\nเมนูที่ระบบจัดไว้จะถูกลบออกด้วย',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ไม่ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: dangerRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('ยืนยันยกเลิก'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final WriteBatch batch = FirebaseFirestore.instance.batch();

      final DocumentReference challengeRef = FirebaseFirestore.instance
          .collection('nutrition_challenges')
          .doc(challengeId);

      batch.update(challengeRef, {
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final QuerySnapshot planSnapshot = await FirebaseFirestore.instance
          .collection('challenge_meal_plans')
          .where('challengeId', isEqualTo: challengeId)
          .where('userId', isEqualTo: user.uid)
          .get();

      for (final doc in planSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      _showSnackBar('ยกเลิกชาเลนจ์แล้ว');
    } catch (e) {
      _showSnackBar('ยกเลิกชาเลนจ์ไม่สำเร็จ: $e', success: false);
    }
  }

  Future<void> _toggleMealEaten({
    required String planId,
    required bool currentValue,
  }) async {
    await FirebaseFirestore.instance
        .collection('challenge_meal_plans')
        .doc(planId)
        .update({
      'isEaten': !currentValue,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _claimReward({
    required String challengeId,
    required int pointsReward,
  }) async {
    final User? user = currentUser;

    if (user == null) {
      _showSnackBar('กรุณาเข้าสู่ระบบก่อน', success: false);
      return;
    }

    try {
      final QuerySnapshot planSnapshot = await FirebaseFirestore.instance
          .collection('challenge_meal_plans')
          .where('challengeId', isEqualTo: challengeId)
          .where('userId', isEqualTo: user.uid)
          .get();

      if (planSnapshot.docs.isEmpty) {
        _showSnackBar('ยังไม่มีเมนูในชาเลนจ์นี้', success: false);
        return;
      }

      final bool allEaten = planSnapshot.docs.every((doc) {
        final Map<String, dynamic> data =
            doc.data() as Map<String, dynamic>? ?? {};
        return data['isEaten'] == true;
      });

      if (!allEaten) {
        _showSnackBar(
          'ต้องทำเครื่องหมายว่ากินครบทุกมื้อก่อนรับคะแนน',
          success: false,
        );
        return;
      }

      final WriteBatch batch = FirebaseFirestore.instance.batch();

      final DocumentReference userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      final DocumentReference challengeRef = FirebaseFirestore.instance
          .collection('nutrition_challenges')
          .doc(challengeId);

      final DocumentReference transactionRef =
          FirebaseFirestore.instance.collection('point_transactions').doc();

      batch.update(userRef, {
        'points': FieldValue.increment(pointsReward),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      batch.update(challengeRef, {
        'isRewardClaimed': true,
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      batch.set(transactionRef, {
        'userId': user.uid,
        'challengeId': challengeId,
        'type': 'challenge_reward',
        'points': pointsReward,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      _showSnackBar('รับคะแนนสำเร็จ +$pointsReward points');
    } catch (e) {
      _showSnackBar('รับคะแนนไม่สำเร็จ: $e', success: false);
    }
  }

  void _showCreateChallengeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.92,
                ),
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 48,
                          height: 5,
                          decoration: BoxDecoration(
                            color: borderColor,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: mintGreen,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.flag_rounded,
                              color: primaryGreen,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'สร้างชาเลนจ์โภชนาการ',
                                  style: TextStyle(
                                    color: darkText,
                                    fontSize: 21,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'สำหรับผู้ใช้ทั่วไปที่ไม่ได้เลือกโรค',
                                  style: TextStyle(
                                    color: grayText,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: softBlue,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: blue.withValues(alpha: 0.18),
                          ),
                        ),
                        child: const Text(
                          'ระบบจะเลือกเมนูจากร้านอาหาร โดยดูจากเป้าหมายแคลอรี่ น้ำตาล ไขมัน คาร์โบไฮเดรต และโซเดียม',
                          style: TextStyle(
                            color: Color(0xFF075985),
                            fontSize: 13,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildSheetTextField(
                        controller: titleController,
                        label: 'ชื่อชาเลนจ์',
                        icon: Icons.flag_rounded,
                      ),
                      const SizedBox(height: 12),
                      _buildPeriodSelector(setModalState),
                      const SizedBox(height: 12),
                      _buildSheetTextField(
                        controller: caloriesController,
                        label: 'แคลอรี่สูงสุด (kcal)',
                        icon: Icons.local_fire_department_rounded,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSheetTextField(
                              controller: sugarController,
                              label: 'น้ำตาล (g)',
                              icon: Icons.cake_rounded,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildSheetTextField(
                              controller: fatController,
                              label: 'ไขมัน (g)',
                              icon: Icons.opacity_rounded,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSheetTextField(
                              controller: proteinController,
                              label: 'โปรตีน (g)',
                              icon: Icons.fitness_center_rounded,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildSheetTextField(
                              controller: carbController,
                              label: 'คาร์โบไฮเดรต (g)',
                              icon: Icons.rice_bowl_rounded,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildSheetTextField(
                        controller: sodiumController,
                        label: 'โซเดียมสูงสุด (mg)',
                        icon: Icons.water_drop_rounded,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 18),
                      _buildRewardPreview(),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: isCreatingChallenge
                              ? null
                              : () async {
                                  await _createChallenge();
                                  setModalState(() {});
                                },
                          icon: isCreatingChallenge
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.add_rounded),
                          label: Text(
                            isCreatingChallenge
                                ? 'กำลังสร้าง...'
                                : 'สร้างชาเลนจ์',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSheetTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryGreen),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: primaryGreen, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(void Function(void Function()) setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ระยะเวลา',
          style: TextStyle(
            color: darkText,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildPeriodChip(
              label: 'รายวัน',
              value: 'daily',
              icon: Icons.today_rounded,
              setModalState: setModalState,
            ),
            const SizedBox(width: 8),
            _buildPeriodChip(
              label: 'รายสัปดาห์',
              value: 'weekly',
              icon: Icons.calendar_view_week_rounded,
              setModalState: setModalState,
            ),
            const SizedBox(width: 8),
            _buildPeriodChip(
              label: 'รายเดือน',
              value: 'monthly',
              icon: Icons.calendar_month_rounded,
              setModalState: setModalState,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPeriodChip({
    required String label,
    required String value,
    required IconData icon,
    required void Function(void Function()) setModalState,
  }) {
    final bool selected = selectedPeriod == value;

    return Expanded(
      child: InkWell(
        onTap: () {
          setModalState(() {
            selectedPeriod = value;
          });
          setState(() {
            selectedPeriod = value;
          });
        },
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? mintGreen : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? primaryGreen : borderColor,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? primaryGreen : lightText,
                size: 20,
              ),
              const SizedBox(height: 5),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? primaryGreen : grayText,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRewardPreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFFBEB),
            Color(0xFFFFF7ED),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: warningOrange.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: warningOrange.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: warningOrange,
              size: 25,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'รางวัล ${_getPeriodText(selectedPeriod)}: ${_getRewardPoint(selectedPeriod)} points',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF92400E),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(int points) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF16A34A),
            Color(0xFF22C55E),
            Color(0xFF14B8A6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ชาเลนจ์โภชนาการ',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'จัดเมนูจากร้านค้าให้เหมาะกับเป้าหมายของคุณ',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$points points',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientGrid(Map<String, dynamic> data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double itemWidth = (constraints.maxWidth - 8) / 2;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SizedBox(
              width: itemWidth,
              height: 84,
              child: _buildNutrientBox(
                'แคล',
                '${_toDouble(data['targetCalories']).toStringAsFixed(0)} kcal',
                Icons.local_fire_department_rounded,
                warningOrange,
                softOrange,
              ),
            ),
            SizedBox(
              width: itemWidth,
              height: 84,
              child: _buildNutrientBox(
                'น้ำตาล',
                '${_toDouble(data['targetSugar']).toStringAsFixed(0)} g',
                Icons.cake_rounded,
                purple,
                softPurple,
              ),
            ),
            SizedBox(
              width: itemWidth,
              height: 84,
              child: _buildNutrientBox(
                'ไขมัน',
                '${_toDouble(data['targetFat']).toStringAsFixed(0)} g',
                Icons.opacity_rounded,
                blue,
                softBlue,
              ),
            ),
            SizedBox(
              width: itemWidth,
              height: 84,
              child: _buildNutrientBox(
                'โปรตีน',
                '${_toDouble(data['targetProtein']).toStringAsFixed(0)} g',
                Icons.fitness_center_rounded,
                primaryGreen,
                mintGreen,
              ),
            ),
            SizedBox(
              width: itemWidth,
              height: 84,
              child: _buildNutrientBox(
                'คาร์โบไฮเดรต',
                '${_toDouble(data['targetCarb']).toStringAsFixed(0)} g',
                Icons.rice_bowl_rounded,
                warningOrange,
                softOrange,
              ),
            ),
            SizedBox(
              width: itemWidth,
              height: 84,
              child: _buildNutrientBox(
                'โซเดียม',
                '${_toDouble(data['targetSodium']).toStringAsFixed(0)} mg',
                Icons.water_drop_rounded,
                blue,
                softBlue,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNutrientBox(
    String label,
    String value,
    IconData icon,
    Color iconColor,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 19,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: grayText,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: const TextStyle(
                      color: darkText,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard({
    required String challengeId,
    required Map<String, dynamic> data,
  }) {
    final String title = _toText(data['title'], defaultValue: 'ชาเลนจ์');
    final String periodText = _toText(
      data['periodText'],
      defaultValue: _getPeriodText(data['periodType'] ?? 'daily'),
    );
    final int pointsReward = (data['pointsReward'] as num?)?.toInt() ?? 100;
    final bool isRewardClaimed = data['isRewardClaimed'] == true;
    final String status = _toText(data['status'], defaultValue: 'active');

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: softOrange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.flag_rounded,
                  color: warningOrange,
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: darkText,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$periodText · รับ $pointsReward points',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: grayText,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                constraints: const BoxConstraints(maxWidth: 86),
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: status == 'completed' ? mintGreen : softOrange,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status == 'completed' ? 'สำเร็จ' : 'กำลังทำ',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: status == 'completed'
                        ? primaryGreen
                        : warningOrange,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildNutrientGrid(data),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.event_available_rounded,
                color: lightText,
                size: 18,
              ),
              const SizedBox(width: 5),
              Text(
                'สิ้นสุด: ${_formatDate(data['endDate'])}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: grayText,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMealPlanList(challengeId),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: isRegeneratingPlan
                        ? null
                        : () => _regenerateMealPlan(
                              challengeId: challengeId,
                              challengeData: data,
                            ),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('จัดใหม่'),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryGreen,
                      side: const BorderSide(color: primaryGreen),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () => _cancelChallenge(challengeId: challengeId),
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('ยกเลิก'),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: dangerRed,
                      side: const BorderSide(color: dangerRed),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: isRewardClaimed
                  ? null
                  : () => _claimReward(
                        challengeId: challengeId,
                        pointsReward: pointsReward,
                      ),
              icon: Icon(
                isRewardClaimed
                    ? Icons.check_circle_rounded
                    : Icons.emoji_events_rounded,
                size: 20,
              ),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  isRewardClaimed ? 'รับคะแนนแล้ว' : 'รับรางวัล',
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                disabledBackgroundColor: grayText.withValues(alpha: 0.35),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealPlanList(String challengeId) {
    final User? user = currentUser;

    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('challenge_meal_plans')
          .where('challengeId', isEqualTo: challengeId)
          .where('userId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(
              child: CircularProgressIndicator(color: primaryGreen),
            ),
          );
        }

        if (snapshot.hasError) {
          return Text(
            'โหลดเมนูไม่สำเร็จ: ${snapshot.error}',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: dangerRed,
              fontSize: 12,
            ),
          );
        }

        final List<QueryDocumentSnapshot> plans = snapshot.data?.docs ?? [];

        if (plans.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: softGreen,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: mintGreen),
            ),
            child: const Text(
              'สร้างชาเลนจ์แล้ว แต่ยังไม่มีเมนูที่ตรงกับเป้าหมาย ลองกด “จัดใหม่” หรือเพิ่มค่าเป้าหมายให้กว้างขึ้น',
              style: TextStyle(
                color: grayText,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          );
        }

        plans.sort((a, b) {
          final Map<String, dynamic> dataA =
              a.data() as Map<String, dynamic>? ?? {};
          final Map<String, dynamic> dataB =
              b.data() as Map<String, dynamic>? ?? {};

          final List<String> order = ['เช้า', 'กลางวัน', 'เย็น'];

          return order
              .indexOf(_toText(dataA['mealType']))
              .compareTo(order.indexOf(_toText(dataB['mealType'])));
        });

        return Column(
          children: plans.map((doc) {
            final Map<String, dynamic> data =
                doc.data() as Map<String, dynamic>? ?? {};

            return _buildMealCard(
              planId: doc.id,
              data: data,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildMealCard({
    required String planId,
    required Map<String, dynamic> data,
  }) {
    final String mealType = _toText(data['mealType'], defaultValue: 'มื้อ');
    final String foodName =
        _toText(data['foodName'], defaultValue: 'เมนูอาหาร');
    final String restaurantName =
        _toText(data['restaurantName'], defaultValue: 'ร้านอาหาร');
    final bool isEaten = data['isEaten'] == true;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isEaten ? softGreen : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isEaten ? primaryGreen.withValues(alpha: 0.35) : borderColor,
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => _toggleMealEaten(
              planId: planId,
              currentValue: isEaten,
            ),
            borderRadius: BorderRadius.circular(999),
            child: Icon(
              isEaten
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isEaten ? primaryGreen : lightText,
              size: 28,
            ),
          ),
          const SizedBox(width: 9),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isEaten ? mintGreen : Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isEaten ? mintGreen : borderColor,
              ),
            ),
            child: Icon(
              Icons.restaurant_rounded,
              color: isEaten ? primaryGreen : grayText,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$mealType · $foodName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: darkText,
                    fontSize: 13.8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  restaurantName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: grayText,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_toDouble(data['calories']).toStringAsFixed(0)} kcal · น้ำตาล ${_toDouble(data['sugar']).toStringAsFixed(0)}g · โซเดียม ${_toDouble(data['sodium']).toStringAsFixed(0)}mg',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: grayText,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeList() {
    final User? user = currentUser;

    if (user == null) {
      return const Center(
        child: Text(
          'กรุณาเข้าสู่ระบบ',
          style: TextStyle(color: grayText),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('nutrition_challenges')
          .where('userId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: primaryGreen),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'โหลดชาเลนจ์ไม่สำเร็จ: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: dangerRed,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }

        final List<QueryDocumentSnapshot> challenges =
            (snapshot.data?.docs ?? []).where((doc) {
          final Map<String, dynamic> data =
              doc.data() as Map<String, dynamic>? ?? {};
          final String status = _toText(data['status'], defaultValue: 'active');
          return status != 'cancelled';
        }).toList();

        challenges.sort((a, b) {
          final Map<String, dynamic> dataA =
              a.data() as Map<String, dynamic>? ?? {};
          final Map<String, dynamic> dataB =
              b.data() as Map<String, dynamic>? ?? {};

          final Timestamp? timeA = dataA['createdAt'] is Timestamp
              ? dataA['createdAt'] as Timestamp
              : null;

          final Timestamp? timeB = dataB['createdAt'] is Timestamp
              ? dataB['createdAt'] as Timestamp
              : null;

          return (timeB?.millisecondsSinceEpoch ?? 0)
              .compareTo(timeA?.millisecondsSinceEpoch ?? 0);
        });

        if (challenges.isEmpty) {
          return _buildEmptyChallenge();
        }

        return Column(
          children: challenges.map((doc) {
            final Map<String, dynamic> data =
                doc.data() as Map<String, dynamic>? ?? {};

            return _buildChallengeCard(
              challengeId: doc.id,
              data: data,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildEmptyChallenge() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: mintGreen,
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(
              Icons.emoji_events_outlined,
              color: primaryGreen,
              size: 48,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'ยังไม่มีชาเลนจ์',
            style: TextStyle(
              color: darkText,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'กดปุ่มสร้าง เพื่อให้ระบบจัดเมนูจากร้านค้าให้คุณ',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: grayText,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showCreateChallengeSheet,
            icon: const Icon(Icons.add_rounded),
            label: const Text('สร้างชาเลนจ์'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    final User? user = currentUser;

    if (user == null) {
      return const Center(
        child: Text(
          'กรุณาเข้าสู่ระบบ',
          style: TextStyle(color: grayText),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final Map<String, dynamic> userData =
            snapshot.data?.data() as Map<String, dynamic>? ?? {};

        final int points = (userData['points'] as num?)?.toInt() ?? 0;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(points),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'ชาเลนจ์ของฉัน',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: darkText,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _showCreateChallengeSheet,
                    icon: const Icon(Icons.add_rounded, size: 19),
                    label: const Text('สร้าง'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildChallengeList(),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: darkText,
        elevation: 0,
        title: const Text(
          'ชาเลนจ์',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          _buildMainContent(),
          if (isRegeneratingPlan)
            Container(
              color: Colors.black.withValues(alpha: 0.12),
              child: const Center(
                child: CircularProgressIndicator(color: primaryGreen),
              ),
            ),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 2,
        onTap: _handleNavTap,
      ),
    );
  }
}