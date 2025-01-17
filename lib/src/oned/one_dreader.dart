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

import 'dart:math' as math;

import '../binary_bitmap.dart';
import '../common/bit_array.dart';
import '../decode_hint_type.dart';
import '../not_found_exception.dart';
import '../reader.dart';
import '../reader_exception.dart';
import '../result.dart';
import '../result_metadata_type.dart';
import '../result_point.dart';

/// Encapsulates functionality and implementation that is common to all families
/// of one-dimensional barcodes.
///
/// @author dswitkin@google.com (Daniel Switkin)
/// @author Sean Owen
abstract class OneDReader implements Reader {
  // Note that we don't try rotation without the try harder flag, even if rotation was supported.
  @override
  Result decode(BinaryBitmap image, [Map<DecodeHintType, Object>? hints]) {
    try {
      return _doDecode(image, hints);
    } on NotFoundException catch (_) {
      final tryHarder =
          hints != null && hints.containsKey(DecodeHintType.TRY_HARDER);
      if (tryHarder && image.isRotateSupported) {
        final rotatedImage = image.rotateCounterClockwise();
        final result = _doDecode(rotatedImage, hints);
        // Record that we found it rotated 90 degrees CCW / 270 degrees CW
        final metadata = result.resultMetadata;
        int orientation = 270;
        if (metadata != null &&
            metadata.containsKey(ResultMetadataType.ORIENTATION)) {
          // But if we found it reversed in doDecode(), add in that result here:
          orientation = (orientation +
                  (metadata[ResultMetadataType.ORIENTATION] as int)) %
              360;
        }
        result.putMetadata(ResultMetadataType.ORIENTATION, orientation);
        // Update result points
        final points = result.resultPoints;
        if (points != null) {
          final height = rotatedImage.height;
          for (int i = 0; i < points.length; i++) {
            points[i] = ResultPoint(height - points[i]!.y - 1, points[i]!.x);
          }
        }
        return result;
      } else {
        rethrow;
      }
    }
  }

  @override
  void reset() {
    // do nothing
  }

  /// We're going to examine rows from the middle outward, searching alternately above and below the
  /// middle, and farther out each time. rowStep is the number of rows between each successive
  /// attempt above and below the middle. So we'd scan row middle, then middle - rowStep, then
  /// middle + rowStep, then middle - (2 * rowStep), etc.
  /// rowStep is bigger as the image is taller, but is always at least 1. We've somewhat arbitrarily
  /// decided that moving up and down by about 1/16 of the image is pretty good; we try more of the
  /// image if "trying harder".
  ///
  /// @param image The image to decode
  /// @param hints Any hints that were requested
  /// @return The contents of the decoded barcode
  /// @throws NotFoundException Any spontaneous errors which occur
  Result _doDecode(BinaryBitmap image, Map<DecodeHintType, Object>? hints) {
    final width = image.width;
    final height = image.height;
    BitArray row = BitArray(width);

    final tryHarder =
        hints != null && hints.containsKey(DecodeHintType.TRY_HARDER);
    final rowStep = math.max(1, height >> (tryHarder ? 8 : 5));
    late int maxLines;
    if (tryHarder) {
      maxLines = height; // Look at the whole image, not just the center
    } else {
      // 15 rows spaced 1/32 apart is roughly the middle half of the image
      maxLines = 15;
    }

    final middle = height ~/ 2;
    for (int x = 0; x < maxLines; x++) {
      // Scanning from the middle out. Determine which row we're looking at next:
      final rowStepsAboveOrBelow = (x + 1) ~/ 2;
      final isAbove = (x & 0x01) == 0; // i.e. is x even?
      final rowNumber = middle +
          rowStep * (isAbove ? rowStepsAboveOrBelow : -rowStepsAboveOrBelow);
      if (rowNumber < 0 || rowNumber >= height) {
        // Oops, if we run off the top or bottom, stop
        break;
      }

      // Estimate black point for this row and load it:
      try {
        row = image.getBlackRow(rowNumber, row);
      } on NotFoundException catch (_) {
        continue;
      }

      // While we have the image data in a BitArray, it's fairly cheap to reverse it in place to
      // handle decoding upside down barcodes.
      for (int attempt = 0; attempt < 2; attempt++) {
        if (attempt == 1) {
          // trying again?
          row.reverse(); // reverse the row and continue
          // This means we will only ever draw result points *once* in the life of this method
          // since we want to avoid drawing the wrong points after flipping the row, and,
          // don't want to clutter with noise from every single row scan -- just the scans
          // that start on the center line.
          if (hints != null &&
              hints.containsKey(DecodeHintType.NEED_RESULT_POINT_CALLBACK)) {
            final newHints = <DecodeHintType, Object>{};
            newHints.addAll(hints);
            newHints.remove(DecodeHintType.NEED_RESULT_POINT_CALLBACK);
            hints = newHints;
          }
        }
        try {
          // Look for a barcode
          final result = decodeRow(rowNumber, row, hints);
          // We found our barcode
          if (attempt == 1) {
            // But it was upside down, so note that
            result.putMetadata(ResultMetadataType.ORIENTATION, 180);
            // And remember to flip the result points horizontally.
            final points = result.resultPoints;
            if (points != null) {
              points[0] = ResultPoint(width - points[0]!.x - 1, points[0]!.y);
              points[1] = ResultPoint(width - points[1]!.x - 1, points[1]!.y);
            }
          }
          return result;
        } on ReaderException catch (_) {
          // continue -- just couldn't decode this row
        }
      }
    }

    throw NotFoundException.instance;
  }

  /// Records the size of successive runs of white and black pixels in a row, starting at a given point.
  /// The values are recorded in the given array, and the number of runs recorded is equal to the size
  /// of the array. If the row starts on a white pixel at the given start point, then the first count
  /// recorded is the run of white pixels starting from that point; likewise it is the count of a run
  /// of black pixels if the row begin on a black pixels at that point.
  ///
  /// @param row row to count from
  /// @param start offset into row to start at
  /// @param counters array into which to record counts
  /// @throws NotFoundException if counters cannot be filled entirely from row before running out
  ///  of pixels
  static void recordPattern(BitArray row, int start, List<int> counters) {
    final numCounters = counters.length;
    counters.fillRange(0, numCounters, 0);
    final end = row.size;
    if (start >= end) {
      throw NotFoundException.instance;
    }
    bool isWhite = !row.get(start);
    int counterPosition = 0;
    int i = start;
    while (i < end) {
      if (row.get(i) != isWhite) {
        counters[counterPosition]++;
      } else {
        if (++counterPosition == numCounters) {
          break;
        } else {
          counters[counterPosition] = 1;
          isWhite = !isWhite;
        }
      }
      i++;
    }
    // If we read fully the last section of pixels and filled up our counters -- or filled
    // the last counter but ran off the side of the image, OK. Otherwise, a problem.
    if (!(counterPosition == numCounters ||
        (counterPosition == numCounters - 1 && i == end))) {
      throw NotFoundException.instance;
    }
  }

  static void recordPatternInReverse(
    BitArray row,
    int start,
    List<int> counters,
  ) {
    // This could be more efficient I guess
    int numTransitionsLeft = counters.length;
    bool last = row.get(start);
    while (start > 0 && numTransitionsLeft >= 0) {
      if (row.get(--start) != last) {
        numTransitionsLeft--;
        last = !last;
      }
    }
    if (numTransitionsLeft >= 0) {
      throw NotFoundException.instance;
    }
    recordPattern(row, start + 1, counters);
  }

  /// Determines how closely a set of observed counts of runs of black/white values matches a given
  /// target pattern. This is reported as the ratio of the total variance from the expected pattern
  /// proportions across all pattern elements, to the length of the pattern.
  ///
  /// @param counters observed counters
  /// @param pattern expected pattern
  /// @param maxIndividualVariance The most any counter can differ before we give up
  /// @return ratio of total variance between counters and pattern compared to total pattern size
  static double patternMatchVariance(
    List<int> counters,
    List<int> pattern,
    double maxIndividualVariance,
  ) {
    final numCounters = counters.length;
    int total = 0;
    int patternLength = 0;
    for (int i = 0; i < numCounters; i++) {
      total += counters[i];
      patternLength += pattern[i];
    }
    if (total < patternLength) {
      // If we don't even have one pixel per unit of bar width, assume this is too small
      // to reliably match, so fail:
      return double.infinity;
    }

    final unitBarWidth = total / patternLength;
    maxIndividualVariance *= unitBarWidth;

    double totalVariance = 0.0;
    for (int x = 0; x < numCounters; x++) {
      final counter = counters[x];
      final scaledPattern = pattern[x] * unitBarWidth;
      final variance = counter > scaledPattern
          ? counter - scaledPattern
          : scaledPattern - counter;
      if (variance > maxIndividualVariance) {
        return double.infinity;
      }
      totalVariance += variance;
    }
    return totalVariance / total;
  }

  /// <p>Attempts to decode a one-dimensional barcode format given a single row of
  /// an image.</p>
  ///
  /// @param rowNumber row number from top of the row
  /// @param row the black/white pixel data of the row
  /// @param hints decode hints
  /// @return [Result] containing encoded string and start/end of barcode
  /// @throws NotFoundException if no potential barcode is found
  /// @throws ChecksumException if a potential barcode is found but does not pass its checksum
  /// @throws FormatException if a potential barcode is found but format is invalid
  Result decodeRow(
    int rowNumber,
    BitArray row,
    Map<DecodeHintType, Object>? hints,
  );
}
