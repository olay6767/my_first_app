import 'package:flutter/material.dart';

class GrabMockOrderPage extends StatefulWidget {
  final String foodId;
  final Map<String, dynamic> foodData;

  const GrabMockOrderPage({
    super.key,
    required this.foodId,
    required this.foodData,
  });

  @override
  State<GrabMockOrderPage> createState() => _GrabMockOrderPageState();
}

class _GrabMockOrderPageState extends State<GrabMockOrderPage> {
  static const Color grabGreen = Color(0xFF00B14F);
  static const Color darkGreen = Color(0xFF00843D);
  static const Color lightGreen = Color(0xFFE9F9F0);
  static const Color backgroundColor = Color(0xFFF6F7F9);
  static const Color darkText = Color(0xFF111827);
  static const Color grayText = Color(0xFF6B7280);
  static const Color lightText = Color(0xFF9CA3AF);
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color redColor = Color(0xFFEF4444);

  int _quantity = 1;
  String _spicyLevel = 'ปกติ';
  String _riceOption = 'ปกติ';
  String _note = '';

  @override
  Widget build(BuildContext context) {
    final String foodName = _toText(
      widget.foodData['name'],
      defaultValue: 'ไม่มีชื่อเมนู',
    );

    final String restaurantName = _toText(
      widget.foodData['restaurantName'],
      defaultValue: 'ไม่ระบุร้าน',
    );

    final String imageUrl = _toText(
      widget.foodData['imageUrl'],
      defaultValue: '',
    );

    final String ingredients = _toText(
      widget.foodData['ingredients'],
      defaultValue: 'ยังไม่มีข้อมูลวัตถุดิบ',
    );

    final String recommendation = _toText(
      widget.foodData['recommendation'],
      defaultValue: 'ไม่มีคำแนะนำเพิ่มเติม',
    );

    final int price = _getPrice(widget.foodData);
    final int deliveryFee = 15;
    final int serviceFee = 5;
    final int totalPrice = (price * _quantity) + deliveryFee + serviceFee;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildAppBar(
                context: context,
                imageUrl: imageUrl,
                foodName: foodName,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 150),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFoodTitleCard(
                        foodName: foodName,
                        restaurantName: restaurantName,
                        price: price,
                      ),
                      const SizedBox(height: 12),
                      _buildDeliveryInfoCard(),
                      const SizedBox(height: 12),
                      _buildPromoCard(),
                      const SizedBox(height: 12),
                      _buildOptionSection(),
                      const SizedBox(height: 12),
                      _buildNutritionCard(),
                      const SizedBox(height: 12),
                      _buildDetailCard(
                        title: 'รายละเอียดเมนู',
                        icon: Icons.restaurant_menu_rounded,
                        content: ingredients,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailCard(
                        title: 'คำแนะนำด้านสุขภาพ',
                        icon: Icons.health_and_safety_rounded,
                        content: recommendation,
                      ),
                      const SizedBox(height: 12),
                      _buildNoteCard(),
                      const SizedBox(height: 12),
                      _buildPriceSummaryCard(
                        foodPrice: price * _quantity,
                        deliveryFee: deliveryFee,
                        serviceFee: serviceFee,
                        totalPrice: totalPrice,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          _buildBottomCartBar(totalPrice),
        ],
      ),
    );
  }

  Widget _buildAppBar({
    required BuildContext context,
    required String imageUrl,
    required String foodName,
  }) {
    return SliverAppBar(
      expandedHeight: 290,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: darkText,
      leading: Padding(
        padding: const EdgeInsets.only(left: 10),
        child: CircleAvatar(
          backgroundColor: Colors.white.withOpacity(0.95),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: darkText),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.95),
            child: IconButton(
              icon: const Icon(Icons.favorite_border_rounded, color: darkText),
              onPressed: () {
                _showSnackBar('บันทึกเมนูโปรดจำลองแล้ว');
              },
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 56, right: 56, bottom: 14),
        title: Text(
          foodName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            _buildFoodImage(imageUrl),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.08),
                    Colors.black.withOpacity(0.58),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              left: 16,
              bottom: 58,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: grabGreen,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.delivery_dining_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Food delivery mockup',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return _buildFoodImagePlaceholder();
    }

    final bool isNetworkImage =
        imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

    if (isNetworkImage) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildFoodImagePlaceholder();
        },
      );
    }

    return Image.asset(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _buildFoodImagePlaceholder();
      },
    );
  }

  Widget _buildFoodImagePlaceholder() {
    return Container(
      color: lightGreen,
      child: const Center(
        child: Icon(
          Icons.restaurant_menu_rounded,
          color: grabGreen,
          size: 82,
        ),
      ),
    );
  }

  Widget _buildFoodTitleCard({
    required String foodName,
    required String restaurantName,
    required int price,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            foodName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: darkText,
              fontSize: 24,
              height: 1.15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.storefront_rounded,
                color: grabGreen,
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  restaurantName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: grayText,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                '฿$price',
                style: const TextStyle(
                  color: darkText,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: redColor.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'ขายดี',
                  style: TextStyle(
                    color: redColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              _buildRatingBadge(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: warningOrange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.star_rounded,
            color: warningOrange,
            size: 16,
          ),
          SizedBox(width: 4),
          Text(
            '4.8',
            style: TextStyle(
              color: warningOrange,
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              _buildDeliveryIcon(Icons.timer_rounded),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'จัดส่งโดยประมาณ 15–25 นาที',
                      style: TextStyle(
                        color: darkText,
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'ระบบจำลองการสั่งอาหาร ยังไม่เชื่อมระบบจ่ายเงินจริง',
                      style: TextStyle(
                        color: grayText,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: lightText,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: borderColor),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildDeliveryIcon(Icons.location_on_rounded),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'ส่งถึง: ตำแหน่งปัจจุบันของผู้ใช้',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: darkText,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Text(
                'เปลี่ยน',
                style: TextStyle(
                  color: grabGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryIcon(IconData icon) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        icon,
        color: grabGreen,
        size: 22,
      ),
    );
  }

  Widget _buildPromoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: warningOrange.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: warningOrange.withOpacity(0.13),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.local_offer_rounded,
              color: warningOrange,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'โปรจำลอง: ส่งฟรีเมื่อสั่งครบ ฿120',
              style: TextStyle(
                color: Color(0xFF92400E),
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF92400E),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ปรับแต่งเมนู',
            style: TextStyle(
              color: darkText,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'เลือกตัวเลือกตามความต้องการ',
            style: TextStyle(
              color: grayText,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 14),
          _buildOptionGroup(
            title: 'ระดับความเผ็ด',
            selectedValue: _spicyLevel,
            options: const ['ไม่เผ็ด', 'ปกติ', 'เผ็ดมาก'],
            onChanged: (value) {
              setState(() {
                _spicyLevel = value;
              });
            },
          ),
          const SizedBox(height: 16),
          _buildOptionGroup(
            title: 'ปริมาณข้าว / เส้น',
            selectedValue: _riceOption,
            options: const ['น้อย', 'ปกติ', 'พิเศษ'],
            onChanged: (value) {
              setState(() {
                _riceOption = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOptionGroup({
    required String title,
    required String selectedValue,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: darkText,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Column(
          children: options.map((option) {
            final bool selected = selectedValue == option;

            return InkWell(
              onTap: () => onChanged(option),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: selected ? lightGreen : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? grabGreen : borderColor,
                    width: selected ? 1.4 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      selected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: selected ? grabGreen : lightText,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          color: selected ? darkGreen : darkText,
                          fontSize: 14,
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (option == 'พิเศษ')
                      const Text(
                        '+฿10',
                        style: TextStyle(
                          color: grayText,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
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

  Widget _buildNutritionCard() {
    final int calories = _toInt(widget.foodData['calories']);
    final int carb = _toInt(widget.foodData['carb']);
    final int protein = _toInt(widget.foodData['protein']);
    final int fat = _toInt(widget.foodData['fat']);
    final int sugar = _toInt(widget.foodData['sugar']);
    final int sodium = _toInt(widget.foodData['sodium']);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ข้อมูลโภชนาการ',
            style: TextStyle(
              color: darkText,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 13),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.5,
            children: [
              _buildNutritionItem(
                icon: Icons.local_fire_department_rounded,
                label: 'พลังงาน',
                value: '$calories kcal',
              ),
              _buildNutritionItem(
                icon: Icons.rice_bowl_rounded,
                label: 'คาร์บ',
                value: '$carb g',
              ),
              _buildNutritionItem(
                icon: Icons.fitness_center_rounded,
                label: 'โปรตีน',
                value: '$protein g',
              ),
              _buildNutritionItem(
                icon: Icons.opacity_rounded,
                label: 'ไขมัน',
                value: '$fat g',
              ),
              _buildNutritionItem(
                icon: Icons.cake_rounded,
                label: 'น้ำตาล',
                value: '$sugar g',
              ),
              _buildNutritionItem(
                icon: Icons.grain_rounded,
                label: 'โซเดียม',
                value: '$sodium mg',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: grabGreen,
            size: 21,
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
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: darkText,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard({
    required String title,
    required IconData icon,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: grabGreen,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: darkText,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
              color: grayText,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'หมายเหตุถึงร้าน',
            style: TextStyle(
              color: darkText,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            maxLines: 3,
            onChanged: (value) {
              _note = value.trim();
            },
            decoration: InputDecoration(
              hintText: 'เช่น ไม่ใส่พริก, ขอข้าวน้อย, ไม่ใส่น้ำตาล',
              hintStyle: const TextStyle(
                color: lightText,
                fontSize: 13,
              ),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.all(13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: grabGreen,
                  width: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSummaryCard({
    required int foodPrice,
    required int deliveryFee,
    required int serviceFee,
    required int totalPrice,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'สรุปราคา',
            style: TextStyle(
              color: darkText,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildPriceRow('ราคาอาหาร', foodPrice),
          _buildPriceRow('ค่าส่งจำลอง', deliveryFee),
          _buildPriceRow('ค่าบริการจำลอง', serviceFee),
          const Divider(height: 22, color: borderColor),
          _buildPriceRow(
            'รวมทั้งหมด',
            totalPrice,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    int price, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isTotal ? darkText : grayText,
                fontSize: isTotal ? 15.5 : 13.5,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
          Text(
            '฿$price',
            style: TextStyle(
              color: isTotal ? grabGreen : darkText,
              fontSize: isTotal ? 16.5 : 13.5,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCartBar(int totalPrice) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(26),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              _buildQuantityControl(),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _mockOrder(totalPrice),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: grabGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    'เพิ่มลงตะกร้า • ฿$totalPrice',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityControl() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _buildQuantityButton(
            icon: Icons.remove_rounded,
            onTap: () {
              if (_quantity <= 1) return;

              setState(() {
                _quantity--;
              });
            },
          ),
          SizedBox(
            width: 34,
            child: Text(
              '$_quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: darkText,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildQuantityButton(
            icon: Icons.add_rounded,
            onTap: () {
              setState(() {
                _quantity++;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 30,
        height: 30,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: grabGreen,
          size: 20,
        ),
      ),
    );
  }

  void _mockOrder(int totalPrice) {
    final String foodName = _toText(
      widget.foodData['name'],
      defaultValue: 'เมนูนี้',
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: 68,
                  height: 68,
                  decoration: const BoxDecoration(
                    color: lightGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: grabGreen,
                    size: 42,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'เพิ่มลงตะกร้าจำลองแล้ว',
                  style: TextStyle(
                    color: darkText,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '"$foodName" จำนวน $_quantity รายการ',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: grayText,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'เผ็ด: $_spicyLevel • ข้าว/เส้น: $_riceOption',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: grayText,
                    fontSize: 13,
                  ),
                ),
                if (_note.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'หมายเหตุ: $_note',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: grayText,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'รวม ฿$totalPrice',
                  style: const TextStyle(
                    color: grabGreen,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: grabGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'ตกลง',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: darkGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        content: Text(message),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
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
    );
  }

  int _getPrice(Map<String, dynamic> data) {
    final dynamic value =
        data['price'] ?? data['foodPrice'] ?? data['menuPrice'] ?? data['cost'];

    final int price = _toInt(value);

    if (price > 0) return price;

    return 59;
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String _toText(dynamic value, {String defaultValue = '-'}) {
    if (value == null) return defaultValue;

    final String text = value.toString().trim();

    if (text.isEmpty) return defaultValue;

    return text;
  }
}