/*
 * Copyright 2008 ZXing authors
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

import '../barcode_format.dart';
import '../common/bit_array.dart';
import '../common/string_builder.dart';
import '../not_found_exception.dart';
import 'upceanreader.dart';

/// Implements decoding of the EAN-13 format.
///
/// @author dswitkin@google.com (Daniel Switkin)
/// @author Sean Owen
/// @author alasdair@google.com (Alasdair Mackintosh)
class EAN13Reader extends UPCEANReader {
  // For an EAN-13 barcode, the first digit is represented by the parities used
  // to encode the next six digits, according to the table below. For example,
  // if the barcode is 5 123456 789012 then the value of the first digit is
  // signified by using odd for '1', even for '2', even for '3', odd for '4',
  // odd for '5', and even for '6'. See http://en.wikipedia.org/wiki/EAN-13
  //
  //                Parity of next 6 digits
  //    Digit   0     1     2     3     4     5
  //       0    Odd   Odd   Odd   Odd   Odd   Odd
  //       1    Odd   Odd   Even  Odd   Even  Even
  //       2    Odd   Odd   Even  Even  Odd   Even
  //       3    Odd   Odd   Even  Even  Even  Odd
  //       4    Odd   Even  Odd   Odd   Even  Even
  //       5    Odd   Even  Even  Odd   Odd   Even
  //       6    Odd   Even  Even  Even  Odd   Odd
  //       7    Odd   Even  Odd   Even  Odd   Even
  //       8    Odd   Even  Odd   Even  Even  Odd
  //       9    Odd   Even  Even  Odd   Even  Odd
  //
  // Note that the encoding for '0' uses the same parity as a UPC barcode. Hence
  // a UPC barcode can be converted to an EAN-13 barcode by prepending a 0.
  //
  // The encoding is represented by the following array, which is a bit pattern
  // using Odd = 0 and Even = 1. For example, 5 is represented by:
  //
  //              Odd Even Even Odd Odd Even
  // in binary:
  //                0    1    1   0   0    1   == 0x19
  //
  static const FIRST_DIGIT_ENCODINGS = [
    0x00, 0x0B, 0x0D, 0xE, 0x13, 0x19, 0x1C, 0x15, 0x16, 0x1A //
  ];

  final _decodeMiddleCounters = [0, 0, 0, 0];

  EAN13Reader();

  @override
  int decodeMiddle(BitArray row, List<int> startRange, StringBuilder result) {
    final counters = _decodeMiddleCounters;
    counters.fillRange(0, counters.length, 0);
    final end = row.size;
    int rowOffset = startRange[1];

    int lgPatternFound = 0;

    for (int x = 0; x < 6 && rowOffset < end; x++) {
      final bestMatch = UPCEANReader.decodeDigit(
        row,
        counters,
        rowOffset,
        UPCEANReader.lAndGPatterns,
      );
      result.writeCharCode(48 /* 0 */ + bestMatch % 10);
      for (int counter in counters) {
        rowOffset += counter;
      }
      if (bestMatch >= 10) {
        lgPatternFound |= 1 << (5 - x);
      }
    }

    _determineFirstDigit(result, lgPatternFound);

    final middleRange = UPCEANReader.findGuardPattern(
      row,
      rowOffset,
      true,
      UPCEANReader.MIDDLE_PATTERN,
    );
    rowOffset = middleRange[1];

    for (int x = 0; x < 6 && rowOffset < end; x++) {
      final bestMatch = UPCEANReader.decodeDigit(
        row,
        counters,
        rowOffset,
        UPCEANReader.L_PATTERNS,
      );
      result.writeCharCode(48 /* 0 */ + bestMatch);
      for (int counter in counters) {
        rowOffset += counter;
      }
    }

    return rowOffset;
  }

  @override
  BarcodeFormat get barcodeFormat => BarcodeFormat.EAN_13;

  /// Based on pattern of odd-even ('L' and 'G') patterns used to encoded the explicitly-encoded
  /// digits in a barcode, determines the implicitly encoded first digit and adds it to the
  /// result string.
  ///
  /// @param resultString string to insert decoded first digit into
  /// @param lgPatternFound int whose bits indicates the pattern of odd/even L/G patterns used to
  ///  encode digits
  /// @throws NotFoundException if first digit cannot be determined
  static void _determineFirstDigit(
    StringBuilder resultString,
    int lgPatternFound,
  ) {
    for (int d = 0; d < 10; d++) {
      if (lgPatternFound == FIRST_DIGIT_ENCODINGS[d]) {
        resultString.insert(0, String.fromCharCode(48 /* 0 */ + d));
        return;
      }
    }
    throw NotFoundException.instance;
  }
}
