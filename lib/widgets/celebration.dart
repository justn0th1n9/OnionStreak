import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../state/habit_store.dart';
import 'onion_mascot.dart';

Future<void> showCelebration(BuildContext context, Habit habit, int streak) {
  final unit = unitStreak(habit);
  return showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.5, end: 1.0),
            duration: const Duration(milliseconds: 700),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: OnionMascot(streak: streak, size: 150),
          ),
          const SizedBox(height: 8),
          Text('Streak $streak $unit!',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Kamu konsisten $streak $unit berturut-turut di "${habit.nama}". Bawangmu makin besar.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Lanjut')),
      ],
    ),
  );
}
