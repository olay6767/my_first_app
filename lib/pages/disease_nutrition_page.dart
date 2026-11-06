import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DiseaseNutritionPage extends StatefulWidget {
  const DiseaseNutritionPage({super.key});

  @override
  State<DiseaseNutritionPage> createState() => _DiseaseNutritionPageState();
}

class _DiseaseNutritionPageState extends State<DiseaseNutritionPage> {
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFFE8F5E9);
  static const Color backgroundColor = Color(0xFFF8FBF8);
  static const Color darkText = Color(0xFF1F2937);
  static const Color grayText = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFDC2626);

  String selectedDisease = 'เบาหวานชนิดที่ 2';

  List<String> get diseases {
    return diseaseData.keys.toList();
  }

  final Map<String, Map<String, dynamic>> diseaseData = {
    'เบาหวานชนิดที่ 2': {
      'icon': Icons.bloodtype_rounded,
      'level': 'ควบคุมน้ำตาลในเลือด',
      'description':
          'ควรควบคุมปริมาณคาร์โบไฮเดรต น้ำตาล และเลือกอาหารที่ย่อยช้า เพื่อช่วยให้ระดับน้ำตาลไม่พุ่งสูงเร็ว',
      'control': [
        'น้ำตาล',
        'คาร์โบไฮเดรต',
        'แคลอรี',
        'ไขมันอิ่มตัว',
      ],
      'recommended': [
        'ข้าวกล้องปริมาณพอดี',
        'อกไก่ / ปลา / ไข่ต้ม',
        'ผักใบเขียว',
        'ต้มยำ / แกงส้มรสไม่หวาน',
        'อาหารน้ำตาลต่ำ',
      ],
      'avoid': [
        'ข้าวเหนียวมะม่วง',
        'โรตี',
        'น้ำหวาน / ชานม',
        'ข้าวผัดปริมาณมาก',
        'ของทอดและของหวานจัด',
      ],
      'rules': [
        'แบ่งคาร์บต่อมื้อให้พอดี',
        'หลีกเลี่ยงน้ำตาลเติมเพิ่ม',
        'เลือกโปรตีนไม่ติดมัน',
        'เพิ่มผักในทุกมื้อ',
      ],
    },
    'ความดันโลหิตสูง': {
      'icon': Icons.monitor_heart_rounded,
      'level': 'ควบคุมโซเดียม',
      'description':
          'ควรลดอาหารเค็ม โซเดียมสูง และอาหารแปรรูป เพราะอาจทำให้ความดันโลหิตสูงขึ้น',
      'control': [
        'โซเดียม',
        'ไขมัน',
        'อาหารแปรรูป',
        'น้ำปลา / ซีอิ๊ว',
      ],
      'recommended': [
        'อาหารต้ม / นึ่ง',
        'ปลา / อกไก่',
        'ผักสดหรือผักลวก',
        'แกงส้มรสไม่เค็ม',
        'ลาบหรือส้มตำแบบลดเค็ม',
      ],
      'avoid': [
        'อาหารรสเค็มจัด',
        'ของหมักดอง',
        'บะหมี่กึ่งสำเร็จรูป',
        'อาหารแปรรูป',
        'น้ำจิ้ม / ซอสเยอะ',
      ],
      'rules': [
        'ลดน้ำปลา ซีอิ๊ว ซอสปรุงรส',
        'เลือกเมนูต้ม นึ่ง ย่าง แทนทอด',
        'ชิมก่อนปรุง',
        'หลีกเลี่ยงอาหารแปรรูป',
      ],
    },
    'โรคไตเรื้อรัง': {
      'icon': Icons.water_drop_rounded,
      'level': 'ควบคุมโซเดียมและโปรตีน',
      'description':
          'ควรควบคุมโซเดียม โปรตีน ฟอสฟอรัส และโพแทสเซียม ตามระดับความรุนแรงของโรคไต',
      'control': [
        'โซเดียม',
        'โปรตีน',
        'โพแทสเซียม',
        'ฟอสฟอรัส',
      ],
      'recommended': [
        'ข้าวสวยปริมาณพอดี',
        'ไข่ขาว',
        'ปลา / ไก่ปริมาณเหมาะสม',
        'ผักต้มบางชนิด',
        'อาหารรสอ่อน',
      ],
      'avoid': [
        'อาหารเค็มจัด',
        'อาหารแปรรูป',
        'เครื่องในสัตว์',
        'น้ำซุปเข้มข้น',
        'อาหารโปรตีนสูงเกินไป',
      ],
      'rules': [
        'ควบคุมโซเดียมอย่างเคร่งครัด',
        'ไม่กินโปรตีนมากเกินคำแนะนำ',
        'ระวังน้ำซุปและซอส',
        'ควรปรึกษาแพทย์หรือนักกำหนดอาหาร',
      ],
    },
    'ไขมันในเลือดสูง': {
      'icon': Icons.opacity_rounded,
      'level': 'ควบคุมไขมันอิ่มตัว',
      'description':
          'ควรลดไขมันอิ่มตัว ของทอด และอาหารมันจัด เพื่อช่วยลดความเสี่ยงของโรคหัวใจและหลอดเลือด',
      'control': [
        'ไขมันรวม',
        'ไขมันอิ่มตัว',
        'ของทอด',
        'น้ำมัน',
      ],
      'recommended': [
        'ปลา',
        'อกไก่',
        'ผักหลากสี',
        'อาหารต้ม / ย่าง',
        'แกงส้ม / ต้มยำไม่มัน',
      ],
      'avoid': [
        'หมูกรอบ',
        'ของทอด',
        'โรตี',
        'อาหารกะทิเยอะ',
        'หนังไก่ / เนื้อติดมัน',
      ],
      'rules': [
        'ลดของทอดและอาหารมัน',
        'เลือกโปรตีนไม่ติดมัน',
        'เพิ่มผักและใยอาหาร',
        'ลดอาหารที่ใช้น้ำมันมาก',
      ],
    },
    'โรคอ้วน': {
      'icon': Icons.fitness_center_rounded,
      'level': 'ควบคุมพลังงานรวม',
      'description':
          'ควรควบคุมพลังงานรวม ลดน้ำตาล ลดไขมัน และเลือกอาหารที่อิ่มนานแต่พลังงานไม่สูง',
      'control': [
        'แคลอรี',
        'น้ำตาล',
        'ไขมัน',
        'ปริมาณอาหาร',
      ],
      'recommended': [
        'ผักเยอะ',
        'ปลา / อกไก่',
        'อาหารต้ม / นึ่ง',
        'สุกี้น้ำ',
        'แกงส้ม / ต้มยำ',
      ],
      'avoid': [
        'ของทอด',
        'น้ำหวาน',
        'ของหวาน',
        'ข้าวปริมาณมาก',
        'อาหารไขมันสูง',
      ],
      'rules': [
        'ลดพลังงานต่อมื้อ',
        'เพิ่มผักและโปรตีนไม่ติดมัน',
        'หลีกเลี่ยงเครื่องดื่มหวาน',
        'ควบคุมปริมาณข้าวและของทอด',
      ],
    },
  };

  @override
  void initState() {
    super.initState();

    if (!diseaseData.containsKey(selectedDisease) && diseases.isNotEmpty) {
      selectedDisease = diseases.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: darkText),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'ข้อควบคุมโภชนาการ',
          style: TextStyle(
            color: darkText,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: user == null
          ? _buildContent(userData: null)
          : FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryGreen),
                  );
                }

                if (snapshot.hasError) {
                  return _buildContent(userData: null);
                }

                final Map<String, dynamic>? userData = snapshot.data?.data();

                return _buildContent(userData: userData);
              },
            ),
    );
  }

  Widget _buildContent({
    required Map<String, dynamic>? userData,
  }) {
    if (diseases.isEmpty) {
      return const Center(
        child: Text(
          'ยังไม่มีข้อมูลโรค',
          style: TextStyle(
            color: grayText,
            fontSize: 14,
          ),
        ),
      );
    }

    if (!diseaseData.containsKey(selectedDisease)) {
      selectedDisease = diseases.first;
    }

    final Map<String, dynamic> data =
        diseaseData[selectedDisease] ?? diseaseData[diseases.first]!;

    final _BmiInfo? bmiInfo = _getBmiInfo(userData);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDiseaseSelector(),
          const SizedBox(height: 18),
          _buildDiseaseHeader(data),
          const SizedBox(height: 14),
          _buildBmiAdviceCard(bmiInfo),
          const SizedBox(height: 18),
          _buildSectionTitle('สารอาหารที่ควรควบคุม'),
          const SizedBox(height: 10),
          _buildControlGrid(_safeList(data['control'])),
          const SizedBox(height: 20),
          _buildFoodListSection(
            title: 'อาหารที่แนะนำ',
            items: _safeList(data['recommended']),
            icon: Icons.check_circle_rounded,
            color: primaryGreen,
          ),
          const SizedBox(height: 20),
          _buildFoodListSection(
            title: 'อาหารที่ควรหลีกเลี่ยง',
            items: _safeList(data['avoid']),
            icon: Icons.cancel_rounded,
            color: dangerRed,
          ),
          const SizedBox(height: 20),
          _buildFoodListSection(
            title: 'คำแนะนำเพิ่มเติม',
            items: _safeList(data['rules']),
            icon: Icons.tips_and_updates_rounded,
            color: warningOrange,
          ),
          const SizedBox(height: 20),
          _buildDisclaimer(),
        ],
      ),
    );
  }

  Widget _buildDiseaseSelector() {
    final List<String> diseaseList = diseases;

    if (diseaseList.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: diseaseList.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final String disease = diseaseList[index];
          final bool isSelected = selectedDisease == disease;

          return InkWell(
            onTap: () {
              setState(() {
                selectedDisease = disease;
              });
            },
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected ? primaryGreen : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected ? primaryGreen : borderColor,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                disease,
                style: TextStyle(
                  color: isSelected ? Colors.white : grayText,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDiseaseHeader(Map<String, dynamic> data) {
    final IconData icon = data['icon'] is IconData
        ? data['icon'] as IconData
        : Icons.health_and_safety_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: primaryGreen,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedDisease,
                  style: const TextStyle(
                    color: darkText,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data['level']?.toString() ?? '-',
                  style: const TextStyle(
                    color: primaryGreen,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data['description']?.toString() ?? '-',
                  style: const TextStyle(
                    color: grayText,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBmiAdviceCard(_BmiInfo? bmiInfo) {
    if (bmiInfo == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_rounded, color: warningOrange),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'ยังไม่มีข้อมูล BMI ของผู้ใช้ ระบบจึงยังไม่สามารถให้คำแนะนำตามน้ำหนักได้',
                style: TextStyle(
                  color: grayText,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Color color;
    IconData icon;
    String title;
    List<String> advice;

    if (bmiInfo.isUnderWeight) {
      color = warningOrange;
      icon = Icons.trending_up_rounded;
      title = 'BMI ${bmiInfo.value.toStringAsFixed(1)}: น้ำหนักต่ำกว่าเกณฑ์';
      advice = [
        'ควรเพิ่มพลังงานต่อวันอย่างเหมาะสม',
        'เพิ่มโปรตีนคุณภาพดี เช่น ไข่ ปลา ไก่ เต้าหู้',
        'กินให้ครบ 3 มื้อ และอาจเพิ่มมื้อว่างสุขภาพ',
        'เลือกอาหารที่มีประโยชน์ ไม่ใช่เพิ่มของหวานหรือน้ำหวาน',
      ];
    } else if (bmiInfo.isOverWeight) {
      color = dangerRed;
      icon = Icons.trending_down_rounded;
      title = 'BMI ${bmiInfo.value.toStringAsFixed(1)}: ${bmiInfo.category}';
      advice = [
        'ควรลดพลังงานรวมต่อวัน',
        'ลดของทอด น้ำหวาน ของหวาน และอาหารไขมันสูง',
        'เพิ่มผัก โปรตีนไม่ติดมัน และอาหารที่อิ่มนาน',
        'ควบคุมปริมาณข้าว แป้ง และน้ำตาลในแต่ละมื้อ',
      ];
    } else {
      color = primaryGreen;
      icon = Icons.balance_rounded;
      title = 'BMI ${bmiInfo.value.toStringAsFixed(1)}: สมส่วน';
      advice = [
        'รักษาสัดส่วนอาหารให้สมดุล',
        'กินโปรตีน ผัก คาร์โบไฮเดรตในปริมาณเหมาะสม',
        'หลีกเลี่ยงหวาน มัน เค็มมากเกินไป',
        'เลือกอาหารตามข้อควบคุมของโรคที่เลือก',
      ];
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...advice.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_rounded, color: color, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: darkText,
                        fontSize: 13,
                        height: 1.35,
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

  Widget _buildControlGrid(List<String> items) {
    if (items.isEmpty) {
      return const Text(
        'ยังไม่มีข้อมูล',
        style: TextStyle(
          color: grayText,
          fontSize: 13,
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.8,
      children: items.map((item) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: warningOrange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item,
                  style: const TextStyle(
                    color: darkText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFoodListSection({
    required String title,
    required List<String> items,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor),
          ),
          child: items.isEmpty
              ? const Text(
                  'ยังไม่มีข้อมูล',
                  style: TextStyle(
                    color: grayText,
                    fontSize: 13,
                  ),
                )
              : Column(
                  children: items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(icon, color: color, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item,
                              style: const TextStyle(
                                color: darkText,
                                fontSize: 13.5,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: warningOrange),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'หมายเหตุ: คำแนะนำนี้เป็นข้อมูลเบื้องต้นสำหรับการทำโปรเจกต์ ไม่ใช่คำวินิจฉัยหรือคำสั่งรักษาทางการแพทย์ หากมีโรคประจำตัวควรปรึกษาแพทย์หรือนักกำหนดอาหาร',
              style: TextStyle(
                color: grayText,
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _BmiInfo? _getBmiInfo(Map<String, dynamic>? userData) {
    if (userData == null) return null;

    final double savedBmi = _toDouble(userData['bmi']);

    if (savedBmi > 0) {
      return _createBmiInfo(savedBmi);
    }

    final double weight = _firstDouble(
      userData,
      [
        'weightKg',
        'weight',
        'userWeight',
      ],
    );

    double height = _firstDouble(
      userData,
      [
        'heightCm',
        'height',
        'userHeight',
      ],
    );

    if (weight <= 0 || height <= 0) {
      return null;
    }

    if (height > 3) {
      height = height / 100;
    }

    final double bmi = weight / (height * height);
    return _createBmiInfo(bmi);
  }

  double _firstDouble(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
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

  double _toDouble(dynamic value) {
    if (value == null) return 0;

    if (value is double) return value;

    if (value is int) return value.toDouble();

    if (value is num) return value.toDouble();

    if (value is String) {
      return double.tryParse(value.trim()) ?? 0;
    }

    return 0;
  }

  List<String> _safeList(dynamic value) {
    if (value == null) return [];

    if (value is List<String>) {
      return value;
    }

    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }

    return [];
  }
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