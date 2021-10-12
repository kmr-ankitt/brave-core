/* Copyright (c) 2021 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef BRAVE_VENDOR_BAT_NATIVE_ADS_SRC_BAT_ADS_INTERNAL_FREQUENCY_CAPPING_EXCLUSION_RULES_PER_MONTH_FREQUENCY_CAP_H_  // NOLINT
#define BRAVE_VENDOR_BAT_NATIVE_ADS_SRC_BAT_ADS_INTERNAL_FREQUENCY_CAPPING_EXCLUSION_RULES_PER_MONTH_FREQUENCY_CAP_H_  // NOLINT

#include <string>

#include "bat/ads/internal/ad_events/ad_event_info_aliases.h"
#include "bat/ads/internal/bundle/creative_ad_info.h"
#include "bat/ads/internal/frequency_capping/exclusion_rules/exclusion_rule.h"

namespace ads {

class PerMonthFrequencyCap final : public ExclusionRule<CreativeAdInfo> {
 public:
  explicit PerMonthFrequencyCap(const AdEventList& ad_events);
  ~PerMonthFrequencyCap() override;

  PerMonthFrequencyCap(const PerMonthFrequencyCap&) = delete;
  PerMonthFrequencyCap& operator=(const PerMonthFrequencyCap&) = delete;

  std::string GetUuid(const CreativeAdInfo& creative_ad) const override;

  bool ShouldExclude(const CreativeAdInfo& creative_ad) override;

  std::string GetLastMessage() const override;

 private:
  AdEventList ad_events_;

  std::string last_message_;

  bool DoesRespectCap(const AdEventList& ad_events,
                      const CreativeAdInfo& creative_ad);
};

}  // namespace ads

#endif  // BRAVE_VENDOR_BAT_NATIVE_ADS_SRC_BAT_ADS_INTERNAL_FREQUENCY_CAPPING_EXCLUSION_RULES_PER_MONTH_FREQUENCY_CAP_H_
