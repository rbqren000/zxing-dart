/*
 * Copyright 2012 ZXing authors
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

import '../../pdf417_common.dart';
import 'modulus_poly.dart';

/// A field based on powers of a generator integer, modulo some modulus.
///
/// See [GenericGF]
///
/// @author Sean Owen
class ModulusGF {
  static final ModulusGF pdf417Gf =
      ModulusGF._(PDF417Common.NUMBER_OF_CODEWORDS, 3);

  late List<int> _expTable;
  late List<int> _logTable;
  late ModulusPoly _zero;
  late ModulusPoly _one;
  final int _modulus;

  ModulusGF._(this._modulus, int generator) {
    _expTable = List.filled(_modulus, 0);
    _logTable = List.filled(_modulus, 0);
    int x = 1;
    for (int i = 0; i < _modulus; i++) {
      _expTable[i] = x;
      x = (x * generator) % _modulus;
    }
    for (int i = 0; i < _modulus - 1; i++) {
      _logTable[_expTable[i]] = i;
    }
    // logTable[0] == 0 but this should never be used
    _zero = ModulusPoly(this, [0]);
    _one = ModulusPoly(this, [1]);
  }

  ModulusPoly get zero => _zero;

  ModulusPoly get one => _one;

  ModulusPoly buildMonomial(int degree, int coefficient) {
    if (degree < 0) {
      throw ArgumentError();
    }
    if (coefficient == 0) {
      return _zero;
    }
    final coefficients = List.filled(degree + 1, 0);
    coefficients[0] = coefficient;
    return ModulusPoly(this, coefficients);
  }

  int add(int a, int b) => (a + b) % _modulus;

  int subtract(int a, int b) => (_modulus + a - b) % _modulus;

  int exp(int a) => _expTable[a];

  int log(int a) {
    if (a == 0) {
      throw ArgumentError();
    }
    return _logTable[a];
  }

  int inverse(int a) {
    if (a == 0) {
      //ArithmeticException
      throw ArgumentError();
    }
    return _expTable[_modulus - _logTable[a] - 1];
  }

  int multiply(int a, int b) {
    if (a == 0 || b == 0) {
      return 0;
    }
    return _expTable[(_logTable[a] + _logTable[b]) % (_modulus - 1)];
  }

  int get size => _modulus;
}
