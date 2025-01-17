/*
 * Copyright 2007 ZXing authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import '../../common/detector/math_utils.dart';
import 'error_correction_level.dart';

/// Encapsulates a QR Code's format information, including the data mask used and
/// error correction level.
///
/// See [DataMask]
/// See [ErrorCorrectionLevel]
///
/// @author Sean Owen
class FormatInformation {
  static const int _FORMAT_INFO_MASK_QR = 0x5412;

  /// See ISO 18004:2006, Annex C, Table C.1
  static const List<List<int>> _FORMAT_INFO_DECODE_LOOKUP = [
    [0x5412, 0x00],
    [0x5125, 0x01],
    [0x5E7C, 0x02],
    [0x5B4B, 0x03],
    [0x45F9, 0x04],
    [0x40CE, 0x05],
    [0x4F97, 0x06],
    [0x4AA0, 0x07],
    [0x77C4, 0x08],
    [0x72F3, 0x09],
    [0x7DAA, 0x0A],
    [0x789D, 0x0B],
    [0x662F, 0x0C],
    [0x6318, 0x0D],
    [0x6C41, 0x0E],
    [0x6976, 0x0F],
    [0x1689, 0x10],
    [0x13BE, 0x11],
    [0x1CE7, 0x12],
    [0x19D0, 0x13],
    [0x0762, 0x14],
    [0x0255, 0x15],
    [0x0D0C, 0x16],
    [0x083B, 0x17],
    [0x355F, 0x18],
    [0x3068, 0x19],
    [0x3F31, 0x1A],
    [0x3A06, 0x1B],
    [0x24B4, 0x1C],
    [0x2183, 0x1D],
    [0x2EDA, 0x1E],
    [0x2BED, 0x1F],
  ];

  late ErrorCorrectionLevel _errorCorrectionLevel;
  late int _dataMask;

  FormatInformation._(int formatInfo) {
    // Bits 3,4
    _errorCorrectionLevel =
        ErrorCorrectionLevel.values[(formatInfo >> 3) & 0x03];
    // Bottom 3 bits
    _dataMask = (formatInfo & 0x07);
  }

  static int numBitsDiffering(int a, int b) {
    return MathUtils.bitCount(a ^ b);
  }

  /// @param maskedFormatInfo1 format info indicator, with mask still applied
  /// @param maskedFormatInfo2 second copy of same info; both are checked at the same time
  ///  to establish best match
  /// @return information about the format it specifies, or `null`
  ///  if doesn't seem to match any known pattern
  static FormatInformation? decodeFormatInformation(
    int maskedFormatInfo1,
    int maskedFormatInfo2,
  ) {
    final formatInfo =
        _doDecodeFormatInformation(maskedFormatInfo1, maskedFormatInfo2);
    if (formatInfo != null) {
      return formatInfo;
    }
    // Should return null, but, some QR codes apparently
    // do not mask this info. Try again by actually masking the pattern
    // first
    return _doDecodeFormatInformation(
      maskedFormatInfo1 ^ _FORMAT_INFO_MASK_QR,
      maskedFormatInfo2 ^ _FORMAT_INFO_MASK_QR,
    );
  }

  static FormatInformation? _doDecodeFormatInformation(
    int maskedFormatInfo1,
    int maskedFormatInfo2,
  ) {
    // Find the int in FORMAT_INFO_DECODE_LOOKUP with fewest bits differing
    int bestDifference = MathUtils.MAX_VALUE; //Integer.MAX_VALUE;
    int bestFormatInfo = 0;
    for (List<int> decodeInfo in _FORMAT_INFO_DECODE_LOOKUP) {
      final targetInfo = decodeInfo[0];
      if (targetInfo == maskedFormatInfo1 || targetInfo == maskedFormatInfo2) {
        // Found an exact match
        return FormatInformation._(decodeInfo[1]);
      }
      int bitsDifference = numBitsDiffering(maskedFormatInfo1, targetInfo);
      if (bitsDifference < bestDifference) {
        bestFormatInfo = decodeInfo[1];
        bestDifference = bitsDifference;
      }
      if (maskedFormatInfo1 != maskedFormatInfo2) {
        // also try the other option
        bitsDifference = numBitsDiffering(maskedFormatInfo2, targetInfo);
        if (bitsDifference < bestDifference) {
          bestFormatInfo = decodeInfo[1];
          bestDifference = bitsDifference;
        }
      }
    }
    // Hamming distance of the 32 masked codes is 7, by construction, so <= 3 bits
    // differing means we found a match
    if (bestDifference <= 3) {
      return FormatInformation._(bestFormatInfo);
    }
    return null;
  }

  ErrorCorrectionLevel get errorCorrectionLevel => _errorCorrectionLevel;

  int get dataMask => _dataMask;

  @override
  int get hashCode {
    return (ecOrdinal(_errorCorrectionLevel) << 3) | _dataMask;
  }

  @override
  bool operator ==(Object other) {
    if (other is! FormatInformation) {
      return false;
    }
    return _errorCorrectionLevel == other._errorCorrectionLevel &&
        _dataMask == other._dataMask;
  }
}
