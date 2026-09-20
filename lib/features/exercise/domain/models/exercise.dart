import 'package:flutter/material.dart';
import 'package:rivalfit/app/theme/app_colors.dart';

/// Grupo muscular de la progresión personal. Cada grupo acumula reps
/// verificadas desde las sesiones y sube de nivel (Bronce -> Diamante).
enum MuscleGroup {
  chestArms('Pecho y brazos'),
  legs('Piernas'),
  core('Core'),
  cardio('Cardio');

  final String label;

  const MuscleGroup(this.label);
}

/// Ejercicio disponible para entrenar. En la Fase 1 el listado es estático;
/// luego se enriquece con reps de hoy, PR y si ya se mostró el tutorial.
class Exercise {
  final String id;
  final String name;
  final IconData icon;
  final Color accent;
  final List<MuscleGroup> muscleGroups;

  const Exercise({
    required this.id,
    required this.name,
    required this.icon,
    required this.accent,
    required this.muscleGroups,
  });

  String get muscleLabel =>
      muscleGroups.map((g) => g.label).join(' · ');
}

/// Catálogo inicial de RivalFit (PRD seccion 3).
const List<Exercise> appExercises = [
  Exercise(
    id: 'lagartijas',
    name: 'Lagartijas',
    icon: Icons.fitness_center_rounded,
    accent: AppColors.volt,
    muscleGroups: [MuscleGroup.chestArms],
  ),
  Exercise(
    id: 'sentadillas',
    name: 'Sentadillas',
    icon: Icons.accessibility_new_rounded,
    accent: AppColors.intermediateOrange,
    muscleGroups: [MuscleGroup.legs],
  ),
  Exercise(
    id: 'abdominales',
    name: 'Abdominales',
    icon: Icons.sports_gymnastics,
    accent: AppColors.advancedCoral,
    muscleGroups: [MuscleGroup.core],
  ),
  Exercise(
    id: 'dips',
    name: 'Dips',
    icon: Icons.self_improvement,
    accent: AppColors.carbon,
    muscleGroups: [MuscleGroup.chestArms],
  ),
  Exercise(
    id: 'cardio',
    name: 'Cardio',
    icon: Icons.monitor_heart_rounded,
    accent: AppColors.grayMain,
    muscleGroups: [MuscleGroup.cardio],
  ),
];