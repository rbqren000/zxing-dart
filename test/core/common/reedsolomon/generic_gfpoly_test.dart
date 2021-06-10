/*
 * Copyright 2018 ZXing authors
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



import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:zxing_lib/common.dart';
import 'package:zxing_lib/zxing.dart';


/// Tests [GenericGFPoly].
void main() {

  final GenericGF FIELD = GenericGF.qrCodeField256;

  test('testPolynomialString', () {
    expect("0", FIELD.zero.toString());
    expect("-1", FIELD.buildMonomial(0, -1).toString());
    GenericGFPoly p = new GenericGFPoly(FIELD, Int32List.fromList([3, 0, -2, 1, 1]));
    expect("a^25x^4 - ax^2 + x + 1", p.toString());
    p = new GenericGFPoly(FIELD, Int32List.fromList([3]));
    expect("a^25", p.toString());
  });

  test('testZero',() {
    expect(FIELD.zero,FIELD.buildMonomial(1, 0));
    expect(FIELD.zero, FIELD.buildMonomial(1, 2).multiplyInt(0));
  });

  test('testEvaluate',() {
    expect(3, FIELD.buildMonomial(0, 3).evaluateAt(0));
  });

}