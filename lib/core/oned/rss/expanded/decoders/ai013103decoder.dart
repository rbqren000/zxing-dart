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

import 'package:flutter/cupertino.dart';

import '../../../../common/bit_array.dart';

import 'ai013x0x_decoder.dart';

/**
 * @author Pablo Orduña, University of Deusto (pablo.orduna@deusto.es)
 */
class AI013103decoder extends AI013x0xDecoder {
  AI013103decoder(BitArray information) : super(information);

  @override
  @protected
  void addWeightCode(StringBuffer buf, int weight) {
    buf.write("(3103)");
  }

  @override
  @protected
  int checkWeight(int weight) {
    return weight;
  }
}
