import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../components/animated_tap_card.dart';
import '../components/app_bottom_nav_bar.dart';
import '../components/home_top_card_carousel.dart';
import '../utils/smooth_route.dart';

import 'analyze_food_page.dart';
import 'challenge_page.dart';
import 'disease_nutrition_page.dart';
import 'expert_list_page.dart';
import 'map_page.dart';
import 'profile_page.dart';
import 'subscription_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFFE8F5E9);
  static const Color backgroundColor = Color(0xFFF8FBF8);
  static const Color darkText = Color(0xFF1F2937);
  static const Color grayText = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color warningOrange = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        titleSpacing: 16,
        title: Image.asset(
          'assets/images/app_logo_wide.png',
          height: 42,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Text(
              'FoodSight',
              style: TextStyle(
                color: darkText,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            );
          },
        ),
        actions: [
          IconButton(
            onPressed: () => _goToProfile(context),
            icon: const Icon(
              Icons.person_outline_rounded,
              color: primaryGreen,
            ),
          ),
        ],
      ),
      body: currentUser == null
          ? _buildHomeContent(
              context: context,
              name: 'ผู้ใช้',
              diseases: const [],
              isLoggedIn: false,
              userData: null,
            )
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryGreen),
                  );
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return _buildHomeContent(
                    context: context,
                    name: currentUser.email ?? 'ผู้ใช้',
                    diseases: const [],
                    isLoggedIn: true,
                    userData: null,
                  );
                }

                final Map<String, dynamic> userData =
                    snapshot.data!.data() as Map<String, dynamic>? ?? {};

                final String name = _toText(
                  userData['name'],
                  defaultValue: 'ผู้ใช้',
                );

                final List diseases =
                    userData['diseases'] is List ? userData['diseases'] : [];

                return _buildHomeContent(
                  context: context,
                  name: name,
                  diseases: diseases,
                  isLoggedIn: true,
                  userData: userData,
                );
              },
            ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  void _goToProfile(BuildContext context) {
    Navigator.push(
      context,
      smoothRoute(const ProfilePage()),
    );
  }

  void _goToAnalyzeFood(BuildContext context) {
    Navigator.push(
      context,
      smoothRoute(const AnalyzeFoodPage()),
    );
  }

  void _goToMap(BuildContext context) {
    Navigator.push(
      context,
      smoothRoute(const MapPage()),
    );
  }

  void _goToDiseaseNutrition(BuildContext context) {
    Navigator.push(
      context,
      smoothRoute(const DiseaseNutritionPage()),
    );
  }

  void _goToSubscriptionDetail(BuildContext context) {
    Navigator.push(
      context,
      smoothRoute(
        const SubscriptionDetailPage(
          title: 'แพ็กเกจสมาชิก',
          price: 'Free / 99 / 199 บาทต่อเดือน',
          description:
              'รายละเอียดโปรโมชั่นของแพ็กเกจสมาชิกในแอป FoodSight สำหรับผู้ใช้ทั่วไปและผู้ที่ต้องการดูแลสุขภาพแบบจริงจัง หน้านี้เป็นหน้าดูรายละเอียดเท่านั้น ยังไม่ได้เชื่อมระบบชำระเงินจริง',
          primaryColor: Color(0xFF0F766E),
          icon: Icons.workspace_premium_rounded,
          features: [
            'Free Version: วิเคราะห์อาหารจากภาพได้ 2 รูปต่อวัน',
            'Free Version: ดูข้อมูลโภชนาการพื้นฐาน',
            'Free Version: มีการแสดงโฆษณาภายในแอป',
            'Premium 99 บาท/เดือน: วิเคราะห์อาหารจากภาพไม่จำกัด',
            'Premium 99 บาท/เดือน: ระบุโรคได้หลายโรคพร้อมกัน',
            'Premium 99 บาท/เดือน: แนะนำเมนูเฉพาะบุคคล',
            'Premium 99 บาท/เดือน: แนะนำร้านอาหารที่เหมาะกับโรค',
            'Premium 99 บาท/เดือน: ระบบ Challenge สะสม Point',
            'Premium Plus 199 บาท/เดือน: ฟีเจอร์ทั้งหมดของ Premium',
            'Premium Plus 199 บาท/เดือน: Chat ผู้เชี่ยวชาญด้านโภชนาการ',
            'Premium Plus 199 บาท/เดือน: จำกัด 10–20 คำถามต่อเดือน',
            'Premium Plus 199 บาท/เดือน: รับคำตอบภายใน 24 ชั่วโมง',
            'รายได้จากพันธมิตร: ค่าคอมมิชชันจากร้านอาหารพันธมิตร',
            'รายได้จากพันธมิตร: ค่าบริการโปรโมทร้านอาหารและโฆษณาภายในแอป',
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent({
    required BuildContext context,
    required String name,
    required List diseases,
    required bool isLoggedIn,
    required Map<String, dynamic>? userData,
  }) {
    final _BmiInfo? bmiInfo = _getBmiInfo(userData);
    final int points = _toInt(userData?['points']);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGreetingSection(name),
          const SizedBox(height: 16),
          _buildHealthSummaryCard(
            context: context,
            diseases: diseases,
            isLoggedIn: isLoggedIn,
            bmiInfo: bmiInfo,
            points: points,
          ),
          const SizedBox(height: 20),
          _buildShortcutGrid(
            context: context,
            diseases: diseases,
            userData: userData,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(
            title: 'เมนูแนะนำสำหรับคุณ',
            actionText: 'ดูทั้งหมด',
            onTap: () {
              _showAllRecommendedFoods(
                context: context,
                diseases: diseases,
                userData: userData,
              );
            },
          ),
          const SizedBox(height: 12),
          _buildRecommendedFoodsFromFirebase(
            diseases: diseases,
            userData: userData,
            limit: 2,
            showBmiBanner: true,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(
            title: 'ร้านอาหารใกล้คุณ',
            actionText: 'ดูแผนที่',
            onTap: () => _goToMap(context),
          ),
          const SizedBox(height: 12),
          _buildNearbyRestaurantsFromFirebase(context),
        ],
      ),
    );
  }

  Widget _buildGreetingSection(String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'สวัสดี, $name ',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: darkText,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'เลือกอาหารที่เหมาะกับสุขภาพของคุณวันนี้',
          style: TextStyle(
            fontSize: 15,
            color: grayText,
          ),
        ),
      ],
    );
  }

  Widget _buildHealthSummaryCard({
    required BuildContext context,
    required List diseases,
    required bool isLoggedIn,
    required _BmiInfo? bmiInfo,
    required int points,
  }) {
    final String diseaseText =
        diseases.isEmpty ? 'ยังไม่ได้เลือกโรค' : diseases.join(', ');

    final String bmiText = bmiInfo == null
        ? 'ยังไม่มีข้อมูล'
        : '${bmiInfo.value.toStringAsFixed(1)} (${bmiInfo.category})';

    return HomeTopCardCarousel(
      diseaseText: diseaseText,
      bmiText: bmiText,
      isLoggedIn: isLoggedIn,
      points: points,
      onHealthTap: () => _goToProfile(context),
      onNutritionControlTap: () => _goToDiseaseNutrition(context),
      onSubscriptionTap: () => _goToSubscriptionDetail(context),
    );
  }

  Widget _buildShortcutGrid({
    required BuildContext context,
    required List diseases,
    required Map<String, dynamic>? userData,
  }) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: [
        _buildShortcutCard(
          icon: Icons.camera_alt_rounded,
          title: 'วิเคราะห์อาหาร',
          subtitle: 'ถ่ายรูปหรืออัปโหลดรูป',
          color: primaryGreen,
          onTap: () => _goToAnalyzeFood(context),
        ),
        _buildShortcutCard(
          icon: Icons.restaurant_menu_rounded,
          title: 'เมนูแนะนำ',
          subtitle: 'ตามข้อควบคุมโภชนาการ',
          color: const Color(0xFF10B981),
          onTap: () {
            _showAllRecommendedFoods(
              context: context,
              diseases: diseases,
              userData: userData,
            );
          },
        ),
        _buildShortcutCard(
          icon: Icons.map_rounded,
          title: 'ร้านใกล้ฉัน',
          subtitle: 'หาร้านอาหารสุขภาพ',
          color: const Color(0xFF0EA5E9),
          onTap: () => _goToMap(context),
        ),
        _buildShortcutCard(
          icon: Icons.medical_information_rounded,
          title: 'ข้อควบคุม',
          subtitle: 'โภชนาการตามโรค',
          color: warningOrange,
          onTap: () => _goToDiseaseNutrition(context),
        ),
      ],
    );
  }

  Widget _buildShortcutCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AnimatedTapCard(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: color,
                size: 23,
              ),
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.bold,
                color: darkText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                height: 1.2,
                color: grayText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedFoodsFromFirebase({
    required List diseases,
    required Map<String, dynamic>? userData,
    required int limit,
    required bool showBmiBanner,
  }) {
    final _BmiInfo? bmiInfo = _getBmiInfo(userData);
    final List<String> selectedDiseases =
        diseases.map((item) => item.toString()).toList();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collectionGroup('foods').snapshots(),
      builder: (context, foodSnapshot) {
        if (foodSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: primaryGreen),
            ),
          );
        }

        if (foodSnapshot.hasError) {
          return _buildEmptyState(
            icon: Icons.error_outline_rounded,
            text: 'โหลดเมนูไม่สำเร็จ: ${foodSnapshot.error}',
          );
        }

        if (!foodSnapshot.hasData || foodSnapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.restaurant_menu_rounded,
            text:
                'ยังไม่พบเมนูใน Firebase\nต้องมีข้อมูลที่ restaurants/{restaurantId}/foods',
          );
        }

        final List<_RecommendedFoodItem> displayFoods =
            _prepareRecommendedFoods(
          docs: foodSnapshot.data!.docs,
          selectedDiseases: selectedDiseases,
          bmiInfo: bmiInfo,
          limit: limit,
        );

        if (displayFoods.isEmpty) {
          return _buildEmptyState(
            icon: Icons.restaurant_menu_rounded,
            text: 'ยังไม่มีเมนูที่นำมาแนะนำได้',
          );
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: Column(
            key: ValueKey<int>(displayFoods.length),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showBmiBanner)
                _buildRecommendationBanner(
                  diseases: selectedDiseases,
                  bmiInfo: bmiInfo,
                ),
              ...displayFoods.map((item) => _buildRecommendedFoodCard(item)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecommendationBanner({
    required List<String> diseases,
    required _BmiInfo? bmiInfo,
  }) {
    String text;

    if (diseases.isNotEmpty) {
      text = diseases.length == 1
          ? 'ระบบเลือกเมนูจากอาหารที่แนะนำสำหรับ ${diseases.first}'
          : 'ระบบเลือกเมนูจากอาหารที่แนะนำและเหมาะกับโรคที่คุณเลือก';
    } else if (bmiInfo != null) {
      text =
          'BMI: ${bmiInfo.value.toStringAsFixed(1)} (${bmiInfo.category}) ระบบจะแนะนำเมนูตาม BMI';
    } else {
      text = 'ระบบแนะนำเมนูทั่วไปที่ยังรับประทานได้';
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: primaryGreen,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  List<_RecommendedFoodItem> _prepareRecommendedFoods({
    required List<QueryDocumentSnapshot> docs,
    required List<String> selectedDiseases,
    required _BmiInfo? bmiInfo,
    required int limit,
  }) {
    final List<_RecommendedFoodItem> nutritionGuideFoods = [];
    final List<_RecommendedFoodItem> lowRiskFoods = [];
    final List<_RecommendedFoodItem> mediumRiskFoods = [];
    final List<_RecommendedFoodItem> bmiFoods = [];
    final List<_RecommendedFoodItem> fallbackFoods = [];

    for (final doc in docs) {
      final Map<String, dynamic> rawFood =
          doc.data() as Map<String, dynamic>? ?? {};

      final DocumentReference? restaurantRef = doc.reference.parent.parent;

      final Map<String, dynamic> food = {
        ...rawFood,
        'restaurantId': rawFood['restaurantId'] ?? restaurantRef?.id ?? '',
      };

      final bool isActive = food['isActive'] != false;
      if (!isActive) continue;

      final String status = _toText(
        food['status'],
        defaultValue: 'ควรระวัง',
      );

      final int calories = _toInt(food['calories']);
      final int fat = _toInt(food['fat']);
      final int protein = _toInt(food['protein']);
      int score = _toInt(food['suitableScore']);

      if (selectedDiseases.isNotEmpty) {
        final _RiskSummary riskSummary = _getRiskSummaryForDiseases(
          food: food,
          diseases: selectedDiseases,
        );

        if (riskSummary.hasHighRisk) continue;

        final bool matchNutritionGuide = _matchNutritionGuideRecommendedFood(
          food: food,
          diseases: selectedDiseases,
        );

        if (matchNutritionGuide) {
          score += 120;
          nutritionGuideFoods.add(
            _RecommendedFoodItem(
              id: doc.id,
              food: food,
              finalScore: _clampScore(score),
              reason: 'ตรงกับอาหารที่แนะนำตามโรค',
            ),
          );
          continue;
        }

        if (riskSummary.allLowRisk) {
          score += 90;
          lowRiskFoods.add(
            _RecommendedFoodItem(
              id: doc.id,
              food: food,
              finalScore: _clampScore(score),
              reason: riskSummary.reason,
            ),
          );
          continue;
        }

        if (riskSummary.hasMediumRisk) {
          score += 45;
          mediumRiskFoods.add(
            _RecommendedFoodItem(
              id: doc.id,
              food: food,
              finalScore: _clampScore(score),
              reason: 'ความเสี่ยงปานกลาง ควรควบคุมปริมาณ',
            ),
          );
          continue;
        }

        fallbackFoods.add(
          _RecommendedFoodItem(
            id: doc.id,
            food: food,
            finalScore: _clampScore(score),
            reason: 'เมนูสำรองจากข้อมูลโภชนาการ',
          ),
        );

        continue;
      }

      if (bmiInfo != null) {
        if (bmiInfo.isUnderWeight) {
          if (calories >= 300 || protein >= 8) {
            score += 60;
            bmiFoods.add(
              _RecommendedFoodItem(
                id: doc.id,
                food: food,
                finalScore: _clampScore(score),
                reason: 'ช่วยเพิ่มพลังงานและโปรตีน',
              ),
            );
            continue;
          }
        }

        if (bmiInfo.isOverWeight) {
          if (calories <= 550 && fat <= 22) {
            score += 60;
            bmiFoods.add(
              _RecommendedFoodItem(
                id: doc.id,
                food: food,
                finalScore: _clampScore(score),
                reason: 'เหมาะกับการควบคุมน้ำหนัก',
              ),
            );
            continue;
          }
        }

        if (!bmiInfo.isUnderWeight && !bmiInfo.isOverWeight) {
          if (status == 'เหมาะสม' || status == 'ควรระวัง') {
            score += 35;
            bmiFoods.add(
              _RecommendedFoodItem(
                id: doc.id,
                food: food,
                finalScore: _clampScore(score),
                reason: 'เหมาะกับสุขภาพทั่วไป',
              ),
            );
            continue;
          }
        }
      }

      fallbackFoods.add(
        _RecommendedFoodItem(
          id: doc.id,
          food: food,
          finalScore: _clampScore(score),
          reason: 'เมนูแนะนำทั่วไป',
        ),
      );
    }

    nutritionGuideFoods.sort((a, b) => b.finalScore.compareTo(a.finalScore));
    lowRiskFoods.sort((a, b) => b.finalScore.compareTo(a.finalScore));
    mediumRiskFoods.sort((a, b) => b.finalScore.compareTo(a.finalScore));
    bmiFoods.sort((a, b) => b.finalScore.compareTo(a.finalScore));
    fallbackFoods.sort((a, b) => b.finalScore.compareTo(a.finalScore));

    List<_RecommendedFoodItem> merged = [];

    if (selectedDiseases.isNotEmpty) {
      merged = [
        ...nutritionGuideFoods,
        ...lowRiskFoods,
        ...mediumRiskFoods,
        ...fallbackFoods,
      ];
    } else {
      merged = [
        ...bmiFoods,
        ...fallbackFoods,
      ];
    }

    merged = _removeDuplicateFoods(merged);

    return merged.take(limit).toList();
  }

  bool _matchNutritionGuideRecommendedFood({
    required Map<String, dynamic> food,
    required List<String> diseases,
  }) {
    final String name = _toText(food['name'], defaultValue: '').toLowerCase();
    final String ingredients =
        _toText(food['ingredients'], defaultValue: '').toLowerCase();
    final String recommendation =
        _toText(food['recommendation'], defaultValue: '').toLowerCase();

    final String allText = [
      name,
      ingredients,
      recommendation,
    ].join(' ');

    final List<String> keywords = _getRecommendedFoodKeywordsByDiseases(
      diseases,
    );

    if (keywords.isEmpty) return false;

    return keywords.any((keyword) {
      return allText.contains(keyword.toLowerCase());
    });
  }

  List<String> _getRecommendedFoodKeywordsByDiseases(List<String> diseases) {
    final Set<String> keywords = {};

    for (final disease in diseases) {
      final String text = disease.trim();

      if (text.contains('เบาหวาน')) {
        keywords.addAll([
          'ข้าวกล้อง',
          'ธัญพืช',
          'อกไก่',
          'ปลา',
          'ไข่ต้ม',
          'ผัก',
          'ต้มยำ',
          'แกงส้ม',
          'ลาบ',
          'ส้มตำ',
          'ปลาทอด',
        ]);
      }

      if (text.contains('ความดัน')) {
        keywords.addAll([
          'ผัก',
          'ผลไม้',
          'ปลา',
          'อกไก่',
          'ต้ม',
          'แกงส้ม',
          'ต้มยำ',
          'ลาบ',
          'ปลาทอด',
          'ส้มตำ',
        ]);
      }

      if (text.contains('ไต')) {
        keywords.addAll([
          'ข้าว',
          'ไข่ขาว',
          'ปลา',
          'ไก่',
          'ผักต้ม',
          'ต้ม',
          'แกงส้ม',
        ]);
      }

      if (text.contains('ไขมัน')) {
        keywords.addAll([
          'ปลา',
          'อกไก่',
          'ผัก',
          'ธัญพืช',
          'ต้ม',
          'แกงส้ม',
          'ต้มยำ',
          'ลาบ',
          'ส้มตำ',
          'ปลาทอด',
        ]);
      }

      if (text.contains('อ้วน')) {
        keywords.addAll([
          'ผัก',
          'ปลา',
          'อกไก่',
          'ต้ม',
          'สุกี้',
          'แกงส้ม',
          'ต้มยำ',
          'ลาบ',
          'ส้มตำ',
        ]);
      }
    }

    return keywords.toList();
  }

  _RiskSummary _getRiskSummaryForDiseases({
    required Map<String, dynamic> food,
    required List<String> diseases,
  }) {
    int lowCount = 0;
    int mediumCount = 0;
    int highCount = 0;
    int unknownCount = 0;

    for (final disease in diseases) {
      final String risk = _getRiskLevelForDisease(
        food: food,
        disease: disease,
      );

      if (risk == 'low') {
        lowCount++;
      } else if (risk == 'medium') {
        mediumCount++;
      } else if (risk == 'high') {
        highCount++;
      } else {
        unknownCount++;
      }
    }

    if (highCount > 0) {
      return const _RiskSummary(
        allLowRisk: false,
        hasMediumRisk: false,
        hasHighRisk: true,
        reason: 'มีโรคที่เสี่ยงสูง',
      );
    }

    if (diseases.isNotEmpty && lowCount == diseases.length) {
      return _RiskSummary(
        allLowRisk: true,
        hasMediumRisk: false,
        hasHighRisk: false,
        reason: diseases.length == 1
            ? 'เสี่ยงต่ำสำหรับโรคที่คุณเลือก'
            : 'เสี่ยงต่ำกับทุกโรคที่คุณเลือก',
      );
    }

    if (mediumCount > 0 && highCount == 0) {
      return const _RiskSummary(
        allLowRisk: false,
        hasMediumRisk: true,
        hasHighRisk: false,
        reason: 'ความเสี่ยงปานกลาง ควรควบคุมปริมาณ',
      );
    }

    if (unknownCount > 0) {
      return const _RiskSummary(
        allLowRisk: false,
        hasMediumRisk: false,
        hasHighRisk: false,
        reason: 'ยังไม่มีข้อมูลความเสี่ยงครบ',
      );
    }

    return const _RiskSummary(
      allLowRisk: false,
      hasMediumRisk: false,
      hasHighRisk: false,
      reason: 'เมนูแนะนำทั่วไป',
    );
  }

  String _getRiskLevelForDisease({
    required Map<String, dynamic> food,
    required String disease,
  }) {
    final String key = _diseaseToRiskKey(disease);

    final dynamic riskLevelByDisease = food['riskLevelByDisease'];

    if (riskLevelByDisease is Map) {
      final dynamic value =
          riskLevelByDisease[key] ?? riskLevelByDisease[disease];
      final String normalized = _normalizeRisk(value);

      if (normalized != 'unknown') {
        return normalized;
      }
    }

    final dynamic risks = food['risks'];

    if (risks is Map) {
      final dynamic value = risks[key] ?? risks[disease];
      final String normalized = _normalizeRisk(value);

      if (normalized != 'unknown') {
        return normalized;
      }
    }

    final Map<String, String> oldRiskFields = {
      'diabetes': 'diabetesRisk',
      'hypertension': 'hypertensionRisk',
      'kidney': 'kidneyRisk',
      'dyslipidemia': 'dyslipidemiaRisk',
      'obesity': 'obesityRisk',
    };

    final String? oldField = oldRiskFields[key];

    if (oldField != null) {
      final String normalized = _normalizeRisk(food[oldField]);

      if (normalized != 'unknown') {
        return normalized;
      }
    }

    return 'unknown';
  }

  String _diseaseToRiskKey(String disease) {
    final String text = disease.trim();

    if (text.contains('เบาหวาน')) return 'diabetes';
    if (text.contains('ความดัน')) return 'hypertension';
    if (text.contains('ไต')) return 'kidney';
    if (text.contains('ไขมัน')) return 'dyslipidemia';
    if (text.contains('อ้วน')) return 'obesity';

    return text;
  }

  String _normalizeRisk(dynamic value) {
    if (value == null) return 'unknown';

    final String text = value.toString().trim().toLowerCase();

    if (text.isEmpty) return 'unknown';

    if (text == 'low' ||
        text == 'ต่ำ' ||
        text == 'เสี่ยงต่ำ' ||
        text.contains('low')) {
      return 'low';
    }

    if (text == 'medium' ||
        text == 'กลาง' ||
        text == 'ปานกลาง' ||
        text == 'เสี่ยงปานกลาง' ||
        text.contains('medium')) {
      return 'medium';
    }

    if (text == 'high' ||
        text == 'สูง' ||
        text == 'เสี่ยงสูง' ||
        text.contains('high')) {
      return 'high';
    }

    return 'unknown';
  }

  List<_RecommendedFoodItem> _removeDuplicateFoods(
    List<_RecommendedFoodItem> foods,
  ) {
    final Set<String> usedNames = {};
    final List<_RecommendedFoodItem> result = [];

    for (final item in foods) {
      final String rawName = _toText(
        item.food['name'],
        defaultValue: item.id,
      );

      final String normalizedName = rawName
          .toLowerCase()
          .replaceAll(' ', '')
          .replaceAll('\n', '')
          .replaceAll('\t', '');

      if (usedNames.contains(normalizedName)) continue;

      usedNames.add(normalizedName);
      result.add(item);
    }

    return result;
  }

  void _showAllRecommendedFoods({
    required BuildContext context,
    required List diseases,
    required Map<String, dynamic>? userData,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.86,
          minChildSize: 0.55,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
              decoration: const BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: ListView(
                controller: scrollController,
                physics: const BouncingScrollPhysics(),
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
                  const Text(
                    'เมนูแนะนำทั้งหมด',
                    style: TextStyle(
                      color: darkText,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'แตะเมนูเพื่อเปิดร้านและดูรายละเอียดเมนู',
                    style: TextStyle(
                      color: grayText,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildRecommendedFoodsFromFirebase(
                    diseases: diseases,
                    userData: userData,
                    limit: 50,
                    showBmiBanner: false,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRecommendedFoodCard(_RecommendedFoodItem item) {
    final Map<String, dynamic> food = item.food;

    final String name = _toText(food['name'], defaultValue: 'ไม่มีชื่อเมนู');
    final String restaurantName =
        _toText(food['restaurantName'], defaultValue: 'แตะเพื่อดูร้านอาหาร');
    final String imageUrl = _toText(food['imageUrl'], defaultValue: '');

    final int calories = _toInt(food['calories']);
    final int carb = _toInt(food['carb']);
    final int sugar = _toInt(food['sugar']);
    final int sodium = _toInt(food['sodium']);

    return AnimatedTapCard(
      onTap: () => _openFoodRestaurantOnMap(context, item.id, food),
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
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildFoodImage(imageUrl),
            const SizedBox(width: 12),
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
                    '$calories kcal',
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: lightGreen,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      item.reason,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: primaryGreen,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.storefront_rounded,
              color: primaryGreen,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openFoodRestaurantOnMap(
    BuildContext context,
    String foodId,
    Map<String, dynamic> food,
  ) async {
    final String restaurantId = _toText(
      food['restaurantId'],
      defaultValue: '',
    );

    final String foodRestaurantName = _toText(
      food['restaurantName'],
      defaultValue: 'ร้านอาหาร',
    );

    if (restaurantId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เมนูนี้ยังไม่มีข้อมูลร้านอาหาร'),
        ),
      );
      return;
    }

    try {
      final DocumentSnapshot restaurantDoc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .get();

      if (!mounted) return;

      if (!restaurantDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ไม่พบข้อมูลร้านอาหารของเมนูนี้'),
          ),
        );
        return;
      }

      final Map<String, dynamic> restaurantData =
          restaurantDoc.data() as Map<String, dynamic>? ?? {};

      final String restaurantName = _toText(
        restaurantData['name'],
        defaultValue: foodRestaurantName,
      );

      final double latitude = _toDouble(restaurantData['latitude']);
      final double longitude = _toDouble(restaurantData['longitude']);

      if (latitude == 0 || longitude == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ร้านนี้ยังไม่มีพิกัดแผนที่'),
          ),
        );
        return;
      }

      Navigator.push(
        context,
        smoothRoute(
          MapPage(
            focusLatitude: latitude,
            focusLongitude: longitude,
            focusRestaurantName: restaurantName,
            focusRestaurantId: restaurantId,
            focusFoodId: foodId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เปิดแผนที่ไม่สำเร็จ: $e'),
        ),
      );
    }
  }

  Widget _buildFoodImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return _buildFoodImagePlaceholder();
    }

    final bool isNetworkImage =
        imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: isNetworkImage
          ? Image.network(
              imageUrl,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildFoodImagePlaceholder();
              },
            )
          : Image.asset(
              imageUrl,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildFoodImagePlaceholder();
              },
            ),
    );
  }

  Widget _buildFoodImagePlaceholder() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.restaurant_menu_rounded,
        color: primaryGreen,
        size: 32,
      ),
    );
  }

  Widget _buildNearbyRestaurantsFromFirebase(BuildContext context) {
    return FutureBuilder<List<_NearbyRestaurant>>(
      future: _loadNearbyRestaurants(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: primaryGreen),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildEmptyState(
            icon: Icons.error_outline_rounded,
            text: 'โหลดร้านอาหารใกล้คุณไม่สำเร็จ',
          );
        }

        final restaurants = snapshot.data ?? [];

        if (restaurants.isEmpty) {
          return _buildEmptyState(
            icon: Icons.storefront_rounded,
            text: 'ยังไม่มีข้อมูลร้านอาหารใน Firebase',
          );
        }

        final topRestaurants = restaurants.take(3).toList();

        return Column(
          children: topRestaurants.map((restaurant) {
            return _buildRestaurantCard(context, restaurant);
          }).toList(),
        );
      },
    );
  }

  Future<List<_NearbyRestaurant>> _loadNearbyRestaurants() async {
    final Position? userPosition = await _getCurrentPosition();

    final snapshot = await FirebaseFirestore.instance
        .collection('restaurants')
        .where('isActive', isEqualTo: true)
        .get();

    final List<_NearbyRestaurant> restaurants = [];

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final double latitude = _toDouble(data['latitude']);
      final double longitude = _toDouble(data['longitude']);

      double? distanceKm;

      if (userPosition != null && latitude != 0 && longitude != 0) {
        final double meters = Geolocator.distanceBetween(
          userPosition.latitude,
          userPosition.longitude,
          latitude,
          longitude,
        );

        distanceKm = meters / 1000;
      }

      restaurants.add(
        _NearbyRestaurant(
          id: doc.id,
          data: data,
          distanceKm: distanceKm,
        ),
      );
    }

    restaurants.sort((a, b) {
      final double aDistance = a.distanceKm ?? 999999;
      final double bDistance = b.distanceKm ?? 999999;
      return aDistance.compareTo(bDistance);
    });

    return restaurants;
  }

  Future<Position?> _getCurrentPosition() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) return null;

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

  Widget _buildRestaurantCard(
    BuildContext context,
    _NearbyRestaurant nearbyRestaurant,
  ) {
    final Map<String, dynamic> restaurant = nearbyRestaurant.data;

    final String name =
        _toText(restaurant['name'], defaultValue: 'ไม่มีชื่อร้าน');
    final String address =
        _toText(restaurant['address'], defaultValue: 'ไม่ระบุที่อยู่');
    final String imageUrl = _toText(restaurant['imageUrl'], defaultValue: '');

    final double latitude = _toDouble(restaurant['latitude']);
    final double longitude = _toDouble(restaurant['longitude']);

    final List foodCategories =
        restaurant['foodCategories'] is List ? restaurant['foodCategories'] : [];

    final String distanceText = nearbyRestaurant.distanceKm == null
        ? 'ยังไม่ได้เปิดตำแหน่ง'
        : '${nearbyRestaurant.distanceKm!.toStringAsFixed(1)} km จากคุณ';

    return AnimatedTapCard(
      onTap: () {
        if (latitude == 0 || longitude == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ร้านนี้ยังไม่มีพิกัดแผนที่')),
          );
          return;
        }

        Navigator.push(
          context,
          smoothRoute(
            MapPage(
              focusLatitude: latitude,
              focusLongitude: longitude,
              focusRestaurantName: name,
              focusRestaurantId: nearbyRestaurant.id,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(22),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildRestaurantImage(imageUrl),
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: grayText),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    distanceText,
                    style: const TextStyle(fontSize: 13, color: grayText),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    foodCategories.isEmpty
                        ? 'ยังไม่ระบุประเภทอาหาร'
                        : foodCategories.join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return _buildRestaurantImagePlaceholder();
    }

    final bool isNetworkImage =
        imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: isNetworkImage
          ? Image.network(
              imageUrl,
              width: 62,
              height: 62,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildRestaurantImagePlaceholder();
              },
            )
          : Image.asset(
              imageUrl,
              width: 62,
              height: 62,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildRestaurantImagePlaceholder();
              },
            ),
    );
  }

  Widget _buildRestaurantImagePlaceholder() {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Icon(
        Icons.storefront_rounded,
        color: primaryGreen,
        size: 30,
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String actionText,
    required VoidCallback onTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(
            actionText,
            style: const TextStyle(
              color: primaryGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Icon(icon, color: primaryGreen, size: 42),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: grayText,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return AppBottomNavBar(
      currentIndex: 0,
      onTap: (index) {
        if (index == 0) return;

        if (index == 1) {
          Navigator.pushReplacement(
            context,
            smoothRoute(const AnalyzeFoodPage()),
          );
          return;
        }

        if (index == 2) {
          Navigator.pushReplacement(
            context,
            smoothRoute(const ChallengePage()),
          );
          return;
        }

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
      },
    );
  }

  _BmiInfo? _getBmiInfo(Map<String, dynamic>? userData) {
    if (userData == null) return null;

    final double savedBmi = _toDouble(userData['bmi']);
    if (savedBmi > 0) return _createBmiInfo(savedBmi);

    final double weight = _firstDouble(
      userData,
      ['weightKg', 'weight', 'userWeight'],
    );

    double height = _firstDouble(
      userData,
      ['heightCm', 'height', 'userHeight'],
    );

    if (weight <= 0 || height <= 0) return null;

    if (height > 3) height = height / 100;

    final double bmi = weight / (height * height);
    return _createBmiInfo(bmi);
  }

  double _firstDouble(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final double value = _toDouble(data[key]);
      if (value > 0) return value;
    }
    return 0;
  }

  _BmiInfo _createBmiInfo(double bmi) {
    if (bmi < 18.5) {
      return _BmiInfo(
        value: bmi,
        category: 'น้ำหนักต่ำกว่าเกณฑ์',
        isUnderWeight: true,
        isOverWeight: false,
      );
    }

    if (bmi < 23) {
      return _BmiInfo(
        value: bmi,
        category: 'สมส่วน',
        isUnderWeight: false,
        isOverWeight: false,
      );
    }

    if (bmi < 25) {
      return _BmiInfo(
        value: bmi,
        category: 'น้ำหนักเกิน',
        isUnderWeight: false,
        isOverWeight: true,
      );
    }

    return _BmiInfo(
      value: bmi,
      category: 'อ้วน',
      isUnderWeight: false,
      isOverWeight: true,
    );
  }

  int _clampScore(int score) {
    if (score < 0) return 0;
    if (score > 100) return 100;
    return score;
  }

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
    final String text = value.toString().trim();
    return text.isEmpty ? defaultValue : text;
  }
}

class _NearbyRestaurant {
  final String id;
  final Map<String, dynamic> data;
  final double? distanceKm;

  const _NearbyRestaurant({
    required this.id,
    required this.data,
    required this.distanceKm,
  });
}

class _RecommendedFoodItem {
  final String id;
  final Map<String, dynamic> food;
  final int finalScore;
  final String reason;

  const _RecommendedFoodItem({
    required this.id,
    required this.food,
    required this.finalScore,
    required this.reason,
  });
}

class _BmiInfo {
  final double value;
  final String category;
  final bool isUnderWeight;
  final bool isOverWeight;

  const _BmiInfo({
    required this.value,
    required this.category,
    required this.isUnderWeight,
    required this.isOverWeight,
  });
}

class _RiskSummary {
  final bool allLowRisk;
  final bool hasMediumRisk;
  final bool hasHighRisk;
  final String reason;

  const _RiskSummary({
    required this.allLowRisk,
    required this.hasMediumRisk,
    required this.hasHighRisk,
    required this.reason,
  });
}