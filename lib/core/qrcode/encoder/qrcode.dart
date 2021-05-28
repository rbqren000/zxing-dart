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

import 'package:zxing/core/qrcode/decoder/error_correction_level.dart';
import 'package:zxing/core/qrcode/decoder/mode.dart';
import 'package:zxing/core/qrcode/decoder/version.dart';

import 'byte_matrix.dart';

/**
 * @author satorux@google.com (Satoru Takabayashi) - creator
 * @author dswitkin@google.com (Daniel Switkin) - ported from C++
 */
class QRCode {
  static final int NUM_MASK_PATTERNS = 8;

  Mode? mode;
  ErrorCorrectionLevel? ecLevel;
  Version? version;
  late int maskPattern;
  ByteMatrix? matrix;

  QRCode() {
    maskPattern = -1;
  }

  Mode? getMode() {
    return mode;
  }

  ErrorCorrectionLevel? getECLevel() {
    return ecLevel;
  }

  Version? getVersion() {
    return version;
  }

  int getMaskPattern() {
    return maskPattern;
  }

  ByteMatrix? getMatrix() {
    return matrix;
  }

  @override
  String toString() {
    StringBuffer result = StringBuffer();
    result.write("<<\n");
    result.write(" mode: ");
    result.write(mode);
    result.write("\n ecLevel: ");
    result.write(ecLevel);
    result.write("\n version: ");
    result.write(version);
    result.write("\n maskPattern: ");
    result.write(maskPattern);
    if (matrix == null) {
      result.write("\n matrix: null\n");
    } else {
      result.write("\n matrix:\n");
      result.write(matrix);
    }
    result.write(">>\n");
    return result.toString();
  }

  void setMode(Mode value) {
    mode = value;
  }

  void setECLevel(ErrorCorrectionLevel value) {
    ecLevel = value;
  }

  void setVersion(Version version) {
    this.version = version;
  }

  void setMaskPattern(int value) {
    maskPattern = value;
  }

  void setMatrix(ByteMatrix value) {
    matrix = value;
  }

  // Check if "mask_pattern" is valid.
  static bool isValidMaskPattern(int maskPattern) {
    return maskPattern >= 0 && maskPattern < NUM_MASK_PATTERNS;
  }
}
