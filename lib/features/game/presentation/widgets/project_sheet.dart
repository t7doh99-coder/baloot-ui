import 'package:flutter/material.dart';
import '../../../../data/models/card_model.dart';
import '../../../../data/models/round_state_model.dart';
import '../../domain/engines/project_detector.dart';
import 'playing_card.dart';

// ══════════════════════════════════════════════════════════════════
//  PROJECT PICKER SHEET — shown during trick 1
//
//  Displays the player's detected projects and lets them choose
//  which ones to declare (max 2, Baloot excluded — it's auto).
//
//  Per BALOOT_RULES.md Section 6.1:
//    • Announced in the FIRST trick via a UI button
//    • Each player may announce max 2 projects
//    • Baloot is auto — not shown here
// ══════════════════════════════════════════════════════════════════

class ProjectPickerSheet extends StatefulWidget {
  final List<DetectedProject> detected;
  final List<DeclaredProject> alreadyDeclared;
  final GameMode? mode;

  const ProjectPickerSheet({
    super.key,
    required this.detected,
    required this.alreadyDeclared,
    this.mode,
  });

  @override
  State<ProjectPickerSheet> createState() => _ProjectPickerSheetState();
}

class _ProjectPickerSheetState extends State<ProjectPickerSheet> {
  final Set<int> _selected = {};

  int get _alreadyCount => widget.alreadyDeclared.length;
  int get _remaining => 2 - _alreadyCount;

  @override
  Widget build(BuildContext context) {
    final projects = widget.detected
        .where((p) => p.type != ProjectType.baloot)
        .toList();

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8F6F0),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Title
          const Text('Declare Projects',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            _remaining > 0
                ? 'Select up to $_remaining project${_remaining > 1 ? 's' : ''}'
                : 'Maximum projects declared',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 14),

          // Project list
          if (projects.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text('No projects found in your hand',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14)),
            )
          else
            ...projects.asMap().entries.map((e) {
              final idx = e.key;
              final project = e.value;
              final isAlreadyDeclared = widget.alreadyDeclared
                  .any((d) => d.type == project.type);
              final isSelected = _selected.contains(idx);
              final canSelect = !isAlreadyDeclared &&
                  (_selected.length < _remaining || isSelected);

              return _ProjectTile(
                project: project,
                mode: widget.mode,
                isSelected: isSelected || isAlreadyDeclared,
                isDeclared: isAlreadyDeclared,
                enabled: canSelect && !isAlreadyDeclared,
                onTap: () {
                  if (isAlreadyDeclared) return;
                  setState(() {
                    if (isSelected) {
                      _selected.remove(idx);
                    } else if (_selected.length < _remaining) {
                      _selected.add(idx);
                    }
                  });
                },
              );
            }),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, <int>[]),
                  child: const Text('Skip',
                      style: TextStyle(color: Colors.grey, fontSize: 15)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _selected.isEmpty
                      ? null
                      : () => Navigator.pop(context, _selected.toList()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: const Color(0xFF3D2518),
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    _selected.isEmpty
                        ? 'Declare'
                        : 'Declare (${_selected.length})',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  SINGLE PROJECT TILE — shows type, cards, and abnat value
// ══════════════════════════════════════════════════════════════════

class _ProjectTile extends StatelessWidget {
  final DetectedProject project;
  final GameMode? mode;
  final bool isSelected;
  final bool isDeclared;
  final bool enabled;
  final VoidCallback onTap;

  const _ProjectTile({
    required this.project,
    this.mode,
    required this.isSelected,
    required this.isDeclared,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDeclared
        ? const Color(0xFF28802E)
        : isSelected
            ? const Color(0xFFD4AF37)
            : Colors.grey[300]!;

    final bgColor = isDeclared
        ? const Color(0xFF28802E).withValues(alpha: 0.08)
        : isSelected
            ? const Color(0xFFD4AF37).withValues(alpha: 0.08)
            : Colors.white;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            // Selection indicator
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected || isDeclared
                    ? borderColor
                    : Colors.grey[200],
                border: Border.all(color: borderColor),
              ),
              child: (isSelected || isDeclared)
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),

            // Project info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _projectLabel(project.type),
                        style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 6),
                      if (isDeclared)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF28802E),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Declared',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Card preview
                  SizedBox(
                    height: 36,
                    child: Row(
                      children: project.cards.map((c) => Padding(
                        padding: const EdgeInsets.only(right: 3),
                        child: PlayingCard(
                          card: c,
                          size: CardSize.small,
                          faceUp: true,
                        ),
                      )).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Points value
            Column(
              children: [
                Text(
                  _abnatValue(project.type, mode),
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFD4AF37)),
                ),
                const Text('Abnat',
                    style: TextStyle(fontSize: 9, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _projectLabel(ProjectType type) {
    switch (type) {
      case ProjectType.sera:        return 'Sera (3 in a row)';
      case ProjectType.fifty:       return 'Fifty (4 in a row)';
      case ProjectType.hundred:     return 'Hundred (5+)';
      case ProjectType.fourHundred: return 'Four Hundred (4 Aces)';
      case ProjectType.baloot:      return 'Baloot';
    }
  }

  static String _abnatValue(ProjectType type, GameMode? mode) {
    final isHakam = mode == GameMode.hakam;
    switch (type) {
      case ProjectType.sera:        return isHakam ? '20' : '4';
      case ProjectType.fifty:       return isHakam ? '50' : '10';
      case ProjectType.hundred:     return '100';
      case ProjectType.fourHundred: return '40';
      case ProjectType.baloot:      return '2';
    }
  }
}

// ══════════════════════════════════════════════════════════════════
//  PROJECT REVEAL BANNER — shown briefly at trick 2 start
// ══════════════════════════════════════════════════════════════════

class ProjectRevealBanner extends StatelessWidget {
  final List<DeclaredProject> projects;
  final String Function(int seat) playerName;

  const ProjectRevealBanner({
    super.key,
    required this.projects,
    required this.playerName,
  });

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0F08).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Projects Revealed',
              style: TextStyle(
                color: Color(0xFFD4AF37),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              )),
          const SizedBox(height: 8),
          ...projects.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            playerName(p.playerIndex),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: p.playerIndex % 2 == 0
                                  ? const Color(0xFF28802E)
                                  : const Color(0xFFE63946),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _typeLabel(p.type),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Horizontal scroll avoids Row overflow on narrow widths.
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: p.cards
                            .take(5)
                            .map(
                              (c) => Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: PlayingCard(
                                  card: c,
                                  size: CardSize.small,
                                  faceUp: true,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  static String _typeLabel(ProjectType type) {
    switch (type) {
      case ProjectType.sera:        return 'Sera';
      case ProjectType.fifty:       return 'Fifty';
      case ProjectType.hundred:     return 'Hundred';
      case ProjectType.fourHundred: return '400';
      case ProjectType.baloot:      return 'Baloot';
    }
  }
}
