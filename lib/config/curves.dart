import 'package:flutter/animation.dart';

class AppCurves {
  // Smooth ease in out cubic curve for animations
  static const Curve easeInOutCubic = Curves.easeInOutCubic;
  
  // Other useful curves
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve elasticOut = Curves.elasticOut;
  static const Curve bounceOut = Curves.bounceOut;
  
  // Custom curve for button press
  static const Curve buttonPress = Curves.easeInOutCubic;
  
  // Custom curve for card animations
  static const Curve cardAnimation = Curves.easeInOut;
}
