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

import 'dart:math' as math;

import 'dart:typed_data';

import 'package:zxing/core/common/detector/math_utils.dart';

/**
 * <p>A simple, fast array of bits, represented compactly by an array of ints internally.</p>
 *
 * @author Sean Owen
 */
class BitArray {
  late List<int> bits;
  int size;

  BitArray({List<int>? bits, this.size = 0}) {
    if (bits == null) {
      this.bits = makeArray(size);
    }
  }

  int getSize() {
    return size;
  }

  int getSizeInBytes() {
    return (size + 7) ~/ 8;
  }

  void ensureCapacity(int size) {
    if (size > bits.length * 32) {
      List<int> newBits = makeArray(size);
      List.copyRange(newBits, 0, bits, 0, bits.length);
      this.bits = newBits;
    }
  }

  /**
   * @param i bit to get
   * @return true iff bit i is set
   */
  bool get(int i) {
    return (bits[i ~/ 32] & (1 << (i & 0x1F))) != 0;
  }

  /**
   * Sets bit i.
   *
   * @param i bit to set
   */
  void set(int i) {
    bits[i ~/ 32] |= 1 << (i & 0x1F);
  }

  /**
   * Flips bit i.
   *
   * @param i bit to set
   */
  void flip(int i) {
    bits[i ~/ 32] ^= 1 << (i & 0x1F);
  }

  /**
   * @param from first bit to check
   * @return index of first bit that is set, starting from the given index, or size if none are set
   *  at or beyond this given index
   * @see #getNextUnset(int)
   */
  int getNextSet(int from) {
    if (from >= size) {
      return size;
    }
    int bitsOffset = from ~/ 32;
    int currentBits = bits[bitsOffset];
    // mask off lesser bits first
    currentBits &= -(1 << (from & 0x1F));
    while (currentBits == 0) {
      if (++bitsOffset == bits.length) {
        return size;
      }
      currentBits = bits[bitsOffset];
    }
    int result =
        (bitsOffset * 32) + MathUtils.numberOfTrailingZeros(currentBits);
    return math.min(result, size);
  }

  /**
   * @param from index to start looking for unset bit
   * @return index of next unset bit, or {@code size} if none are unset until the end
   * @see #getNextSet(int)
   */
  int getNextUnset(int from) {
    if (from >= size) {
      return size;
    }
    int bitsOffset = from ~/ 32;
    int currentBits = ~bits[bitsOffset];
    // mask off lesser bits first
    currentBits &= -(1 << (from & 0x1F));
    while (currentBits == 0) {
      if (++bitsOffset == bits.length) {
        return size;
      }
      currentBits = ~bits[bitsOffset];
    }
    int result =
        (bitsOffset * 32) + MathUtils.numberOfTrailingZeros(currentBits);
    return math.min(result, size);
  }

  /**
   * Sets a block of 32 bits, starting at bit i.
   *
   * @param i first bit to set
   * @param newBits the new value of the next 32 bits. Note again that the least-significant bit
   * corresponds to bit i, the next-least-significant to i+1, and so on.
   */
  void setBulk(int i, int newBits) {
    bits[i ~/ 32] = newBits;
  }

  /**
   * Sets a range of bits.
   *
   * @param start start of range, inclusive.
   * @param end end of range, exclusive
   */
  void setRange(int start, int end) {
    if (end < start || start < 0 || end > size) {
      throw Exception(r'Illegal Argument');
    }
    if (end == start) {
      return;
    }
    end--; // will be easier to treat this as the last actually set bit -- inclusive
    int firstInt = start ~/ 32;
    int lastInt = end ~/ 32;
    for (int i = firstInt; i <= lastInt; i++) {
      int firstBit = i > firstInt ? 0 : start & 0x1F;
      int lastBit = i < lastInt ? 31 : end & 0x1F;
      // Ones from firstBit to lastBit, inclusive
      int mask = (2 << lastBit) - (1 << firstBit);
      bits[i] |= mask;
    }
  }

  /**
   * Clears all bits (sets to false).
   */
  void clear() {
    int max = bits.length;
    for (int i = 0; i < max; i++) {
      bits[i] = 0;
    }
  }

  /**
   * Efficient method to check if a range of bits is set, or not set.
   *
   * @param start start of range, inclusive.
   * @param end end of range, exclusive
   * @param value if true, checks that bits in range are set, otherwise checks that they are not set
   * @return true iff all bits are set or not set in range, according to value argument
   * @throws IllegalArgumentException if end is less than start or the range is not contained in the array
   */
  bool isRange(int start, int end, bool value) {
    if (end < start || start < 0 || end > size) {
      throw Exception(r'Illegal Argument');
    }
    if (end == start) {
      return true; // empty range matches
    }
    end--; // will be easier to treat this as the last actually set bit -- inclusive
    int firstInt = start ~/ 32;
    int lastInt = end ~/ 32;
    for (int i = firstInt; i <= lastInt; i++) {
      int firstBit = i > firstInt ? 0 : start & 0x1F;
      int lastBit = i < lastInt ? 31 : end & 0x1F;
      // Ones from firstBit to lastBit, inclusive
      int mask = (2 << lastBit) - (1 << firstBit);

      // Return false if we're looking for 1s and the masked bits[i] isn't all 1s (that is,
      // equals the mask, or we're looking for 0s and the masked portion is not all 0s
      if ((bits[i] & mask) != (value ? mask : 0)) {
        return false;
      }
    }
    return true;
  }

  void appendBit(bool bit) {
    ensureCapacity(size + 1);
    if (bit) {
      bits[size ~/ 32] |= 1 << (size & 0x1F);
    }
    size++;
  }

  /**
   * Appends the least-significant bits, from value, in order from most-significant to
   * least-significant. For example, appending 6 bits from 0x000001E will append the bits
   * 0, 1, 1, 1, 1, 0 in that order.
   *
   * @param value {@code int} containing bits to append
   * @param numBits bits from value to append
   */
  void appendBits(int value, int numBits) {
    assert(numBits >= 0 && numBits <= 32, r'Num bits must be between 0 and 32');

    ensureCapacity(size + numBits);
    for (int numBitsLeft = numBits; numBitsLeft > 0; numBitsLeft--) {
      appendBit(((value >> (numBitsLeft - 1)) & 0x01) == 1);
    }
  }

  void appendBitArray(BitArray other) {
    int otherSize = other.size;
    ensureCapacity(size + otherSize);
    for (int i = 0; i < otherSize; i++) {
      appendBit(other.get(i));
    }
  }

  void xor(BitArray other) {
    assert(size == other.size, r"Sizes don't match");

    for (int i = 0; i < bits.length; i++) {
      // The last int could be incomplete (i.e. not have 32 bits in
      // it) but there is no problem since 0 XOR 0 == 0.
      bits[i] ^= other.bits[i];
    }
  }

  /**
   *
   * @param bitOffset first bit to start writing
   * @param array array to write into. Bytes are written most-significant byte first. This is the opposite
   *  of the internal representation, which is exposed by {@link #getBitArray()}
   * @param offset position in array to start writing
   * @param numBytes how many bytes to write
   */
  void toBytes(int bitOffset, Uint8List array, int offset, int numBytes) {
    for (int i = 0; i < numBytes; i++) {
      int theByte = 0;
      for (int j = 0; j < 8; j++) {
        if (get(bitOffset)) {
          theByte |= 1 << (7 - j);
        }
        bitOffset++;
      }
      array[offset + i] = theByte;
    }
  }

  /**
   * @return underlying array of ints. The first element holds the first 32 bits, and the least
   *         significant bit is bit 0.
   */
  List<int> getBitArray() {
    return bits;
  }

  /**
   * Reverses all bits in the array.
   */
  void reverse() {
    List<int> newBits = List.generate(bits.length, (index) => 0);
    // reverse all int's first
    int len = (size - 1) ~/ 32;
    int oldBitsLen = len + 1;
    for (int i = 0; i < oldBitsLen; i++) {
      int x = bits[i];
      x = ((x >> 1) & 0x55555555) | ((x & 0x55555555) << 1);
      x = ((x >> 2) & 0x33333333) | ((x & 0x33333333) << 2);
      x = ((x >> 4) & 0x0f0f0f0f) | ((x & 0x0f0f0f0f) << 4);
      x = ((x >> 8) & 0x00ff00ff) | ((x & 0x00ff00ff) << 8);
      x = ((x >> 16) & 0x0000ffff) | ((x & 0x0000ffff) << 16);
      newBits[len - i] = x;
    }
    // now correct the int's if the bit size isn't a multiple of 32
    if (size != oldBitsLen * 32) {
      int leftOffset = oldBitsLen * 32 - size;
      int currentInt = newBits[0] >> leftOffset;
      for (int i = 1; i < oldBitsLen; i++) {
        int nextInt = newBits[i];
        currentInt |= nextInt << (32 - leftOffset);
        newBits[i - 1] = currentInt;
        currentInt = nextInt >> leftOffset;
      }
      newBits[oldBitsLen - 1] = currentInt;
    }
    bits = newBits;
  }

  static List<int> makeArray(int size) {
    return List.generate((size + 31) ~/ 32, (index) => 0);
  }

  @override
  bool equals(Object o) {
    if (!(o is BitArray)) {
      return false;
    }
    BitArray other = o;
    return size == other.size && bits == other.bits;
  }

  @override
  int get hashCode {
    return 31 * size + bits.hashCode;
  }

  @override
  String toString() {
    StringBuffer result = StringBuffer();
    for (int i = 0; i < size; i++) {
      if ((i & 0x07) == 0) {
        result.write(' ');
      }
      result.write(get(i) ? 'X' : '.');
    }
    return result.toString();
  }

  BitArray clone() {
    return BitArray(bits: bits.getRange(0, bits.length).toList(), size: size);
  }
}
