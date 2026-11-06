import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../components/app_bottom_nav_bar.dart';
import 'analyze_food_page.dart';
import 'challenge_page.dart';
import 'chat_room_page.dart';
import 'home_page.dart';
import 'profile_page.dart';

class ExpertListPage extends StatefulWidget {
  const ExpertListPage({super.key});

  @override
  State<ExpertListPage> createState() => _ExpertListPageState();
}

class _ExpertListPageState extends State<ExpertListPage> {
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFFE8F5E9);
  static const Color backgroundColor = Color(0xFFF8FBF8);
  static const Color darkText = Color(0xFF1F2937);
  static const Color grayText = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFDC2626);

  bool _isCreatingChat = false;

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  void _handleNavTap(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
      return;
    }

    if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AnalyzeFoodPage()),
      );
      return;
    }

    if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ChallengePage()),
      );
      return;
    }

    if (index == 3) return;

    if (index == 4) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProfilePage()),
      );
    }
  }

  String _toText(dynamic value, {String defaultValue = '-'}) {
    if (value == null) return defaultValue;
    final String text = value.toString().trim();
    return text.isEmpty ? defaultValue : text;
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp is! Timestamp) return '';

    final DateTime dateTime = timestamp.toDate();
    final String day = dateTime.day.toString().padLeft(2, '0');
    final String month = dateTime.month.toString().padLeft(2, '0');
    final String hour = dateTime.hour.toString().padLeft(2, '0');
    final String minute = dateTime.minute.toString().padLeft(2, '0');

    return '$day/$month $hour:$minute';
  }

  void _showSnackBar(String message, {bool success = true}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? primaryGreen : dangerRed,
      ),
    );
  }

  Future<Map<String, dynamic>> _getUserData(String uid) async {
    final DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    return userDoc.data() as Map<String, dynamic>? ?? {};
  }

  Future<void> _openOrCreateChat({
    required String expertId,
    required Map<String, dynamic> expertData,
  }) async {
    final User? currentUser = _currentUser;

    if (currentUser == null) {
      _showSnackBar('กรุณาเข้าสู่ระบบก่อนใช้งานแชท', success: false);
      return;
    }

    if (_isCreatingChat) return;

    setState(() {
      _isCreatingChat = true;
    });

    try {
      final Map<String, dynamic> userData = await _getUserData(currentUser.uid);

      final String userName = _toText(
        userData['name'],
        defaultValue: currentUser.email ?? 'ผู้ใช้',
      );

      final String expertName = _toText(
        expertData['name'],
        defaultValue: 'ผู้เชี่ยวชาญ',
      );

      final String expertSpecialty = _toText(
        expertData['specialty'],
        defaultValue: 'โภชนาการ',
      );

      final String expertEmail = _toText(
        expertData['email'],
        defaultValue: '',
      );

      final String chatId = '${currentUser.uid}_$expertId';

      final DocumentReference chatRef =
          FirebaseFirestore.instance.collection('chats').doc(chatId);

      final DocumentSnapshot chatDoc = await chatRef.get();

      if (!chatDoc.exists) {
        await chatRef.set({
          'userId': currentUser.uid,
          'userName': userName,
          'userEmail': currentUser.email ?? '',
          'expertId': expertId,
          'expertName': expertName,
          'expertEmail': expertEmail,
          'expertSpecialty': expertSpecialty,
          'lastMessage': 'เริ่มต้นการปรึกษา',
          'lastMessageAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'status': 'open',
          'createdAt': FieldValue.serverTimestamp(),
        });

        await chatRef.collection('messages').add({
          'senderId': 'system',
          'senderName': 'ระบบ',
          'senderRole': 'system',
          'text':
              'สวัสดีครับ/ค่ะ คุณสามารถพิมพ์คำถามเกี่ยวกับอาหารและโภชนาการได้เลย',
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatRoomPage(
            chatId: chatId,
            expertName: expertName,
            expertSpecialty: expertSpecialty,
          ),
        ),
      );
    } catch (e) {
      _showSnackBar('เปิดห้องแชทไม่สำเร็จ: $e', success: false);
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingChat = false;
        });
      }
    }
  }

  void _openChatForExpert({
    required String chatId,
    required Map<String, dynamic> chatData,
  }) {
    final String userName = _toText(
      chatData['userName'],
      defaultValue: 'ผู้ใช้',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatRoomPage(
          chatId: chatId,
          expertName: userName,
          expertSpecialty: 'ผู้ใช้ที่เข้ามาปรึกษา',
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    if (!_isCreatingChat) return const SizedBox.shrink();

    return Container(
      color: Colors.black.withOpacity(0.15),
      child: const Center(
        child: CircularProgressIndicator(color: primaryGreen),
      ),
    );
  }

  Widget _buildUserHeaderCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2E7D32),
            Color(0xFF43A047),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.chat_bubble_rounded,
            color: Colors.white,
            size: 34,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ปรึกษาผู้เชี่ยวชาญ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'เลือกผู้เชี่ยวชาญเพื่อเริ่มถามเรื่องอาหาร โรคประจำตัว และโภชนาการเบื้องต้น',
                  style: TextStyle(
                    color: Color(0xFFE8F5E9),
                    fontSize: 13,
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

  Widget _buildExpertHeaderCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2E7D32),
            Color(0xFF43A047),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.support_agent_rounded,
            color: Colors.white,
            size: 36,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'แชทจากผู้ใช้',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'ตอบคำถามผู้ใช้ที่เข้ามาปรึกษาเรื่องอาหาร โรคประจำตัว และโภชนาการแบบเรียลไทม์',
                  style: TextStyle(
                    color: Color(0xFFE8F5E9),
                    fontSize: 13,
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

  Widget _buildExpertCard({
    required String expertId,
    required Map<String, dynamic> expertData,
  }) {
    final String name = _toText(
      expertData['name'],
      defaultValue: 'ผู้เชี่ยวชาญ',
    );

    final String specialty = _toText(
      expertData['specialty'],
      defaultValue: 'โภชนาการ',
    );

    final String expertBio = _toText(
      expertData['expertBio'],
      defaultValue: 'ให้คำปรึกษาด้านโภชนาการและการเลือกอาหาร',
    );

    final int experienceYears = _toInt(expertData['experienceYears']);
    final bool isVerified = expertData['isVerified'] == true;
    final bool isAvailable = expertData['isAvailable'] == true;

    return InkWell(
      onTap: isAvailable
          ? () => _openOrCreateChat(
                expertId: expertId,
                expertData: expertData,
              )
          : null,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: lightGreen,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.health_and_safety_rounded,
                color: primaryGreen,
                size: 32,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: darkText,
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isVerified)
                        const Icon(
                          Icons.verified_rounded,
                          color: primaryGreen,
                          size: 20,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    specialty,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: primaryGreen,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    expertBio,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: grayText,
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.work_history_rounded,
                        color: Colors.grey.shade500,
                        size: 16,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          experienceYears > 0
                              ? 'ประสบการณ์ $experienceYears ปี'
                              : 'พร้อมให้คำปรึกษา',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: grayText,
                            fontSize: 12,
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
                          color: isAvailable
                              ? lightGreen
                              : warningOrange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          isAvailable ? 'เริ่มแชท' : 'ไม่ว่าง',
                          style: TextStyle(
                            color: isAvailable ? primaryGreen : warningOrange,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isAvailable) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: primaryGreen,
                          size: 13,
                        ),
                      ],
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

  Widget _buildUserChatCard({
    required String chatId,
    required Map<String, dynamic> chatData,
  }) {
    final String userName = _toText(
      chatData['userName'],
      defaultValue: 'ผู้ใช้',
    );

    final String userEmail = _toText(
      chatData['userEmail'],
      defaultValue: '',
    );

    final String lastMessage = _toText(
      chatData['lastMessage'],
      defaultValue: 'ยังไม่มีข้อความ',
    );

    final String status = _toText(
      chatData['status'],
      defaultValue: 'open',
    );

    final String lastTime = _formatTime(chatData['lastMessageAt']);

    return InkWell(
      onTap: () => _openChatForExpert(
        chatId: chatId,
        chatData: chatData,
      ),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
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
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: lightGreen,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: primaryGreen,
                size: 34,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: darkText,
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (userEmail.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      userEmail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: grayText,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 7),
                  Text(
                    lastMessage,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: grayText,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: status == 'open'
                              ? lightGreen
                              : warningOrange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          status == 'open' ? 'กำลังเปิด' : status,
                          style: TextStyle(
                            color: status == 'open'
                                ? primaryGreen
                                : warningOrange,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (lastTime.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          lastTime,
                          style: const TextStyle(
                            color: grayText,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                      const Spacer(),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: primaryGreen,
                        size: 14,
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

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: primaryGreen,
              size: 64,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: darkText,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: grayText,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return _buildEmptyState(
      icon: Icons.error_outline_rounded,
      title: 'โหลดข้อมูลไม่สำเร็จ',
      subtitle: '$error',
    );
  }

  Widget _buildEmptyExperts() {
    return _buildEmptyState(
      icon: Icons.support_agent_rounded,
      title: 'ยังไม่มีผู้เชี่ยวชาญที่พร้อมให้บริการ',
      subtitle: 'กรุณาเพิ่ม users ที่มี role = expert และ isAvailable = true',
    );
  }

  Widget _buildEmptyExpertChats() {
    return _buildEmptyState(
      icon: Icons.mark_chat_unread_rounded,
      title: 'ยังไม่มีผู้ใช้ทักมา',
      subtitle: 'เมื่อผู้ใช้เลือกคุณเป็นผู้เชี่ยวชาญ ห้องแชทจะแสดงที่นี่แบบ realtime',
    );
  }

  Widget _buildNormalUserExpertList() {
    final User? user = _currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'expert')
          .where('isAvailable', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: primaryGreen),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error!);
        }

        final List<QueryDocumentSnapshot> experts =
            (snapshot.data?.docs ?? []).where((doc) {
          if (user == null) return true;
          return doc.id != user.uid;
        }).toList();

        if (experts.isEmpty) {
          return _buildEmptyExperts();
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildUserHeaderCard(),
            ...experts.map((doc) {
              final Map<String, dynamic> expertData =
                  doc.data() as Map<String, dynamic>? ?? {};

              return _buildExpertCard(
                expertId: doc.id,
                expertData: expertData,
              );
            }),
            const SizedBox(height: 90),
          ],
        );
      },
    );
  }

  Widget _buildExpertChatList(String expertId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('expertId', isEqualTo: expertId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: primaryGreen),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error!);
        }

        final List<QueryDocumentSnapshot> chats = snapshot.data?.docs ?? [];

        if (chats.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildExpertHeaderCard(),
              const SizedBox(height: 40),
              _buildEmptyExpertChats(),
            ],
          );
        }

        chats.sort((a, b) {
          final Map<String, dynamic> dataA =
              a.data() as Map<String, dynamic>? ?? {};
          final Map<String, dynamic> dataB =
              b.data() as Map<String, dynamic>? ?? {};

          final Timestamp? timeA = dataA['updatedAt'] is Timestamp
              ? dataA['updatedAt'] as Timestamp
              : dataA['lastMessageAt'] is Timestamp
                  ? dataA['lastMessageAt'] as Timestamp
                  : null;

          final Timestamp? timeB = dataB['updatedAt'] is Timestamp
              ? dataB['updatedAt'] as Timestamp
              : dataB['lastMessageAt'] is Timestamp
                  ? dataB['lastMessageAt'] as Timestamp
                  : null;

          return (timeB?.millisecondsSinceEpoch ?? 0)
              .compareTo(timeA?.millisecondsSinceEpoch ?? 0);
        });

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildExpertHeaderCard(),
            ...chats.map((doc) {
              final Map<String, dynamic> chatData =
                  doc.data() as Map<String, dynamic>? ?? {};

              return _buildUserChatCard(
                chatId: doc.id,
                chatData: chatData,
              );
            }),
            const SizedBox(height: 90),
          ],
        );
      },
    );
  }

  Widget _buildRoleBasedContent() {
    final User? user = _currentUser;

    if (user == null) {
      return _buildEmptyState(
        icon: Icons.login_rounded,
        title: 'กรุณาเข้าสู่ระบบ',
        subtitle: 'เข้าสู่ระบบเพื่อใช้งานระบบแชท',
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: primaryGreen),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error!);
        }

        final Map<String, dynamic> userData =
            snapshot.data?.data() as Map<String, dynamic>? ?? {};

        final String role = _toText(
          userData['role'],
          defaultValue: 'user',
        ).toLowerCase();

        debugPrint('CURRENT UID: ${user.uid}');
        debugPrint('CURRENT EMAIL: ${user.email}');
        debugPrint('CURRENT ROLE: $role');

        if (role == 'expert') {
          return _buildExpertChatList(user.uid);
        }

        return _buildNormalUserExpertList();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: darkText,
        elevation: 0,
        title: const Text(
          'แชท',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          _buildRoleBasedContent(),
          _buildLoadingOverlay(),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 3,
        onTap: _handleNavTap,
      ),
    );
  }
}