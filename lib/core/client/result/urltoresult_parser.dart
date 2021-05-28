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

import 'package:zxing/core/client/result/uriparsed_result.dart';

import '../../result.dart';
import 'result_parser.dart';

/**
 * Parses the "URLTO" result format, which is of the form "URLTO:[title]:[url]".
 * This seems to be used sometimes, but I am not able to find documentation
 * on its origin or official format?
 *
 * @author Sean Owen
 */
class URLTOResultParser extends ResultParser {
  @override
  URIParsedResult? parse(Result result) {
    String rawText = ResultParser.getMassagedText(result);
    if (!rawText.startsWith("urlto:") && !rawText.startsWith("URLTO:")) {
      return null;
    }
    int titleEnd = rawText.indexOf(':', 6);
    if (titleEnd < 0) {
      return null;
    }
    String? title = titleEnd <= 6 ? null : rawText.substring(6, titleEnd);
    String uri = rawText.substring(titleEnd + 1);
    return URIParsedResult(uri, title);
  }
}
