import 'package:flutter/material.dart';
import 'package:rivalfit/app/theme/app_colors.dart';

/// Grupo muscular de la progresion personal. Cada grupo acumula reps
/// verificadas desde las sesiones y sube de nivel (Bronce -> Diamante).
///
/// [icon] es el icono canonico del grupo, compartido por el catalogo de
/// ejercicios y por la malla de "Musculos" de la tab Mi progreso.
enum MuscleGroup {
  chestArms('Pecho y brazos', Icons.fitness_center_rounded),
  legs('Piernas', Icons.accessibility_new_rounded),
  core('Abdomen', Icons.sports_gymnastics),
  cardio('Cardio', Icons.monitor_heart_rounded);

  final String label;
  final IconData icon;

  const MuscleGroup(this.label, this.icon);
}

/// Ejercicio disponible para entrenar. En la Fase 1 el listado es estatico;
/// luego se enriquece con reps de hoy, PR y si ya se mostro el tutorial.
///
/// El icono propio de cada ejercicio puede diferir del canonico de su grupo.
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

  String get muscleLabel => muscleGroups.map((g) => g.label).join(' · ');
}

/// Catálogo inicial de RivalFit (PRD seccion 3).
const List<Exercise> appExercises = [
  Exercise(
    id: 'sentadillas',
    name: 'Sentadillas',
    icon: Icons.accessibility_new_rounded,
    accent: AppColors.intermediateOrange,
    muscleGroups: [MuscleGroup.legs],
  ),
  Exercise(
    id: 'lagartijas',
    name: 'Lagartijas',
    icon: Icons.fitness_center_rounded,
    accent: AppColors.volt,
    muscleGroups: [MuscleGroup.chestArms],
  ),
  Exercise(
    id: 'abdominales',
    name: 'Abdominales',
    icon: Icons.sports_gymnastics,
    accent: AppColors.advancedCoral,
    muscleGroups: [MuscleGroup.core],
  ),
  Exercise(
    id: 'plancha',
    name: 'Plancha',
    icon: Icons.horizontal_rule_rounded,
    accent: AppColors.carbon,
    muscleGroups: [MuscleGroup.core],
  ),
];
