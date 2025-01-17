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

import '../../result.dart';
import 'abstract_do_co_mo_result_parser.dart';
import 'uriparsed_result.dart';
import 'uriresult_parser.dart';

/// @author Sean Owen
class BookmarkDoCoMoResultParser extends AbstractDoCoMoResultParser {
  @override
  URIParsedResult? parse(Result result) {
    final rawText = result.text;
    if (!rawText.startsWith('MEBKM:')) {
      return null;
    }
    final title = matchSingleDoCoMoPrefixedField('TITLE:', rawText, true);
    final rawUri = matchDoCoMoPrefixedField('URL:', rawText);
    if (rawUri == null) {
      return null;
    }
    final uri = rawUri[0];
    return URIResultParser.isBasicallyValidURI(uri)
        ? URIParsedResult(uri, title)
        : null;
  }
}
