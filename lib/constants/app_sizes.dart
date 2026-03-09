import 'package:flutter/widgets.dart';

class AppSizes {
  AppSizes._();

  static const double zero = 0;
  static const double xxxs = 2;
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double huge = 48;
  static const double giant = 56;
  static const double max = 64;

  static const double radiusXs = 6;
  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 18;
  static const double radiusXl = 24;

  static const double iconXs = 14;
  static const double iconSm = 18;
  static const double iconMd = 22;
  static const double iconLg = 28;

  static const double buttonHeight = 48;
  static const double inputHeight = 52;
  static const double appBarHeight = 56;
}

class AppPaddings {
  AppPaddings._();

  static const EdgeInsets allXs = EdgeInsets.all(AppSizes.xs);
  static const EdgeInsets allSm = EdgeInsets.all(AppSizes.sm);
  static const EdgeInsets allMd = EdgeInsets.all(AppSizes.md);
  static const EdgeInsets allLg = EdgeInsets.all(AppSizes.lg);
  static const EdgeInsets allXl = EdgeInsets.all(AppSizes.xl);

  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(horizontal: AppSizes.sm);
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: AppSizes.md);
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: AppSizes.lg);
  static const EdgeInsets horizontalXl = EdgeInsets.symmetric(horizontal: AppSizes.xl);

  static const EdgeInsets verticalXs = EdgeInsets.symmetric(vertical: AppSizes.xs);
  static const EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: AppSizes.sm);
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: AppSizes.md);
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(vertical: AppSizes.lg);

  static const EdgeInsets screen = EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.md);
  static const EdgeInsets card = EdgeInsets.all(AppSizes.md);
  static const EdgeInsets button = EdgeInsets.symmetric(horizontal: AppSizes.lg, vertical: AppSizes.sm);
}

class AppMargins {
  AppMargins._();

  static const EdgeInsets allXs = EdgeInsets.all(AppSizes.xs);
  static const EdgeInsets allSm = EdgeInsets.all(AppSizes.sm);
  static const EdgeInsets allMd = EdgeInsets.all(AppSizes.md);
  static const EdgeInsets allLg = EdgeInsets.all(AppSizes.lg);
  static const EdgeInsets allXl = EdgeInsets.all(AppSizes.xl);

  static const EdgeInsets topSm = EdgeInsets.only(top: AppSizes.sm);
  static const EdgeInsets topMd = EdgeInsets.only(top: AppSizes.md);
  static const EdgeInsets topLg = EdgeInsets.only(top: AppSizes.lg);

  static const EdgeInsets bottomSm = EdgeInsets.only(bottom: AppSizes.sm);
  static const EdgeInsets bottomMd = EdgeInsets.only(bottom: AppSizes.md);
  static const EdgeInsets bottomLg = EdgeInsets.only(bottom: AppSizes.lg);

  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: AppSizes.md);
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: AppSizes.md);
}

class AppGaps {
  AppGaps._();

  static const SizedBox hXXS = SizedBox(height: AppSizes.xxs);
  static const SizedBox hXS = SizedBox(height: AppSizes.xs);
  static const SizedBox hSM = SizedBox(height: AppSizes.sm);
  static const SizedBox hMD = SizedBox(height: AppSizes.md);
  static const SizedBox hLG = SizedBox(height: AppSizes.lg);
  static const SizedBox hXL = SizedBox(height: AppSizes.xl);
  static const SizedBox hXXL = SizedBox(height: AppSizes.xxl);

  static const SizedBox wXXS = SizedBox(width: AppSizes.xxs);
  static const SizedBox wXS = SizedBox(width: AppSizes.xs);
  static const SizedBox wSM = SizedBox(width: AppSizes.sm);
  static const SizedBox wMD = SizedBox(width: AppSizes.md);
  static const SizedBox wLG = SizedBox(width: AppSizes.lg);
  static const SizedBox wXL = SizedBox(width: AppSizes.xl);
  static const SizedBox wXXL = SizedBox(width: AppSizes.xxl);

  static SizedBox h(double value) => SizedBox(height: value);
  static SizedBox w(double value) => SizedBox(width: value);
}

class AppRadius {
  AppRadius._();

  static const BorderRadius xs = BorderRadius.all(Radius.circular(AppSizes.radiusXs));
  static const BorderRadius sm = BorderRadius.all(Radius.circular(AppSizes.radiusSm));
  static const BorderRadius md = BorderRadius.all(Radius.circular(AppSizes.radiusMd));
  static const BorderRadius lg = BorderRadius.all(Radius.circular(AppSizes.radiusLg));
  static const BorderRadius xl = BorderRadius.all(Radius.circular(AppSizes.radiusXl));
}
