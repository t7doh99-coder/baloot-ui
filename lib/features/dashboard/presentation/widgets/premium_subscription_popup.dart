import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/l10n/locale_provider.dart';

class PremiumSubscriptionPopup extends StatefulWidget {
  const PremiumSubscriptionPopup({super.key});

  @override
  State<PremiumSubscriptionPopup> createState() => _PremiumSubscriptionPopupState();
}

class _PremiumSubscriptionPopupState extends State<PremiumSubscriptionPopup> with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _shimmerCtrl;
  String _selectedPlan = 'annual';
  String? _pressedBtn;

  final List<Map<String, dynamic>> _benefits = [
    {'icon': '✂️', 'ar': 'القطع والقيد', 'en': 'Cut & Bind'},
    {'icon': '👑', 'ar': 'ملكية الجلسة', 'en': 'Session Ownership'},
    {'icon': '🔒', 'ar': 'الجلسات الخاصة', 'en': 'Private Sessions'},
    {'icon': '💬', 'ar': 'الدردشة العامة والخاصة', 'en': 'Public & Private Chat'},
    {'icon': '➕', 'ar': 'إنشاء الجلسات', 'en': 'Create Sessions'},
    {'icon': '🚫', 'ar': 'بدون إعلانات', 'en': 'No Ads'},
    {'icon': '🎟️', 'ar': 'تذكرتان يومياً للكأس', 'en': '2 Daily Cup Tickets'},
    {'icon': '✨', 'ar': 'إرسال التعابير', 'en': 'Send Expressions'},
    {'icon': '🏆', 'ar': 'دوريات غير محدودة', 'en': 'Unlimited Tournaments'},
    {'icon': '🃏', 'ar': 'أوجه بطاقات حصرية', 'en': 'Exclusive Card Faces'},
  ];

  final List<Map<String, dynamic>> _plans = [
    {'id': 'weekly', 'ar': 'أسبوعي', 'en': 'Weekly', 'price': '12.99', 'unit': 'أسبوع', 'unit_en': 'Week', 'badge': null, 'badge_en': null},
    {'id': 'monthly', 'ar': 'شهري', 'en': 'Monthly', 'price': '34.99', 'unit': 'شهر', 'unit_en': 'Month', 'badge': '%وفر 30', 'badge_en': 'Save 30%'},
    {'id': 'annual', 'ar': 'سنوي', 'en': 'Annual', 'price': '284.99', 'unit': 'سنة', 'unit_en': 'Year', 'badge': '%وفر 55', 'badge_en': 'Save 55%'},
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LocaleProvider>().isArabic;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 80),
      child: Center(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 360),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFF4A3008), width: 1.5),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1E1308), Color(0xFF120C04), Color(0xFF0A0703)],
              stops: [0.0, 0.5, 1.0],
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x14D4A520), spreadRadius: 3),
              BoxShadow(color: Color(0x33B4780A), blurRadius: 60),
              BoxShadow(color: Color(0xE6000000), blurRadius: 100, offset: Offset(0, 40)),
            ],
          ),
          child: Stack(
            children: [
              // Quilted texture overlay
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: CustomPaint(painter: _QuiltedPainter()),
                ),
              ),

              // Content Column
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(isArabic),
                    _buildBenefits(isArabic),
                    _buildPricing(isArabic),
                  ],
                ),
              ),

              // Close Button
              Positioned(
                top: 14,
                right: 14,
                child: _CloseButton(onTap: () => Navigator.pop(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isArabic) {
    return Container(
      padding: const EdgeInsets.only(top: 32, left: 24, right: 24, bottom: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xE6321E05), Colors.transparent],
        ),
      ),
      child: Column(
        children: [


          // Title
          AnimatedBuilder(
            animation: _shimmerCtrl,
            builder: (context, child) {
              return ShaderMask(
                shaderCallback: (bounds) {
                  final stops = const [0.0, 0.3, 0.7, 1.0];
                  final gradient = const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFAEAA0), Color(0xFFF0C840), Color(0xFFC49010), Color(0xFF8B6010)],
                    stops: [0.0, 0.3, 0.7, 1.0],
                  );
                  // Shimmer overlay
                  final shimmerOffset = -2.0 + (_shimmerCtrl.value * 4.0);
                  // Return primary gradient (shimmer can be complex in Flutter with one ShaderMask, so we just use base gold gradient)
                  return gradient.createShader(bounds);
                },
                child: child,
              );
            },
            child: Text(
              'VIP PREMIUM',
              style: GoogleFonts.readexPro(
                
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 3.84, // 0.16em * 24
                color: Colors.white,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 6),

          Text(
            isArabic ? 'اشترك واحصل على تجربة لعب لا مثيل لها' : 'Subscribe for an unparalleled gaming experience',
            style: GoogleFonts.readexPro(
              
              fontSize: 12,
              color: Color(0xFF8B7040),
              letterSpacing: 0.24,
            ),
          ),
          const SizedBox(height: 18),

          // Gold Rule
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Color(0xFF5C3E0A)],
                      stops: [0.0, 0.8],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 5, height: 5, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF4A3008))),
                  const SizedBox(width: 5),
                  Transform.rotate(
                    angle: math.pi / 4,
                    child: Container(width: 5, height: 5, decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: const Color(0xFFD4A520))),
                  ),
                  const SizedBox(width: 5),
                  Container(width: 5, height: 5, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF4A3008))),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 1,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF5C3E0A), Colors.transparent],
                      stops: [0.2, 1.0],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBenefits(bool isArabic) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      child: Column(
        children: [
          Text(
            isArabic ? 'الميزات المميزة' : 'PREMIUM FEATURES',
            style: GoogleFonts.readexPro(
              
              fontSize: 9,
              letterSpacing: 2.25,
              color: Color(0xFF6B5028),
            ),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 7,
              crossAxisSpacing: 7,
              childAspectRatio: 4,
            ),
            itemCount: _benefits.length,
            itemBuilder: (context, index) {
              final b = _benefits[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0x12FFC832), Color(0x0AB4780A)],
                  ),
                  border: Border.all(color: const Color(0x21D4A520)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x4D000000), blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    Text(b['icon']!, style: GoogleFonts.readexPro(fontSize: 15, height: 1)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
                        child: Text(
                          isArabic ? b['ar']! : b['en']!,
                          style: GoogleFonts.readexPro(
                            
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFCDB882),
                            height: 1.3,
                          ),
                          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // Gold Divider
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Color(0xFF3A2606)],
                      stops: [0.0, 0.8],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.star, color: Color(0xFF3A2606), size: 14),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 1,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF3A2606), Colors.transparent],
                      stops: [0.2, 1.0],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPricing(bool isArabic) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: _plans.map((plan) {
              final sel = _selectedPlan == plan['id'];
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedPlan = plan['id']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutBack,
                      transform: Matrix4.translationValues(0, sel ? -6 : 0, 0)
                        ..scale(sel ? 1.04 : 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: sel
                                ? const [Color(0xFF2C1C08), Color(0xFF1A1004), Color(0xFF0F0902)]
                                : const [Color(0xFF181005), Color(0xFF0E0902)],
                            stops: sel ? const [0.0, 0.5, 1.0] : const [0.0, 1.0],
                          ),
                          border: Border.all(
                            color: sel ? const Color(0xFFC49010) : const Color(0x665C3E0A),
                            width: sel ? 1.5 : 1.0,
                          ),
                          boxShadow: sel
                              ? const [
                                  BoxShadow(color: Color(0x33C49010), spreadRadius: 3),
                                  BoxShadow(color: Color(0x40C49010), blurRadius: 20),
                                  BoxShadow(color: Color(0xFF3A2506), offset: Offset(0, 8)),
                                  BoxShadow(color: Color(0xB3000000), blurRadius: 20, offset: Offset(0, 12)),
                                ]
                              : const [
                                  BoxShadow(color: Color(0xCC140C03), offset: Offset(0, 4)),
                                  BoxShadow(color: Color(0x80000000), blurRadius: 12, offset: Offset(0, 6)),
                                ],
                        ),
                        child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              top: plan['badge'] != null ? 22 : 14,
                              bottom: 14,
                              left: 6,
                              right: 6,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    isArabic ? plan['ar'] : plan['en'],
                                    style: GoogleFonts.readexPro(
                                      
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: sel ? const Color(0xFFF0C840) : const Color(0xFF5C4018),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                ShaderMask(
                                  shaderCallback: (bounds) {
                                    return LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: sel
                                          ? const [Color(0xFFF8E060), Color(0xFFD4A520), Color(0xFF9A6C10)]
                                          : const [Color(0xFF6B5028), Color(0xFF3A2810)],
                                      stops: sel ? const [0.0, 0.6, 1.0] : const [0.0, 1.0],
                                    ).createShader(bounds);
                                  },
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      plan['price'],
                                      style: GoogleFonts.readexPro(
                                        
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        height: 1,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    isArabic ? 'AED / ${plan['unit']}' : '${plan['unit_en']} / AED',
                                    style: GoogleFonts.readexPro(
                                      
                                      fontSize: 9,
                                      color: sel ? const Color(0xFF7A5E28) : const Color(0xFF3A2810),
                                    ),
                                  ),
                                ),
                                Opacity(
                                  opacity: sel ? 1.0 : 0.0,
                                  child: Container(
                                    margin: const EdgeInsets.only(top: 7),
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFFD4A520),
                                      boxShadow: [BoxShadow(color: Color(0xE6D4A520), blurRadius: 8)],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (plan['badge'] != null)
                            Positioned(
                              top: -11,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    color: const Color(0xFF3A2408),
                                    border: Border.all(color: const Color(0xFFC49010)),
                                    boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 4, offset: Offset(0, 2))],
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      isArabic ? plan['badge'] : plan['badge_en'],
                                      style: GoogleFonts.readexPro(
                                        
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFFCDB882),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
          ),
          const SizedBox(height: 24),

          // 3D Subscribe Button
          Stack(
            children: [
              // Outer glow
              Positioned.fill(
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: const RadialGradient(
                      colors: [Color(0x4DD4A520), Colors.transparent],
                      stops: [0.0, 0.7],
                    ),
                  ),
                ),
              ),
              _Btn3D(
                isPressed: _pressedBtn == 'sub',
                onPress: () => setState(() => _pressedBtn = 'sub'),
                onRelease: () => setState(() => _pressedBtn = null),
                onTap: () {
                  // Subscribe Action
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'SUBSCRIBE NOW',
                      style: GoogleFonts.readexPro(
                        
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.8,
                        fontSize: 15,
                        color: const Color(0xFF1A0E02),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'اشترك الآن',
                      style: GoogleFonts.readexPro(
                        
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        color: const Color(0xBF1A0E02),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          
          // Fine print
          Text(
            isArabic ? 'يتجدد تلقائياً · يمكن الإلغاء في أي وقت' : 'Auto-renews · Cancel anytime',
            style: GoogleFonts.readexPro(
              fontSize: 9,
              color: const Color(0xFF3A2808),
              height: 1.7,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _Btn3D extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback onPress;
  final VoidCallback onRelease;
  final bool isPressed;

  const _Btn3D({
    required this.child,
    required this.onTap,
    required this.onPress,
    required this.onRelease,
    required this.isPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onPress(),
      onTapUp: (_) {
        onRelease();
        onTap();
      },
      onTapCancel: onRelease,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        transform: Matrix4.translationValues(0, isPressed ? 5 : 0, 0),
        child: Stack(
          children: [
            // Bottom 3D depth slab
            AnimatedContainer(
              duration: const Duration(milliseconds: 90),
              transform: Matrix4.translationValues(0, isPressed ? 0 : 5, 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: const Color(0xFF6A4A08),
              ),
              child: const SizedBox(height: 56, width: double.infinity),
            ),
            // Face
            AnimatedContainer(
              duration: const Duration(milliseconds: 90),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isPressed
                      ? const [Color(0xFFC49010), Color(0xFFE8B820), Color(0xFFC49010)]
                      : const [Color(0xFFF8E060), Color(0xFFE8C030), Color(0xFFD4A520), Color(0xFFB87E08)],
                  stops: isPressed ? const [0.0, 0.4, 1.0] : const [0.0, 0.25, 0.6, 1.0],
                ),
              ),
              child: Stack(
                children: [
                  if (!isPressed)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 28,
                      child: Container(
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x47FFFFFF), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                  Center(child: child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _QuiltedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = const Color(0x07D4A520)
      ..strokeWidth = 1.0;
    
    // Draw diagonal grid
    const double spacing = 28.0;
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), linePaint);
      canvas.drawLine(Offset(i, size.height), Offset(i + size.height, 0), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CloseButton extends StatefulWidget {
  final VoidCallback onTap;
  const _CloseButton({required this.onTap});

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xE6140C03),
            border: Border.all(
              color: _hover ? const Color(0xFFF0C840) : const Color(0xFFD4A520),
            ),
          ),
          child: Icon(
            Icons.close,
            size: 16,
            color: _hover ? const Color(0xFFF0C840) : const Color(0xFFD4A520),
          ),
        ),
      ),
    );
  }
}
