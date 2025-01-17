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

import 'package:test/scaffolding.dart';
import 'package:zxing_lib/zxing.dart';

import '../common/abstract_black_box.dart';

/// This is a set of mobile image taken at 480x360 with difficult lighting.
///
void main() {
  test('EAN13BlackBox2TestCase', () {
    AbstractBlackBoxTestCase(
      'test/resources/blackbox/ean13-2',
      MultiFormatReader(),
      BarcodeFormat.EAN_13,
    )
      ..addTest(12, 17, 0.0, 0, 1)
      ..addTest(11, 17, 180.0, 0, 1)
      ..testBlackBox();
  });
}
