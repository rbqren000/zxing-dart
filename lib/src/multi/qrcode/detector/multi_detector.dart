/*
 * Copyright 2009 ZXing authors
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

import '../../../qrcode/detector/finder_pattern_info.dart';
import '../../../common/bit_matrix.dart';
import '../../../common/detector_result.dart';
import '../../../decode_hint_type.dart';
import '../../../not_found_exception.dart';
import '../../../qrcode/detector/detector.dart';
import '../../../reader_exception.dart';
import '../../../result_point_callback.dart';
import 'multi_finder_pattern_finder.dart';

/// Encapsulates logic that can detect one or more QR Codes in an image, even if the QR Code
/// is rotated or skewed, or partially obscured.
///
/// @author Sean Owen
/// @author Hannes Erven
class MultiDetector extends Detector {
  static const List<DetectorResult> _EMPTY_DETECTOR_RESULTS = [];

  MultiDetector(BitMatrix image) : super(image);

  List<DetectorResult> detectMulti(Map<DecodeHintType, Object>? hints) {
    final resultPointCallback =
        hints?[DecodeHintType.NEED_RESULT_POINT_CALLBACK]
            as ResultPointCallback?;
    final finder = MultiFinderPatternFinder(image, resultPointCallback);
    final infos = finder.findMulti(hints);

    if (infos.isEmpty) {
      throw NotFoundException.instance;
    }

    final result = <DetectorResult>[];
    for (FinderPatternInfo info in infos) {
      try {
        result.add(processFinderPatternInfo(info));
      } on ReaderException catch (_) {
        // ignore
      }
    }
    if (result.isEmpty) {
      return _EMPTY_DETECTOR_RESULTS;
    } else {
      return result.toList();
    }
  }
}
