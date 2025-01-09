import 'package:fbroadcast/fbroadcast.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:techtruckers/config/theme/app_colors.dart';
import 'package:techtruckers/features/common/widgets/custom_tab_item.dart';
import 'package:techtruckers/features/dispatch/views/upcoming_dispatch_tab.dart';
import 'package:techtruckers/utils/constant.dart';
import 'package:techtruckers/utils/general_functions.dart';


import 'active_dispatch_tab.dart';
import 'on_route_dispatch_screen.dart';

class DispatchListScreen extends StatefulWidget {
  final int? preselected;
  const DispatchListScreen({super.key, this.preselected});

  @override
  State<DispatchListScreen> createState() => _DispatchListScreenState();
}

class _DispatchListScreenState extends State<DispatchListScreen> {
  int _currentIndex = 0;
  bool fullScreen = false;

  @override
  void initState() {
    super.initState();

    _currentIndex = widget.preselected ?? 0;

    FBroadcast.instance().register(Constant.dispatchStatus, (value, callback) {

      if (value == Constant.tripStarted) {
        setState(() {
          _currentIndex = 2;
        });
      }

      if (value == Constant.loadDelivered) {
        setState(() {
          _currentIndex = 0;
        });
      }
    });

    FBroadcast.instance().register(Constant.dispatchMapScreenState,
        (value, callback) {
      setState(() {
        fullScreen = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.sizeOf(context).width;
    return Scaffold(
      appBar: fullScreen
          ? null
          : getAppBar(true, context,
              titleText: _currentIndex == 2
                  ? "On Route Load"
                  : "Load Planning Dashboard"),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: AppColors.isDark(context)
                  ? [
                      AppColors.scaffoldDarkBackground,
                      AppColors.scaffoldDarkBackground
                    ]
                  : [
                      Colors.white,
                      _currentIndex != 2
                          ? const Color(0XFFEAF9FF)
                          : Colors.white,
                    ],
            ),
          ),
          child: Column(
            children: [
              if (!fullScreen)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CustomTabItem(text: 'Active', onTapEvent: (){
                      setState(() {
                        _currentIndex = 0;
                      });
                    }, isActive: _currentIndex == 0).expand(),
                    12.width,
                    CustomTabItem(text: 'Upcoming', onTapEvent: (){
                      setState(() {
                        _currentIndex = 1;
                      });
                    }, isActive: _currentIndex == 1).expand(),
                    12.width,
                    CustomTabItem(text: 'On-Route', onTapEvent: (){
                      setState(() {
                        _currentIndex = 2;
                      });
                    }, isActive: _currentIndex == 2).expand(),
                  ],
                ).paddingAll(16),
              Expanded(
                  child: _currentIndex == 0
                      ? ActiveDispatchTab()
                      : _currentIndex == 1
                          ? UpcomingDispatchTab()
                          : OnRouteDispatchScreen())
            ],
          ),
        ),
      ),
    );
  }
}
