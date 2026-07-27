import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pick_my_snacks/src/core/const/appcolors.dart';

class TextHelper {
  TextHelper._();

  static TextStyle get poppins {
    return GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary,
    );
  }

  static TextStyle get title {
    return GoogleFonts.poppins(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: AppColors.text,
    );
  }

  static TextStyle get sectionTitle {
    return GoogleFonts.poppins(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: AppColors.text,
    );
  }

  static TextStyle get body {
    return GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColors.text,
    );
  }

  static TextStyle get bodySemiBold {
    return GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppColors.text,
    );
  }

  static TextStyle get caption {
    return GoogleFonts.poppins(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary,
    );
  }

  static TextStyle get captionText {
    return GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColors.text,
    );
  }

  static TextStyle get primaryBody {
    return GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColors.primary,
    );
  }

  static TextStyle get deleteButton {
    return GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColors.delete,
    );
  }

  static TextStyle get whiteButton {
    return GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    );
  }

  static TextStyle get appBarTitle {
    return GoogleFonts.poppins(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    );
  }

  static TextStyle get appBarSubtitle {
    return GoogleFonts.poppins(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: const Color(0xFFCBD5E1),
    );
  }

  static TextStyle get appBarSearch {
    return GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: Colors.white,
    );
  }

  static TextStyle get appBarSearchHint {
    return GoogleFonts.poppins(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: const Color(0xFFCBD5E1),
    );
  }

  static TextStyle get totalAmount {
    return GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: AppColors.primary,
    );
  }

  static TextStyle get totalAmountValue {
    return GoogleFonts.poppins(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: AppColors.primary,
    );
  }

  static TextStyle get paymentSelected {
    return GoogleFonts.poppins(
      fontSize: 10,
      fontWeight: FontWeight.w400,
      color: AppColors.primary,
    );
  }
}
