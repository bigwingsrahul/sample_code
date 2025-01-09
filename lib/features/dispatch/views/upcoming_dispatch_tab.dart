import 'package:fbroadcast/fbroadcast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:techtruckers/config/theme/app_colors.dart';
import 'package:techtruckers/config/theme/app_text_styles.dart';
import 'package:techtruckers/features/common/widgets/custom_button.dart';
import 'package:techtruckers/features/common/widgets/no_record_widget.dart';
import 'package:techtruckers/features/dispatch/bloc/dispatcher_bloc.dart';
import 'package:techtruckers/features/dispatch/models/dispatch_load_data_model.dart';
import 'package:techtruckers/utils/constant.dart';
import 'package:techtruckers/utils/general_functions.dart';
import 'package:techtruckers/widget/tag.dart';

class UpcomingDispatchTab extends StatefulWidget {
  const UpcomingDispatchTab({super.key});

  @override
  State<UpcomingDispatchTab> createState() => _UpcomingDispatchTabState();
}

class _UpcomingDispatchTabState extends State<UpcomingDispatchTab> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<DispatchLoadData> loadItems = [];
  DispatcherBloc? dispatcherBloc;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    dispatcherBloc = BlocProvider.of<DispatcherBloc>(context);
    callBloc(dispatcherBloc?.add(UpcomingDispatcherLoadEvent(true)));
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.sizeOf(context).height;
    double width = MediaQuery.sizeOf(context).width;
    return BlocProvider(
      create: (context) => DispatcherBloc(),
      child: BlocListener<DispatcherBloc, DispatcherState>(
        bloc: dispatcherBloc,
        listener: (context, state) {
          if (state is DispatcherLoading) {
            setState(() {
              _isLoading = true;
            });
          }

          if (state is DispatcherFailure) {
            setState(() {
              _isLoading = false;
            });
            showToast(context, state.mError, true);
          }

          if (state is UpcomingDispatcherResponseState) {
            setState(() {
              _isLoading = false;
              loadItems = state.data.data;
            });
          }

          if (state is AutoLogoutFailure) {
            logoutUser(context);
          }
        },
        child: Scaffold(
          key: _scaffoldKey,
          body: _isLoading
              ? Center(
                  child: CircularProgressIndicator(),
                ).center()
              : loadItems.isNotEmpty
                  ? ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: loadItems.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.colorPrimary.withValues(alpha: 0.5),
                            ),
                            borderRadius: BorderRadius.circular(10),
                            color: AppColors.isDark(context)
                                ? AppColors.darkBackground
                                : Colors.white,
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
                              ).paddingOnly(
                                  top: 12, bottom: 8, left: 12, right: 12),
                              Divider(
                                color: AppColors.blackWhiteText(context)
                                    .withValues(alpha: 0.8),
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
                                        backgroundColor:
                                            AppColors.isDark(context)
                                                ? AppColors.cardDarkColor
                                                : const Color(0xffEAF9FF)),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: (width / 1.2) / 2,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Tag(
                                                height: 20,
                                                width: 90,
                                                text:
                                                    "Pick Up (${loadItems[index].stops.where((data) => data.stopType == "Pickup").length})",
                                                color: const Color(0xffF8F5A7),
                                              ),
                                              Column(
                                                children: [
                                                  buildRowItem(
                                                      Icons.location_on,
                                                      loadItems[index]
                                                          .stops
                                                          .first
                                                          .location),
                                                  8.height,
                                                  buildRowItem(
                                                      Icons.calendar_month,
                                                      getNormalDate(
                                                          loadItems[index]
                                                              .stops
                                                              .first
                                                              .date)),
                                                  8.height,
                                                  buildRowItem(
                                                      Icons.watch_later_rounded,
                                                      loadItems[index].stops.first.scheduleType
                                                          .toLowerCase() ==
                                                          "fcfs"
                                                          ? "${loadItems[index].stops.first.appointmentTime} - ${loadItems[index].stops.first.appointmentTime2} (FCFS)"
                                                          : loadItems[index].stops.first
                                                          .appointmentTime),
                                                ],
                                              )
                                                  .paddingSymmetric(vertical: 8)
                                                  .paddingLeft(12),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          width: (width / 1.2) / 2,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 8.0),
                                                child: Tag(
                                                  height: 20,
                                                  width: 90,
                                                  text:
                                                      "Drop Off (${loadItems[index].stops.where((data) => data.stopType != "Pickup").length})",
                                                  color:
                                                      const Color(0xff1EB980),
                                                ),
                                              ),
                                              Column(
                                                children: [
                                                  buildRowItem(
                                                      Icons.location_on,
                                                      loadItems[index]
                                                          .stops
                                                          .last
                                                          .location),
                                                  8.height,
                                                  buildRowItem(
                                                      Icons.calendar_month,
                                                      getNormalDate(
                                                          loadItems[index]
                                                              .stops
                                                              .last
                                                              .date)),
                                                  8.height,
                                                  buildRowItem(
                                                      Icons.watch_later_rounded,
                                                      loadItems[index].stops.last.scheduleType
                                                          .toLowerCase() ==
                                                          "fcfs"
                                                          ? "${loadItems[index].stops.last.appointmentTime} - ${loadItems[index].stops.last.appointmentTime2} (FCFS)"
                                                          : loadItems[index].stops.last
                                                          .appointmentTime),
                                                ],
                                              )
                                                  .paddingSymmetric(vertical: 8)
                                                  .paddingLeft(12),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  12.height,
                                  CustomButton(
                                    color: loadItems[index].isAccepted != true
                                        ? null
                                        : Color(0xff1EB980),
                                    gradientColors: loadItems[index]
                                                .isAccepted !=
                                            true
                                        ? AppColors.getButtonGradient(context)
                                        : [],
                                    borderColor:
                                        loadItems[index].isAccepted != true
                                            ? AppColors.colorPrimary
                                            : Colors.transparent,
                                    text: loadItems[index].isAccepted != true
                                        ? "Review & Accept"
                                        : "Accepted",
                                    onTapEvent: () async {
                                    },
                                  )
                                ],
                              ).paddingOnly(
                                  top: 8, left: 12, right: 12, bottom: 12),
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
      ),
    );
  }

  buildRowItem(IconData icon, String title) {
    return Row(
      children: [
        Icon(
          icon,
          color:
              AppColors.isDark(context) ? Colors.white : AppColors.colorPrimary,
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
}
