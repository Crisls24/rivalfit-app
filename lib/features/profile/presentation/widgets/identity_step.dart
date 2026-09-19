import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:rivalfit/app/theme/app_colors.dart';

import 'avatar_selector.dart';

/// Paso 1 — Identidad.
/// Avatar flotante con halo Volt + campo alias limpio + campo edad +
/// preview de rival. Recibe todo su estado desde [CompleteProfilePage];
/// no maneja estado propio.
class IdentityStep extends StatelessWidget {
  final ImageProvider? avatarImage;
  final String initials;
  final bool uploading;
  final VoidCallback onPickAvatar;
  final TextEditingController nameController;
  final FocusNode nameFocusNode;
  final bool nameFocused;
  final bool hasName;
  final String alias;
  final VoidCallback onNameChanged;
  final VoidCallback onUnfocus;
  final TextEditingController ageController;
  final FocusNode ageFocusNode;
  final bool ageFocused;
  final bool hasAge;
  final VoidCallback onAgeChanged;
  final VoidCallback onAgeUnfocus;

  const IdentityStep({
    super.key,
    required this.avatarImage,
    required this.initials,
    required this.uploading,
    required this.onPickAvatar,
    required this.nameController,
    required this.nameFocusNode,
    required this.nameFocused,
    required this.hasName,
    required this.alias,
    required this.onNameChanged,
    required this.onUnfocus,
    required this.ageController,
    required this.ageFocusNode,
    required this.ageFocused,
    required this.hasAge,
    required this.onAgeChanged,
    required this.onAgeUnfocus,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Avatar flotante sobre disco volt ──
          _AvatarHero(
            image: avatarImage,
            initials: initials,
            uploading: uploading,
            onTap: onPickAvatar,
            compact: nameFocused || ageFocused,
          )
              .animate()
              .fadeIn(duration: 300.ms, curve: Curves.easeOut)
              .slideY(begin: 0.05, end: 0, duration: 320.ms),

          const SizedBox(height: 14),

          // ── Campo alias ──
          _AliasField(
            controller: nameController,
            focusNode: nameFocusNode,
            focused: nameFocused,
            alias: alias,
            hasName: hasName,
            onChanged: onNameChanged,
            onUnfocus: onUnfocus,
          )
              .animate(delay: 80.ms)
              .fadeIn(duration: 280.ms, curve: Curves.easeOut)
              .slideY(begin: 0.04, end: 0, duration: 300.ms),

          const SizedBox(height: 12),

          // ── Campo edad ──
          _AgeField(
            controller: ageController,
            focusNode: ageFocusNode,
            focused: ageFocused,
            hasAge: hasAge,
            onChanged: onAgeChanged,
            onUnfocus: onAgeUnfocus,
          )
              .animate(delay: 140.ms)
              .fadeIn(duration: 280.ms, curve: Curves.easeOut)
              .slideY(begin: 0.04, end: 0, duration: 300.ms),

          if (hasName) ...[
            const SizedBox(height: 12),
            _RivalPreview(image: avatarImage, initials: initials, alias: alias)
                .animate(delay: 120.ms)
                .fadeIn(duration: 260.ms, curve: Curves.easeOut)
                .slideY(begin: 0.04, end: 0, duration: 280.ms),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────── Avatar Hero ───────────────────────────────

class _AvatarHero extends StatelessWidget {
  final ImageProvider? image;
  final String initials;
  final bool uploading;
  final VoidCallback onTap;
  final bool compact;

  const _AvatarHero({
    required this.image,
    required this.initials,
    required this.uploading,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: compact ? 4 : 0, bottom: compact ? 0 : 4),
      child: Column(
        children: [
          // Disco Volt detrás del avatar
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.volt.withValues(alpha: 0.22),
                      AppColors.volt.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
              AvatarSelector(
                image: image,
                initials: initials,
                uploading: uploading,
                onTap: onTap,
                radius: 58,
              ),
            ],
          ),
          // En compacto (teclado abierto) se ocultan la línea y el texto
          // para que el avatar no quede pegado al card de Alias.
          if (!compact) ...[
            const SizedBox(height: 12),
            // Línea acento volt
            Container(
              width: 40,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.volt,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Toca para elegir tu foto',
              style: TextStyle(
                color: AppColors.grayMain.withValues(alpha: 0.75),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────── Alias Field ───────────────────────────────

class _AliasField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool focused;
  final String alias;
  final bool hasName;
  final VoidCallback onChanged;
  final VoidCallback onUnfocus;

  const _AliasField({
    required this.controller,
    required this.focusNode,
    required this.focused,
    required this.alias,
    required this.hasName,
    required this.onChanged,
    required this.onUnfocus,
  });

  @override
  Widget build(BuildContext context) {
    final len = controller.text.length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: focused ? AppColors.volt : AppColors.subtleBorder,
          width: focused ? 2 : 1,
        ),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: AppColors.volt.withValues(alpha: 0.20),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Tag "ALIAS"
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.volt.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'ALIAS',
                  style: TextStyle(
                    color: AppColors.carbon,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.3,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '$len / 25',
                style: TextStyle(
                  color: AppColors.grayMain.withValues(alpha: 0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // @  badge
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.carbon.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '@',
                  style: TextStyle(
                    color: AppColors.carbon,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  textInputAction: TextInputAction.done,
                  maxLength: 25,
                  onChanged: (_) => onChanged(),
                  onTapOutside: (_) => onUnfocus(),
                  style: const TextStyle(
                    color: AppColors.carbon,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                  cursorColor: AppColors.volt,
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'Tu alias',
                    hintStyle: TextStyle(
                      color: AppColors.carbon.withValues(alpha: 0.22),
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        if (hasName) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.people_alt_outlined,
                  size: 12,
                  color: AppColors.grayMain.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  'Se mostrará como @$alias',
                  style: TextStyle(
                    color: AppColors.grayMain.withValues(alpha: 0.8),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────── Age Field ──────────────────────────────────

class _AgeField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool focused;
  final bool hasAge;
  final VoidCallback onChanged;
  final VoidCallback onUnfocus;

  const _AgeField({
    required this.controller,
    required this.focusNode,
    required this.focused,
    required this.hasAge,
    required this.onChanged,
    required this.onUnfocus,
  });

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.trim().isNotEmpty;
    final error = hasText && !hasAge;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: error
              ? AppColors.danger
              : focused
                  ? AppColors.volt
                  : AppColors.subtleBorder,
          width: error || focused ? 2 : 1,
        ),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: AppColors.volt.withValues(alpha: 0.20),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Tag "EDAD"
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.volt.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'EDAD',
                  style: TextStyle(
                    color: AppColors.carbon,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.3,
                  ),
                ),
              ),
              const Spacer(),
              if (hasText)
                Text(
                  '${controller.text.trim()} años',
                  style: TextStyle(
                    color: AppColors.grayMain.withValues(alpha: 0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Ícono de edad
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.carbon.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  error ? Icons.error_outline : Icons.cake_outlined,
                  color: error ? AppColors.danger : AppColors.carbon,
                  size: 17,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  maxLength: 2,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (_) => onChanged(),
                  onTapOutside: (_) => onUnfocus(),
                  style: const TextStyle(
                    color: AppColors.carbon,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                  cursorColor: AppColors.volt,
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'Tu edad',
                    hintStyle: TextStyle(
                      color: AppColors.carbon.withValues(alpha: 0.22),
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                error ? Icons.info_outline : Icons.shield_outlined,
                size: 12,
                color: error
                    ? AppColors.danger
                    : AppColors.grayMain.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  error
                      ? 'La edad debe estar entre 13 y 99 años'
                      : 'Solo visible para tus rivales en la ficha',
                  style: TextStyle(
                    color: error
                        ? AppColors.danger
                        : AppColors.grayMain.withValues(alpha: 0.8),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
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

// ─────────────────────────────── Rival Preview ─────────────────────────────

class _RivalPreview extends StatelessWidget {
  final ImageProvider? image;
  final String initials;
  final String alias;

  const _RivalPreview({
    required this.image,
    required this.initials,
    required this.alias,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.subtleBorder),
      ),
      child: Row(
        children: [
          // Mini avatar
          Container(
            width: 40,
            height: 40,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.avatarBackground,
            ),
            child: image != null
                ? Image(image: image!, fit: BoxFit.cover, width: 40, height: 40)
                : Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: AppColors.carbon,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ASÍ TE VERÁN TUS RIVALES',
                  style: TextStyle(
                    color: AppColors.grayMain.withValues(alpha: 0.8),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '@$alias',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.carbon,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          // Volt badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.volt,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'RIVAL',
              style: TextStyle(
                color: Colors.black,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
