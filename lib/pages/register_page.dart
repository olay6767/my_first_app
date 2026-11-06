import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'home_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFFE8F5E9);
  static const Color backgroundColor = Color(0xFFF8FBF8);
  static const Color darkText = Color(0xFF1F2937);
  static const Color grayText = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color dangerRed = Color(0xFFDC2626);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController heightController = TextEditingController();

  bool isLoading = false;
  bool isPasswordHidden = true;
  bool isConfirmPasswordHidden = true;

  String selectedGender = 'ไม่ระบุ';

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

  final List<String> selectedDiseases = [];
  final List<String> selectedAllergies = [];

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    ageController.dispose();
    weightController.dispose();
    heightController.dispose();
    super.dispose();
  }

  Future<void> registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    final String name = nameController.text.trim();
    final String email = emailController.text.trim().toLowerCase();
    final String password = passwordController.text.trim();

    final int age = int.tryParse(ageController.text.trim()) ?? 0;
    final double weight = double.tryParse(weightController.text.trim()) ?? 0;
    final double height = double.tryParse(heightController.text.trim()) ?? 0;
    final double bmi = calculateBmi(weight, height);

    try {
      setState(() {
        isLoading = true;
      });

      final UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('ไม่พบข้อมูลผู้ใช้หลังสมัครสมาชิก');
      }

      final String uid = firebaseUser.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'name': name,
        'email': email,
        'age': age,
        'gender': selectedGender,
        'weight': weight,
        'height': height,
        'bmi': bmi,
        'diseases': selectedDiseases,
        'allergies': selectedAllergies,
        'photoUrl': '',

        // สำคัญมาก:
        // สมัครผ่านแอปได้แค่ user เท่านั้น
        // ถ้าจะให้เป็น expert ให้ไปแก้ role ใน Firebase เอง
        'role': 'user',

        // ค่าเริ่มต้นสำหรับ user
        'points': 0,
        'isAvailable': false,
        'isVerified': false,

        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      showMessage('สมัครสมาชิกสำเร็จ');

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const HomePage(),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      showMessage(_getFirebaseAuthErrorMessage(e));
    } catch (e) {
      showMessage('เกิดข้อผิดพลาด: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  double calculateBmi(double weight, double heightCm) {
    if (weight <= 0 || heightCm <= 0) return 0;

    final double heightM = heightCm / 100;
    final double bmi = weight / (heightM * heightM);

    return double.parse(bmi.toStringAsFixed(2));
  }

  String _getFirebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'อีเมลนี้ถูกใช้งานแล้ว';
      case 'invalid-email':
        return 'รูปแบบอีเมลไม่ถูกต้อง';
      case 'weak-password':
        return 'รหัสผ่านไม่ปลอดภัยพอ';
      case 'operation-not-allowed':
        return 'ยังไม่ได้เปิด Email/Password ใน Firebase Authentication';
      case 'network-request-failed':
        return 'เชื่อมต่ออินเทอร์เน็ตไม่ได้';
      default:
        return e.message ?? 'สมัครสมาชิกไม่สำเร็จ';
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: message.contains('สำเร็จ') ? primaryGreen : dangerRed,
      ),
    );
  }

  void toggleDisease(String disease) {
    setState(() {
      if (selectedDiseases.contains(disease)) {
        selectedDiseases.remove(disease);
      } else {
        selectedDiseases.add(disease);
      }
    });
  }

  void toggleAllergy(String allergy) {
    setState(() {
      if (selectedAllergies.contains(allergy)) {
        selectedAllergies.remove(allergy);
      } else {
        selectedAllergies.add(allergy);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        foregroundColor: darkText,
        title: const Text(
          'สมัครสมาชิก',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: darkText,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildRegisterCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'สร้างบัญชี FoodSight',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: darkText,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'สมัครใหม่จะเป็นผู้ใช้ทั่วไปเท่านั้น ผู้เชี่ยวชาญให้แอดมินเปลี่ยน role ใน Firebase',
          style: TextStyle(
            fontSize: 15,
            color: grayText,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildTextField(
              controller: nameController,
              label: 'ชื่อ-นามสกุล หรือชื่อเล่น',
              hint: 'เช่น เสริม หรือ อภิรักษ์',
              icon: Icons.person_outline_rounded,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'กรุณากรอกชื่อ';
                }

                if (value.trim().length < 2) {
                  return 'ชื่อต้องมีอย่างน้อย 2 ตัวอักษร';
                }

                return null;
              },
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: emailController,
              label: 'อีเมล',
              hint: 'example@email.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'กรุณากรอกอีเมล';
                }

                final String email = value.trim();

                if (!email.contains('@') || !email.contains('.')) {
                  return 'กรุณากรอกอีเมลให้ถูกต้อง';
                }

                return null;
              },
            ),
            const SizedBox(height: 14),
            _buildPasswordField(),
            const SizedBox(height: 14),
            _buildConfirmPasswordField(),
            const SizedBox(height: 14),
            _buildTextField(
              controller: ageController,
              label: 'อายุ',
              hint: 'เช่น 20',
              icon: Icons.cake_outlined,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'กรุณากรอกอายุ';
                }

                final int? age = int.tryParse(value.trim());

                if (age == null) {
                  return 'กรุณากรอกอายุเป็นตัวเลข';
                }

                if (age <= 0 || age > 120) {
                  return 'กรุณากรอกอายุให้ถูกต้อง';
                }

                return null;
              },
            ),
            const SizedBox(height: 14),
            _buildGenderDropdown(),
            const SizedBox(height: 14),
            _buildTextField(
              controller: weightController,
              label: 'น้ำหนัก (kg)',
              hint: 'เช่น 60',
              icon: Icons.monitor_weight_outlined,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'กรุณากรอกน้ำหนัก';
                }

                final double? weight = double.tryParse(value.trim());

                if (weight == null) {
                  return 'กรุณากรอกน้ำหนักเป็นตัวเลข';
                }

                if (weight <= 0 || weight > 300) {
                  return 'กรุณากรอกน้ำหนักให้ถูกต้อง';
                }

                return null;
              },
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: heightController,
              label: 'ส่วนสูง (cm)',
              hint: 'เช่น 170',
              icon: Icons.height_rounded,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'กรุณากรอกส่วนสูง';
                }

                final double? height = double.tryParse(value.trim());

                if (height == null) {
                  return 'กรุณากรอกส่วนสูงเป็นตัวเลข';
                }

                if (height <= 0 || height > 250) {
                  return 'กรุณากรอกส่วนสูงให้ถูกต้อง';
                }

                return null;
              },
            ),
            const SizedBox(height: 22),
            _buildMultiSelectSection(
              title: 'โรคประจำตัว',
              subtitle: 'เลือกได้มากกว่า 1 โรค',
              icon: Icons.health_and_safety_outlined,
              options: diseaseOptions,
              selectedOptions: selectedDiseases,
              onTap: toggleDisease,
            ),
            const SizedBox(height: 20),
            _buildMultiSelectSection(
              title: 'อาหารที่แพ้',
              subtitle: 'เลือกได้มากกว่า 1 รายการ',
              icon: Icons.no_food_outlined,
              options: allergyOptions,
              selectedOptions: selectedAllergies,
              onTap: toggleAllergy,
            ),
            const SizedBox(height: 18),
            _buildRoleNotice(),
            const SizedBox(height: 24),
            _buildRegisterButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryGreen.withOpacity(0.25),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: primaryGreen,
            size: 22,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'บัญชีที่สมัครผ่านหน้านี้จะถูกสร้างเป็น role: user เท่านั้น',
              style: TextStyle(
                color: primaryGreen,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _inputDecoration(
        label: label,
        hint: hint,
        icon: icon,
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: passwordController,
      obscureText: isPasswordHidden,
      decoration: _inputDecoration(
        label: 'รหัสผ่าน',
        hint: 'อย่างน้อย 6 ตัวอักษร',
        icon: Icons.lock_outline_rounded,
      ).copyWith(
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              isPasswordHidden = !isPasswordHidden;
            });
          },
          icon: Icon(
            isPasswordHidden
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'กรุณากรอกรหัสผ่าน';
        }

        if (value.trim().length < 6) {
          return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
        }

        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: confirmPasswordController,
      obscureText: isConfirmPasswordHidden,
      decoration: _inputDecoration(
        label: 'ยืนยันรหัสผ่าน',
        hint: 'กรอกรหัสผ่านอีกครั้ง',
        icon: Icons.lock_reset_rounded,
      ).copyWith(
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              isConfirmPasswordHidden = !isConfirmPasswordHidden;
            });
          },
          icon: Icon(
            isConfirmPasswordHidden
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'กรุณายืนยันรหัสผ่าน';
        }

        if (value.trim() != passwordController.text.trim()) {
          return 'รหัสผ่านไม่ตรงกัน';
        }

        return null;
      },
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedGender,
      decoration: _inputDecoration(
        label: 'เพศ',
        hint: 'เลือกเพศ',
        icon: Icons.wc_rounded,
      ),
      items: const [
        DropdownMenuItem(value: 'ไม่ระบุ', child: Text('ไม่ระบุ')),
        DropdownMenuItem(value: 'ชาย', child: Text('ชาย')),
        DropdownMenuItem(value: 'หญิง', child: Text('หญิง')),
        DropdownMenuItem(value: 'อื่น ๆ', child: Text('อื่น ๆ')),
      ],
      onChanged: (value) {
        if (value == null) return;

        setState(() {
          selectedGender = value;
        });
      },
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: primaryGreen,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: dangerRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: dangerRed,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildMultiSelectSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<String> options,
    required List<String> selectedOptions,
    required void Function(String) onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: primaryGreen, size: 22),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: darkText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: grayText,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final bool isSelected = selectedOptions.contains(option);

            return InkWell(
              onTap: () => onTap(option),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? lightGreen : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isSelected ? primaryGreen : borderColor,
                    width: isSelected ? 1.4 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      size: 18,
                      color: isSelected ? primaryGreen : grayText,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      option,
                      style: TextStyle(
                        color: isSelected ? primaryGreen : darkText,
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
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

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : registerUser,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primaryGreen.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                'สมัครสมาชิก',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}