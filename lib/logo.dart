// =============================================================================
// LOGO WIDGET REUTILIZABLE CON ANIMACIÓN
// =============================================================================

import 'package:flutter/material.dart';

class AppLogo extends StatefulWidget {
  final double height;
  final bool showBadge;
  const AppLogo({this.height = 28, this.showBadge = true});

  @override
  State<AppLogo> createState() => _AppLogoState();
}

class _AppLogoState extends State<AppLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    _slide = Tween<Offset>(
      begin: const Offset(-0.08, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(
          scale: _scale,
          child:
             Row(children: [
  Expanded(child: SizedBox()),
               Image.asset(
                'logo_positivo.png',
              width: widget.height,
             //   fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  height: widget.height,
                  width: widget.height,
                  decoration: BoxDecoration(
                 
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.grid_view_rounded,
                      color: Colors.white, size: 16),
                ),
              ),
              Expanded(child: SizedBox()),
              SizedBox(width: 20,),
            
             ],)
              
            
          
        ),
      ),
    );
  }
}