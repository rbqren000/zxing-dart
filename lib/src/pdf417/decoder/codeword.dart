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

/// @author Guenther Grau
class Codeword {
  static const int _BARCODE_ROW_UNKNOWN = -1;

  final int _startX;
  final int _endX;
  final int _bucket;
  final int _value;
  int rowNumber = _BARCODE_ROW_UNKNOWN;

  Codeword(this._startX, this._endX, this._bucket, this._value);

  bool hasValidRowNumber() {
    return isValidRowNumber(rowNumber);
  }

  bool isValidRowNumber(int rowNumber) {
    return rowNumber != _BARCODE_ROW_UNKNOWN && _bucket == (rowNumber % 3) * 3;
  }

  void setRowNumberAsRowIndicatorColumn() {
    rowNumber = (_value ~/ 30) * 3 + _bucket ~/ 3;
  }

  int get width => _endX - _startX;

  int get startX => _startX;

  int get endX => _endX;

  int get bucket => _bucket;

  int get value => _value;

  @override
  String toString() {
    return '$rowNumber|$_value';
  }
}
