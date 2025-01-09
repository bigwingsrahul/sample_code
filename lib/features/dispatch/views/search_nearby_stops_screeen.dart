import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/core.errors.dart';
import 'package:here_sdk/consent.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/routing.dart';
import 'package:here_sdk/search.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:techtruckers/config/theme/app_colors.dart';
import 'package:techtruckers/config/theme/app_text_styles.dart';
import 'package:techtruckers/features/common/widgets/loader_dialog.dart';
import 'package:techtruckers/features/dispatch/models/search_result_model.dart';
import 'package:techtruckers/features/navigation/navigation_screen.dart';
import 'package:techtruckers/main.dart';
import 'package:techtruckers/utils/general_functions.dart';
import 'package:here_sdk/routing.dart' as here; // Alias for HERE SDK

class SearchNearbyStopsScreen extends StatefulWidget {
  final String type;
  const SearchNearbyStopsScreen({super.key, required this.type});

  @override
  State<SearchNearbyStopsScreen> createState() => _SearchNearbyStopsScreenState();
}

class _SearchNearbyStopsScreenState extends State<SearchNearbyStopsScreen> {

  late SearchEngine _searchEngine;
  late RoutingEngine _routingEngine;
  SearchOptions searchOptions = SearchOptions();
  List<SearchResultModel> searchItems = [];
  SearchResultModel? searchResultModel;
  HereMapController? mapController;
  WidgetPin? widgetPin;
  bool isLoading = false;
  ConsentEngine? _consentEngine;

  @override
  void initState() {
    super.initState();

    try {
      _searchEngine = SearchEngine();
      _routingEngine = RoutingEngine();
      _consentEngine = ConsentEngine();

      var query = TextQuery.withArea("${widget.type} stops", TextQueryArea.withCenter(currentLocation.value));
      searchQuery(query, () {
        setState(() {});
      });
    } on InstantiationException {
      throw Exception("Initialization of SearchEngine failed.");
    }

  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.sizeOf(context);
    return Scaffold(
      appBar: getAppBar(false, context, titleText: "Search nearby"),
      floatingActionButton: Visibility(
        visible: searchResultModel != null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: "reset",
              onPressed: (){
                searchResultModel = null;
                searchItems.clear();
                setState(() {});
            }, backgroundColor: Colors.redAccent, child: Icon(Icons.replay),),
            12.height,
            FloatingActionButton(
              backgroundColor: Colors.white,
              heroTag: "navigate",
              onPressed: (){
                if(Platform.isIOS || _consentEngine!.userConsentState == ConsentUserReply.granted){
                  startNavigate(searchResultModel!.geoCoordinates);
                }else{
                  _requestConsent();
                }
              }, child: Image.asset(
              AppColors.isDark(
                  context)
                  ? "assets/images/ic_nav_dark.png"
                  : "assets/images/ic_nav_light.png",
            ),),
          ],
        ),
      ),
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
        child: searchResultModel == null ? buildSearchView() : buildMapView(),
      ),
    );
  }

  searchQuery(TextQuery query, VoidCallback onFinish) {
    searchItems.clear();
    _searchEngine.searchByText(query, searchOptions, (SearchError? searchError, List<Place>? list) async {

      if (searchError != null) {
        log(query.query);
        log(searchError.toString());
        return;
      }

      log((list?.length ?? 0).toString());

      // Add new marker for each search result on map.
      if(list == null){
        setState(() {});
        return;
      }

      for (Place searchResult in list) {
        searchItems.add(SearchResultModel(searchResult.address.addressText, searchResult.geoCoordinates!));
      }

      onFinish();
    });
  }

  buildSearchView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${widget.type.capitalizeFirstLetter()} stops nearby",
          style: AppTextStyles.textBodySemiBold,
          overflow: TextOverflow.ellipsis,
        ),
        16.height,
        Expanded(
          child: ListView.builder(
              shrinkWrap: true,
              itemCount: searchItems.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.location_on_rounded),
                  title: Text(searchItems[index].name),
                  onTap: () {
                    searchResultModel = searchItems[index];
                    // isLoading = true;
                    setState(() {});
                  },
                );
              }),
        )
      ],
    ).paddingAll(16);
  }

  buildMapView() {
    return isLoading ? Center(child: CircularProgressIndicator(),) : Column(
      children: [
        RichText(text: TextSpan(
          text: "Showing map view for ",
          style: AppTextStyles.textBodyNormal.copyWith(
            color: AppColors.blackWhiteText(context)
          ),
          children: [
            TextSpan(
              text: "'${searchResultModel?.name}'", style: AppTextStyles.textBodySemiBold
            )
          ]
        )),
        16.height,
        HereMap(
          onMapCreated: _onMapCreated,
        ).expand()
      ],
    ).paddingAll(16);
  }

  void _onMapCreated(HereMapController hereMapController) {
    mapController = hereMapController;
    hereMapController.mapScene.loadSceneForMapScheme(AppColors.isDark(context) ? MapScheme.normalNight : MapScheme.normalDay, (MapError? error) async {
      if (error != null) {
        debugPrint('Map scene not loaded. MapError: ${error.toString()}');
        return;
      }

      if(searchResultModel != null){
        // Add Current marker
        MapImage currentPinImage = await _createCurrentImage();
        MapMarker currentLocMarker = MapMarker(currentLocation.value, currentPinImage);
        mapController!.mapScene.addMapMarker(currentLocMarker);

        // Add location marker
        MapImage mapImage = await _createMapImage();
        addMapMarker(searchResultModel!.geoCoordinates, mapImage, mapController!);
        var res = await getDistanceDuration(searchResultModel!.geoCoordinates);

        widgetPin = mapController!
            .pinWidget(_createWidget(res), searchResultModel!.geoCoordinates);
        widgetPin?.anchor = Anchor2D.withHorizontalAndVertical(0.5, 1.5);
        // setState(() {
        //   isLoading = false;
        // });
      }
    });
  }


  Widget _createWidget(Map<String, String> data) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: MediaQuery.sizeOf(context).width * 0.65,
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.isDark(context) ? Colors.white : Color(0xffEAF9FF),
            border: Border.all(color: Color(0xff363640)),
          ),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    color: Colors.green),
                height: 48,
                width: 48,
                padding: EdgeInsets.all(8),
                child: SvgPicture.asset(
                  "assets/images/ic_vehicles.svg",
                  colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
              ),
              12.width,
              Column(
                  crossAxisAlignment: CrossAxisAlignment.end, children: [
                Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "${data["distance"]} miles, ${data["duration"]}",
                      style: AppTextStyles.textSmallNormal
                          .copyWith(color: AppColors.colorPrimary),
                    )),
                Text(
                  searchResultModel?.name ?? "-",
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.textSmallNormal.copyWith(
                      color: Colors.black
                  ),
                )
              ]).expand()
            ],
          ),
        ),
        RotatedBox(
            quarterTurns: 2,
            child: SvgPicture.asset("assets/images/ic_triangle.svg", color: AppColors.isDark(context) ? Colors.white : Color(0xff363641),))
      ],
    );
  }

  Future<MapImage> _createCurrentImage() async {
    ByteData fileData = await rootBundle.load("assets/images/pin.png");
    Uint8List pixelData = fileData.buffer.asUint8List();
    int width = 18.w.round(); // Set desired width
    int height = 18.w.round(); // Set desired height
    return MapImage.withImageDataImageFormatWidthAndHeight(
        pixelData, ImageFormat.png, width, height);
  }

  Future<MapImage> _createMapImage() async {
    ByteData fileData = await rootBundle.load('assets/images/map-pin.svg');
    Uint8List pixelData = fileData.buffer.asUint8List();
    int width = Device.screenType == ScreenType.tablet ? 7.5.w.round() : 11.w.round(); // Set desired width
    int height = 9.h.round(); // Set desired height
    return MapImage.withImageDataImageFormatWidthAndHeight(
        pixelData, ImageFormat.png, width, height);
  }


  void addMapMarker(GeoCoordinates coordinates, MapImage mapImage, HereMapController mapController) {
    Anchor2D anchor2D = Anchor2D.withHorizontalAndVertical(0.5, 1);

    MapMarker mapMarker = MapMarker.withAnchor(coordinates, mapImage, anchor2D);
    mapMarker.drawOrder = 0;

    mapController.mapScene.addMapMarker(mapMarker);
  }

  Future<Map<String, String>> getDistanceDuration(
      GeoCoordinates destination) async {
    Map<String, String> dataMap = {"distance": "0", "duration": "0"};

    var startWaypoint = Waypoint.withDefaults(currentLocation.value);
    var destinationWaypoint = Waypoint.withDefaults(destination);

    List<Waypoint> waypoints = [startWaypoint, destinationWaypoint];
    // Using Completer to wait for the asynchronous operation to complete
    Completer<void> completer = Completer<void>();

    _routingEngine.calculateTruckRoute(waypoints, TruckOptions(),
            (RoutingError? routingError, List<here.Route>? routeList) async {
          if (routingError == null) {
            // When error is null, it is guaranteed that the list is not empty.
            here.Route route = routeList!.first;
            dataMap["distance"] =
                metersToMiles(route.lengthInMeters).toStringAsFixed(2);
            dataMap["duration"] =
                formatDuration(route.duration.inSeconds).toString();

            GeoPolyline routeGeoPoly = route.geometry;
            double polywidth = 3.0;
            var mypolyline = MapPolyline.withRepresentation(
                routeGeoPoly,
                MapPolylineSolidRepresentation(
                    MapMeasureDependentRenderSize.withSingleSize(
                        RenderSizeUnit.pixels, polywidth),
                    AppColors.colorPrimaryNight,
                    LineCap.round));
            mapController!.mapScene.addMapPolyline(mypolyline);

            // Adjust camera to fit the route
            _zoomToRoute(route);

          } else {
            var error = routingError.toString();
            toast('Error while calculating a route: $error');
          }

          // Complete the Completer once the route calculation is done
          completer.complete();
        });

    // Wait for the Completer to complete before returning dataMap
    await completer.future;

    return dataMap;
  }

  void _zoomToRoute(here.Route route) {
    if (mapController == null) return;

    GeoBox routeBoundingBox = route.boundingBox;
    GeoCoordinates northEast = routeBoundingBox.northEastCorner;
    GeoCoordinates southWest = routeBoundingBox.southWestCorner;

    mapController!.camera.lookAtAreaWithGeoOrientation(
      GeoBox(southWest, northEast),
      GeoOrientationUpdate(0, 0),
    );
  }

  Future<void> _requestConsent() async {
    if (!Platform.isIOS) {
      // This shows a localized widget that asks the user if data can be collected or not.
      await _consentEngine?.requestUserConsent(context);
    }

    if(Platform.isIOS || _consentEngine!.userConsentState == ConsentUserReply.granted){
      startNavigate(searchResultModel!.geoCoordinates);
    }
  }

  startNavigate(GeoCoordinates destination){
    LoaderDialog().show(context, "Creating route");

    List<here.Waypoint> wayPoints =
    [currentLocation.value, destination].map((coord) {
      return here.Waypoint.withDefaults(coord);
    }).toList();

    var truckOptions = here.TruckOptions();
    var routeOptions = here.RouteOptions();
    routeOptions.enableRouteHandle = true;
    truckOptions.routeOptions = routeOptions;

    _routingEngine.calculateTruckRoute(
      wayPoints,
      truckOptions,
          (error, routing) {

        LoaderDialog().hide();

        if (error == null) {
          var route = routing!.first;
          navigate(context, NavigationScreen(route: route, wayPoints: wayPoints), false);
        } else {
          toast(error.name);
        }
      },
    );
  }
}
