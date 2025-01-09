import 'dart:convert';

import 'package:fbroadcast/fbroadcast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:techtruckers/config/theme/app_colors.dart';
import 'package:techtruckers/config/theme/app_text_styles.dart';
import 'package:techtruckers/features/common/widgets/custom_button.dart';
import 'package:techtruckers/features/dispatch/bloc/dispatcher_bloc.dart';
import 'package:techtruckers/features/dispatch/models/dispatch_load_data_model.dart' as dispatchModel;
import 'package:techtruckers/features/dispatch/models/redeliver_notification_model.dart';
import 'package:techtruckers/features/dispatch/views/dispatch_list_screen.dart';
import 'package:techtruckers/utils/constant.dart';
import 'package:techtruckers/utils/general_functions.dart';

class DispatchRejectionApprovalScreen extends StatefulWidget {
  final dispatchModel.Stop? newStop;
  const DispatchRejectionApprovalScreen({super.key, this.newStop});

  @override
  State<DispatchRejectionApprovalScreen> createState() =>
      _DispatchRejectionApprovalScreenState();
}

class _DispatchRejectionApprovalScreenState
    extends State<DispatchRejectionApprovalScreen> {
  int type = 0;
  ReDeliverNotificationData? reDeliverNotificationData;

  @override
  void initState() {
    super.initState();

    if(widget.newStop != null){
      if (widget.newStop!.poNumber != "Redeliver") {
        type == 0;
      } else {
        type == 1;
      }
    }

    FBroadcast.instance().register(Constant.dispatchRejectionStatus,
        (value, callback) {
      print(value);

      try {
        reDeliverNotificationData =
            reDeliverNotificationDataFromJson(jsonEncode(value));
        if (reDeliverNotificationData?.stop.poNumber != "Redeliver") {
          type == 0;
        } else {
          type == 1;
        }
      }catch(e, stack){
        print(e);
        print(stack);
      }finally {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.sizeOf(context);
    return BlocListener<DispatcherBloc, DispatcherState>(
      listener: (context, state) {

        if(state is UpdateStopState){
          navigate(context, DispatchListScreen(preselected: 2,), true);
        }

      },
      child: Scaffold(
        appBar: getAppBar(false, context),
        body: Container(
          height: size.height,
          width: size.width,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: AppColors.isDark(context)
                  ? [
                      AppColors.scaffoldDarkBackground,
                      AppColors.scaffoldDarkBackground,
                    ]
                  : [
                      Colors.white,
                      Color(0XFFEAF9FF),
                      Color(0XFFEAF9FF),
                      Color(0XFFEAF9FF),
                    ],
            ),
          ),
          child: reDeliverNotificationData == null && widget.newStop == null
              ? buildWaitingScreen()
              : buildApprovalScreen(),
        ),
      ),
    );
  }

  buildWaitingScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Lottie.asset(
            AppColors.isDark(context)
                ? "assets/lottie/clock_lottie_dark.json"
                : "assets/lottie/clock_lottie.json",
            height: 28.h),
        Text(
          "Rejection on the load,\nWaiting for the final approval",
          textAlign: TextAlign.center,
          style: AppTextStyles.textBodySemiBold,
        )
      ],
    ).paddingBottom(48);
  }

  buildApprovalScreen() {
    return Column(
      children: [
        Text(
          type == 0
              ? "The load is to be redelivered\nat the location shared below:"
              : "The load is to be Dumped and Donated\nat the location shared below:",
          style: AppTextStyles.textBodySemiBold,
        ),
        16.height,
        Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.isDark(context)
                      ? Colors.white
                      : AppColors.colorPrimary),
              color: AppColors.isDark(context)
                  ? AppColors.darkBackground
                  : Colors.white),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type == 0 ? "Re-Deliver At" : "Dump & Donate At",
                style: AppTextStyles.textSmallTitleSemiBold,
              ).paddingOnly(top: 12, bottom: 8, left: 12, right: 12),
              Divider(
                color: AppColors.blackWhiteText(context).withValues(alpha: 0.8),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Total Miles - ${widget.newStop?.miles ?? reDeliverNotificationData?.stop.miles} mi",
                    style: AppTextStyles.textBodyBold,
                  ),
                  Container(
                    decoration: boxDecorationWithRoundedCorners(
                        backgroundColor: AppColors.isDark(context)
                            ? AppColors.cardDarkColor
                            : const Color(0xffEAF9FF)),
                    padding: EdgeInsets.all(12),
                    margin: EdgeInsets.symmetric(vertical: 12),
                    child: widget.newStop != null ? Column(
                      children: [
                        buildRowItem(Icons.location_on,
                            widget.newStop!.location),
                        8.height,
                        buildRowItem(
                          Icons.calendar_month,
                          getFormattedDate("MM/dd/yyyy", DateTime.parse(widget.newStop!.stopDateTime), true),
                        ),
                        8.height,
                        buildRowItem(Icons.watch_later,
                            widget.newStop!.appointmentTime),
                      ],
                    ) : Column(
                      children: [
                        buildRowItem(Icons.location_on,
                            reDeliverNotificationData!.stop.location),
                        8.height,
                        buildRowItem(
                            Icons.calendar_month,
                            getFormattedDate("MM/dd/yyyy", reDeliverNotificationData!.stop.stopDateTime, true),
                        ),
                        8.height,
                        buildRowItem(Icons.watch_later,
                            reDeliverNotificationData!.stop.appointmentTime),
                      ],
                    ),
                  ),
                  12.height,
                  CustomButton(
                    color: Color(0xff1EB980),
                    borderColor: Colors.transparent,
                    text: "Proceed",
                    onTapEvent: () {
                      var bodyMap = {
                        "stopId": widget.newStop?.id ?? reDeliverNotificationData!.stop.id,
                        "isAccepted": true
                      };

                      callBloc(BlocProvider.of<DispatcherBloc>(context)
                          .add(UpdateStopStatusEvent(body: bodyMap)));
                    },
                  ),
                ],
              ).paddingOnly(top: 8, left: 12, right: 12, bottom: 12),
            ],
          ),
        )
      ],
    ).paddingAll(16);
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
