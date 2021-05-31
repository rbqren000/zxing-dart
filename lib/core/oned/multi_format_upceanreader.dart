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



import '../common/bit_array.dart';

import '../barcode_format.dart';
import '../decode_hint_type.dart';
import '../not_found_exception.dart';
import '../reader.dart';
import '../result.dart';
import 'ean13_reader.dart';
import 'ean8_reader.dart';
import 'one_dreader.dart';
import 'upcareader.dart';
import 'upceanreader.dart';
import 'upcereader.dart';

/**
 * <p>A reader that can read all available UPC/EAN formats. If a caller wants to try to
 * read all such formats, it is most efficient to use this implementation rather than invoke
 * individual readers.</p>
 *
 * @author Sean Owen
 */
class MultiFormatUPCEANReader extends OneDReader {

  static const List<UPCEANReader> _EMPTY_READER_ARRAY = [];

  late List<UPCEANReader> _readers;

  MultiFormatUPCEANReader(Map<DecodeHintType, Object>? hints) {
    // @SuppressWarnings("unchecked")
    List<BarcodeFormat>? possibleFormats = hints == null ? null :
         hints[DecodeHintType.POSSIBLE_FORMATS] as List<BarcodeFormat>;
    List<UPCEANReader> readers = [];
    if (possibleFormats != null) {
      if (possibleFormats.contains(BarcodeFormat.EAN_13)) {
        readers.add(EAN13Reader());
      } else if (possibleFormats.contains(BarcodeFormat.UPC_A)) {
        readers.add(UPCAReader());
      }
      if (possibleFormats.contains(BarcodeFormat.EAN_8)) {
        readers.add(EAN8Reader());
      }
      if (possibleFormats.contains(BarcodeFormat.UPC_E)) {
        readers.add(UPCEReader());
      }
    }
    if (readers.isEmpty) {
      readers.add(EAN13Reader());
      // UPC-A is covered by EAN-13
      readers.add(EAN8Reader());
      readers.add(UPCEReader());
    }
    this._readers = readers.toList();
  }

  @override
  Result decodeRow(int rowNumber,
                          BitArray row,
                          Map<DecodeHintType, Object>? hints){
    // Compute this location once and reuse it on multiple implementations
    List<int>? startGuardPattern = UPCEANReader.findStartGuardPattern(row);
    for (UPCEANReader reader in _readers) {
      try {
        Result result = reader.decodeRow(rowNumber, row, hints, startGuardPattern);
        // Special case: a 12-digit code encoded in UPC-A is identical to a "0"
        // followed by those 12 digits encoded as EAN-13. Each will recognize such a code,
        // UPC-A as a 12-digit string and EAN-13 as a 13-digit string starting with "0".
        // Individually these are correct and their readers will both read such a code
        // and correctly call it EAN-13, or UPC-A, respectively.
        //
        // In this case, if we've been looking for both types, we'd like to call it
        // a UPC-A code. But for efficiency we only run the EAN-13 decoder to also read
        // UPC-A. So we special case it here, and convert an EAN-13 result to a UPC-A
        // result if appropriate.
        //
        // But, don't return UPC-A if UPC-A was not a requested format!
        bool ean13MayBeUPCA =
            result.getBarcodeFormat() == BarcodeFormat.EAN_13 &&
                result.getText()[0] == '0';
        // @SuppressWarnings("unchecked")
        List<BarcodeFormat>? possibleFormats =
            hints == null ? null : hints[DecodeHintType.POSSIBLE_FORMATS] as List<BarcodeFormat>;
        bool canReturnUPCA = possibleFormats == null || possibleFormats.contains(BarcodeFormat.UPC_A);
  
        if (ean13MayBeUPCA && canReturnUPCA) {
          // Transfer the metadata across
          Result resultUPCA = Result(result.getText().substring(1),
                                         result.getRawBytes(),
                                         result.getResultPoints(),
                                         BarcodeFormat.UPC_A);
          resultUPCA.putAllMetadata(result.getResultMetadata());
          return resultUPCA;
        }
        return result;
      } catch ( ignored) { // ReaderException
        // continue
      }
    }

    throw NotFoundException.getNotFoundInstance();
  }

  @override
  void reset() {
    for (Reader reader in _readers) {
      reader.reset();
    }
  }

}
