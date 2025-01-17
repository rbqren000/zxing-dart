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
import 'package:zxing_lib/client.dart';
import 'package:zxing_lib/zxing.dart';

import '../../utils.dart';

/// Tests [SMSParsedResult].
///
void main() {
  void doTest(
    String contents,
    String number,
    String? subject,
    String? body,
    String? via,
    String parsedURI,
  ) {
    final fakeResult = Result(contents, null, null, BarcodeFormat.QR_CODE);
    final result = ResultParser.parseResult(fakeResult);
    expect(ParsedResultType.SMS, result.type);
    final smsResult = result as SMSParsedResult;
    assertArrayEquals(<String>[number], smsResult.numbers);
    expect(subject, smsResult.subject);
    expect(body, smsResult.body);
    assertArrayEquals(via == null ? <String>[] : <String>[via], smsResult.vias);
    expect(parsedURI, smsResult.smsURI);
  }

  test('testSMS', () {
    doTest('sms:+15551212', '+15551212', null, null, null, 'sms:+15551212');
    doTest(
      'sms:+15551212?subject=foo&body=bar',
      '+15551212',
      'foo',
      'bar',
      null,
      'sms:+15551212?body=bar&subject=foo',
    );
    doTest(
      'sms:+15551212;via=999333',
      '+15551212',
      null,
      null,
      '999333',
      'sms:+15551212;via=999333',
    );
  });

  test('testMMS', () {
    doTest('mms:+15551212', '+15551212', null, null, null, 'sms:+15551212');
    doTest(
      'mms:+15551212?subject=foo&body=bar',
      '+15551212',
      'foo',
      'bar',
      null,
      'sms:+15551212?body=bar&subject=foo',
    );
    doTest(
      'mms:+15551212;via=999333',
      '+15551212',
      null,
      null,
      '999333',
      'sms:+15551212;via=999333',
    );
  });
}
