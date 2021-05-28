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

import 'parsed_result.dart';
import 'parsed_result_type.dart';

/**
 * Represents a parsed result that encodes extended product information as encoded
 * by the RSS format, like weight, price, dates, etc.
 *
 * @author Antonio Manuel Benjumea Conde, Servinform, S.A.
 * @author Agustín Delgado, Servinform, S.A.
 */
class ExpandedProductParsedResult extends ParsedResult {
  static final String KILOGRAM = "KG";
  static final String POUND = "LB";

  final String? rawText;
  final String? productID;
  final String? sscc;
  final String? lotNumber;
  final String? productionDate;
  final String? packagingDate;
  final String? bestBeforeDate;
  final String? expirationDate;
  final String? weight;
  final String? weightType;
  final String? weightIncrement;
  final String? price;
  final String? priceIncrement;
  final String? priceCurrency;
  // For AIS that not exist in this object
  final Map<String, String> uncommonAIs;

  ExpandedProductParsedResult(
      this.rawText,
      this.productID,
      this.sscc,
      this.lotNumber,
      this.productionDate,
      this.packagingDate,
      this.bestBeforeDate,
      this.expirationDate,
      this.weight,
      this.weightType,
      this.weightIncrement,
      this.price,
      this.priceIncrement,
      this.priceCurrency,
      this.uncommonAIs)
      : super(ParsedResultType.PRODUCT);

  @override
  operator ==(Object o) {
    if (!(o is ExpandedProductParsedResult)) {
      return false;
    }

    ExpandedProductParsedResult other = o;

    return productID == other.productID &&
        (sscc == other.sscc) &&
        (lotNumber == other.lotNumber) &&
        (productionDate == other.productionDate) &&
        (bestBeforeDate == other.bestBeforeDate) &&
        (expirationDate == other.expirationDate) &&
        (weight == other.weight) &&
        (weightType == other.weightType) &&
        (weightIncrement == other.weightIncrement) &&
        (price == other.price) &&
        (priceIncrement == other.priceIncrement) &&
        (priceCurrency == other.priceCurrency) &&
        (uncommonAIs == other.uncommonAIs);
  }

  @override
  int get hashCode {
    int hash = productID.hashCode;
    hash ^= sscc.hashCode;
    hash ^= lotNumber.hashCode;
    hash ^= productionDate.hashCode;
    hash ^= bestBeforeDate.hashCode;
    hash ^= expirationDate.hashCode;
    hash ^= weight.hashCode;
    hash ^= weightType.hashCode;
    hash ^= weightIncrement.hashCode;
    hash ^= price.hashCode;
    hash ^= priceIncrement.hashCode;
    hash ^= priceCurrency.hashCode;
    hash ^= uncommonAIs.hashCode;
    return hash;
  }

  String? getRawText() {
    return rawText;
  }

  String? getProductID() {
    return productID;
  }

  String? getSscc() {
    return sscc;
  }

  String? getLotNumber() {
    return lotNumber;
  }

  String? getProductionDate() {
    return productionDate;
  }

  String? getPackagingDate() {
    return packagingDate;
  }

  String? getBestBeforeDate() {
    return bestBeforeDate;
  }

  String? getExpirationDate() {
    return expirationDate;
  }

  String? getWeight() {
    return weight;
  }

  String? getWeightType() {
    return weightType;
  }

  String? getWeightIncrement() {
    return weightIncrement;
  }

  String? getPrice() {
    return price;
  }

  String? getPriceIncrement() {
    return priceIncrement;
  }

  String? getPriceCurrency() {
    return priceCurrency;
  }

  Map<String, String> getUncommonAIs() {
    return uncommonAIs;
  }

  @override
  String getDisplayResult() {
    return rawText.toString();
  }
}
