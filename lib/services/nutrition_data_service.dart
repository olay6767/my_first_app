import 'package:flutter/services.dart';

class NutritionInfo {
  final String directory;
  final String menuName;
  final double portionG;
  final String ingredients;

  final double kcal;
  final double carbG;
  final double sugarG;
  final double proteinG;
  final double fatG;
  final double saturatedFatG;
  final double sodiumMg;

  final String diabetesRisk;
  final String hypertensionRisk;
  final String dyslipidemiaRisk;
  final String kidneyRisk;
  final String obesityRisk;

  final String riskNote;
  final String recommendation;
  final String nutritionSource;
  final String riskCriteria;
  final String medicalDisclaimer;

  NutritionInfo({
    required this.directory,
    required this.menuName,
    required this.portionG,
    required this.ingredients,
    required this.kcal,
    required this.carbG,
    required this.sugarG,
    required this.proteinG,
    required this.fatG,
    required this.saturatedFatG,
    required this.sodiumMg,
    required this.diabetesRisk,
    required this.hypertensionRisk,
    required this.dyslipidemiaRisk,
    required this.kidneyRisk,
    required this.obesityRisk,
    required this.riskNote,
    required this.recommendation,
    required this.nutritionSource,
    required this.riskCriteria,
    required this.medicalDisclaimer,
  });

  factory NutritionInfo.fromMap(Map<String, String> map) {
    return NutritionInfo(
      directory: map['directory'] ?? '',
      menuName: map['menu_name'] ?? '',
      portionG: _toDouble(map['portion_g']),
      ingredients: map['ingredients'] ?? '',
      kcal: _toDouble(map['kcal']),
      carbG: _toDouble(map['carb_g']),
      sugarG: _toDouble(map['sugar_g']),
      proteinG: _toDouble(map['protein_g']),
      fatG: _toDouble(map['fat_g']),
      saturatedFatG: _toDouble(map['saturated_fat_g']),
      sodiumMg: _toDouble(map['sodium_mg']),
      diabetesRisk: map['diabetes_risk'] ?? '',
      hypertensionRisk: map['hypertension_risk'] ?? '',
      dyslipidemiaRisk: map['dyslipidemia_risk'] ?? '',
      kidneyRisk: map['kidney_risk'] ?? '',
      obesityRisk: map['obesity_risk'] ?? '',
      riskNote: map['risk_note'] ?? '',
      recommendation: map['recommendation'] ?? '',
      nutritionSource: map['nutrition_source'] ?? '',
      riskCriteria: map['risk_criteria'] ?? '',
      medicalDisclaimer: map['medical_disclaimer'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'directory': directory,
      'menuName': menuName,
      'portionG': portionG,
      'ingredients': ingredients,
      'kcal': kcal,
      'carbG': carbG,
      'sugarG': sugarG,
      'proteinG': proteinG,
      'fatG': fatG,
      'saturatedFatG': saturatedFatG,
      'sodiumMg': sodiumMg,
      'diabetesRisk': diabetesRisk,
      'hypertensionRisk': hypertensionRisk,
      'dyslipidemiaRisk': dyslipidemiaRisk,
      'kidneyRisk': kidneyRisk,
      'obesityRisk': obesityRisk,
      'riskNote': riskNote,
      'recommendation': recommendation,
      'nutritionSource': nutritionSource,
      'riskCriteria': riskCriteria,
      'medicalDisclaimer': medicalDisclaimer,
    };
  }

  static double _toDouble(String? value) {
    if (value == null) return 0;
    return double.tryParse(value.trim()) ?? 0;
  }
}

class DailyNutritionSummary {
  final double totalKcal;
  final double totalCarbG;
  final double totalSugarG;
  final double totalProteinG;
  final double totalFatG;
  final double totalSaturatedFatG;
  final double totalSodiumMg;

  DailyNutritionSummary({
    required this.totalKcal,
    required this.totalCarbG,
    required this.totalSugarG,
    required this.totalProteinG,
    required this.totalFatG,
    required this.totalSaturatedFatG,
    required this.totalSodiumMg,
  });

  Map<String, dynamic> toMap() {
    return {
      'totalKcal': totalKcal,
      'totalCarbG': totalCarbG,
      'totalSugarG': totalSugarG,
      'totalProteinG': totalProteinG,
      'totalFatG': totalFatG,
      'totalSaturatedFatG': totalSaturatedFatG,
      'totalSodiumMg': totalSodiumMg,
    };
  }
}

class NutritionDataService {
  final List<NutritionInfo> _menus = [];

  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  List<NutritionInfo> get menus => _menus;

  Future<void> loadNutritionData() async {
    if (_isLoaded) return;

    try {
      final tsvText = await rootBundle.loadString(
        'assets/data/menus_nutrition.tsv',
      );

      final rows = _parseTsv(tsvText);

      if (rows.isEmpty) {
        throw Exception('ไฟล์ menus_nutrition.tsv ไม่มีข้อมูล');
      }

      _menus.clear();

      for (final row in rows) {
        final nutrition = NutritionInfo.fromMap(row);

        if (nutrition.menuName.isNotEmpty) {
          _menus.add(nutrition);
        }
      }

      _isLoaded = true;

      print('✅ Nutrition data loaded: ${_menus.length} menus');
    } catch (e) {
      _isLoaded = false;
      throw Exception('โหลดข้อมูลโภชนาการไม่สำเร็จ: $e');
    }
  }

  List<Map<String, String>> _parseTsv(String text) {
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.length < 2) return [];

    final headers = lines.first.split('\t').map((e) => e.trim()).toList();

    final List<Map<String, String>> result = [];

    for (int i = 1; i < lines.length; i++) {
      final values = lines[i].split('\t');

      final Map<String, String> row = {};

      for (int j = 0; j < headers.length; j++) {
        row[headers[j]] = j < values.length ? values[j].trim() : '';
      }

      result.add(row);
    }

    return result;
  }

  Future<NutritionInfo?> findByMenuName(String menuName) async {
    if (!_isLoaded) {
      await loadNutritionData();
    }

    final query = _normalizeText(menuName);

    for (final menu in _menus) {
      if (_normalizeText(menu.menuName) == query) {
        return menu;
      }
    }

    for (final menu in _menus) {
      if (_normalizeText(menu.menuName).contains(query) ||
          query.contains(_normalizeText(menu.menuName))) {
        return menu;
      }
    }

    return null;
  }

  Future<NutritionInfo?> findByDirectory(String directory) async {
    if (!_isLoaded) {
      await loadNutritionData();
    }

    final query = directory.trim();

    for (final menu in _menus) {
      if (menu.directory == query) {
        return menu;
      }
    }

    return null;
  }

  Future<NutritionInfo?> findByPrediction({
    required String classId,
    required String foodName,
  }) async {
    if (!_isLoaded) {
      await loadNutritionData();
    }

    final byDirectory = await findByDirectory(classId);

    if (byDirectory != null) {
      return byDirectory;
    }

    return findByMenuName(foodName);
  }

  Future<List<NutritionInfo>> searchMenus(String keyword) async {
    if (!_isLoaded) {
      await loadNutritionData();
    }

    final query = _normalizeText(keyword);

    if (query.isEmpty) return _menus;

    return _menus.where((menu) {
      final name = _normalizeText(menu.menuName);
      final ingredients = _normalizeText(menu.ingredients);

      return name.contains(query) || ingredients.contains(query);
    }).toList();
  }

  Future<List<String>> getMenuNames() async {
    if (!_isLoaded) {
      await loadNutritionData();
    }

    return _menus.map((menu) => menu.menuName).toList();
  }

  DailyNutritionSummary calculateDailySummary(
    List<NutritionInfo> selectedMenus,
  ) {
    double totalKcal = 0;
    double totalCarbG = 0;
    double totalSugarG = 0;
    double totalProteinG = 0;
    double totalFatG = 0;
    double totalSaturatedFatG = 0;
    double totalSodiumMg = 0;

    for (final menu in selectedMenus) {
      totalKcal += menu.kcal;
      totalCarbG += menu.carbG;
      totalSugarG += menu.sugarG;
      totalProteinG += menu.proteinG;
      totalFatG += menu.fatG;
      totalSaturatedFatG += menu.saturatedFatG;
      totalSodiumMg += menu.sodiumMg;
    }

    return DailyNutritionSummary(
      totalKcal: totalKcal,
      totalCarbG: totalCarbG,
      totalSugarG: totalSugarG,
      totalProteinG: totalProteinG,
      totalFatG: totalFatG,
      totalSaturatedFatG: totalSaturatedFatG,
      totalSodiumMg: totalSodiumMg,
    );
  }

  String getRiskByDisease({
    required NutritionInfo nutrition,
    required String disease,
  }) {
    if (disease == 'เบาหวานชนิดที่ 2') {
      return nutrition.diabetesRisk;
    }

    if (disease == 'ความดันโลหิตสูง') {
      return nutrition.hypertensionRisk;
    }

    if (disease == 'ไขมันในเลือดสูง') {
      return nutrition.dyslipidemiaRisk;
    }

    if (disease == 'โรคไตเรื้อรัง') {
      return nutrition.kidneyRisk;
    }

    if (disease == 'โรคอ้วน') {
      return nutrition.obesityRisk;
    }

    return 'ไม่ระบุ';
  }

  String getOverallRiskForDiseases({
    required NutritionInfo nutrition,
    required List<String> diseases,
  }) {
    if (diseases.isEmpty) {
      return 'ไม่ระบุ';
    }

    final risks = diseases.map((disease) {
      return getRiskByDisease(
        nutrition: nutrition,
        disease: disease,
      );
    }).toList();

    if (risks.any((risk) => _isHighRisk(risk))) {
      return 'ไม่แนะนำ';
    }

    if (risks.any((risk) => _isMediumRisk(risk))) {
      return 'ควรระวัง';
    }

    return 'เหมาะสม';
  }

  int calculateSuitableScore({
    required NutritionInfo nutrition,
    required List<String> diseases,
  }) {
    if (diseases.isEmpty) {
      return 70;
    }

    final overallRisk = getOverallRiskForDiseases(
      nutrition: nutrition,
      diseases: diseases,
    );

    if (overallRisk == 'เหมาะสม') return 90;
    if (overallRisk == 'ควรระวัง') return 60;
    if (overallRisk == 'ไม่แนะนำ') return 30;

    return 70;
  }

  bool isOverDailyGoal({
    required DailyNutritionSummary summary,
    double calorieGoal = 1800,
    double carbGoal = 180,
    double sugarGoal = 25,
    double sodiumGoal = 1500,
    double fatGoal = 60,
  }) {
    return summary.totalKcal > calorieGoal ||
        summary.totalCarbG > carbGoal ||
        summary.totalSugarG > sugarGoal ||
        summary.totalSodiumMg > sodiumGoal ||
        summary.totalFatG > fatGoal;
  }

  Map<String, String> compareWithDailyGoal({
    required DailyNutritionSummary summary,
    double calorieGoal = 1800,
    double carbGoal = 180,
    double sugarGoal = 25,
    double sodiumGoal = 1500,
    double fatGoal = 60,
  }) {
    return {
      'calories': summary.totalKcal <= calorieGoal ? 'อยู่ในเกณฑ์' : 'เกินเป้าหมาย',
      'carb': summary.totalCarbG <= carbGoal ? 'อยู่ในเกณฑ์' : 'เกินเป้าหมาย',
      'sugar': summary.totalSugarG <= sugarGoal ? 'อยู่ในเกณฑ์' : 'เกินเป้าหมาย',
      'sodium': summary.totalSodiumMg <= sodiumGoal ? 'อยู่ในเกณฑ์' : 'เกินเป้าหมาย',
      'fat': summary.totalFatG <= fatGoal ? 'อยู่ในเกณฑ์' : 'เกินเป้าหมาย',
    };
  }

  bool _isHighRisk(String risk) {
    final value = risk.toLowerCase();

    return value.contains('สูง') ||
        value.contains('high') ||
        value.contains('ไม่แนะนำ') ||
        value.contains('avoid');
  }

  bool _isMediumRisk(String risk) {
    final value = risk.toLowerCase();

    return value.contains('กลาง') ||
        value.contains('medium') ||
        value.contains('ควรระวัง') ||
        value.contains('moderate');
  }

  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .replaceAll('_', '')
        .trim();
  }
}