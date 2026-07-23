import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:baloot_game/core/painters/diamond_painter.dart';
import 'package:baloot_game/features/game/presentation/game_provider.dart';

// ══════════════════════════════════════════════════════════════════
//  SETTINGS SCREEN — Premium Sandstone UI (Option H)
//  Features: Profile summary row, left-aligned icons, richer toggles,
//            inner shadows, gold shimmer title, and confirmation UI.
// ══════════════════════════════════════════════════════════════════

const _kBgCanvas   = Color(0xFF1E1808);
const _kBgCard     = Color(0xFF2C2210);
const _kBgElevated = Color(0xFF392C14);
const _kSandGold   = Color(0xFFC49028);
const _kSandLight  = Color(0xFFDFAE45);

const _kCrimson    = Color(0xFF8B2020);
const _kTextPrim   = Color(0xFFF8EDD8);
const _kTextSec    = Color(0xFFC8A868);
const _kTextMuted  = Color(0xFF806840);
const _kSandBorder = Color(0x42C49028); // rgba(196,144,40,0.26)

class SettingsScreen extends StatefulWidget {
  final bool isArabic;
  const SettingsScreen({super.key, this.isArabic = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ── Audio Toggles ──
  bool _allVoices = true;
  bool _chatVoice = true;
  bool _soundEffects = true;

  // ── Voice Selection ──
  int _selectedVoiceIndex = 0;
  bool _differentVoicePerPlayer = false;

  final List<String> _voicesMale = ['Faisal', 'Ahmed', 'Majid', 'Turki'];
  final List<String> _voicesFemale = ['Suad', 'Sarah', 'Abeer', 'Anoud'];

  // ── Game Controls ──
  bool _cardShading = true;
  bool _swapConfirmation = false;
  bool _preBuy = true;
  bool _cardHeight = false;
  bool _vibration = true;
  bool _showTurn = true;

  // ── Social Media ──
  bool _googleLinked = true;
  bool _xLinked = false;
  bool _facebookLinked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1808),
      body: Stack(
        children: [
          // ── Diamond background — matches home screen game feel ──
          Positioned.fill(
            child: CustomPaint(painter: DiamondOnlyPainter()),
          ),
          // ── Content ──
          SafeArea(
            child: Column(
              children: [
                // ── Header Bar ──
                _buildHeader(),
                
                // ── Scrollable Body ──
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                    child: Column(
                      children: [
                        // ── Section 1: Audio Controls ──
                        _buildSectionPanel(
                          label: 'Audio Controls',
                          icon: Icons.volume_up_rounded,
                          child: Column(
                            children: [
                              _buildToggleRow(icon: Icons.campaign_rounded, label: 'All Voices', value: _allVoices, onChanged: (v) => setState(() => _allVoices = v)),
                              _buildToggleRow(icon: Icons.forum_rounded, label: 'Chat Voice', value: _chatVoice, onChanged: (v) => setState(() => _chatVoice = v)),
                              _buildToggleRow(icon: Icons.music_note_rounded, label: 'Sound Effects', value: _soundEffects, onChanged: (v) => setState(() => _soundEffects = v)),
                              _buildDivider(),
                              
                              // Player Voices
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text('Voice Selector', style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w700, color: _kSandLight)),
                              ),
                              const SizedBox(height: 12),
                              _buildVoiceGrid(),
                              const SizedBox(height: 12),
                              _buildToggleRow(icon: Icons.people_alt_rounded, label: 'Different voice for each player', value: _differentVoicePerPlayer, onChanged: (v) => setState(() => _differentVoicePerPlayer = v), isLast: true),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Section 2: Game Controls ──
                        _buildSectionPanel(
                          label: 'Game Controls',
                          icon: Icons.sports_esports_rounded,
                          child: Column(
                            children: [
                              _buildToggleRow(icon: Icons.style_rounded, label: 'Card Shading', subtitle: 'Shading cards unavailable in limited play', value: _cardShading, onChanged: (v) => setState(() => _cardShading = v)),
                              _buildToggleRow(icon: Icons.swap_horiz_rounded, label: 'Swap Confirmation', subtitle: 'Show confirmation menu when playing Swap', value: _swapConfirmation, onChanged: (v) => setState(() => _swapConfirmation = v)),
                              _buildToggleRow(icon: Icons.shopping_cart_checkout_rounded, label: 'Select Pre-Buy', subtitle: 'Allow pre-buying', value: _preBuy, onChanged: (v) => setState(() => _preBuy = v)),
                              _buildToggleRow(icon: Icons.height_rounded, label: 'Change Card Height', subtitle: 'Changes height of cards with different rank', value: _cardHeight, onChanged: (v) => setState(() => _cardHeight = v)),
                              _buildToggleRow(icon: Icons.vibration_rounded, label: 'Vibration Feature', subtitle: 'Enable device vibration', value: _vibration, onChanged: (v) => setState(() => _vibration = v)),
                              _buildToggleRow(icon: Icons.update_rounded, label: 'Show Your Turn', subtitle: 'Card height changes when it\'s your turn', value: _showTurn, onChanged: (v) => setState(() => _showTurn = v), isLast: true),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Section 3: Accounts ──
                        _buildSectionPanel(
                          label: 'Accounts',
                          icon: Icons.account_circle_rounded,
                          child: Column(
                            children: [
                              _buildProfileSummary(context),
                              _buildDivider(),
                              const SizedBox(height: 12),
                              _buildSocialRow(platform: 'Google', icon: Icons.g_mobiledata_rounded, isLinked: _googleLinked, onChanged: (v) => setState(() => _googleLinked = v)),
                              _buildSocialRow(platform: 'X (Twitter)', icon: Icons.alternate_email_rounded, isLinked: _xLinked, onChanged: (v) => setState(() => _xLinked = v)),
                              _buildSocialRow(platform: 'Facebook', icon: Icons.facebook_rounded, isLinked: _facebookLinked, onChanged: (v) => setState(() => _facebookLinked = v)),
                              _buildDivider(),
                              const SizedBox(height: 12),
                              _buildActionButton(label: 'Help', icon: Icons.help_outline_rounded),
                              const SizedBox(height: 8),
                              _buildActionButton(label: 'Privacy Policy', icon: Icons.privacy_tip_outlined),
                              const SizedBox(height: 8),
                              _buildActionButton(label: 'Delete Account', icon: Icons.delete_outline_rounded, isDestructive: true),
                              const SizedBox(height: 8),
                              _buildActionButton(label: 'Logout', icon: Icons.logout_rounded, isDestructive: true),
                            ],
                          ),
                        ),

                        // ── Footer ──
                        const SizedBox(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: _kBgElevated,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _kSandBorder),
                              ),
                              child: const Text('🃏', style: TextStyle(fontSize: 16)),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Kamelna v2.4.1',
                              style: GoogleFonts.readexPro(color: _kTextMuted, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  HEADER
  // ════════════════════════════════════════════════════════════════
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x1AC49028))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button — game-mode handle style
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: CustomPaint(
              painter: _BackHandlePainter(),
              child: SizedBox(
                width: 64,
                height: 40,
                child: Center(
                  child: CustomPaint(
                    size: const Size(11, 20),
                    painter: _BackChevronPainter(),
                  ),
                ),
              ),
            ),
          ),
          Column(
            children: [
              Text(
                widget.isArabic ? 'الإعدادات' : 'Settings',
                style: GoogleFonts.cairo(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  foreground: Paint()
                    ..shader = const LinearGradient(
                      colors: [_kSandGold, _kSandLight, Color(0xFFF5E6C0), _kSandLight, _kSandGold],
                    ).createShader(const Rect.fromLTWH(0, 0, 200, 50)),
                ),
              ),
              Text(
                'Customize your experience',
                style: GoogleFonts.readexPro(fontSize: 11, color: _kTextMuted, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(width: 44), // balance back button
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  SECTION PANEL
  // ════════════════════════════════════════════════════════════════
  Widget _buildSectionPanel({required String label, required IconData icon, required Widget child}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [_kBgCard, _kBgElevated],
            ),
            border: Border.all(color: _kSandBorder),
            boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 20, offset: Offset(0, 8))],
          ),
          child: child,
        ),
        // Inner shadow on top edge (fake it with a top positioned container)
        Positioned(
          top: 17, left: 1, right: 1,
          child: Container(
            height: 20,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.black.withValues(alpha: 0.2), Colors.transparent],
              ),
            ),
          ),
        ),
        // Section Header Pill
        Positioned(
          top: 0, left: 0, right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: _kBgElevated,
                border: Border.all(color: _kSandBorder),
                boxShadow: const [BoxShadow(color: Color(0x33C49028), blurRadius: 12)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: _kSandGold),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w800, color: _kSandLight, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  TOGGLE ROW
  // ════════════════════════════════════════════════════════════════
  Widget _buildToggleRow({
    required IconData icon,
    required String label,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: subtitle != null ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kBgCanvas,
              border: Border.all(color: _kSandBorder),
            ),
            child: Icon(icon, size: 18, color: _kTextSec),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (subtitle == null) const SizedBox(height: 8),
                Text(label, style: GoogleFonts.cairo(color: _kTextPrim, fontSize: 15, fontWeight: FontWeight.w700)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.readexPro(color: _kTextMuted, fontSize: 11, height: 1.2)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: _kBgCanvas,
            activeTrackColor: _kSandLight,
            inactiveThumbColor: const Color(0xFF4A3818),
            inactiveTrackColor: _kBgCanvas,
            trackOutlineColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return Colors.transparent;
              return _kSandBorder;
            }),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  VOICE GRID
  // ════════════════════════════════════════════════════════════════
  Widget _buildVoiceGrid() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(4, (i) => _buildVoiceChip(_voicesMale[i], i, '👨🏽')),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(4, (i) => _buildVoiceChip(_voicesFemale[i], i + 4, '👩🏽')),
        ),
      ],
    );
  }

  Widget _buildVoiceChip(String name, int index, String emoji) {
    final isSelected = _selectedVoiceIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedVoiceIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 70, height: 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? _kSandGold : _kBgCanvas,
          border: Border.all(color: isSelected ? _kSandLight : _kSandBorder),
          boxShadow: isSelected ? const [BoxShadow(color: Color(0x66C49028), blurRadius: 12)] : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: GoogleFonts.cairo(
                    color: isSelected ? _kBgCanvas : _kTextSec,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (isSelected)
              const Positioned(
                top: 4, right: 4,
                child: Icon(Icons.mic_rounded, size: 14, color: _kBgCanvas),
              ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  ACCOUNTS SECTION
  // ════════════════════════════════════════════════════════════════
  Widget _buildProfileSummary(BuildContext context) {
    final stats = context.watch<GameProvider>().playerStats;
    return Row(
      children: [
        Container(
          width: 54, height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _kBgCanvas,
            border: Border.all(color: _kSandGold, width: 2),
            boxShadow: const [BoxShadow(color: Color(0x33C49028), blurRadius: 8)],
          ),
          child: const Icon(Icons.person, color: _kTextSec, size: 30),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(stats.playerName, style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w800, color: _kTextPrim)),
              Text('ghh.lof@example.com', style: GoogleFonts.readexPro(fontSize: 12, color: _kTextMuted)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSocialRow({required String platform, required IconData icon, required bool isLinked, required ValueChanged<bool> onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isLinked ? const Color(0xFF2ECC71).withValues(alpha: 0.15) : _kBgCanvas,
              border: Border.all(color: isLinked ? const Color(0xFF2ECC71) : _kSandBorder),
            ),
            child: Icon(icon, size: 20, color: isLinked ? const Color(0xFF2ECC71) : _kTextSec),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(platform, style: GoogleFonts.cairo(color: _kTextPrim, fontSize: 15, fontWeight: FontWeight.w700)),
          ),
          GestureDetector(
            onTap: () => onChanged(!isLinked),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: isLinked ? const Color(0xFF2ECC71).withValues(alpha: 0.1) : _kSandGold,
                border: Border.all(color: isLinked ? const Color(0xFF2ECC71) : Colors.transparent),
                boxShadow: isLinked ? null : const [BoxShadow(color: Color(0x44C49028), blurRadius: 8)],
              ),
              child: Text(
                isLinked ? 'Linked' : 'Link',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isLinked ? const Color(0xFF2ECC71) : _kBgCanvas,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required String label, required IconData icon, bool isDestructive = false}) {
    return GestureDetector(
      onTap: () {
        if (isDestructive) {
          _showConfirmationDialog(label);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isDestructive ? _kCrimson.withValues(alpha: 0.1) : _kBgCanvas,
          border: Border.all(color: isDestructive ? _kCrimson.withValues(alpha: 0.3) : _kSandBorder),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isDestructive ? _kCrimson : _kTextSec),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDestructive ? _kCrimson : _kTextPrim,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, size: 20, color: isDestructive ? _kCrimson : _kTextMuted),
          ],
        ),
      ),
    );
  }

  void _showConfirmationDialog(String action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _kBgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: _kSandBorder)),
        title: Text('Confirm $action', style: GoogleFonts.cairo(color: _kTextPrim, fontWeight: FontWeight.w800)),
        content: Text('Are you sure you want to proceed with $action? This action cannot be undone.', style: GoogleFonts.readexPro(color: _kTextMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.cairo(color: _kTextSec, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kCrimson,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Confirm', style: GoogleFonts.cairo(color: _kTextPrim, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, _kSandBorder, Colors.transparent],
        ),
      ),
    );
  }
}

// ── Gold trapezoid back-button painters ───────────────────────────────────────

class _BackHandlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double inset = 8.0, slope = 10.0, r = 8.0;
    final outerPath = Path()
      ..moveTo(inset + r, 0)
      ..lineTo(size.width - inset - r, 0)
      ..quadraticBezierTo(size.width - inset, 0, size.width - inset + slope * 0.4, size.height * 0.4)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..lineTo(inset - slope * 0.4, size.height * 0.4)
      ..quadraticBezierTo(inset, 0, inset + r, 0)
      ..close();
    canvas.drawPath(outerPath, Paint()
      ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFF392C14), Color(0xFF1E1808)]).createShader(Offset.zero & size));
    canvas.drawPath(Path()
      ..moveTo(0, size.height)
      ..lineTo(inset - slope * 0.4, size.height * 0.4)
      ..quadraticBezierTo(inset, 0, inset + r, 0)
      ..lineTo(size.width - inset - r, 0)
      ..quadraticBezierTo(size.width - inset, 0, size.width - inset + slope * 0.4, size.height * 0.4)
      ..lineTo(size.width, size.height),
      Paint()..color = const Color(0xFFC49028)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    const double px = 10, py = 6;
    final innerRect = Rect.fromLTRB(px, py, size.width - px, size.height - py);
    final inner = RRect.fromRectAndRadius(innerRect, const Radius.circular(6));
    canvas.drawRRect(inner.shift(const Offset(0, 2)), Paint()..color = const Color(0xFF141008));
    canvas.drawRRect(inner, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFFC49028), Color(0xFF886018)]).createShader(innerRect));
    final glossRect = Rect.fromLTRB(px, py, size.width - px, py + (size.height - py * 2) * 0.45);
    canvas.drawRRect(RRect.fromRectAndRadius(glossRect, const Radius.circular(6)),
        Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0x99FFFFFF), Color(0x00FFFFFF)]).createShader(glossRect));
    canvas.drawRRect(inner, Paint()..color = const Color(0xFFDFAE45)..style = PaintingStyle.stroke..strokeWidth = 1.2);
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}

class _BackChevronPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.8, 0)
      ..lineTo(size.width * 0.2, size.height * 0.5)
      ..lineTo(size.width * 0.8, size.height);
    canvas.drawPath(path, Paint()..color = const Color(0xFF141008)..style = PaintingStyle.stroke
        ..strokeWidth = 5.0..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
    canvas.drawPath(path, Paint()..color = Colors.white..style = PaintingStyle.stroke
        ..strokeWidth = 2.5..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}
