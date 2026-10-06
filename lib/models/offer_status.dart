import 'package:flutter/material.dart';

enum OfferStatus { enNegociation, accepte, refuse }

extension OfferStatusX on OfferStatus {
  String get label {
    switch (this) {
      case OfferStatus.enNegociation:
        return 'En négociation';
      case OfferStatus.accepte:
        return 'Acceptée';
      case OfferStatus.refuse:
        return 'Refusée';
    }
  }

  Color get color {
    switch (this) {
      case OfferStatus.enNegociation:
        return const Color(0xFFFF8580);
      case OfferStatus.accepte:
        return const Color(0xFFFFE8D5);
      case OfferStatus.refuse:
        return const Color(0xFF9CAFC4);
    }
  }

  Color get textColor {
    switch (this) {
      case OfferStatus.accepte:
        return const Color(0xFFE89B61);
      case OfferStatus.enNegociation:
      case OfferStatus.refuse:
        return Colors.white;
    }
  }
}
