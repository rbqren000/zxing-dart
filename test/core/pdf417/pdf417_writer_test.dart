/*
 * Copyright 2016 ZXing authors
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

import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:zxing_lib/pdf417.dart';
import 'package:zxing_lib/zxing.dart';

/// Tests [PDF417Writer].
void main() {
  test('testDataMatrixImageWriter', () {
    final hints = <EncodeHintType, Object>{};
    hints[EncodeHintType.MARGIN] = 0;
    const size = 64;
    final writer = PDF417Writer();
    final matrix =
        writer.encode('Hello Google', BarcodeFormat.PDF_417, size, size, hints);
    // assertNotNull(matrix);
    final expected =
        'X X X X X X X X   X   X   X       X X X X   X   X   X X X X         X X   X   X           X X         X X X X   X X     X     X X X     X X   X           X       X X     X X X X X   X   X   X X X X X     X X X X X X X   X       X   X     X \n'
        'X X X X X X X X   X   X   X       X X X X   X   X   X X X X         X X   X   X           X X         X X X X   X X     X     X X X     X X   X           X       X X     X X X X X   X   X   X X X X X     X X X X X X X   X       X   X     X \n'
        'X X X X X X X X   X   X   X       X X X X   X   X   X X X X         X X   X   X           X X         X X X X   X X     X     X X X     X X   X           X       X X     X X X X X   X   X   X X X X X     X X X X X X X   X       X   X     X \n'
        'X X X X X X X X   X   X   X       X X X X   X   X   X X X X         X X   X   X           X X         X X X X   X X     X     X X X     X X   X           X       X X     X X X X X   X   X   X X X X X     X X X X X X X   X       X   X     X \n'
        'X X X X X X X X   X   X   X       X X X X   X   X         X         X   X X     X     X X X X X X     X X X           X   X X       X   X X X   X           X X     X     X X X X X X   X   X   X X X       X X X X X X X   X       X   X     X \n'
        'X X X X X X X X   X   X   X       X X X X   X   X         X         X   X X     X     X X X X X X     X X X           X   X X       X   X X X   X           X X     X     X X X X X X   X   X   X X X       X X X X X X X   X       X   X     X \n'
        'X X X X X X X X   X   X   X       X X X X   X   X         X         X   X X     X     X X X X X X     X X X           X   X X       X   X X X   X           X X     X     X X X X X X   X   X   X X X       X X X X X X X   X       X   X     X \n'
        'X X X X X X X X   X   X   X       X X X X   X   X         X         X   X X     X     X X X X X X     X X X           X   X X       X   X X X   X           X X     X     X X X X X X   X   X   X X X       X X X X X X X   X       X   X     X \n'
        'X X X X X X X X   X   X   X       X   X   X     X X X X             X   X X X       X       X X       X     X X   X X     X X X X       X X       X X X X X     X     X   X   X   X         X X X X         X X X X X X X   X       X   X     X \n'
        'X X X X X X X X   X   X   X       X   X   X     X X X X             X   X X X       X       X X       X     X X   X X     X X X X       X X       X X X X X     X     X   X   X   X         X X X X         X X X X X X X   X       X   X     X \n'
        'X X X X X X X X   X   X   X       X   X   X     X X X X             X   X X X       X       X X       X     X X   X X     X X X X       X X       X X X X X     X     X   X   X   X         X X X X         X X X X X X X   X       X   X     X \n'
        'X X X X X X X X   X   X   X       X   X   X     X X X X             X   X X X       X       X X       X     X X   X X     X X X X       X X       X X X X X     X     X   X   X   X         X X X X         X X X X X X X   X       X   X     X \n'
        'X X X X X X X X   X   X   X       X   X   X X X X     X X X X       X         X X       X X     X     X   X     X X X X       X X X X   X       X X       X X         X   X X   X   X X X X     X X X X X   X X X X X X X   X       X   X     X \n'
        'X X X X X X X X   X   X   X       X   X   X X X X     X X X X       X         X X       X X     X     X   X     X X X X       X X X X   X       X X       X X         X   X X   X   X X X X     X X X X X   X X X X X X X   X       X   X     X \n'
        'X X X X X X X X   X   X   X       X   X   X X X X     X X X X       X         X X       X X     X     X   X     X X X X       X X X X   X       X X       X X         X   X X   X   X X X X     X X X X X   X X X X X X X   X       X   X     X \n'
        'X X X X X X X X   X   X   X       X   X   X X X X     X X X X       X         X X       X X     X     X   X     X X X X       X X X X   X       X X       X X         X   X X   X   X X X X     X X X X X   X X X X X X X   X       X   X     X \n'
        'X X X X X X X X   X   X   X       X X   X   X X X           X       X X     X       X X X     X       X X X X X X   X X   X     X X     X   X X X   X     X X X X X       X X X   X   X X X     X X         X X X X X X X   X       X   X     X \n'
        'X X X X X X X X   X   X   X       X X   X   X X X           X       X X     X       X X X     X       X X X X X X   X X   X     X X     X   X X X   X     X X X X X       X X X   X   X X X     X X         X X X X X X X   X       X   X     X \n'
        'X X X X X X X X   X   X   X       X X   X   X X X           X       X X     X       X X X     X       X X X X X X   X X   X     X X     X   X X X   X     X X X X X       X X X   X   X X X     X X         X X X X X X X   X       X   X     X \n'
        'X X X X X X X X   X   X   X       X X   X   X X X           X       X X     X       X X X     X       X X X X X X   X X   X     X X     X   X X X   X     X X X X X       X X X   X   X X X     X X         X X X X X X X   X       X   X     X \n'
        'X X X X X X X X   X   X   X       X X X X X   X   X X X X   X X     X           X   X       X X X X   X       X   X         X X X X     X           X X X   X       X X   X X X X   X   X X X X X   X X     X X X X X X X   X       X   X     X \n'
        'X X X X X X X X   X   X   X       X X X X X   X   X X X X   X X     X           X   X       X X X X   X       X   X         X X X X     X           X X X   X       X X   X X X X   X   X X X X X   X X     X X X X X X X   X       X   X     X \n'
        'X X X X X X X X   X   X   X       X X X X X   X   X X X X   X X     X           X   X       X X X X   X       X   X         X X X X     X           X X X   X       X X   X X X X   X   X X X X X   X X     X X X X X X X   X       X   X     X \n'
        'X X X X X X X X   X   X   X       X X X X X   X   X X X X   X X     X           X   X       X X X X   X       X   X         X X X X     X           X X X   X       X X   X X X X   X   X X X X X   X X     X X X X X X X   X       X   X     X \n';
    expect(expected, matrix.toString());
  });
}
