/*
 * Copyright 2013 ZXing authors
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

import '../pdf417_common.dart';

/// @author Guenther Grau
/// @author creatale GmbH (christoph.schulz@creatale.de)
class PDF417CodewordDecoder {
  static bool _isInit = false;
  static final List<List<double>> _ratiosTable = List.generate(
    PDF417Common.SYMBOL_TABLE.length,
    (index) => List.filled(PDF417Common.BARS_IN_MODULE, 0),
  );

  static void init() {
    if (_isInit) return;
    _isInit = true;
    // Pre-computes the symbol ratio table.
    for (int i = 0; i < PDF417Common.SYMBOL_TABLE.length; i++) {
      int currentSymbol = PDF417Common.SYMBOL_TABLE[i];
      int currentBit = currentSymbol & 0x1;
      for (int j = 0; j < PDF417Common.BARS_IN_MODULE; j++) {
        double size = 0.0;
        while ((currentSymbol & 0x1) == currentBit) {
          size += 1.0;
          currentSymbol >>= 1;
        }
        currentBit = currentSymbol & 0x1;
        _ratiosTable[i][PDF417Common.BARS_IN_MODULE - j - 1] =
            size / PDF417Common.MODULES_IN_CODEWORD;
      }
    }
  }

  PDF417CodewordDecoder._();

  static int getDecodedValue(List<int> moduleBitCount) {
    final decodedValue =
        _getDecodedCodewordValue(_sampleBitCounts(moduleBitCount));
    if (decodedValue != -1) {
      return decodedValue;
    }
    return _getClosestDecodedValue(moduleBitCount);
  }

  static List<int> _sampleBitCounts(List<int> moduleBitCount) {
    final bitCountSum = MathUtils.sum(moduleBitCount).toDouble();
    final result = List.filled(PDF417Common.BARS_IN_MODULE, 0);
    int bitCountIndex = 0;
    int sumPreviousBits = 0;
    for (int i = 0; i < PDF417Common.MODULES_IN_CODEWORD; i++) {
      final sampleIndex = bitCountSum / (2 * PDF417Common.MODULES_IN_CODEWORD) +
          (i * bitCountSum) / PDF417Common.MODULES_IN_CODEWORD;
      if (sumPreviousBits + moduleBitCount[bitCountIndex] <= sampleIndex) {
        sumPreviousBits += moduleBitCount[bitCountIndex];
        bitCountIndex++;
      }
      result[bitCountIndex]++;
    }
    return result;
  }

  static int _getDecodedCodewordValue(List<int> moduleBitCount) {
    final decodedValue = _getBitValue(moduleBitCount);
    return PDF417Common.getCodeword(decodedValue) == -1 ? -1 : decodedValue;
  }

  static int _getBitValue(List<int> moduleBitCount) {
    int result = 0;
    for (int i = 0; i < moduleBitCount.length; i++) {
      for (int bit = 0; bit < moduleBitCount[i]; bit++) {
        result = (result << 1) | (i % 2 == 0 ? 1 : 0);
      }
    }
    return result;
  }

  static int _getClosestDecodedValue(List<int> moduleBitCount) {
    init();
    final bitCountSum = MathUtils.sum(moduleBitCount);
    final bitCountRatios = List.filled(PDF417Common.BARS_IN_MODULE, 0.0);
    if (bitCountSum > 1) {
      for (int i = 0; i < bitCountRatios.length; i++) {
        bitCountRatios[i] = moduleBitCount[i] / bitCountSum;
      }
    }
    double bestMatchError = double.maxFinite;
    int bestMatch = -1;
    for (int j = 0; j < _ratiosTable.length; j++) {
      double error = 0.0;
      final ratioTableRow = _ratiosTable[j];
      for (int k = 0; k < PDF417Common.BARS_IN_MODULE; k++) {
        final diff = ratioTableRow[k] - bitCountRatios[k];
        error += diff * diff;
        if (error >= bestMatchError) {
          break;
        }
      }
      // todo the compare may be different with java
      if (error < bestMatchError) {
        bestMatchError = error;
        bestMatch = PDF417Common.SYMBOL_TABLE[j];
      }
    }
    return bestMatch;
  }
}
