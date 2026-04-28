import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/game_l10n.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../data/models/round_state_model.dart' show BiddingPhase;
import '../../domain/baloot_game_controller.dart' show GamePhase;
import '../game_provider.dart';
import 'playing_card.dart';

// ══════════════════════════════════════════════════════════════════
//  DEAL OVERLAY WIDGET
//
//  Shown on top of the rug during:
//  • dealing   — animated "dealing" spinner + label
//  • bidding   — buyer card face-up in center + round label
//
//  The buyer card is the single face-up card placed by the engine
//  during bidding so all players can see which card is at stake.
// ══════════════════════════════════════════════════════════════════

class DealOverlayWidget extends StatelessWidget {
  const DealOverlayWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final game  = context.watch<GameProvider>();
    final phase = game.phase;

    // All-pass both rounds — show cancelled overlay before new deal
    if (game.isRoundCancelled) {
      return _RoundCancelledOverlay(newDealerName: game.cancelledNewDealerName);
    }

    if (phase == GamePhase.dealing && !game.isRoundJustEnded) {
      return const _DealingSpinner();
    }

    if (phase == GamePhase.bidding || phase == GamePhase.doubleWindow) {
      final buyerCard = game.buyerCard;
      if (buyerCard != null) {
        return _BuyerCardDisplay(game: game);
      }
    }

    return const SizedBox.shrink();
  }
}

// ── Dealing spinner ────────────────────────────────────────────────

class _DealingSpinner extends StatefulWidget {
  const _DealingSpinner();

  @override
  State<_DealingSpinner> createState() => _DealingSpinnerState();
}

class _DealingSpinnerState extends State<_DealingSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    final loc = GameL10n.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RotationTransition(
            turns: _ctrl,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.goldAccent.withValues(alpha: 0.6),
                  width: 3,
                ),
              ),
              child: const Icon(
                Icons.style_outlined,
                color: AppColors.goldAccent,
                size: 22,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            loc.dealing,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Buyer card display ─────────────────────────────────────────────

class _BuyerCardDisplay extends StatefulWidget {
  final GameProvider game;
  const _BuyerCardDisplay({required this.game});

  @override
  State<_BuyerCardDisplay> createState() => _BuyerCardDisplayState();
}

class _BuyerCardDisplayState extends State<_BuyerCardDisplay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();
    _scale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    final loc = GameL10n.of(context);
    final game      = widget.game;
    final buyerCard = game.buyerCard!;
    final buyerIdx  = game.buyerIndex;
    final buyerName = buyerIdx != null ? game.playerName(buyerIdx) : '—';
    final phase     = game.phase;

    return Center(
      child: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Buyer label
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.goldAccent.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  buyerIdx != null ? loc.buyerLine(buyerName) : loc.bidding,
                  style: TextStyle(
                    color: AppColors.goldAccent,
                    fontSize: 11,
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // Buyer card — large, face-up
              PlayingCard(
                card: buyerCard,
                size: CardSize.large,
                faceUp: true,
              ),

              const SizedBox(height: 6),

              // Phase label (bidding round)
              _PhasePill(phase: phase, game: game),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

// ── Phase pill ─────────────────────────────────────────────────────

class _PhasePill extends StatelessWidget {
  final GamePhase phase;
  final GameProvider game;
  const _PhasePill({required this.phase, required this.game});

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    final loc = GameL10n.of(context);
    String label;
    Color color;

    switch (phase) {
      case GamePhase.bidding:
        final bp = game.biddingPhase;
        if (bp == BiddingPhase.hakamConfirmation) {
          label = loc.confirmOrSwitch;
        } else {
          label = bp == BiddingPhase.round2 ? loc.bidRound2 : loc.bidRound1;
        }
        color = AppColors.goldAccent;
        break;
      case GamePhase.doubleWindow:
        label = loc.doubleWindow;
        color = const Color(0xFFE63946);
        break;
      case GamePhase.projectDeclaration:
        label = loc.projects;
        color = AppColors.goldAccent;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontFamily: 'Tajawal',
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Round Cancelled overlay ─────────────────────────────────────────

class _RoundCancelledOverlay extends StatefulWidget {
  final String newDealerName;
  const _RoundCancelledOverlay({required this.newDealerName});

  @override
  State<_RoundCancelledOverlay> createState() => _RoundCancelledOverlayState();
}

class _RoundCancelledOverlayState extends State<_RoundCancelledOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, 0.45), // below the card throw zone
      child: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFE63946).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFE63946).withValues(alpha: 0.6),
                width: 1,
              ),
            ),
            child: Text(
              'الجلسة ملغية  •  موزع جديد: ${widget.newDealerName}',
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                color: Color(0xFFE63946),
                fontSize: 12,
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
