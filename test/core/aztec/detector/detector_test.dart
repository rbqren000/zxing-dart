/*
 * Copyright 2013 ZXing authors
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

import 'dart:collection';
import 'dart:math';

import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:zxing_lib/aztec.dart';
import 'package:zxing_lib/common.dart';
import 'package:zxing_lib/zxing.dart';

/// Tests for the Detector
///
void main() {
  // Rotates a square BitMatrix to the right by 90 degrees
  BitMatrix rotateRight(BitMatrix input) {
    final int width = input.width;
    final result = BitMatrix(width);
    for (int x = 0; x < width; x++) {
      for (int y = 0; y < width; y++) {
        if (input.get(x, y)) {
          result.set(y, width - x - 1);
        }
      }
    }
    return result;
  }

  // Returns the transpose of a bit matrix, which is equivalent to rotating the
  // matrix to the right, and then flipping it left-to-right
  BitMatrix transpose(BitMatrix input) {
    final int width = input.width;
    final BitMatrix result = BitMatrix(width);
    for (int x = 0; x < width; x++) {
      for (int y = 0; y < width; y++) {
        if (input.get(x, y)) {
          result.set(y, x);
        }
      }
    }
    return result;
  }

  BitMatrix clone(BitMatrix input) {
    final int width = input.width;
    final BitMatrix result = BitMatrix(width);
    for (int x = 0; x < width; x++) {
      for (int y = 0; y < width; y++) {
        if (input.get(x, y)) {
          result.set(x, y);
        }
      }
    }
    return result;
  }

  List<Point> getOrientationPoints(AztecCode code) {
    final int center = code.matrix!.width ~/ 2;
    final int offset = code.isCompact ? 5 : 7;
    final List<Point> result = [];
    for (int xSign = -1; xSign <= 1; xSign += 2) {
      for (int ySign = -1; ySign <= 1; ySign += 2) {
        result.add(Point(center + xSign * offset, center + ySign * offset));
        result
            .add(Point(center + xSign * (offset - 1), center + ySign * offset));
        result
            .add(Point(center + xSign * offset, center + ySign * (offset - 1)));
      }
    }
    return result;
  }

  // Returns a list of the four rotations of the BitMatrix.
  Iterable<BitMatrix> getRotations(BitMatrix matrix0) {
    final BitMatrix matrix90 = rotateRight(matrix0);
    final BitMatrix matrix180 = rotateRight(matrix90);
    final BitMatrix matrix270 = rotateRight(matrix180);
    return [matrix0, matrix90, matrix180, matrix270];
  }

  // Zooms a bit matrix so that each bit is factor x factor
  BitMatrix makeLarger(BitMatrix input, int factor) {
    final int width = input.width;
    final BitMatrix output = BitMatrix(width * factor);
    for (int inputY = 0; inputY < width; inputY++) {
      for (int inputX = 0; inputX < width; inputX++) {
        if (input.get(inputX, inputY)) {
          output.setRegion(inputX * factor, inputY * factor, factor, factor);
        }
      }
    }
    return output;
  }

  // Test that we can tolerate errors in the parameter locator bits
  void testErrorInParameterLocator(String data) {
    final aztec = Encoder.encode(data, 25, Encoder.DEFAULT_AZTEC_LAYERS);
    // pseudo-random, but deterministic
    final random = Random(aztec.matrix!.hashCode);
    final int layers = aztec.layers;
    final bool compact = aztec.isCompact;
    final List<Point> orientationPoints = getOrientationPoints(aztec);
    for (bool isMirror in [false, true]) {
      for (BitMatrix matrix in getRotations(aztec.matrix!)) {
        // Systematically try every possible 1- and 2-bit error.
        for (int error1 = 0; error1 < orientationPoints.length; error1++) {
          for (int error2 = error1;
              error2 < orientationPoints.length;
              error2++) {
            final BitMatrix copy = isMirror ? transpose(matrix) : clone(matrix);
            copy.flip(orientationPoints[error1].x, orientationPoints[error1].y);
            if (error2 > error1) {
              // if error2 == error1, we only test a single error
              copy.flip(
                orientationPoints[error2].x,
                orientationPoints[error2].y,
              );
            }
            // The detector doesn't seem to work when matrix bits are only 1x1.  So magnify.
            final r = Detector(makeLarger(copy, 3)).detect(isMirror);
            //assertNotNull(r);
            expect(r.nbLayers, layers);
            expect(r.isCompact, compact);
            final DecoderResult res = Decoder().decode(r);
            expect(res.text, data);
          }
        }
        // Try a few random three-bit errors;
        for (int i = 0; i < 5; i++) {
          final BitMatrix copy = clone(matrix);
          final errors = SplayTreeSet<int>(); // TreeSet
          while (errors.length < 3) {
            // Quick and dirty way of getting three distinct integers between 1 and n.
            errors.add(random.nextInt(orientationPoints.length));
          }

          for (int error in errors) {
            copy.flip(orientationPoints[error].x, orientationPoints[error].y);
          }
          expect(
            () => Detector(makeLarger(copy, 3)).detect(false),
            throwsA(TypeMatcher<NotFoundException>()),
            reason: 'Should throw NotFoundException',
          );
        }
      }
    }
  }

  test('testErrorInParameterLocatorZeroZero', () {
    // Layers=1, CodeWords=1.  So the parameter info and its Reed-Solomon info
    // will be completely zero!
    testErrorInParameterLocator('X');
  });

  test('testErrorInParameterLocatorCompact', () {
    testErrorInParameterLocator(
      'This is an example Aztec symbol for Wikipedia.',
    );
  });

  test('testErrorInParameterLocatorNotCompact', () {
    final alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYabcdefghijklmnopqrstuvwxyz';
    testErrorInParameterLocator(alphabet + alphabet + alphabet);
  });
}
