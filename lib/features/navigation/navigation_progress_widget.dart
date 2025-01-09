/*
 * Copyright (C) 2020-2024 HERE Europe B.V.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * SPDX-License-Identifier: Apache-2.0
 * License-Filename: LICENSE
 */

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:techtruckers/config/theme/app_colors.dart';
import 'package:techtruckers/config/theme/app_text_styles.dart';
import 'package:techtruckers/config/theme/ui_style.dart';
import 'package:techtruckers/utils/general_functions.dart';

import 'route_progress_widget.dart';

/// A widget that displays the current navigation progress.
class NavigationProgress extends StatelessWidget {
  /// The length of the route.
  final int routeLengthInMeters;

  /// Remaining distance in meters.
  final int remainingDistanceInMeters;

  /// Delay time in seconds.
  final int remainingDurationInSeconds;

  /// Load status.
  final String loadStatus;

  // Exit tap
  final VoidCallback onExit;

  // Map tap
  final VoidCallback onMapSwitch;

  // Appointment date
  final DateTime? appointmentDate;

  /// Constructs a widget.
  NavigationProgress({
    super.key,
    required this.routeLengthInMeters,
    required this.remainingDistanceInMeters,
    required this.remainingDurationInSeconds,
    required this.loadStatus,
    required this.onExit,
    required this.appointmentDate, required this.onMapSwitch,
  });

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;

    DateTime dt = DateTime.now();
    DateTime dtArrival = dt.add(Duration(seconds: remainingDurationInSeconds));

    int remainingHours = (remainingDurationInSeconds / 3600).truncate();
    int remainingMinutes = ((remainingDurationInSeconds - remainingHours * 3600) / 60).truncate();

    String remainingDistanceUnits = appLocalizations.kilometerAbbreviationText;
    int remainingDistance = (remainingDistanceInMeters / 1000).truncate();
    if (remainingDistance == 0) {
      remainingDistance = remainingDistanceInMeters;
      remainingDistanceUnits = appLocalizations.meterAbbreviationText;
    }

    return Container(
      decoration: boxDecorationWithRoundedCorners(
          backgroundColor: AppColors.darkBackground,
          borderRadius: BorderRadius.circular(0)),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatDuration(remainingDurationInSeconds),
                    style: AppTextStyles.textTitleSemiBold
                        .copyWith(color: Colors.white),
                  ),
                  8.width,
                  Row(
                    children: [
                      Text(formatDistance(remainingDistanceInMeters),
                          style: AppTextStyles.textBodySemiBold
                              .copyWith(color: Colors.white)),
                      8.width,
                      Visibility(
                        visible: loadStatus.isNotEmpty,
                        child: Text(
                          "($loadStatus)",
                          style: TextStyle(
                            fontSize: UIStyle.mediumFontSize,
                            fontWeight: FontWeight.w600,
                            color: loadStatus == "Delayed" ? AppColors.appRedColor : AppColors.appGreenColor,
                          ),
                          maxLines: 1,
                        ),
                      )
                    ],
                  ),
                  12.height,
                  Text(
                      "Est. time : ${getFormattedDate("MMM dd, yyyy | hh:mm a", dtArrival, false)}",
                      style: AppTextStyles.textBodySemiBold
                          .copyWith(color: Colors.white)),
                  12.height,
                  Text(
                      "HOS Time : ${formatDurationComplete(calculateHOS(remainingDurationInSeconds))}",
                      style: AppTextStyles.textBodySemiBold
                          .copyWith(color: Colors.white)),
                  12.height,
                  appointmentDate == null ? SizedBox() : Text(
                      "Apt. time : ${getFormattedDate("MMM dd, yyyy | hh:mm a", appointmentDate!, true)}",
                      style: AppTextStyles.textBodySemiBold
                          .copyWith(color: Colors.white)),
                ],
              ).expand(),
              12.width,
              SizedBox(
                height: 130,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: onMapSwitch,
                      child: Container(
                          height: 48,
                          width: 48,
                          decoration: boxDecorationRoundedWithShadow(1000,
                            backgroundColor: textSecondaryColor
                          ),
                          child: Icon(Icons.map_outlined, color: Colors.white,),
                      ),
                    ),
                    Container(
                      decoration: boxDecorationWithRoundedCorners(
                          borderRadius: BorderRadius.circular(100),
                          backgroundColor: Colors.redAccent),
                      padding: EdgeInsets.symmetric(
                          vertical: 12, horizontal: 24),
                      child: Text(
                        "Exit",
                        style: AppTextStyles.textBodySemiBold
                            .copyWith(color: Colors.white),
                      ),
                    ).onTap(onExit),
                  ],
                ),
              )
            ],
          ),
          8.height,
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: RouteProgress(
                routeLengthInMeters: routeLengthInMeters,
                remainingDistanceInMeters: remainingDistanceInMeters,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
