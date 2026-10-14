import 'package:flutter/material.dart';

import '../models/habit.dart';
import 'habit_style.dart';

class HabitTile extends StatelessWidget {
  const HabitTile({
    super.key,
    required this.habit,
    required this.done,
    required this.subtitle,
    required this.streak,
    required this.onTap,
    this.onToggle,
    this.paused = false,
  });

  final Habit habit;
  final bool done;
  final String subtitle;
  final int streak;
  final VoidCallback onTap;
  final VoidCallback? onToggle;
  final bool paused;

  @override
  Widget build(BuildContext context) {
    final warna = Color(habit.warna);
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: warna.withAlpha(40),
                child: Icon(ikonDari(habit.ikon), color: warna),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(habit.nama,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    Text(subtitle,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              if (streak > 0) ...[
                const Icon(Icons.local_fire_department,
                    size: 18, color: Color(0xFFF57C00)),
                Text('$streak',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
              ],
              if (paused)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.pause_circle_outline),
                )
              else
                Semantics(
                  button: true,
                  label: done ? 'Batalkan ${habit.nama}' : 'Selesaikan ${habit.nama}',
                  child: InkResponse(
                    onTap: onToggle,
                    radius: 28,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: done ? warna : Colors.transparent,
                          border: Border.all(color: warna, width: 2),
                        ),
                        child: done
                            ? const Icon(Icons.check, size: 20, color: Colors.white)
                            : null,
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
}
