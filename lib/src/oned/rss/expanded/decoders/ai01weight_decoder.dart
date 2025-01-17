/*
 * Copyright (C) 2010 ZXing authors
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

/*
 * These authors would like to acknowledge the Spanish Ministry of Industry,
 * Tourism and Trade, for the support in the project TSI020301-2008-2
 * "PIRAmIDE: Personalizable Interactions with Resources on AmI-enabled
 * Mobile Dynamic Environments", led by Treelogic
 * ( http://www.treelogic.com/ ):
 *
 *   http://www.piramidepse.com/
 */

import '../../../../common/bit_array.dart';

import 'ai01decoder.dart';

/// @author Pablo Orduña, University of Deusto (pablo.orduna@deusto.es)
abstract class AI01weightDecoder extends AI01decoder {
  AI01weightDecoder(BitArray information) : super(information);

  void encodeCompressedWeight(
    StringBuffer buf,
    int currentPos,
    int weightSize,
  ) {
    final originalWeightNumeric =
        generalDecoder.extractNumericValueFromBitArray(currentPos, weightSize);
    addWeightCode(buf, originalWeightNumeric);

    final weightNumeric = checkWeight(originalWeightNumeric);

    int currentDivisor = 100000;
    for (int i = 0; i < 5; ++i) {
      if (weightNumeric ~/ currentDivisor == 0) {
        buf.write('0');
      }
      currentDivisor = currentDivisor ~/ 10;
    }
    buf.write(weightNumeric);
  }

  //@protected
  void addWeightCode(StringBuffer buf, int weight);

  //@protected
  int checkWeight(int weight);
}
