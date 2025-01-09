import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_google_maps_webservices/places.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_api_headers/google_api_headers.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/core.errors.dart';
import 'package:here_sdk/consent.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/routing.dart';
import 'package:here_sdk/search.dart';
import 'package:nb_utils/nb_utils.dart' hide log;
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:techtruckers/config/theme/app_colors.dart';
import 'package:techtruckers/config/theme/app_text_styles.dart';
import 'package:techtruckers/features/common/widgets/loader_dialog.dart';
import 'package:techtruckers/features/dispatch/models/nearby_places_response_model.dart';
import 'package:techtruckers/features/dispatch/models/search_result_model.dart';
import 'package:techtruckers/features/navigation/navigation_screen.dart';
import 'package:techtruckers/main.dart';
import 'package:techtruckers/utils/constant.dart';
import 'package:techtruckers/utils/general_functions.dart';
import 'package:here_sdk/routing.dart' as here;
import 'package:uuid/uuid.dart'; // Alias for HERE SDK
import 'package:http/http.dart' as http;

class SearchNearbyScreen extends StatefulWidget {
  final String currentAddress;
  const SearchNearbyScreen({super.key, required this.currentAddress});

  @override
  State<SearchNearbyScreen> createState() => _SearchNearbyScreenState();
}

class _SearchNearbyScreenState extends State<SearchNearbyScreen> {

  Timer? _debounce;
  late SearchEngine _searchEngine;
  late RoutingEngine _routingEngine;
  SearchOptions searchOptions = SearchOptions();
  SearchResultModel? searchResultModel;
  final TextEditingController searchController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  HereMapController? mapController;
  WidgetPin? widgetPin;
  bool isLoading = false;
  ConsentEngine? _consentEngine;
  here.Route? route;
  var sessionToken = '';
  List<Prediction> placesList = [];

  @override
  void initState() {
    super.initState();

    try {
      addressController.text = widget.currentAddress;
      _searchEngine = SearchEngine();
      _routingEngine = RoutingEngine();
      _consentEngine = ConsentEngine();
      var uuid = const Uuid();
      sessionToken = uuid.v4();
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
                placesList.clear();
                setState(() {});
            }, backgroundColor: Colors.redAccent, child: Icon(Icons.replay),),
            12.height,
            FloatingActionButton(
              backgroundColor: Colors.white,
              heroTag: "navigate",
              onPressed: (){
                if(Platform.isIOS || _consentEngine!.userConsentState == ConsentUserReply.granted){
                  List<here.Waypoint> wayPoints =
                  [currentLocation.value, searchResultModel!.geoCoordinates].map((coord) {
                    return here.Waypoint.withDefaults(coord);
                  }).toList();
                  navigate(context, NavigationScreen(route: route!, wayPoints: wayPoints,), false);
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


  /*searchQuery(TextQuery query, VoidCallback onFinish) {
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
  }*/


  searchQuery(String query) async {
    placesList.clear();
    try{
      var response = await http.get(Uri.parse(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&sessiontoken=$sessionToken&key=${Constant.kGoogleApiKey}&location=${currentLocation.value.latitude}%2C${currentLocation.value.longitude}&radius=50'));
      var json = jsonDecode(response.body);
      if (response.statusCode == 200 && json["status"] == "OK") {
        var resultModel = nearbyPlacesResponseModelFromJson(response.body);
        if(resultModel.predictions.isNotEmpty) {
          for (var data in resultModel.predictions) {
            placesList.add(Prediction.fromJson(data.toJson()));
          }
        }
      }
      setState(() {});
    }catch(e, stack){
      debugPrint(e.toString());
      debugPrintStack(stackTrace: stack);
    }
  }

  buildSearchView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Search location here",
          style: AppTextStyles.textBodySemiBold,
          overflow: TextOverflow.ellipsis,
        ),
        8.height,
        Container(
          height: 42,
          decoration: BoxDecoration(
              color: AppColors.isDark(context)
                  ? AppColors.cardDarkColor
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.colorPrimary)),
          child: Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: TextFormField(
              controller: addressController,
              readOnly: true,
              onTap: () {},
              style: AppTextStyles.textBodyNormal,
              textAlignVertical: TextAlignVertical.center,
              onChanged: (val) {
                if (_debounce?.isActive ?? false) _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 500), () async {
                  searchQuery(searchController.text);
                });
              },
              decoration: InputDecoration(
                isCollapsed: true,
                suffixIcon: Icon(Icons.location_on_rounded),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        16.height,
        Container(
          height: 42,
          decoration: BoxDecoration(
              color: AppColors.isDark(context)
                  ? AppColors.cardDarkColor
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.colorPrimary)),
          child: Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: TextFormField(
              controller: searchController,
              style: AppTextStyles.textBodyNormal,
              textAlignVertical: TextAlignVertical.center,
              onChanged: (val) {
                if (_debounce?.isActive ?? false) _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 500), () async {
                  // var query = TextQuery.withArea(searchController.text, TextQueryArea.withCenter(currentLocation.value));

                  if(searchController.text.isEmpty) {
                    placesList.clear();
                    setState(() {});
                    return;
                  }

                  searchQuery(searchController.text);
                });
              },
              decoration: InputDecoration(
                isCollapsed: true,
                suffixIcon: Icon(Icons.search),
                hintText: "Enter destination",
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        16.height,
        Expanded(
          child: ListView.builder(
              shrinkWrap: true,
              itemCount: placesList.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.location_on_rounded),
                  title: Text(placesList[index].description ?? "-"),
                  onTap: () async {
                    LoaderDialog().show(context, "Fetching location details");
                    var result = await displayPrediction(placesList[index], sessionToken);

                    if(result?.result.geometry != null) {
                      searchResultModel = SearchResultModel(placesList[index].description ?? "-", GeoCoordinates(result!.result.geometry!.location.lat, result!.result.geometry!.location.lng));
                    }

                    LoaderDialog().hide();
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

  Future<Map<String, String>> getDistanceDuration(GeoCoordinates destination) async {
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
            route = routeList!.first;
            dataMap["distance"] =
                metersToMiles(route!.lengthInMeters).toStringAsFixed(2);
            dataMap["duration"] =
                formatDuration(route!.duration.inSeconds).toString();

            GeoPolyline routeGeoPoly = route!.geometry;
            double polywidth = 5.0;
            var mypolyline = MapPolyline.withRepresentation(
                routeGeoPoly,
                MapPolylineSolidRepresentation(
                    MapMeasureDependentRenderSize.withSingleSize(
                        RenderSizeUnit.pixels, polywidth),
                    AppColors.colorPrimaryNight,
                    LineCap.round));
            mapController!.mapScene.addMapPolyline(mypolyline);

            // Adjust camera to fit the route
            _zoomToRoute(route!);

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
      List<here.Waypoint> wayPoints =
      [currentLocation.value, searchResultModel!.geoCoordinates].map((coord) {
        return here.Waypoint.withDefaults(coord);
      }).toList();
      navigate(context, NavigationScreen(route: route!, wayPoints: wayPoints,), false);
    }
  }

  Future<PlacesDetailsResponse?> displayPrediction(Prediction? p, String sessionToken) async {
    if (p != null) {
      GoogleMapsPlaces? places = GoogleMapsPlaces(
        apiKey: Constant.kGoogleApiKey,
        apiHeaders: await const GoogleApiHeaders().getHeaders(),
      );
      PlacesDetailsResponse? detail = await places.getDetailsByPlaceId(p.placeId.toString(), sessionToken: sessionToken, fields: [
        "formatted_address", "geometry", "name", "place_id"
      ]);

      print("Selected data is ${detail.result.toJson()}");
      return detail;
    }
    return null;
  }

}
