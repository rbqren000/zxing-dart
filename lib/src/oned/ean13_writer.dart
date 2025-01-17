/*
 * Copyright 2009 ZXing authors
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
import '../encode_hint_type.dart';
import '../formats_exception.dart';
import 'ean13_reader.dart';
import 'one_dimensional_code_writer.dart';
import 'upceanreader.dart';
import 'upceanwriter.dart';

/// This object renders an EAN13 code as a [BitMatrix].
///
/// @author aripollak@gmail.com (Ari Pollak)
class EAN13Writer extends UPCEANWriter {
  static const int _CODE_WIDTH = 3 + // start guard
      (7 * 6) + // left bars
      5 + // middle guard
      (7 * 6) + // right bars
      3; // end guard

  // @protected
  @override
  List<BarcodeFormat> get supportedWriteFormats => [BarcodeFormat.EAN_13];

  @override
  List<bool> encodeContent(
    String contents, [
    Map<EncodeHintType, Object?>? hints,
  ]) {
    final length = contents.length;
    switch (length) {
      case 12:
        // No check digit present, calculate it and add it
        int check;
        try {
          check = UPCEANReader.getStandardUPCEANChecksum(contents);
        } on FormatsException catch (fe) {
          throw ArgumentError(fe);
        }
        contents += check.toString();
        break;
      case 13:
        try {
          if (!UPCEANReader.checkStandardUPCEANChecksum(contents)) {
            throw ArgumentError('Contents do not pass checksum');
          }
        } on FormatsException catch (_) {
          throw ArgumentError('Illegal contents');
        }
        break;
      default:
        throw ArgumentError(
          'Requested contents should be 12 or 13 '
          'digits long, but got $length',
        );
    }

    OneDimensionalCodeWriter.checkNumeric(contents);

    final firstDigit = int.parse(contents[0]);
    final parities = EAN13Reader.FIRST_DIGIT_ENCODINGS[firstDigit];
    final result = List.filled(_CODE_WIDTH, false);
    int pos = 0;

    pos += OneDimensionalCodeWriter.appendPattern(
      result,
      pos,
      UPCEANReader.START_END_PATTERN,
      true,
    );

    // See EAN13Reader for a description of how the first digit & left bars are encoded
    for (int i = 1; i <= 6; i++) {
      int digit = int.parse(contents[i]);
      if ((parities >> (6 - i) & 1) == 1) {
        digit += 10;
      }
      pos += OneDimensionalCodeWriter.appendPattern(
        result,
        pos,
        UPCEANReader.lAndGPatterns[digit],
        false,
      );
    }

    pos += OneDimensionalCodeWriter.appendPattern(
      result,
      pos,
      UPCEANReader.MIDDLE_PATTERN,
      false,
    );

    for (int i = 7; i <= 12; i++) {
      final digit = int.parse(contents[i]);
      pos += OneDimensionalCodeWriter.appendPattern(
        result,
        pos,
        UPCEANReader.L_PATTERNS[digit],
        true,
      );
    }
    OneDimensionalCodeWriter.appendPattern(
      result,
      pos,
      UPCEANReader.START_END_PATTERN,
      true,
    );

    return result;
  }
}
