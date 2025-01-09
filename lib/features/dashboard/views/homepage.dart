// ignore_for_file: depend_on_referenced_packages
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/search.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:flutter/material.dart';

import 'package:here_sdk/mapview.dart';
import 'package:intl/intl.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:techtruckers/config/theme/app_text_styles.dart';
import 'package:techtruckers/config/helpers/preferences_helper.dart';
import 'package:techtruckers/features/dashboard/models/dashboard_model.dart';
import 'package:techtruckers/features/dispatch/bloc/dispatcher_bloc.dart';
import 'package:techtruckers/features/dispatch/views/dispatch_list_screen.dart';
import 'package:techtruckers/features/dispatch/views/search_nearby_screen.dart';
import 'package:techtruckers/main.dart';
import 'package:techtruckers/utils/constant.dart';
import 'package:techtruckers/utils/general_functions.dart';

import '../../../config/theme/app_colors.dart';
import '../../../widget/blocwidget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  HereMapController? mapController;
  String currentAddress = "";
  late SearchEngine _searchEngine;
  final ValueNotifier<String> expiryMessage = ValueNotifier("");
  final searchController = TextEditingController();

  bool callingLoad =false;


  final listItems = [
    DashboardModel("ic_dispatch", "Dispatch", DispatchListScreen()),
    DashboardModel("ic_dispatch", "Dispatch", DispatchListScreen()),
    DashboardModel("ic_dispatch", "Dispatch", DispatchListScreen()),
    DashboardModel("ic_dispatch", "Dispatch", DispatchListScreen()),
  ];

  String formattedDate() {
    var now = DateTime.now();
    var formatter = DateFormat('MMM-dd-yyyy');
    String formattedDate = formatter.format(now);
    return formattedDate;
  }

  @override
  void initState() {
    super.initState();

    _searchEngine = SearchEngine();
    checkNotificationTap();

    getCurrentAddress();

    callRequiredApis();

    newDispatchCount.addListener(() {
      callingLoad = false;
      checkLoadingStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              height: 100.h,
              width: 100.w,
              decoration: BoxDecoration(
                gradient: AppColors.homeBackgroundGradient(context),
              ),
            ),
            Device.screenType == ScreenType.tablet ? buildTabUI() : buildMobileUI(),
          ],
        ),
      ),
    );
  }

  void _onMapCreated(HereMapController hereMapController) {
    hereMapController.mapScene.loadSceneForMapScheme(AppColors.isDark(context) ? MapScheme.normalNight : MapScheme.normalDay, (MapError? error) {
      if (error != null) {
        return;
      }

      mapController = hereMapController;
      setState(() {});

      hereMapController.camera.lookAtPoint(currentLocation.value);
    });
  }

  buildMobileUI() {
    double height = MediaQuery.sizeOf(context).height;
    double width = MediaQuery.sizeOf(context).width;

    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Hello ${PreferencesHelper.instance.getString(Constant.name, defaultValue: "")}!",
                style: AppTextStyles.textSmallTitleBold.copyWith(color: Colors.white),
              ),
              Icon(Icons.power_settings_new, color: Colors.white,).onTap(() {

              }),
            ],
          ).paddingSymmetric(horizontal: 25).paddingTop(16),
          _buildSearchField(),
          GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16),
              padding: EdgeInsets.all(16),
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: 4,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () async {
                    if(listItems[index].destination != null) {
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => listItems[index].destination!));
                      callRequiredApis();
                    }
                  },
                  child: BlockWidget(
                    width: width,
                    icon: "assets/images/${listItems[index].icon}.svg",
                    text: listItems[index].name,
                    count: 0,
                  ),
                );
              }),
          16.height,
          Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
                color: AppColors.isDark(context) ? Colors.black : Colors.white),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(height / 60),
                  child: Center(
                    child: RichText(
                      text: TextSpan(children: [
                        TextSpan(text: "Current Location: ", style: AppTextStyles.textSmallNormal.copyWith(color: AppColors.blackWhiteText(context))),
                        TextSpan(
                            text: currentAddress,
                            style: AppTextStyles.textSmallNormal
                                .copyWith(color: AppColors.colorPrimary, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic))
                      ]),
                    ),
                  ),
                ),
                SizedBox(
                  height: height / 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Center(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
                        child: HereMap(onMapCreated: _onMapCreated),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ).paddingBottom(64),
    );
  }

  buildTabUI() {
    double height = MediaQuery.sizeOf(context).height;
    double width = MediaQuery.sizeOf(context).width;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Hello ${PreferencesHelper.instance.getString(Constant.name, defaultValue: "")}!",
              style: AppTextStyles.textSmallTitleBold.copyWith(color: Colors.white),
            ),
            Text(
              formattedDate(),
              style: AppTextStyles.textSmallSemiBold.copyWith(color: Colors.white),
            ),
          ],
        ).paddingSymmetric(horizontal: 25).paddingTop(16),
        _buildSearchField(),
        ValueListenableBuilder(
            valueListenable: expiryMessage,
            builder: (context, value, child) {
              return value.isNotEmpty
                  ? Container(
                      width: width,
                      decoration: boxDecorationRoundedWithShadow(12, backgroundColor: AppColors.appRedColor),
                      margin: EdgeInsets.fromLTRB(16, 16, 16, 0),
                      padding: EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error,
                            color: Colors.white,
                          ),
                          16.width,
                          Text(
                            value,
                            style: AppTextStyles.buttonTextStyle.copyWith(fontSize: 15.sp),
                          ).expand()
                        ],
                      ),
                    )
                  : SizedBox();
            }),
        ValueListenableBuilder(
          builder: (context, value, child) {
            return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 16, mainAxisSpacing: 16),
                padding: EdgeInsets.all(16),
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: 4,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () async {
                      print("Tapped");
                      if (index == 0 && value > 0) {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DispatchListScreen(
                              preselected: 1,
                            ),
                          ),
                        );
                        print("Called");
                        callRequiredApis();
                      } else {

                        if(listItems[index].destination != null) {
                          await Navigator.push(context, MaterialPageRoute(builder: (context) => listItems[index].destination!));
                          callRequiredApis();
                        }
                      }
                    },
                    child: BlockWidget(
                      width: width,
                      icon: "assets/images/${listItems[index].icon}.svg",
                      text: listItems[index].name,
                      count: index == 0 ? value : 0,
                    ),
                  );
                });
          },
          valueListenable: newDispatchCount,
        ),
        Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
              color: AppColors.isDark(context) ? Colors.black : Colors.white),
          padding: EdgeInsets.only(top: 20),
          child: Column(
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: HereMap(onMapCreated: _onMapCreated),
                ).paddingSymmetric(horizontal: 16),
              ).expand(),
              Padding(
                padding: EdgeInsets.all(height / 60),
                child: Center(
                  child: RichText(
                    text: TextSpan(children: [
                      TextSpan(
                        text: "Current Location: ",
                        style: AppTextStyles.textBodyNormal,
                      ),
                      TextSpan(
                        text: currentAddress,
                        style: AppTextStyles.textBodyNormal,
                      )
                    ]),
                  ),
                ),
              ),
            ],
          ),
        ).expand()
      ],
    ).paddingBottom(64);
  }

  // Widget for search field
  Widget _buildSearchField() {
    return Container(
      height: 5.h,
      margin: EdgeInsets.fromLTRB(16, 16, 16, 0),
      width: MediaQuery.sizeOf(context).width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          width: 2,
          color: Colors.white,
        ),
      ),
      child: TextFormField(
        controller: searchController,
        textAlignVertical: TextAlignVertical.center,
        keyboardType: TextInputType.number,
        readOnly: true,
        onTap: () => navigate(
            context,
            SearchNearbyScreen(
              currentAddress: currentAddress,
            ),
            false),
        onChanged: (val) {},
        decoration: InputDecoration(
          isCollapsed: true,
          hintText: "Search Nearby Location",
          hintStyle: AppTextStyles.textBodySemiBold.copyWith(color: Color(0xffFAFEFF)),
          contentPadding: EdgeInsets.only(left: 15),
          suffixIcon: Icon(
            Icons.arrow_forward_ios,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Future<void> checkNotificationTap() async {
    // RemoteMessage? terminatedMessage =
    //     await FirebaseMessaging.instance.getInitialMessage();

    // if (terminatedMessage != null) {
    //   if (terminatedMessage.data.containsKey("navigate")) {
    //     // todo navigate here
    //   }
    // }
  }

  void getCurrentAddress() {
    SearchOptions reverseGeocodingOptions = SearchOptions();
    reverseGeocodingOptions.languageCode = LanguageCode.enGb;
    reverseGeocodingOptions.maxItems = 1;

    print("Fetching location for ${currentLocation.value.latitude}, ${currentLocation.value.longitude} latLng");

    _searchEngine.searchByCoordinates(currentLocation.value, reverseGeocodingOptions, (SearchError? searchError, List<Place>? list) async {
      if (searchError != null) {
        toast("Error: $searchError");
        print("Error: ${searchError.name}");
        return;
      }

      // If error is null, list is guaranteed to be not empty.
      currentAddress = list!.first.address.addressText;
      if (mounted) {
        setState(() {});
      }
    });
  }

  void callRequiredApis() {
    callingLoad = true;
    callBloc(BlocProvider.of<DispatcherBloc>(context).add(UpcomingDispatcherLoadEvent(false)));
    checkLoadingStatus();
  }

  checkLoadingStatus(){
    if(!callingLoad) {
      showLoader.value = false;
    } else {
      showLoader.value = true;
    }
  }
}
