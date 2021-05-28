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

import 'dart:math' as Math;

import 'package:zxing/core/common/bit_matrix.dart';
import 'package:zxing/core/common/detector/math_utils.dart';
import 'package:zxing/core/common/detector_result.dart';
import 'package:zxing/core/common/grid_sampler.dart';
import 'package:zxing/core/common/perspective_transform.dart';
import 'package:zxing/core/qrcode/decoder/version.dart';

import '../../decode_hint_type.dart';
import '../../not_found_exception.dart';
import '../../result_point.dart';
import '../../result_point_callback.dart';
import 'alignment_pattern.dart';
import 'alignment_pattern_finder.dart';
import 'finder_pattern.dart';
import 'finder_pattern_finder.dart';
import 'finder_pattern_info.dart';

/**
 * <p>Encapsulates logic that can detect a QR Code in an image, even if the QR Code
 * is rotated or skewed, or partially obscured.</p>
 *
 * @author Sean Owen
 */
class Detector {
  final BitMatrix image;
  ResultPointCallback? resultPointCallback;

  Detector(this.image);

  BitMatrix getImage() {
    return image;
  }

  ResultPointCallback? getResultPointCallback() {
    return resultPointCallback;
  }

  /**
   * <p>Detects a QR Code in an image.</p>
   *
   * @param hints optional hints to detector
   * @return {@link DetectorResult} encapsulating results of detecting a QR Code
   * @throws NotFoundException if QR Code cannot be found
   * @throws FormatException if a QR Code cannot be decoded
   */
  DetectorResult detect([Map<DecodeHintType, Object>? hints]) {
    resultPointCallback = hints == null
        ? null
        : hints[DecodeHintType.NEED_RESULT_POINT_CALLBACK]
            as ResultPointCallback;

    FinderPatternFinder finder =
        new FinderPatternFinder(image, resultPointCallback);
    FinderPatternInfo info = finder.find(hints);

    return processFinderPatternInfo(info);
  }

  DetectorResult processFinderPatternInfo(FinderPatternInfo info) {
    FinderPattern topLeft = info.getTopLeft();
    FinderPattern topRight = info.getTopRight();
    FinderPattern bottomLeft = info.getBottomLeft();

    double moduleSize = calculateModuleSize(topLeft, topRight, bottomLeft);
    if (moduleSize < 1.0) {
      throw NotFoundException.getNotFoundInstance();
    }
    int dimension = computeDimension(topLeft, topRight, bottomLeft, moduleSize);
    Version provisionalVersion =
        Version.getProvisionalVersionForDimension(dimension);
    int modulesBetweenFPCenters =
        provisionalVersion.getDimensionForVersion() - 7;

    AlignmentPattern? alignmentPattern;
    // Anything above version 1 has an alignment pattern
    if (provisionalVersion.getAlignmentPatternCenters().length > 0) {
      // Guess where a "bottom right" finder pattern would have been
      double bottomRightX =
          topRight.getX() - topLeft.getX() + bottomLeft.getX();
      double bottomRightY =
          topRight.getY() - topLeft.getY() + bottomLeft.getY();

      // Estimate that alignment pattern is closer by 3 modules
      // from "bottom right" to known top left location
      double correctionToTopLeft = 1.0 - 3.0 / modulesBetweenFPCenters;
      int estAlignmentX = (topLeft.getX() +
              correctionToTopLeft * (bottomRightX - topLeft.getX()))
          .toInt();
      int estAlignmentY = (topLeft.getY() +
              correctionToTopLeft * (bottomRightY - topLeft.getY()))
          .toInt();

      // Kind of arbitrary -- expand search radius before giving up
      for (int i = 4; i <= 16; i <<= 1) {
        try {
          alignmentPattern = findAlignmentInRegion(
              moduleSize, estAlignmentX, estAlignmentY, i.toDouble());
          break;
        } on NotFoundException catch (re) {
          // try next round
        }
      }
      // If we didn't find alignment pattern... well try anyway without it
    }

    PerspectiveTransform transform = createTransform(
        topLeft, topRight, bottomLeft, alignmentPattern, dimension);

    BitMatrix bits = sampleGrid(image, transform, dimension);

    List<ResultPoint> points;
    if (alignmentPattern == null) {
      points = [bottomLeft, topLeft, topRight];
    } else {
      points = [bottomLeft, topLeft, topRight, alignmentPattern];
    }
    return new DetectorResult(bits, points);
  }

  static PerspectiveTransform createTransform(
      ResultPoint topLeft,
      ResultPoint topRight,
      ResultPoint bottomLeft,
      ResultPoint? alignmentPattern,
      int dimension) {
    double dimMinusThree = dimension - 3.5;
    double bottomRightX;
    double bottomRightY;
    double sourceBottomRightX;
    double sourceBottomRightY;
    if (alignmentPattern != null) {
      bottomRightX = alignmentPattern.getX();
      bottomRightY = alignmentPattern.getY();
      sourceBottomRightX = dimMinusThree - 3.0;
      sourceBottomRightY = sourceBottomRightX;
    } else {
      // Don't have an alignment pattern, just make up the bottom-right point
      bottomRightX = (topRight.getX() - topLeft.getX()) + bottomLeft.getX();
      bottomRightY = (topRight.getY() - topLeft.getY()) + bottomLeft.getY();
      sourceBottomRightX = dimMinusThree;
      sourceBottomRightY = dimMinusThree;
    }

    return PerspectiveTransform.quadrilateralToQuadrilateral(
        3.5,
        3.5,
        dimMinusThree,
        3.5,
        sourceBottomRightX,
        sourceBottomRightY,
        3.5,
        dimMinusThree,
        topLeft.getX(),
        topLeft.getY(),
        topRight.getX(),
        topRight.getY(),
        bottomRightX,
        bottomRightY,
        bottomLeft.getX(),
        bottomLeft.getY());
  }

  static BitMatrix sampleGrid(
      BitMatrix image, PerspectiveTransform transform, int dimension) {
    GridSampler sampler = GridSampler.getInstance();
    return sampler.sampleGrid(image, dimension, dimension, transform);
  }

  /**
   * <p>Computes the dimension (number of modules on a size) of the QR Code based on the position
   * of the finder patterns and estimated module size.</p>
   */
  static int computeDimension(ResultPoint topLeft, ResultPoint topRight,
      ResultPoint bottomLeft, double moduleSize) {
    int tltrCentersDimension =
        MathUtils.round(ResultPoint.distance(topLeft, topRight) / moduleSize);
    int tlblCentersDimension =
        MathUtils.round(ResultPoint.distance(topLeft, bottomLeft) / moduleSize);
    int dimension = ((tltrCentersDimension + tlblCentersDimension) ~/ 2) + 7;
    switch (dimension & 0x03) {
      // mod 4
      case 0:
        dimension++;
        break;
      // 1? do nothing
      case 2:
        dimension--;
        break;
      case 3:
        throw NotFoundException.getNotFoundInstance();
    }
    return dimension;
  }

  /**
   * <p>Computes an average estimated module size based on estimated derived from the positions
   * of the three finder patterns.</p>
   *
   * @param topLeft detected top-left finder pattern center
   * @param topRight detected top-right finder pattern center
   * @param bottomLeft detected bottom-left finder pattern center
   * @return estimated module size
   */
  double calculateModuleSize(
      ResultPoint topLeft, ResultPoint topRight, ResultPoint bottomLeft) {
    // Take the average
    return (calculateModuleSizeOneWay(topLeft, topRight) +
            calculateModuleSizeOneWay(topLeft, bottomLeft)) /
        2.0;
  }

  /**
   * <p>Estimates module size based on two finder patterns -- it uses
   * {@link #sizeOfBlackWhiteBlackRunBothWays(int, int, int, int)} to figure the
   * width of each, measuring along the axis between their centers.</p>
   */
  double calculateModuleSizeOneWay(
      ResultPoint pattern, ResultPoint otherPattern) {
    double moduleSizeEst1 = sizeOfBlackWhiteBlackRunBothWays(
      pattern.getX().toInt(),
      pattern.getY().toInt(),
      otherPattern.getX().toInt(),
      otherPattern.getY().toInt(),
    );
    double moduleSizeEst2 = sizeOfBlackWhiteBlackRunBothWays(
      otherPattern.getX().toInt(),
      otherPattern.getY().toInt(),
      pattern.getX().toInt(),
      pattern.getY().toInt(),
    );
    if ((moduleSizeEst1).isNaN) {
      return moduleSizeEst2 / 7.0;
    }
    if ((moduleSizeEst2).isNaN) {
      return moduleSizeEst1 / 7.0;
    }
    // Average them, and divide by 7 since we've counted the width of 3 black modules,
    // and 1 white and 1 black module on either side. Ergo, divide sum by 14.
    return (moduleSizeEst1 + moduleSizeEst2) / 14.0;
  }

  /**
   * See {@link #sizeOfBlackWhiteBlackRun(int, int, int, int)}; computes the total width of
   * a finder pattern by looking for a black-white-black run from the center in the direction
   * of another point (another finder pattern center), and in the opposite direction too.
   */
  double sizeOfBlackWhiteBlackRunBothWays(
      int fromX, int fromY, int toX, int toY) {
    double result = sizeOfBlackWhiteBlackRun(fromX, fromY, toX, toY);

    // Now count other way -- don't run off image though of course
    double scale = 1.0;
    int otherToX = fromX - (toX - fromX);
    if (otherToX < 0) {
      scale = fromX / (fromX - otherToX);
      otherToX = 0;
    } else if (otherToX >= image.getWidth()) {
      scale = (image.getWidth() - 1 - fromX) / (otherToX - fromX);
      otherToX = image.getWidth() - 1;
    }
    int otherToY = (fromY - (toY - fromY) * scale).toInt();

    scale = 1.0;
    if (otherToY < 0) {
      scale = fromY / (fromY - otherToY);
      otherToY = 0;
    } else if (otherToY >= image.getHeight()) {
      scale = (image.getHeight() - 1 - fromY) / (otherToY - fromY);
      otherToY = image.getHeight() - 1;
    }
    otherToX = (fromX + (otherToX - fromX) * scale).toInt();

    result += sizeOfBlackWhiteBlackRun(fromX, fromY, otherToX, otherToY);

    // Middle pixel is double-counted this way; subtract 1
    return result - 1.0;
  }

  /**
   * <p>This method traces a line from a point in the image, in the direction towards another point.
   * It begins in a black region, and keeps going until it finds white, then black, then white again.
   * It reports the distance from the start to this point.</p>
   *
   * <p>This is used when figuring out how wide a finder pattern is, when the finder pattern
   * may be skewed or rotated.</p>
   */
  double sizeOfBlackWhiteBlackRun(int fromX, int fromY, int toX, int toY) {
    // Mild variant of Bresenham's algorithm;
    // see http://en.wikipedia.org/wiki/Bresenham's_line_algorithm
    bool steep = (toY - fromY).abs() > (toX - fromX).abs();
    if (steep) {
      int temp = fromX;
      fromX = fromY;
      fromY = temp;
      temp = toX;
      toX = toY;
      toY = temp;
    }

    int dx = (toX - fromX).abs();
    int dy = (toY - fromY).abs();
    int error = -dx ~/ 2;
    int xstep = fromX < toX ? 1 : -1;
    int ystep = fromY < toY ? 1 : -1;

    // In black pixels, looking for white, first or second time.
    int state = 0;
    // Loop up until x == toX, but not beyond
    int xLimit = toX + xstep;
    for (int x = fromX, y = fromY; x != xLimit; x += xstep) {
      int realX = steep ? y : x;
      int realY = steep ? x : y;

      // Does current pixel mean we have moved white to black or vice versa?
      // Scanning black in state 0,2 and white in state 1, so if we find the wrong
      // color, advance to next state or end if we are in state 2 already
      if ((state == 1) == image.get(realX, realY)) {
        if (state == 2) {
          return MathUtils.distance(
              x.toDouble(), y.toDouble(), fromX.toDouble(), fromY.toDouble());
        }
        state++;
      }

      error += dy;
      if (error > 0) {
        if (y == toY) {
          break;
        }
        y += ystep;
        error -= dx;
      }
    }
    // Found black-white-black; give the benefit of the doubt that the next pixel outside the image
    // is "white" so this last point at (toX+xStep,toY) is the right ending. This is really a
    // small approximation; (toX+xStep,toY+yStep) might be really correct. Ignore this.
    if (state == 2) {
      return MathUtils.distance((toX + xstep).toDouble(), toY.toDouble(),
          fromX.toDouble(), fromY.toDouble());
    }
    // else we didn't find even black-white-black; no estimate is really possible
    return double.nan;
  }

  /**
   * <p>Attempts to locate an alignment pattern in a limited region of the image, which is
   * guessed to contain it. This method uses {@link AlignmentPattern}.</p>
   *
   * @param overallEstModuleSize estimated module size so far
   * @param estAlignmentX x coordinate of center of area probably containing alignment pattern
   * @param estAlignmentY y coordinate of above
   * @param allowanceFactor number of pixels in all directions to search from the center
   * @return {@link AlignmentPattern} if found, or null otherwise
   * @throws NotFoundException if an unexpected error occurs during detection
   */
  AlignmentPattern findAlignmentInRegion(double overallEstModuleSize,
      int estAlignmentX, int estAlignmentY, double allowanceFactor) {
    // Look for an alignment pattern (3 modules in size) around where it
    // should be
    int allowance = (allowanceFactor * overallEstModuleSize).toInt();
    int alignmentAreaLeftX = Math.max(0, estAlignmentX - allowance);
    int alignmentAreaRightX =
        Math.min(image.getWidth() - 1, estAlignmentX + allowance);
    if (alignmentAreaRightX - alignmentAreaLeftX < overallEstModuleSize * 3) {
      throw NotFoundException.getNotFoundInstance();
    }

    int alignmentAreaTopY = Math.max(0, estAlignmentY - allowance);
    int alignmentAreaBottomY =
        Math.min(image.getHeight() - 1, estAlignmentY + allowance);
    if (alignmentAreaBottomY - alignmentAreaTopY < overallEstModuleSize * 3) {
      throw NotFoundException.getNotFoundInstance();
    }

    AlignmentPatternFinder alignmentFinder = AlignmentPatternFinder(
        image,
        alignmentAreaLeftX,
        alignmentAreaTopY,
        alignmentAreaRightX - alignmentAreaLeftX,
        alignmentAreaBottomY - alignmentAreaTopY,
        overallEstModuleSize,
        resultPointCallback);
    return alignmentFinder.find();
  }
}
