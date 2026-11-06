import 'dart:async';

import 'package:flutter/material.dart';

class HomeTopCardCarousel extends StatefulWidget {
  final String diseaseText;
  final String bmiText;
  final bool isLoggedIn;
  final int points;

  final VoidCallback onHealthTap;
  final VoidCallback onNutritionControlTap;
  final VoidCallback onSubscriptionTap;

  const HomeTopCardCarousel({
    super.key,
    required this.diseaseText,
    required this.bmiText,
    required this.isLoggedIn,
    this.points = 0,
    required this.onHealthTap,
    required this.onNutritionControlTap,
    required this.onSubscriptionTap,
  });

  @override
  State<HomeTopCardCarousel> createState() => _HomeTopCardCarouselState();
}

class _HomeTopCardCarouselState extends State<HomeTopCardCarousel> {
  static const Color primaryGreen = Color(0xFF16A34A);
  static const Color teal = Color(0xFF0F766E);
  static const Color orange = Color(0xFFF59E0B);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color indicatorGray = Color(0xFFD1D5DB);

  late final PageController _pageController;
  Timer? _timer;

  int _currentPage = 0;
  int _slideDirection = 1;

  @override
  void initState() {
    super.initState();

    _pageController = PageController(viewportFraction: 0.88);
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_pageController.hasClients) return;

      const int lastPage = 3;

      if (_currentPage == lastPage) {
        _slideDirection = -1;
      } else if (_currentPage == 0) {
        _slideDirection = 1;
      }

      final int nextPage = _currentPage + _slideDirection;

      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<_HomeCardData> cards = [
      _HomeCardData(
        title: 'คะแนนสะสม',
        subtitle: 'Point สำหรับทำ Challenge',
        icon: Icons.stars_rounded,
        primaryColor: purple,
        gradientColors: const [
          Color(0xFF8B5CF6),
          Color(0xFFA855F7),
          Color(0xFFEC4899),
        ],
        bullets: const [
          'สะสมคะแนนจาก Challenge',
          'ใช้ต่อยอดเป็นระบบรางวัลในอนาคต',
        ],
        buttonText: 'ดูโปรไฟล์',
        onTap: widget.onHealthTap,
        isPointCard: true,
        points: widget.points,
      ),
      _HomeCardData(
        title: 'ข้อมูลสุขภาพ',
        subtitle: widget.isLoggedIn
            ? 'ข้อมูลสุขภาพของคุณ'
            : 'เข้าสู่ระบบเพื่อบันทึกข้อมูล',
        icon: Icons.favorite_rounded,
        primaryColor: primaryGreen,
        gradientColors: const [
          Color(0xFF16A34A),
          Color(0xFF22C55E),
          Color(0xFF14B8A6),
        ],
        bullets: [
          'โรค: ${widget.diseaseText}',
          'BMI: ${widget.bmiText}',
        ],
        buttonText: widget.isLoggedIn ? 'ดูโปรไฟล์สุขภาพ' : 'เข้าสู่ระบบ',
        onTap: widget.onHealthTap,
      ),
      _HomeCardData(
        title: 'ข้อควบคุม',
        subtitle: 'ดูข้อควบคุมโภชนาการ',
        icon: Icons.health_and_safety_rounded,
        primaryColor: orange,
        gradientColors: const [
          Color(0xFFF59E0B),
          Color(0xFFF97316),
          Color(0xFFEF4444),
        ],
        bullets: const [
          'ควบคุมน้ำตาล โซเดียม ไขมัน',
          'เหมาะกับโรคและเป้าหมายสุขภาพ',
        ],
        buttonText: 'ดูข้อควบคุม',
        onTap: widget.onNutritionControlTap,
      ),
      _HomeCardData(
        title: 'แพ็กเกจเสริม',
        subtitle: 'ปลดล็อกฟีเจอร์ดูแลสุขภาพ',
        icon: Icons.workspace_premium_rounded,
        primaryColor: teal,
        gradientColors: const [
          Color(0xFF0F766E),
          Color(0xFF14B8A6),
          Color(0xFF22C55E),
        ],
        bullets: const [
          'วิเคราะห์อาหารไม่จำกัด',
          'Chat ผู้เชี่ยวชาญด้านโภชนาการ',
        ],
        buttonText: 'ดูแพ็กเกจ',
        onTap: widget.onSubscriptionTap,
      ),
    ];

    return Column(
      children: [
        SizedBox(
          height: 215,
          child: PageView.builder(
            controller: _pageController,
            itemCount: cards.length,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final _HomeCardData card = cards[index];

              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double scaleValue = 1.0;
                  double opacityValue = 1.0;

                  if (_pageController.position.haveDimensions) {
                    final double page =
                        _pageController.page ?? _currentPage.toDouble();

                    final double distance = page - index.toDouble();

                    scaleValue = (1 - (distance.abs() * 0.08))
                        .clamp(0.92, 1.0)
                        .toDouble();

                    opacityValue = (1 - (distance.abs() * 0.18))
                        .clamp(0.78, 1.0)
                        .toDouble();
                  }

                  return Opacity(
                    opacity: opacityValue,
                    child: Transform.scale(
                      scale: scaleValue,
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: card.isPointCard
                      ? _PointTopCard(
                          points: card.points,
                          title: card.title,
                          subtitle: card.subtitle,
                          icon: card.icon,
                          primaryColor: card.primaryColor,
                          gradientColors: card.gradientColors,
                          bullets: card.bullets,
                          buttonText: card.buttonText,
                          onTap: card.onTap,
                        )
                      : _HomeTopCard(
                          title: card.title,
                          subtitle: card.subtitle,
                          icon: card.icon,
                          primaryColor: card.primaryColor,
                          gradientColors: card.gradientColors,
                          bullets: card.bullets,
                          buttonText: card.buttonText,
                          onTap: card.onTap,
                        ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(cards.length, (index) {
            final bool selected = _currentPage == index;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: selected ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: selected ? primaryGreen : indicatorGray,
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _HomeTopCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color primaryColor;
  final List<Color> gradientColors;
  final List<String> bullets;
  final String buttonText;
  final VoidCallback onTap;

  const _HomeTopCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.primaryColor,
    required this.gradientColors,
    required this.bullets,
    required this.buttonText,
    required this.onTap,
  });

  @override
  State<_HomeTopCard> createState() => _HomeTopCardState();
}

class _HomeTopCardState extends State<_HomeTopCard> {
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
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutBack,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: widget.primaryColor.withValues(alpha: 0.24),
                  blurRadius: 22,
                  offset: const Offset(0, 11),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -24,
                  bottom: -32,
                  child: Icon(
                    widget.icon,
                    size: 126,
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Icon(
                            widget.icon,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                widget.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.86),
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ...widget.bullets.take(2).map((text) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: Colors.white.withValues(alpha: 0.92),
                              size: 17,
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Spacer(),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.20),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.buttonText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 17,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PointTopCard extends StatefulWidget {
  final int points;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color primaryColor;
  final List<Color> gradientColors;
  final List<String> bullets;
  final String buttonText;
  final VoidCallback onTap;

  const _PointTopCard({
    required this.points,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.primaryColor,
    required this.gradientColors,
    required this.bullets,
    required this.buttonText,
    required this.onTap,
  });

  @override
  State<_PointTopCard> createState() => _PointTopCardState();
}

class _PointTopCardState extends State<_PointTopCard> {
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
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutBack,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: widget.primaryColor.withValues(alpha: 0.26),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -22,
                  bottom: -34,
                  child: Icon(
                    Icons.stars_rounded,
                    size: 132,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.20),
                      ),
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.white,
                      size: 27,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'คะแนนสะสม',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.86),
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _AnimatedPointNumber(
                          points: widget.points,
                          fontSize: 42,
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 7),
                          child: Text(
                            'points',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.88),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...widget.bullets.take(2).map((text) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: Colors.white.withValues(alpha: 0.92),
                              size: 17,
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedPointNumber extends StatelessWidget {
  final int points;
  final double fontSize;

  const _AnimatedPointNumber({
    required this.points,
    this.fontSize = 12,
  });

  String _formatComma(int value) {
    return value.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
        );
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: 0,
        end: points.toDouble(),
      ),
      duration: const Duration(milliseconds: 950),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Text(
          _formatComma(value.round()),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        );
      },
    );
  }
}

class _HomeCardData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color primaryColor;
  final List<Color> gradientColors;
  final List<String> bullets;
  final String buttonText;
  final VoidCallback onTap;
  final bool isPointCard;
  final int points;

  const _HomeCardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.primaryColor,
    required this.gradientColors,
    required this.bullets,
    required this.buttonText,
    required this.onTap,
    this.isPointCard = false,
    this.points = 0,
  });
}