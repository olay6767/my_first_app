import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../components/app_bottom_nav_bar.dart';
import '../utils/smooth_route.dart';

import 'analyze_food_page.dart';
import 'challenge_page.dart';
import 'expert_list_page.dart';
import 'home_page.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Color primaryGreen = Color(0xFF16A34A);
  static const Color deepGreen = Color(0xFF15803D);
  static const Color lightGreen = Color(0xFFDCFCE7);
  static const Color softGreen = Color(0xFFF0FDF4);
  static const Color backgroundColor = Color(0xFFF7FBF8);
  static const Color cardColor = Colors.white;
  static const Color darkText = Color(0xFF111827);
  static const Color grayText = Color(0xFF6B7280);
  static const Color lightText = Color(0xFF9CA3AF);
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color blue = Color(0xFF0EA5E9);
  static const Color purple = Color(0xFF8B5CF6);

  final List<String> diseaseOptions = [
    'เบาหวานชนิดที่ 2',
    'ความดันโลหิตสูง',
    'โรคไตเรื้อรัง',
    'ไขมันในเลือดสูง',
    'โรคอ้วน',
  ];

  final List<String> allergyOptions = [
    'นม',
    'ถั่ว',
    'อาหารทะเล',
    'ไข่',
    'แป้งสาลี',
    'ปลา',
  ];

  void _handleBottomNavTap(int index) {
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

    if (index == 4) return;
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      smoothRoute(const HomePage()),
      (route) => false,
    );
  }

  double calculateBmi(double weight, double heightCm) {
    if (weight <= 0 || heightCm <= 0) return 0;

    final double heightM = heightCm / 100;
    final double bmi = weight / (heightM * heightM);

    return double.parse(bmi.toStringAsFixed(2));
  }

  String getBmiStatus(double bmi) {
    if (bmi <= 0) return 'ไม่พบข้อมูล';
    if (bmi < 18.5) return 'น้ำหนักน้อย';
    if (bmi < 23) return 'ปกติ';
    if (bmi < 25) return 'น้ำหนักเกิน';
    if (bmi < 30) return 'อ้วนระดับ 1';
    return 'อ้วนระดับ 2';
  }

  Color getBmiColor(double bmi) {
    if (bmi <= 0) return grayText;
    if (bmi < 18.5) return blue;
    if (bmi < 23) return primaryGreen;
    if (bmi < 25) return warningOrange;
    return dangerRed;
  }

  double _getBmiProgress(double bmi) {
    if (bmi <= 0) return 0;
    if (bmi >= 35) return 1;
    return (bmi / 35).clamp(0, 1);
  }

  void showMessage(String message, {bool success = true}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: success ? primaryGreen : dangerRed,
        margin: const EdgeInsets.all(14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: _buildAppBar(
          title: 'Profile',
          showLogout: false,
        ),
        body: _buildNotLoginState(),
        bottomNavigationBar: AppBottomNavBar(
          currentIndex: 4,
          onTap: _handleBottomNavTap,
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(
        title: 'Profile',
        showLogout: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _buildNoUserDataState(currentUser.email ?? '-');
          }

          final Map<String, dynamic> userData =
              snapshot.data!.data() as Map<String, dynamic>? ?? {};

          return _buildProfileContent(
            uid: currentUser.uid,
            userData: userData,
          );
        },
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 4,
        onTap: _handleBottomNavTap,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar({
    required String title,
    required bool showLogout,
  }) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          color: darkText,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: backgroundColor,
      foregroundColor: darkText,
      elevation: 0,
      actions: [
        if (showLogout)
          IconButton(
            onPressed: logout,
            icon: const Icon(
              Icons.logout_rounded,
              color: dangerRed,
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: _PulseIcon(
        icon: Icons.person_rounded,
        color: primaryGreen,
      ),
    );
  }

  Widget _buildNotLoginState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _AnimatedFadeSlide(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: _cardDecoration(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _PulseIcon(
                  icon: Icons.person_outline_rounded,
                  color: primaryGreen,
                ),
                const SizedBox(height: 20),
                const Text(
                  'ยังไม่ได้เข้าสู่ระบบ',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'เข้าสู่ระบบเพื่อดูข้อมูลสุขภาพ โรคประจำตัว เมนูโปรด และคำแนะนำเฉพาะคุณ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: grayText,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 22),
                _AnimatedPressable(
                  onTap: () {
                    Navigator.push(
                      context,
                      smoothRoute(const LoginPage()),
                    );
                  },
                  child: _buildSolidButton(
                    icon: Icons.login_rounded,
                    label: 'เข้าสู่ระบบ / สมัครสมาชิก',
                    color: primaryGreen,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoUserDataState(String email) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _AnimatedFadeSlide(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: _cardDecoration(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: lightGreen,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: primaryGreen,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'ไม่พบข้อมูลผู้ใช้ใน Firestore',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: grayText),
                ),
                const SizedBox(height: 20),
                _AnimatedPressable(
                  onTap: logout,
                  child: _buildSolidButton(
                    icon: Icons.logout_rounded,
                    label: 'ออกจากระบบ',
                    color: dangerRed,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent({
    required String uid,
    required Map<String, dynamic> userData,
  }) {
    final String name = _toText(userData['name'], defaultValue: 'ผู้ใช้');
    final String email = _toText(userData['email'], defaultValue: '-');
    final String gender = _toText(userData['gender'], defaultValue: 'ไม่ระบุ');
    final int age = _toInt(userData['age']);
    final double weight = _toDouble(userData['weight']);
    final double height = _toDouble(userData['height']);
    final double bmiFromDb = _toDouble(userData['bmi']);
    final double bmi = bmiFromDb > 0 ? bmiFromDb : calculateBmi(weight, height);
    final List diseases =
        userData['diseases'] is List ? userData['diseases'] : [];
    final List allergies =
        userData['allergies'] is List ? userData['allergies'] : [];
    final String photoUrl = _toText(userData['photoUrl'], defaultValue: '');
    final String role = _toText(userData['role'], defaultValue: 'user');
    final int points = _toInt(userData['points']);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AnimatedFadeSlide(
            delay: 0,
            child: _buildProfileHeader(
              name: name,
              email: email,
              photoUrl: photoUrl,
              role: role,
              points: points,
            ),
          ),
          const SizedBox(height: 16),
          _AnimatedFadeSlide(
            delay: 80,
            child: _buildQuickStats(
              age: age,
              weight: weight,
              height: height,
            ),
          ),
          const SizedBox(height: 16),
          _AnimatedFadeSlide(
            delay: 140,
            child: _buildBmiCard(
              bmi: bmi,
              weight: weight,
              height: height,
            ),
          ),
          const SizedBox(height: 16),
          _AnimatedFadeSlide(
            delay: 200,
            child: _buildInfoCard(
              title: 'ข้อมูลส่วนตัว',
              icon: Icons.badge_outlined,
              color: primaryGreen,
              children: [
                _buildInfoRow('ชื่อ', name),
                _buildInfoRow('อีเมล', email),
                _buildInfoRow('อายุ', age > 0 ? '$age ปี' : '-'),
                _buildInfoRow('เพศ', gender),
                _buildInfoRow('น้ำหนัก', weight > 0 ? '$weight kg' : '-'),
                _buildInfoRow('ส่วนสูง', height > 0 ? '$height cm' : '-'),
                _buildInfoRow('คะแนนสะสม', '$points points'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _AnimatedFadeSlide(
            delay: 260,
            child: _buildChipCard(
              title: 'โรคประจำตัว',
              icon: Icons.health_and_safety_outlined,
              color: primaryGreen,
              items: diseases,
              emptyText: 'ยังไม่ได้เลือกโรคประจำตัว',
            ),
          ),
          const SizedBox(height: 16),
          _AnimatedFadeSlide(
            delay: 320,
            child: _buildChipCard(
              title: 'อาหารที่แพ้',
              icon: Icons.no_food_outlined,
              color: warningOrange,
              items: allergies,
              emptyText: 'ไม่มีข้อมูลอาหารที่แพ้',
            ),
          ),
          const SizedBox(height: 20),
          _AnimatedFadeSlide(
            delay: 380,
            child: _buildActionButtons(
              uid: uid,
              userData: userData,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader({
    required String name,
    required String email,
    required String photoUrl,
    required String role,
    required int points,
  }) {
    final String roleText;
    if (role == 'admin') {
      roleText = 'Admin';
    } else if (role == 'expert') {
      roleText = 'Expert';
    } else {
      roleText = 'User';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
          _buildAvatar(photoUrl),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildHeaderPill(roleText, Icons.verified_user_rounded),
                    _buildHeaderPill('$points points', Icons.stars_rounded),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String photoUrl) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutBack,
      tween: Tween(begin: 0.85, end: 1),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Container(
        width: 84,
        height: 84,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(27),
          child: photoUrl.isNotEmpty
              ? Image.network(
                  photoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildAvatarPlaceholder();
                  },
                )
              : _buildAvatarPlaceholder(),
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      color: lightGreen,
      child: const Icon(
        Icons.person_rounded,
        color: primaryGreen,
        size: 52,
      ),
    );
  }

  Widget _buildHeaderPill(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats({
    required int age,
    required double weight,
    required double height,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.cake_rounded,
            label: 'อายุ',
            value: age > 0 ? age.toDouble() : 0,
            unit: 'ปี',
            color: purple,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            icon: Icons.monitor_weight_outlined,
            label: 'น้ำหนัก',
            value: weight,
            unit: 'kg',
            color: primaryGreen,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            icon: Icons.height_rounded,
            label: 'ส่วนสูง',
            value: height,
            unit: 'cm',
            color: blue,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required double value,
    required String unit,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(
        radius: 22,
        shadowAlpha: 0.035,
      ),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: grayText,
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: 2),
          _AnimatedNumberText(
            value: value,
            unit: unit,
            decimalPlaces: value == value.roundToDouble() ? 0 : 1,
            color: color,
            fontSize: 14,
          ),
        ],
      ),
    );
  }

  Widget _buildBmiCard({
    required double bmi,
    required double weight,
    required double height,
  }) {
    final Color bmiColor = getBmiColor(bmi);
    final double progress = _getBmiProgress(bmi);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: bmiColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(
                  Icons.monitor_weight_outlined,
                  color: bmiColor,
                  size: 34,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BMI ของคุณ',
                      style: TextStyle(
                        color: darkText,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      weight > 0 && height > 0
                          ? 'คำนวณจากน้ำหนักและส่วนสูง'
                          : 'ยังไม่มีข้อมูลน้ำหนัก/ส่วนสูง',
                      style: const TextStyle(
                        color: grayText,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _AnimatedNumberText(
                    value: bmi,
                    unit: '',
                    decimalPlaces: 2,
                    color: bmiColor,
                    fontSize: 27,
                  ),
                  Text(
                    getBmiStatus(bmi),
                    style: TextStyle(
                      color: bmiColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 9,
                  color: bmiColor,
                  backgroundColor: bmiColor.withValues(alpha: 0.13),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _buildSectionTitle(
            title: title,
            icon: icon,
            color: color,
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSectionTitle({
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 39,
          height: 39,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: darkText,
              fontSize: 17.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: grayText,
                fontSize: 14,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: darkText,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipCard({
    required String title,
    required IconData icon,
    required Color color,
    required List items,
    required String emptyText,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            title: title,
            icon: icon,
            color: color,
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Text(
                emptyText,
                style: const TextStyle(
                  color: grayText,
                  fontSize: 14,
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.asMap().entries.map((entry) {
                final int index = entry.key;
                final dynamic item = entry.value;

                return _AnimatedFadeSlide(
                  delay: index * 45,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: color.withValues(alpha: 0.24),
                      ),
                    ),
                    child: Text(
                      item.toString(),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons({
    required String uid,
    required Map<String, dynamic> userData,
  }) {
    return Column(
      children: [
        _AnimatedPressable(
          onTap: () {
            _showEditProfileSheet(
              uid: uid,
              userData: userData,
            );
          },
          child: _buildSolidButton(
            icon: Icons.edit_rounded,
            label: 'แก้ไขข้อมูลโปรไฟล์',
            color: primaryGreen,
          ),
        ),
        const SizedBox(height: 12),
        _AnimatedPressable(
          onTap: logout,
          child: _buildOutlineButton(
            icon: Icons.logout_rounded,
            label: 'ออกจากระบบ',
            color: dangerRed,
          ),
        ),
      ],
    );
  }

  Widget _buildSolidButton({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.20),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutlineButton({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileSheet({
    required String uid,
    required Map<String, dynamic> userData,
  }) {
    final TextEditingController nameController = TextEditingController(
      text: _toText(userData['name'], defaultValue: ''),
    );

    final TextEditingController ageController = TextEditingController(
      text: _toInt(userData['age']) > 0 ? _toInt(userData['age']).toString() : '',
    );

    final TextEditingController weightController = TextEditingController(
      text: _toDouble(userData['weight']) > 0
          ? _toDouble(userData['weight']).toString()
          : '',
    );

    final TextEditingController heightController = TextEditingController(
      text: _toDouble(userData['height']) > 0
          ? _toDouble(userData['height']).toString()
          : '',
    );

    String selectedGender = _toText(userData['gender'], defaultValue: 'ไม่ระบุ');

    List<String> selectedDiseases = userData['diseases'] is List
        ? List<String>.from(userData['diseases'])
        : [];

    List<String> selectedAllergies = userData['allergies'] is List
        ? List<String>.from(userData['allergies'])
        : [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> saveProfileData() async {
              final String name = nameController.text.trim();
              final int age = int.tryParse(ageController.text.trim()) ?? 0;
              final double weight =
                  double.tryParse(weightController.text.trim()) ?? 0;
              final double height =
                  double.tryParse(heightController.text.trim()) ?? 0;
              final double bmi = calculateBmi(weight, height);

              if (name.isEmpty) {
                showMessage('กรุณากรอกชื่อ', success: false);
                return;
              }

              try {
                await FirebaseFirestore.instance.collection('users').doc(uid).set(
                  {
                    'name': name,
                    'age': age,
                    'gender': selectedGender,
                    'weight': weight,
                    'height': height,
                    'bmi': bmi,
                    'diseases': selectedDiseases,
                    'allergies': selectedAllergies,
                    'updatedAt': FieldValue.serverTimestamp(),
                  },
                  SetOptions(merge: true),
                );

                if (!mounted) return;

                Navigator.pop(context);
                showMessage('บันทึกข้อมูลโปรไฟล์สำเร็จ');
              } catch (e) {
                showMessage('บันทึกข้อมูลไม่สำเร็จ: $e', success: false);
              }
            }

            return _AnimatedFadeSlide(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.92,
                ),
                padding: EdgeInsets.only(
                  left: 18,
                  right: 18,
                  top: 14,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                decoration: const BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(32),
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
                            color: const Color(0xFFD1D5DB),
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
                              color: lightGreen,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              color: primaryGreen,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'แก้ไขข้อมูลโปรไฟล์',
                              style: TextStyle(
                                color: darkText,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _buildSheetTextField(
                        controller: nameController,
                        label: 'ชื่อ-นามสกุล หรือชื่อเล่น',
                        icon: Icons.person_outline_rounded,
                        keyboardType: TextInputType.text,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSheetTextField(
                              controller: ageController,
                              label: 'อายุ',
                              icon: Icons.cake_outlined,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedGender,
                              decoration: _sheetInputDecoration(
                                label: 'เพศ',
                                icon: Icons.wc_rounded,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'ไม่ระบุ',
                                  child: Text('ไม่ระบุ'),
                                ),
                                DropdownMenuItem(
                                  value: 'ชาย',
                                  child: Text('ชาย'),
                                ),
                                DropdownMenuItem(
                                  value: 'หญิง',
                                  child: Text('หญิง'),
                                ),
                                DropdownMenuItem(
                                  value: 'อื่น ๆ',
                                  child: Text('อื่น ๆ'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                setSheetState(() {
                                  selectedGender = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSheetTextField(
                              controller: weightController,
                              label: 'น้ำหนัก kg',
                              icon: Icons.monitor_weight_outlined,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSheetTextField(
                              controller: heightController,
                              label: 'ส่วนสูง cm',
                              icon: Icons.height_rounded,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildSheetMultiSelect(
                        title: 'โรคประจำตัว',
                        options: diseaseOptions,
                        selected: selectedDiseases,
                        color: primaryGreen,
                        onTap: (value) {
                          setSheetState(() {
                            if (selectedDiseases.contains(value)) {
                              selectedDiseases.remove(value);
                            } else {
                              selectedDiseases.add(value);
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildSheetMultiSelect(
                        title: 'อาหารที่แพ้',
                        options: allergyOptions,
                        selected: selectedAllergies,
                        color: warningOrange,
                        onTap: (value) {
                          setSheetState(() {
                            if (selectedAllergies.contains(value)) {
                              selectedAllergies.remove(value);
                            } else {
                              selectedAllergies.add(value);
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      _AnimatedPressable(
                        onTap: saveProfileData,
                        child: _buildSolidButton(
                          icon: Icons.save_rounded,
                          label: 'บันทึกข้อมูล',
                          color: primaryGreen,
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
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _sheetInputDecoration(
        label: label,
        icon: icon,
      ),
    );
  }

  InputDecoration _sheetInputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primaryGreen),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: primaryGreen,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildSheetMultiSelect({
    required String title,
    required List<String> options,
    required List<String> selected,
    required Color color,
    required void Function(String) onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: darkText,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final bool isSelected = selected.contains(option);

            return _AnimatedPressable(
              onTap: () => onTap(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.12) : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isSelected ? color : borderColor,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color: isSelected ? color : grayText,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      option,
                      style: TextStyle(
                        color: isSelected ? color : darkText,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration({
    double radius = 26,
    double shadowAlpha = 0.045,
  }) {
    return BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: shadowAlpha),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  String _toText(dynamic value, {String defaultValue = '-'}) {
    if (value == null) return defaultValue;
    final String text = value.toString().trim();
    return text.isEmpty ? defaultValue : text;
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
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
}

class _AnimatedFadeSlide extends StatefulWidget {
  final Widget child;
  final int delay;

  const _AnimatedFadeSlide({
    required this.child,
    this.delay = 0,
  });

  @override
  State<_AnimatedFadeSlide> createState() => _AnimatedFadeSlideState();
}

class _AnimatedFadeSlideState extends State<_AnimatedFadeSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    final CurvedAnimation curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(curvedAnimation);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(curvedAnimation);

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

class _AnimatedPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _AnimatedPressable({
    required this.child,
    this.onTap,
  });

  @override
  State<_AnimatedPressable> createState() => _AnimatedPressableState();
}

class _AnimatedPressableState extends State<_AnimatedPressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted) return;

    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        if (widget.onTap != null) _setPressed(true);
      },
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutBack,
          child: widget.child,
        ),
      ),
    );
  }
}

class _PulseIcon extends StatefulWidget {
  final IconData icon;
  final Color color;

  const _PulseIcon({
    required this.icon,
    required this.color,
  });

  @override
  State<_PulseIcon> createState() => _PulseIconState();
}

class _PulseIconState extends State<_PulseIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.92,
      end: 1.08,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Icon(
          widget.icon,
          color: widget.color,
          size: 44,
        ),
      ),
    );
  }
}

class _AnimatedNumberText extends StatelessWidget {
  final double value;
  final String unit;
  final int decimalPlaces;
  final Color color;
  final double fontSize;

  const _AnimatedNumberText({
    required this.value,
    required this.unit,
    required this.decimalPlaces,
    required this.color,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        final String numberText = animatedValue.toStringAsFixed(decimalPlaces);

        return Text(
          unit.isEmpty ? numberText : '$numberText $unit',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    );
  }
}