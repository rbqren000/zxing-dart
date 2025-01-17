/*
 * Copyright (C) 2012 ZXing authors
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

import '../common/bit_array.dart';
import '../barcode_format.dart';
import '../not_found_exception.dart';
import '../result.dart';
import '../result_metadata_type.dart';
import '../result_point.dart';

import 'upceanreader.dart';

/// See [UPCEANExtension5Support]
class UPCEANExtension2Support {
  final List<int> _decodeMiddleCounters = [0, 0, 0, 0];
  final StringBuffer _decodeRowStringBuffer = StringBuffer();

  Result decodeRow(int rowNumber, BitArray row, List<int> extensionStartRange) {
    final result = _decodeRowStringBuffer;
    result.clear();
    final end = _decodeMiddle(row, extensionStartRange, result);

    final resultString = result.toString();
    final extensionData = _parseExtensionString(resultString);

    final extensionResult = Result(
      resultString,
      null,
      [
        ResultPoint(
          (extensionStartRange[0] + extensionStartRange[1]) / 2.0,
          rowNumber.toDouble(),
        ),
        ResultPoint(end.toDouble(), rowNumber.toDouble()),
      ],
      BarcodeFormat.UPC_EAN_EXTENSION,
    );
    if (extensionData != null) {
      extensionResult.putAllMetadata(extensionData);
    }
    return extensionResult;
  }

  int _decodeMiddle(
    BitArray row,
    List<int> startRange,
    StringBuffer resultString,
  ) {
    // TODO is need ?
    final counters = _decodeMiddleCounters;
    counters[0] = 0;
    counters[1] = 0;
    counters[2] = 0;
    counters[3] = 0;
    final end = row.size;
    int rowOffset = startRange[1];

    int checkParity = 0;

    for (int x = 0; x < 2 && rowOffset < end; x++) {
      final bestMatch = UPCEANReader.decodeDigit(
        row,
        counters,
        rowOffset,
        UPCEANReader.lAndGPatterns,
      );
      resultString.writeCharCode(48 /* 0 */ + bestMatch % 10);
      for (int counter in counters) {
        rowOffset += counter;
      }
      if (bestMatch >= 10) {
        checkParity |= 1 << (1 - x);
      }
      if (x != 1) {
        // Read off separator if not last
        rowOffset = row.getNextSet(rowOffset);
        rowOffset = row.getNextUnset(rowOffset);
      }
    }

    if (resultString.length != 2) {
      throw NotFoundException.instance;
    }

    if (int.parse(resultString.toString()) % 4 != checkParity) {
      throw NotFoundException.instance;
    }

    return rowOffset;
  }

  /// @param raw raw content of extension
  /// @return formatted interpretation of raw content as a [Map] mapping
  ///  one [ResultMetadataType] to appropriate value, or `null` if not known
  static Map<ResultMetadataType, Object>? _parseExtensionString(String raw) {
    if (raw.length != 2) {
      return null;
    }
    final result = <ResultMetadataType, Object>{};
    result[ResultMetadataType.ISSUE_NUMBER] = raw.toString();
    return result;
  }
}
