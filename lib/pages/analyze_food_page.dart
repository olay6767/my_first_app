import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../components/animated_number_text.dart';
import '../components/app_bottom_nav_bar.dart';
import '../services/food_classifier_service.dart';
import '../services/nutrition_data_service.dart';
import '../utils/smooth_route.dart';

import 'challenge_page.dart';
import 'expert_list_page.dart';
import 'home_page.dart';
import 'profile_page.dart';

class AnalyzeFoodPage extends StatefulWidget {
  const AnalyzeFoodPage({super.key});

  @override
  State<AnalyzeFoodPage> createState() => _AnalyzeFoodPageState();
}

class _AnalyzeFoodPageState extends State<AnalyzeFoodPage> {
  static const Color primaryGreen = Color(0xFF16A34A);
  static const Color lightGreen = Color(0xFFDCFCE7);
  static const Color softGreen = Color(0xFFF0FDF4);
  static const Color backgroundColor = Color(0xFFF7FBF8);
  static const Color darkText = Color(0xFF111827);
  static const Color grayText = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color blue = Color(0xFF0EA5E9);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color orange = Color(0xFFF97316);

  final ImagePicker _picker = ImagePicker();

  final FoodClassifierService _classifierService = FoodClassifierService();
  final NutritionDataService _nutritionService = NutritionDataService();

  File? selectedImage;
  FoodPrediction? prediction;
  NutritionInfo? nutritionInfo;
  List<FoodPrediction> topPredictions = [];

  String predictionResultTitle = '';
  String predictionResultDetail = '';

  bool isLoadingModel = true;
  bool isAnalyzing = false;
  String statusMessage = 'กำลังโหลด AI และข้อมูลโภชนาการ...';

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  @override
  void dispose() {
    _classifierService.close();
    super.dispose();
  }

  Future<void> _loadServices() async {
    try {
      await _classifierService.loadModel();
      await _nutritionService.loadNutritionData();

      if (!mounted) return;

      setState(() {
        isLoadingModel = false;
        statusMessage = 'พร้อมวิเคราะห์อาหาร';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingModel = false;
        statusMessage = 'โหลดระบบไม่สำเร็จ: $e';
      });

      _showMessage('โหลดระบบไม่สำเร็จ: $e', success: false);
    }
  }

  void _handleBottomNavTap(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        smoothRoute(const HomePage()),
      );
      return;
    }

    if (index == 1) return;

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
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (pickedFile == null) return;

      final File imageFile = File(pickedFile.path);

      setState(() {
        selectedImage = imageFile;
        prediction = null;
        nutritionInfo = null;
        topPredictions = [];
        predictionResultTitle = '';
        predictionResultDetail = '';
        statusMessage = 'ถ่ายรูปแล้ว กำลังวิเคราะห์...';
      });

      await _analyzeImage(imageFile);
    } catch (e) {
      _showMessage('เปิดกล้องหรือถ่ายรูปไม่สำเร็จ: $e', success: false);
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (pickedFile == null) return;

      final File imageFile = File(pickedFile.path);

      setState(() {
        selectedImage = imageFile;
        prediction = null;
        nutritionInfo = null;
        topPredictions = [];
        predictionResultTitle = '';
        predictionResultDetail = '';
        statusMessage = 'เลือกรูปแล้ว กำลังวิเคราะห์...';
      });

      await _analyzeImage(imageFile);
    } catch (e) {
      _showMessage('เลือกรูปไม่สำเร็จ: $e', success: false);
    }
  }

  Future<void> _analyzeImage(File imageFile) async {
    try {
      setState(() {
        isAnalyzing = true;
      });

      final List<FoodPrediction> results =
          await _classifierService.predictTopK(
        imageFile,
        topK: 5,
      );

      if (results.isEmpty) {
        throw Exception('ไม่พบผลลัพธ์จากโมเดล');
      }

      final FoodPrediction bestPrediction = results.first;
      final double confidence = _getConfidenceValue(bestPrediction);

      NutritionInfo? foundNutrition;

      if (confidence >= 0.35) {
        foundNutrition = await _nutritionService.findByPrediction(
          classId: bestPrediction.classId,
          foodName: bestPrediction.foodName,
        );
      }

      if (!mounted) return;

      setState(() {
        prediction = bestPrediction;
        topPredictions = results;
        nutritionInfo = foundNutrition;
        predictionResultTitle = _getPredictionTitle(bestPrediction);
        predictionResultDetail = _getPredictionDetail(bestPrediction);
        isAnalyzing = false;
        statusMessage = predictionResultDetail;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isAnalyzing = false;
        statusMessage = 'วิเคราะห์ไม่สำเร็จ: $e';
      });

      _showMessage('วิเคราะห์ไม่สำเร็จ: $e', success: false);
    }
  }

  double _getConfidenceValue(FoodPrediction item) {
    final String text = item.confidencePercent
        .replaceAll('%', '')
        .replaceAll(',', '')
        .trim();

    final double percent = double.tryParse(text) ?? 0;
    return percent / 100;
  }

  String _getPredictionTitle(FoodPrediction item) {
    final double confidence = _getConfidenceValue(item);

    if (confidence < 0.35) {
      return 'ไม่สามารถวิเคราะห์ภาพได้';
    }

    return item.foodName;
  }

  String _getPredictionDetail(FoodPrediction item) {
    final double confidence = _getConfidenceValue(item);

    if (confidence < 0.35) {
      return 'ภาพอาจไม่ชัดหรือไม่ตรงกับอาหารในระบบ';
    }

    if (confidence < 0.60) {
      return 'ผลลัพธ์ยังไม่มั่นใจ กรุณาตรวจสอบอีกครั้ง';
    }

    return 'วิเคราะห์สำเร็จ';
  }

  Color _getConfidenceColor(FoodPrediction item) {
    final double confidence = _getConfidenceValue(item);

    if (confidence < 0.35) return dangerRed;
    if (confidence < 0.60) return warningOrange;
    return primaryGreen;
  }

  Future<void> _openPredictionNutrition(FoodPrediction item) async {
    try {
      final NutritionInfo? foundNutrition =
          await _nutritionService.findByPrediction(
        classId: item.classId,
        foodName: item.foodName,
      );

      if (!mounted) return;

      if (foundNutrition == null) {
        _showMessage(
          'ไม่พบข้อมูลโภชนาการของ ${item.foodName}',
          success: false,
        );
        return;
      }

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return _AnimatedFadeSlide(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.86,
              ),
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: _buildNutritionPreviewSheet(
                  prediction: item,
                  nutrition: foundNutrition,
                ),
              ),
            ),
          );
        },
      );
    } catch (e) {
      _showMessage('เปิดข้อมูลโภชนาการไม่สำเร็จ: $e', success: false);
    }
  }

  void _showMessage(String message, {bool success = true}) {
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
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'วิเคราะห์อาหาร',
          style: TextStyle(
            color: darkText,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: backgroundColor,
        foregroundColor: darkText,
        elevation: 0,
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 420),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: isLoadingModel
              ? _buildLoadingState()
              : SingleChildScrollView(
                  key: const ValueKey('content'),
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AnimatedFadeSlide(
                        delay: 0,
                        child: _buildHeaderCard(),
                      ),
                      const SizedBox(height: 16),
                      _AnimatedFadeSlide(
                        delay: 80,
                        child: _buildImagePickerCard(),
                      ),
                      const SizedBox(height: 16),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 420),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: isAnalyzing
                            ? _buildAnalyzingCard()
                            : const SizedBox.shrink(),
                      ),
                      if (!isAnalyzing && prediction != null) ...[
                        _AnimatedFadeSlide(
                          delay: 80,
                          child: _buildPredictionCard(),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (!isAnalyzing && nutritionInfo != null) ...[
                        _AnimatedFadeSlide(
                          delay: 130,
                          child: _buildNutritionCard(),
                        ),
                        const SizedBox(height: 16),
                        _AnimatedFadeSlide(
                          delay: 180,
                          child: _buildRiskCard(),
                        ),
                      ],
                      if (!isAnalyzing &&
                          prediction != null &&
                          nutritionInfo == null)
                        _AnimatedFadeSlide(
                          delay: 130,
                          child: _buildNutritionNotFoundCard(),
                        ),
                      if (!isAnalyzing && topPredictions.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _AnimatedFadeSlide(
                          delay: 220,
                          child: _buildTopPredictionsCard(),
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 1,
        onTap: _handleBottomNavTap,
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      key: const ValueKey('loading'),
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
                  icon: Icons.psychology_rounded,
                  color: primaryGreen,
                ),
                const SizedBox(height: 18),
                const Text(
                  'กำลังโหลด AI...',
                  style: TextStyle(
                    color: darkText,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  statusMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: grayText,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    color: primaryGreen,
                    strokeWidth: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
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
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Food Analysis',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  statusMessage,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 13.5,
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

  Widget _buildImagePickerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 420),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final curved = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              );

              return FadeTransition(
                opacity: curved,
                child: ScaleTransition(
                  scale: Tween<double>(
                    begin: 0.96,
                    end: 1.0,
                  ).animate(curved),
                  child: child,
                ),
              );
            },
            child: selectedImage == null
                ? _buildImagePlaceholder()
                : _buildSelectedImage(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _AnimatedPressable(
                  onTap: isAnalyzing ? null : _pickImageFromCamera,
                  child: _buildActionButton(
                    label: 'ถ่ายรูป',
                    icon: Icons.camera_alt_rounded,
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AnimatedPressable(
                  onTap: isAnalyzing ? null : _pickImageFromGallery,
                  child: _buildActionButton(
                    label: 'Gallery',
                    icon: Icons.photo_library_rounded,
                    backgroundColor: softGreen,
                    foregroundColor: primaryGreen,
                    borderColor: primaryGreen.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      key: const ValueKey('placeholder'),
      width: double.infinity,
      height: 230,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: const Icon(
              Icons.image_search_rounded,
              color: primaryGreen,
              size: 44,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'ยังไม่ได้เลือกรูปอาหาร',
            style: TextStyle(
              color: darkText,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'ถ่ายรูปหรือเลือกรูปจาก Gallery เพื่อเริ่มวิเคราะห์',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: grayText,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedImage() {
    return ClipRRect(
      key: ValueKey(selectedImage!.path),
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          Image.file(
            selectedImage!,
            width: double.infinity,
            height: 250,
            fit: BoxFit.cover,
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.00),
                    Colors.black.withValues(alpha: 0.32),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  Icon(
                    isAnalyzing
                        ? Icons.hourglass_top_rounded
                        : Icons.check_circle_rounded,
                    color: isAnalyzing ? warningOrange : primaryGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      isAnalyzing ? 'กำลังวิเคราะห์รูปนี้...' : 'เลือกรูปแล้ว',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: darkText,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color backgroundColor,
    required Color foregroundColor,
    Color? borderColor,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: borderColor == null ? null : Border.all(color: borderColor),
        boxShadow: backgroundColor == primaryGreen
            ? [
                BoxShadow(
                  color: primaryGreen.withValues(alpha: 0.20),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ]
            : [],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: foregroundColor, size: 22),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzingCard() {
    return _AnimatedFadeSlide(
      key: const ValueKey('analyzing'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: _cardDecoration(),
        child: const Column(
          children: [
            _PulseIcon(
              icon: Icons.auto_awesome_rounded,
              color: primaryGreen,
            ),
            SizedBox(height: 16),
            Text(
              'กำลังวิเคราะห์รูปอาหาร...',
              style: TextStyle(
                color: darkText,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'AI กำลังตรวจจับชนิดอาหารและค้นหาข้อมูลโภชนาการ',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: grayText,
                fontSize: 13,
                height: 1.35,
              ),
            ),
            SizedBox(height: 16),
            LinearProgressIndicator(
              color: primaryGreen,
              backgroundColor: lightGreen,
              minHeight: 6,
              borderRadius: BorderRadius.all(Radius.circular(999)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionCard() {
    final FoodPrediction result = prediction!;
    final Color confidenceColor = _getConfidenceColor(result);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: confidenceColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              confidenceColor == dangerRed
                  ? Icons.image_not_supported_rounded
                  : Icons.restaurant_menu_rounded,
              color: confidenceColor,
              size: 36,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ผลการวิเคราะห์',
                  style: TextStyle(
                    color: grayText,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  predictionResultTitle.isEmpty
                      ? _getPredictionTitle(result)
                      : predictionResultTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: darkText,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  predictionResultDetail.isEmpty
                      ? _getPredictionDetail(result)
                      : predictionResultDetail,
                  style: TextStyle(
                    color: confidenceColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: confidenceColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              result.confidencePercent,
              style: TextStyle(
                color: confidenceColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionCard() {
    final NutritionInfo n = nutritionInfo!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            icon: Icons.local_fire_department_rounded,
            title: 'ข้อมูลโภชนาการ',
            color: primaryGreen,
          ),
          const SizedBox(height: 6),
          Text(
            n.menuName,
            style: const TextStyle(
              color: grayText,
              fontSize: 14,
            ),
          ),
          if (n.portionG > 0)
            Text(
              'ปริมาณอ้างอิง: ${_formatNumber(n.portionG)} g',
              style: const TextStyle(
                color: grayText,
                fontSize: 13,
              ),
            ),
          const SizedBox(height: 16),
          _buildNutritionGrid(n),
        ],
      ),
    );
  }

  Widget _buildNutritionGrid(NutritionInfo n) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.75,
      children: [
        _buildNutritionBox(
          title: 'พลังงาน',
          value: n.kcal,
          unit: 'kcal',
          icon: Icons.bolt_rounded,
          color: warningOrange,
        ),
        _buildNutritionBox(
          title: 'คาร์บ',
          value: n.carbG,
          unit: 'g',
          icon: Icons.rice_bowl_rounded,
          color: blue,
        ),
        _buildNutritionBox(
          title: 'น้ำตาล',
          value: n.sugarG,
          unit: 'g',
          icon: Icons.icecream_rounded,
          color: dangerRed,
        ),
        _buildNutritionBox(
          title: 'โซเดียม',
          value: n.sodiumMg,
          unit: 'mg',
          icon: Icons.water_drop_rounded,
          color: purple,
        ),
        _buildNutritionBox(
          title: 'โปรตีน',
          value: n.proteinG,
          unit: 'g',
          icon: Icons.fitness_center_rounded,
          color: primaryGreen,
        ),
        _buildNutritionBox(
          title: 'ไขมัน',
          value: n.fatG,
          unit: 'g',
          icon: Icons.opacity_rounded,
          color: orange,
        ),
      ],
    );
  }

  Widget _buildNutritionBox({
    required String title,
    required double value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    final int decimalPlaces = value == value.roundToDouble() ? 0 : 1;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      tween: Tween(begin: 0.94, end: 1),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 25),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: grayText,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedNumberText(
                    value: value,
                    unit: unit,
                    decimalPlaces: decimalPlaces,
                    duration: const Duration(milliseconds: 950),
                    curve: Curves.easeOutCubic,
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskCard() {
    final NutritionInfo n = nutritionInfo!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: _buildRiskContent(n),
    );
  }

  Widget _buildRiskContent(NutritionInfo n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          icon: Icons.health_and_safety_outlined,
          title: 'คำแนะนำสุขภาพ',
          color: primaryGreen,
        ),
        const SizedBox(height: 14),
        _buildRiskRow('เบาหวานชนิดที่ 2', n.diabetesRisk),
        _buildRiskRow('ความดันโลหิตสูง', n.hypertensionRisk),
        _buildRiskRow('ไขมันในเลือดสูง', n.dyslipidemiaRisk),
        _buildRiskRow('โรคไตเรื้อรัง', n.kidneyRisk),
        _buildRiskRow('โรคอ้วน', n.obesityRisk),
        if (n.recommendation.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            'คำแนะนำ',
            style: TextStyle(
              color: darkText,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            n.recommendation,
            style: const TextStyle(
              color: grayText,
              height: 1.45,
            ),
          ),
        ],
        if (n.medicalDisclaimer.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            n.medicalDisclaimer,
            style: const TextStyle(
              color: dangerRed,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRiskRow(String disease, String risk) {
    final Color color = _getRiskColor(risk);

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              disease,
              style: const TextStyle(
                color: darkText,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              risk.isEmpty ? 'ไม่ระบุ' : risk,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionNotFoundCard() {
    final bool isVeryLowConfidence =
        prediction != null && _getConfidenceValue(prediction!) < 0.35;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: (isVeryLowConfidence ? dangerRed : warningOrange)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              isVeryLowConfidence
                  ? Icons.image_not_supported_rounded
                  : Icons.search_off_rounded,
              color: isVeryLowConfidence ? dangerRed : warningOrange,
              size: 42,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isVeryLowConfidence
                ? 'ภาพไม่ชัดหรือไม่ตรงกับอาหารในระบบ'
                : 'ไม่พบข้อมูลโภชนาการ',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: darkText,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            isVeryLowConfidence
                ? 'โมเดลมีความมั่นใจต่ำมาก กรุณาเลือกรูปอาหารที่ชัดเจนขึ้น'
                : 'AI ทำนายอาหารได้แล้ว แต่ยังหาเมนูนี้ในข้อมูลโภชนาการไม่เจอ',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: grayText,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPredictionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            icon: Icons.auto_awesome_rounded,
            title: 'ผลลัพธ์ที่ใกล้เคียงรูปภาพ',
            color: primaryGreen,
          ),
          const SizedBox(height: 6),
          const Text(
            'กดที่เมนูเพื่อดูข้อมูลโภชนาการของผลลัพธ์นั้น',
            style: TextStyle(
              color: grayText,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          ...topPredictions.asMap().entries.map((entry) {
            final int index = entry.key;
            final FoodPrediction item = entry.value;
            final Color confidenceColor = _getConfidenceColor(item);

            return _AnimatedFadeSlide(
              delay: index * 60,
              child: _AnimatedPressable(
                onTap: () => _openPredictionNutrition(item),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: lightGreen,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            item.classId,
                            style: const TextStyle(
                              color: primaryGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.foodName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: darkText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: confidenceColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          item.confidencePercent,
                          style: TextStyle(
                            color: confidenceColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: grayText,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNutritionPreviewSheet({
    required FoodPrediction prediction,
    required NutritionInfo nutrition,
  }) {
    final Color confidenceColor = _getConfidenceColor(prediction);

    return Column(
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
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: lightGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.restaurant_menu_rounded,
                color: primaryGreen,
                size: 34,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nutrition.menuName,
                    style: const TextStyle(
                      color: darkText,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ความใกล้เคียง ${prediction.confidencePercent}',
                    style: TextStyle(
                      color: confidenceColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (nutrition.portionG > 0)
          Text(
            'ปริมาณอ้างอิง: ${_formatNumber(nutrition.portionG)} g',
            style: const TextStyle(
              color: grayText,
              fontSize: 13,
            ),
          ),
        const SizedBox(height: 14),
        _buildNutritionGrid(nutrition),
        const SizedBox(height: 18),
        _buildRiskContent(nutrition),
      ],
    );
  }

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: color,
            size: 22,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: darkText,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  Color _getRiskColor(String risk) {
    final value = risk.toLowerCase();

    if (value.contains('สูง') ||
        value.contains('high') ||
        value.contains('ไม่แนะนำ')) {
      return dangerRed;
    }

    if (value.contains('กลาง') ||
        value.contains('medium') ||
        value.contains('ควรระวัง')) {
      return warningOrange;
    }

    if (value.contains('ต่ำ') ||
        value.contains('low') ||
        value.contains('เหมาะสม')) {
      return primaryGreen;
    }

    return grayText;
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(1);
  }
}

class _AnimatedFadeSlide extends StatefulWidget {
  final Widget child;
  final int delay;

  const _AnimatedFadeSlide({
    super.key,
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
  void didUpdateWidget(covariant _AnimatedFadeSlide oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.child.key != widget.child.key) {
      _controller
        ..reset()
        ..forward();
    }
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
        width: 74,
        height: 74,
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(26),
        ),
        child: Icon(
          widget.icon,
          color: widget.color,
          size: 42,
        ),
      ),
    );
  }
}