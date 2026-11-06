import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatRoomPage extends StatefulWidget {
  final String chatId;
  final String expertName;
  final String expertSpecialty;

  const ChatRoomPage({
    super.key,
    required this.chatId,
    required this.expertName,
    required this.expertSpecialty,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFFE8F5E9);
  static const Color backgroundColor = Color(0xFFF8FBF8);
  static const Color darkText = Color(0xFF1F2937);
  static const Color grayText = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color dangerRed = Color(0xFFDC2626);
  static const Color warningOrange = Color(0xFFF59E0B);

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isSending = false;

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _toText(dynamic value, {String defaultValue = '-'}) {
    if (value == null) return defaultValue;
    final String text = value.toString().trim();
    return text.isEmpty ? defaultValue : text;
  }

  Future<Map<String, dynamic>> _getCurrentUserData() async {
    final User? user = _currentUser;

    if (user == null) return {};

    final DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    return userDoc.data() as Map<String, dynamic>? ?? {};
  }

  Future<void> _markMessagesAsRead() async {
    final User? user = _currentUser;

    if (user == null) return;

    try {
      final QuerySnapshot unreadSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .get();

      final WriteBatch batch = FirebaseFirestore.instance.batch();

      for (final doc in unreadSnapshot.docs) {
        final Map<String, dynamic> data =
            doc.data() as Map<String, dynamic>? ?? {};

        final String senderId = _toText(data['senderId'], defaultValue: '');

        if (senderId != user.uid && senderId != 'system') {
          batch.update(doc.reference, {
            'isRead': true,
            'readAt': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();
    } catch (_) {
      // ไม่ต้องโชว์ error เพราะเป็นแค่การ mark read
    }
  }

  Future<void> _sendMessage() async {
    final User? currentUser = _currentUser;

    if (currentUser == null) {
      _showSnackBar('กรุณาเข้าสู่ระบบก่อนส่งข้อความ');
      return;
    }

    final String text = _messageController.text.trim();

    if (text.isEmpty) return;
    if (_isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      final Map<String, dynamic> currentUserData =
          await _getCurrentUserData();

      final String senderName = _toText(
        currentUserData['name'],
        defaultValue: currentUser.email ?? 'ผู้ใช้',
      );

      final String senderRole = _toText(
        currentUserData['role'],
        defaultValue: 'user',
      );

      final DocumentReference chatRef =
          FirebaseFirestore.instance.collection('chats').doc(widget.chatId);

      final DocumentReference messageRef =
          chatRef.collection('messages').doc();

      final WriteBatch batch = FirebaseFirestore.instance.batch();

      batch.set(messageRef, {
        'senderId': currentUser.uid,
        'senderName': senderName,
        'senderRole': senderRole,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      batch.set(
        chatRef,
        {
          'lastMessage': text,
          'lastMessageAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'lastSenderId': currentUser.uid,
          'lastSenderName': senderName,
          'lastSenderRole': senderRole,
          'status': 'open',
        },
        SetOptions(merge: true),
      );

      await batch.commit();

      _messageController.clear();
    } catch (e) {
      _showSnackBar('ส่งข้อความไม่สำเร็จ: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp is! Timestamp) return '';

    final DateTime dateTime = timestamp.toDate();

    final String hour = dateTime.hour.toString().padLeft(2, '0');
    final String minute = dateTime.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  Widget _buildHeader() {
    final User? user = _currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .snapshots(),
      builder: (context, snapshot) {
        final Map<String, dynamic> chatData =
            snapshot.data?.data() as Map<String, dynamic>? ?? {};

        final String userId = _toText(chatData['userId'], defaultValue: '');
        final String expertId = _toText(chatData['expertId'], defaultValue: '');

        final String userName = _toText(
          chatData['userName'],
          defaultValue: 'ผู้ใช้',
        );

        final String expertName = _toText(
          chatData['expertName'],
          defaultValue: widget.expertName,
        );

        final String expertSpecialty = _toText(
          chatData['expertSpecialty'],
          defaultValue: widget.expertSpecialty,
        );

        final bool currentIsExpert = user != null && user.uid == expertId;

        final String title = currentIsExpert ? userName : expertName;
        final String subtitle =
            currentIsExpert ? 'ผู้ใช้ที่เข้ามาปรึกษา' : expertSpecialty;

        return Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: borderColor),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                color: darkText,
              ),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: lightGreen,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  currentIsExpert
                      ? Icons.person_rounded
                      : Icons.health_and_safety_rounded,
                  color: primaryGreen,
                  size: 27,
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
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: lightGreen,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'ออนไลน์',
                  style: TextStyle(
                    color: primaryGreen,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: warningOrange.withOpacity(0.22),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: warningOrange,
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'คำปรึกษาในแอปเป็นข้อมูลเบื้องต้น ไม่แทนการวินิจฉัยหรือการรักษาจากแพทย์',
              style: TextStyle(
                color: warningOrange,
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    final User? currentUser = _currentUser;

    if (currentUser == null) {
      return const Center(
        child: Text(
          'กรุณาเข้าสู่ระบบเพื่อใช้งานแชท',
          style: TextStyle(color: grayText),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
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
              padding: const EdgeInsets.all(18),
              child: Text(
                'โหลดข้อความไม่สำเร็จ: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: dangerRed,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }

        final List<QueryDocumentSnapshot> messages =
            snapshot.data?.docs ?? [];

        if (messages.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'ยังไม่มีข้อความ\nเริ่มพิมพ์เพื่อสนทนาได้เลย',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: grayText,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          );
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _markMessagesAsRead();
        });

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final Map<String, dynamic> message =
                messages[index].data() as Map<String, dynamic>? ?? {};

            return _buildMessageBubble(
              message: message,
              currentUserId: currentUser.uid,
            );
          },
        );
      },
    );
  }

  Widget _buildMessageBubble({
    required Map<String, dynamic> message,
    required String currentUserId,
  }) {
    final String senderId = _toText(message['senderId'], defaultValue: '');
    final String senderName = _toText(
      message['senderName'],
      defaultValue: 'ไม่ระบุชื่อ',
    );
    final String senderRole = _toText(
      message['senderRole'],
      defaultValue: 'user',
    );
    final String text = _toText(message['text'], defaultValue: '');
    final String timeText = _formatTime(message['createdAt']);

    final bool isMe = senderId == currentUserId;
    final bool isSystem = senderRole == 'system' || senderId == 'system';

    if (isSystem) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: borderColor.withOpacity(0.65),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: grayText,
              fontSize: 12.5,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) _buildAvatar(senderRole),
          if (!isMe) const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 3),
                    child: Text(
                      senderName,
                      style: const TextStyle(
                        color: grayText,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? primaryGreen : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 5),
                      bottomRight: Radius.circular(isMe ? 5 : 18),
                    ),
                    border: isMe ? null : Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.035),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isMe ? Colors.white : darkText,
                      fontSize: 14.5,
                      height: 1.35,
                    ),
                  ),
                ),
                if (timeText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                    child: Text(
                      timeText,
                      style: const TextStyle(
                        color: grayText,
                        fontSize: 10.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 8),
          if (isMe) _buildAvatar(senderRole),
        ],
      ),
    );
  }

  Widget _buildAvatar(String senderRole) {
    final bool isExpert = senderRole == 'expert';

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: isExpert ? lightGreen : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(
        isExpert ? Icons.health_and_safety_rounded : Icons.person_rounded,
        color: isExpert ? primaryGreen : const Color(0xFF2563EB),
        size: 20,
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        12,
        10 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: borderColor.withOpacity(0.8)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: 'พิมพ์ข้อความ...',
                hintStyle: const TextStyle(color: grayText),
                filled: true,
                fillColor: backgroundColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(
                    color: primaryGreen,
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _isSending ? null : _sendMessage,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _isSending ? grayText : primaryGreen,
                borderRadius: BorderRadius.circular(999),
              ),
              child: _isSending
                  ? const Padding(
                      padding: EdgeInsets.all(13),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 23,
                    ),
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
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildDisclaimer(),
            Expanded(
              child: _buildMessagesList(),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }
}