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
import 'result_parser.dart';
import 'uriparsed_result.dart';

/// Tries to parse results that are a URI of some kind.
///
/// @author Sean Owen
class URIResultParser extends ResultParser {
  static final _allowedUrlCharsPattern =
      RegExp(r"^[-._~:/?#\[\]@!$&'()*+,;=%A-Za-z0-9]+$");
  static final _userInHost = RegExp(':/*([^/@]+)@[^/]+');
  // See http://www.ietf.org/rfc/rfc2396.txt
  static final _urlWithProtocolPattern = RegExp(r'[a-zA-Z][a-zA-Z0-9+-.]+:');
  static final _urlWithoutProtocolPattern = RegExp(
      // host name elements; allow up to say 6 domain elements
      '([a-zA-Z0-9\\-]+\\.){1,6}[a-zA-Z]{2,}'
      // maybe port
      '(:\\d{1,5})?'
      // query, path or nothing
      r'(/|\?|$)');

  @override
  URIParsedResult? parse(Result result) {
    String rawText = ResultParser.getMassagedText(result);
    // We specifically handle the odd "URL" scheme here for simplicity and add "URI" for fun
    // Assume anything starting this way really means to be a URI
    if (rawText.startsWith('URL:') || rawText.startsWith('URI:')) {
      return URIParsedResult(rawText.substring(4).trim(), null);
    }
    rawText = rawText.trim();
    if (!isBasicallyValidURI(rawText) || isPossiblyMaliciousURI(rawText)) {
      return null;
    }
    return URIParsedResult(rawText, null);
  }

  /// @return true if the URI contains suspicious patterns that may suggest it intends to
  ///  mislead the user about its true nature. At the moment this looks for the presence
  ///  of user/password syntax in the host/authority portion of a URI which may be used
  ///  in attempts to make the URI's host appear to be other than it is. Example:
  ///  http://yourbank.com@phisher.com  This URI connects to phisher.com but may appear
  ///  to connect to yourbank.com at first glance.
  static bool isPossiblyMaliciousURI(String uri) {
    return !_allowedUrlCharsPattern.hasMatch(uri) || _userInHost.hasMatch(uri);
  }

  static bool isBasicallyValidURI(String uri) {
    if (uri.contains(' ')) {
      // Quick hack check for a common case
      return false;
    }
    RegExpMatch? m = _urlWithProtocolPattern.firstMatch(uri);
    if (m != null && m.start == 0) {
      return true;
    }

    // match at start only
    m = _urlWithoutProtocolPattern.firstMatch(uri);
    return m != null && m.start == 0;
  }
}
