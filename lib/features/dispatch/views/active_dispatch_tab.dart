import 'package:fbroadcast/fbroadcast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/search.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:techtruckers/config/theme/app_colors.dart';
import 'package:techtruckers/config/theme/app_text_styles.dart';
import 'package:techtruckers/features/common/widgets/custom_button.dart';
import 'package:techtruckers/features/common/widgets/loader_dialog.dart';
import 'package:techtruckers/features/common/widgets/no_record_widget.dart';
import 'package:techtruckers/features/dispatch/bloc/dispatcher_bloc.dart';
import 'package:techtruckers/features/dispatch/models/dispatch_load_data_model.dart';
import 'package:techtruckers/main.dart';
import 'package:techtruckers/utils/constant.dart';
import 'package:techtruckers/utils/general_functions.dart';
import 'package:techtruckers/widget/tag.dart';

class ActiveDispatchTab extends StatefulWidget {
  const ActiveDispatchTab({super.key});

  @override
  State<ActiveDispatchTab> createState() => _ActiveDispatchTabState();
}

class _ActiveDispatchTabState extends State<ActiveDispatchTab> {
  List<DispatchLoadData> loadItems = [];
  bool _isLoading = false;
  String currentAddress = "";
  late SearchEngine _searchEngine;

  @override
  void initState() {
    super.initState();

    _searchEngine = SearchEngine();
    getCurrentAddress();
    callBloc(BlocProvider.of<DispatcherBloc>(context).add(NewDispatcherLoadEvent(true)));
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.sizeOf(context).width;
    return Scaffold(
      body: BlocListener<DispatcherBloc, DispatcherState>(
        listener: (context, state) {
          if (state is DispatcherLoading) {
            setState(() {
              _isLoading = true;
            });
          }

          if (state is DispatcherFailure) {
            LoaderDialog().hide();
            setState(() {
              _isLoading = false;
            });
            showToast(context, state.mError, true);
          }

          if (state is DispatcherResponseState) {
            setState(() {
              _isLoading = false;
              loadItems = state.data.data;
            });
          }

          if (state is StartTripState) {
            if (state.isSuccess) {
              if (state.isEndTrip) {
                // showTripEndedDialog();
                LoaderDialog().show(context, "Checking for new loads");
                callBloc(BlocProvider.of<DispatcherBloc>(context).add(UpcomingDispatcherLoadEvent(true, showJobDone: true)));
              } else {
                FBroadcast.instance().broadcast(Constant.dispatchStatus, value: Constant.tripStarted);
              }
            }
          }

          if (state is UpcomingDispatcherResponseState) {
            LoaderDialog().hide();

            if (state.data.data.isEmpty && state.showJobDone) {
              showJobDoneDialog();
            }
          }

          if (state is AutoLogoutFailure) {
            logoutUser(context);
          }
        },
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(),
              )
            : loadItems.isNotEmpty
                ? ListView.separated(
                    shrinkWrap: true,
                    itemCount: loadItems.length,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (BuildContext context, int index) {
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.colorPrimary.withValues(alpha: 0.5),
                          ),
                          borderRadius: BorderRadius.circular(10),
                          color: AppColors.isDark(context) ? AppColors.darkBackground : Colors.white,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "Load No. - ${loadItems[index].loadId}",
                                  style: AppTextStyles.textSmallTitleBold,
                                ),
                                Spacer(),
                                Icon(Icons.arrow_forward_ios_outlined)
                              ],
                            ).paddingOnly(top: 12, bottom: 8, left: 12, right: 12),
                            Divider(
                              color: AppColors.blackWhiteText(context).withValues(alpha: 0.8),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Total Miles - ${loadItems[index].loadMiles?.proMiles.loadedMiles} mi",
                                  style: AppTextStyles.textBodyBold,
                                ),
                                8.height,
                                Container(
                                  decoration: boxDecorationWithRoundedCorners(
                                      backgroundColor: AppColors.isDark(context) ? AppColors.cardDarkColor : const Color(0xffEAF9FF)),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: (width / 1.2) / 2,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Tag(
                                              height: 20,
                                              width: 90,
                                              text: "Pick Up (${loadItems[index].stops.where((data) => data.stopType == "Pickup").length})",
                                              color: const Color(0xffF8F5A7),
                                            ),
                                            Column(
                                              children: [
                                                buildRowItem(Icons.location_on, loadItems[index].stops.first.location),
                                                8.height,
                                                buildRowItem(Icons.calendar_month, getNormalDate(loadItems[index].stops.first.date)),
                                                8.height,
                                                buildRowItem(
                                                    Icons.watch_later_rounded,
                                                    loadItems[index].stops.first.scheduleType.toLowerCase() == "fcfs"
                                                        ? "${loadItems[index].stops.first.appointmentTime} - ${loadItems[index].stops.first.appointmentTime2} (FCFS)"
                                                        : getFormattedDate("hh:mm a", DateTime.parse(loadItems[index].stops.first.stopDateTime), true)),
                                              ],
                                            ).paddingSymmetric(vertical: 8).paddingLeft(12),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        width: (width / 1.2) / 2,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(left: 8.0),
                                              child: Tag(
                                                height: 20,
                                                width: 90,
                                                text: "Drop Off (${loadItems[index].stops.where((data) => data.stopType != "Pickup").length})",
                                                color: const Color(0xff1EB980),
                                              ),
                                            ),
                                            Column(
                                              children: [
                                                buildRowItem(Icons.location_on, loadItems[index].stops.last.location),
                                                8.height,
                                                buildRowItem(Icons.calendar_month, getNormalDate(loadItems[index].stops.last.date)),
                                                8.height,
                                                buildRowItem(
                                                    Icons.watch_later_rounded,
                                                    loadItems[index].stops.last.scheduleType.toLowerCase() == "fcfs"
                                                        ? "${loadItems[index].stops.last.appointmentTime} - ${loadItems[index].stops.last.appointmentTime2} (FCFS)"
                                                        : getFormattedDate("hh:mm a", DateTime.parse(loadItems[index].stops.last.stopDateTime), true)),
                                              ],
                                            ).paddingSymmetric(vertical: 8).paddingLeft(12),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                12.height,
                                loadItems[index].status.toLowerCase() != "assigned"
                                    ? CustomButton(
                                        text: "End Load",
                                        borderColor: AppColors.appRedColor,
                                        color: (loadItems[index].status == "Redeliver" && loadItems[index].newStop!.latestStatus == "3") ||
                                                (loadItems[index].status != "Redeliver" && loadItems[index].stops.last.latestStatus == "3")
                                            ? AppColors.appRedColor
                                            : AppColors.isDark(context)
                                                ? Color(0xff540B2B)
                                                : Color(0xffFFB4D1),
                                        onTapEvent: () {
                                          if ((loadItems[index].status == "Redeliver" && loadItems[index].newStop!.latestStatus != "3") ||
                                              (loadItems[index].status != "Redeliver" && loadItems[index].stops.last.latestStatus != "3")) {
                                            showToast(context, "Deliver all loads to end the trip", true);
                                            return;
                                          }

                                          // var distanceToStartPoint = calculateDistance(
                                          //     originLat: currentLocation.value.latitude,
                                          //     originLng: currentLocation.value.longitude,
                                          //     destLat: loadItems[index].assignedJobs.endCoordinates.coordinates.last,
                                          //     destLng: loadItems[index].assignedJobs.endCoordinates.coordinates.first);

                                          // if (distanceToStartPoint > (geoFenceDistance / 1000)) {
                                          //   showToast(
                                          //       context,
                                          //       "Please reach at the end location to end trip",
                                          //       true);
                                          //
                                          //   return;
                                          // }

                                          callBloc(BlocProvider.of<DispatcherBloc>(context)
                                              .add(StartTripEvent(loadItems[index].loadId, {"isEnded": true,
                                            "startLocation": currentAddress,
                                            "startLng": currentLocation.value.longitude,
                                            "startLat": currentLocation.value.latitude
                                          })));
                                        })
                                    : CustomButton(
                                        text: loadItems[index].isAccepted != true ? "Review & Accept" : "Start Load",
                                        color: loadItems[index].isAccepted != true ? null : Color(0xff1EB980),
                                        gradientColors: loadItems[index].isAccepted != true ? AppColors.getButtonGradient(context) : [],
                                        borderColor: loadItems[index].isAccepted != true ? AppColors.colorPrimary : Colors.transparent,
                                        onTapEvent: () async {
                                          if (loadItems[index].isAccepted != true) {
                                          } else {
                                            var distanceToStartPoint = calculateDistance(
                                                originLat: currentLocation.value.latitude,
                                                originLng: currentLocation.value.longitude,
                                                destLat: loadItems[index].assignedJobs.startCoordinates.coordinates.last,
                                                destLng: loadItems[index].assignedJobs.startCoordinates.coordinates.first);

                                            if (distanceToStartPoint > (geoFenceDistance / 1000)) {
                                              showToast(
                                                  context,
                                                  "Please reach at the start location to start trip",
                                                  true);

                                              return;
                                            }

                                            callBloc(BlocProvider.of<DispatcherBloc>(context).add(StartTripEvent(loadItems[index].loadId, {
                                              "startLocation": currentAddress,
                                              "startLng": currentLocation.value.longitude,
                                              "startLat": currentLocation.value.latitude
                                            })));
                                          }
                                        },
                                      ).center(),
                              ],
                            ).paddingOnly(top: 8, left: 12, right: 12, bottom: 12),
                          ],
                        ),
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) {
                      return 16.height;
                    },
                  )
                : NoRecordWidget(),
      ),
    );
  }

  buildRowItem(IconData icon, String title) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.isDark(context) ? Colors.white : AppColors.colorPrimary,
          size: 2.h,
        ),
        8.width,
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.textSmallNormal,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void showTripEndedDialog() {
    Future.delayed(Duration(seconds: 2), () {
      Navigator.pop(context);
      LoaderDialog().show(context, "Checking for new loads");
      callBloc(BlocProvider.of<DispatcherBloc>(context).add(UpcomingDispatcherLoadEvent(true, showJobDone: true)));
    });
  }

  Future<void> showJobDoneDialog() async {

  }

  void getCurrentAddress() {
    SearchOptions reverseGeocodingOptions = SearchOptions();
    reverseGeocodingOptions.languageCode = LanguageCode.enGb;
    reverseGeocodingOptions.maxItems = 1;

    _searchEngine.searchByCoordinates(currentLocation.value, reverseGeocodingOptions, (SearchError? searchError, List<Place>? list) async {
      if (searchError != null) {
        toast("Error: $searchError");
        return;
      }

      // If error is null, list is guaranteed to be not empty.
      currentAddress = list!.first.address.addressText;
      if (mounted) {
        setState(() {});
      }
    });
  }
}
