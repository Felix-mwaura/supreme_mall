import 'package:flutter/material.dart';

import '../models/catalogue.dart';
import '../theme/app_colors.dart';

/// Image area shared by product cards and the product page.
///
/// Merchants cannot upload photos yet (that arrives with the merchant
/// dashboard), so most listings have no `image_url`. Rather than a broken
/// image, a listing without a photo gets a department-tinted panel with its
/// category glyph. Remote images fade in, keep their box while loading, and
/// fall back to the same panel if they fail — so the grid never jumps.
class CatalogueImage extends StatelessWidget {
  const CatalogueImage({
    super.key,
    required this.product,
    required this.accent,
    this.icon = Icons.shopping_bag_outlined,
    this.borderRadius = 16,
  });

  final CatalogueProduct product;
  final Color accent;
  final IconData icon;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: AspectRatio(
        aspectRatio: 1,
        child: product.imageUrl == null
            ? _Placeholder(accent: accent, icon: icon)
            : Image.network(
                product.imageUrl!,
                fit: BoxFit.cover,
                // Keep the placeholder visible until the bytes arrive, then
                // fade — no layout shift, no flash of empty box.
                frameBuilder: (
                  BuildContext context,
                  Widget child,
                  int? frame,
                  bool wasSynchronouslyLoaded,
                ) {
                  if (wasSynchronouslyLoaded || frame != null) {
                    return _FadeIn(child: child);
                  }
                  return _Placeholder(accent: accent, icon: icon);
                },
                errorBuilder: (
                  BuildContext context,
                  Object error,
                  StackTrace? stack,
                ) =>
                    _Placeholder(accent: accent, icon: icon),
              ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.accent, required this.icon});

  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.surfaceRaised, AppColors.surface],
        ),
      ),
      child: Center(
        child: Icon(icon, size: 30, color: accent),
      ),
    );
  }
}

/// Fades a freshly decoded image in exactly once.
///
/// `AnimatedOpacity` on its own would render at 1 immediately; the first frame
/// is drawn transparent and the state then flips, so the fade actually happens.
class _FadeIn extends StatefulWidget {
  const _FadeIn({required this.child});

  final Widget child;

  @override
  State<_FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<_FadeIn> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) {
        setState(() => _visible = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child: widget.child,
    );
  }
}
