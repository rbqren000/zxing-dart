/*
 * Copyright 2007 ZXing authors
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
import 'package:zxing_lib/qrcode.dart';

void main() {
  const int MASKED_TEST_FORMAT_INFO = 0x2BED;
  const int UNMASKED_TEST_FORMAT_INFO = MASKED_TEST_FORMAT_INFO ^ 0x5412;

  test('testBitsDiffering', () {
    expect(0, FormatInformation.numBitsDiffering(1, 1));
    expect(1, FormatInformation.numBitsDiffering(0, 2));
    expect(2, FormatInformation.numBitsDiffering(1, 2));
    expect(32, FormatInformation.numBitsDiffering(-1, 0));
  });

  test('testDecode', () {
    // Normal case
    final expected = FormatInformation.decodeFormatInformation(
      MASKED_TEST_FORMAT_INFO,
      MASKED_TEST_FORMAT_INFO,
    );
    assert(expected != null);
    expect(0x07, expected!.dataMask);
    expect(ErrorCorrectionLevel.Q, expected.errorCorrectionLevel);
    // where the code forgot the mask!
    expect(
      expected,
      FormatInformation.decodeFormatInformation(
        UNMASKED_TEST_FORMAT_INFO,
        MASKED_TEST_FORMAT_INFO,
      ),
    );
  });

  test('testDecodeWithBitDifference', () {
    final expected = FormatInformation.decodeFormatInformation(
      MASKED_TEST_FORMAT_INFO,
      MASKED_TEST_FORMAT_INFO,
    );
    // 1,2,3,4 bits difference
    expect(
      expected,
      FormatInformation.decodeFormatInformation(
        MASKED_TEST_FORMAT_INFO ^ 0x01,
        MASKED_TEST_FORMAT_INFO ^ 0x01,
      ),
    );
    expect(
      expected,
      FormatInformation.decodeFormatInformation(
        MASKED_TEST_FORMAT_INFO ^ 0x03,
        MASKED_TEST_FORMAT_INFO ^ 0x03,
      ),
    );
    expect(
      expected,
      FormatInformation.decodeFormatInformation(
        MASKED_TEST_FORMAT_INFO ^ 0x07,
        MASKED_TEST_FORMAT_INFO ^ 0x07,
      ),
    );
    assert(
      FormatInformation.decodeFormatInformation(
            MASKED_TEST_FORMAT_INFO ^ 0x0F,
            MASKED_TEST_FORMAT_INFO ^ 0x0F,
          ) ==
          null,
    );
  });

  test('testDecodeWithMisread', () {
    final expected = FormatInformation.decodeFormatInformation(
      MASKED_TEST_FORMAT_INFO,
      MASKED_TEST_FORMAT_INFO,
    );
    expect(
      expected,
      FormatInformation.decodeFormatInformation(
        MASKED_TEST_FORMAT_INFO ^ 0x03,
        MASKED_TEST_FORMAT_INFO ^ 0x0F,
      ),
    );
  });
}
