import 'dart:async';
import 'dart:io';

import 'package:fbroadcast/fbroadcast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';

import 'package:here_sdk/core.dart';
import 'package:here_sdk/consent.dart';
import 'package:here_sdk/gestures.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/routing.dart' as here; // Alias for HERE SDK
import 'package:here_sdk/routing.dart';
import 'package:here_sdk/search.dart';
import 'package:lottie/lottie.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:techtruckers/config/helpers/tts_helper.dart';
import 'package:techtruckers/config/theme/app_colors.dart';
import 'package:techtruckers/config/theme/app_text_styles.dart';
import 'package:techtruckers/features/common/widgets/loader_dialog.dart';
import 'package:techtruckers/features/common/widgets/no_record_widget.dart';
import 'package:techtruckers/features/dispatch/bloc/dispatcher_bloc.dart';
import 'package:techtruckers/features/dispatch/helpers/dispatch_stage.dart';
import 'package:techtruckers/features/dispatch/models/dispatch_load_data_model.dart';
import 'package:techtruckers/features/dispatch/views/dispatch_rejection_approval_screen.dart';
import 'package:techtruckers/features/dispatch/views/search_nearby_screen.dart';
import 'package:techtruckers/features/navigation/navigation_screen.dart';
import 'package:techtruckers/main.dart';
import 'package:techtruckers/utils/constant.dart';
import 'package:techtruckers/utils/general_functions.dart';
import 'package:collection/collection.dart';
import 'package:here_sdk/mapview.datasource.dart';

class OnRouteDispatchScreen extends StatefulWidget {
  const OnRouteDispatchScreen({super.key});

  @override
  State<OnRouteDispatchScreen> createState() => _OnRouteDispatchScreenState();
}

class _OnRouteDispatchScreenState extends State<OnRouteDispatchScreen> {
  TextEditingController controller = TextEditingController();
  HereMapController? mapController;
  final _sheet = GlobalKey();
  final _controller = DraggableScrollableController();
  DispatchStage nextStage = DispatchStage.headedToPickup;
  List<GeoCoordinates> coordinateData = [];
  WidgetPin? widgetPin;
  DispatchLoadData? loadData;
  bool _isLoading = false;
  bool fullScreen = false;
  String currentAddress = "";
  late SearchEngine _searchEngine;
  late RoutingEngine routingEngine;
  int currentStopIndex = -1;
  ConsentEngine? _consentEngine;
  bool openNav = false;
  bool showWeather = false;
  bool mapLoadingError = false;
  String loadStatus = "";

  MapLayer? _rasterMapLayerStyle;
  RasterDataSource? _rasterDataSourceStyle;
  late StreamSubscription<Position> positionStream;
  bool isInsideRadius = false;
  MapMarker? currentLocMarker;
  int seq = 0;

  @override
  void initState() {
    super.initState();
    _searchEngine = SearchEngine();
    routingEngine = RoutingEngine();
    _consentEngine = ConsentEngine();
    getCurrentAddress();
    currentLocation.addListener(() async {
      getCurrentAddress();
      MapImage currentPinImage = await _createCurrentImage();
      if (mapController != null) {
        if (currentLocMarker != null) {
          mapController!.mapScene.removeMapMarker(currentLocMarker!);
        } else {
          debugPrint("Current marker is null");
        }
        currentLocMarker = MapMarker(currentLocation.value, currentPinImage);
        mapController!.mapScene.addMapMarker(currentLocMarker!);
      } else {
        debugPrint("Map Controller is null");
      }

      var distanceToStartPoint = loadData!.status == "Redeliver"
          ? calculateDistance(
              originLat: currentLocation.value.latitude,
              originLng: currentLocation.value.longitude,
              destLat: loadData!.newStop!.coordinates.coordinates.last,
              destLng: loadData!.newStop!.coordinates.coordinates.first)
          : calculateDistance(
              originLat: currentLocation.value.latitude,
              originLng: currentLocation.value.longitude,
              destLat: loadData!.stops[currentStopIndex].coordinates.coordinates.last,
              destLng: loadData!.stops[currentStopIndex].coordinates.coordinates.first);

      bool isCurrentlyInsideRadius = distanceToStartPoint <= geoFenceDistance / 1000;

      // Trigger action only if there is a state change (from inside to outside or vice versa)
      if (isCurrentlyInsideRadius != isInsideRadius) {
        isInsideRadius = isCurrentlyInsideRadius;

        if (seq > 0) {
          // Call the API or trigger the action here
          seq++;
          callBloc(BlocProvider.of<DispatcherBloc>(context).add(NewDispatcherLoadEvent(true)));
        }
      } else {
        seq++;
      }
    });

    callBloc(BlocProvider.of<DispatcherBloc>(context).add(NewDispatcherLoadEvent(true)));
  }

  @override
  void dispose() {
    _rasterMapLayerStyle?.destroy();
    _rasterDataSourceStyle?.destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DispatcherBloc, DispatcherState>(
      listener: (context, state) {
        if (state is DispatcherLoading) {
          setState(() {
            _isLoading = true;
          });
        }

        if (state is ChangeStatusLoading) {
          LoaderDialog().show(context, state.message ?? "Submitting");
        }

        if (state is DispatcherFailure) {
          setState(() {
            _isLoading = false;
          });
          LoaderDialog().hide();

          showToast(context, state.mError, true);
        }

        if (state is DispatcherResponseState) {
          _isLoading = false;
          loadData = state.data.data.firstWhereOrNull((data) => data.status.toLowerCase() != "assigned");

          if (loadData != null) {
            if (loadData!.status.toLowerCase() == "rejected" || (loadData!.status.toLowerCase() == "redeliver" && loadData?.newStop?.isAccepted == false)) {
              navigate(context, DispatchRejectionApprovalScreen(newStop: loadData!.newStop,), true);
            } else if (loadData!.status.toLowerCase() == "redeliver" && loadData?.newStop?.isAccepted == true) {
              if (loadData!.newStop!.latestStatus != "3") {
                currentStopIndex = 0;
              }

              var distanceToStartPoint = calculateDistance(
                  originLat: currentLocation.value.latitude,
                  originLng: currentLocation.value.longitude,
                  destLat: loadData!.newStop!.coordinates.coordinates.last,
                  destLng: loadData!.newStop!.coordinates.coordinates.first);

              var isAtLocation = distanceToStartPoint <= (geoFenceDistance / 1000);

              if (loadData!.newStop!.stopStatus.isEmpty) {
                nextStage = loadData!.newStop!.poNumber == "Redeliver"
                    ? isAtLocation
                        ? DispatchStage.checkedInReDeliver
                        : DispatchStage.headedToReDeliver
                    : isAtLocation
                        ? DispatchStage.checkedInDumpAndDonate
                        : DispatchStage.headedToDumpAndDonate;
              } else if (loadData!.newStop!.stopStatus.last.status == "1") {
                nextStage = loadData!.newStop!.poNumber == "Redeliver" ? DispatchStage.checkedInReDeliver : DispatchStage.checkedInDumpAndDonate;
              } else {
                nextStage = loadData!.newStop!.poNumber == "Redeliver" ? DispatchStage.redelivered : DispatchStage.dumpAndDonated;
              }

              setState(() {});
            } else {
              for (int index = 0; index < loadData!.stops.length; index++) {
                if (loadData!.stops[index].latestStatus != "3") {
                  debugPrint("Current index $index");

                  // keep track of current stop index
                  currentStopIndex = index;

                  var distanceToStartPoint = calculateDistance(
                      originLat: currentLocation.value.latitude,
                      originLng: currentLocation.value.longitude,
                      destLat: loadData!.stops[currentStopIndex].coordinates.coordinates.last,
                      destLng: loadData!.stops[currentStopIndex].coordinates.coordinates.first);

                  var isAtLocation = distanceToStartPoint <= (geoFenceDistance / 1000);

                  // keep track of current stage
                  if (loadData!.stops[index].stopStatus.isEmpty) {
                    nextStage = loadData!.stops[index].stopType == "Pickup"
                        ? isAtLocation
                            ? DispatchStage.checkedInPickup
                            : DispatchStage.headedToPickup
                        : isAtLocation
                            ? DispatchStage.checkedInDropOff
                            : DispatchStage.headedToDropOff;
                  } else if (loadData!.stops[index].stopStatus.last.status == "1") {
                    nextStage = loadData!.stops[index].stopType == "Pickup" ? DispatchStage.checkedInPickup : DispatchStage.checkedInDropOff;
                  } else {
                    nextStage = loadData!.stops[index].stopType == "Pickup" ? DispatchStage.pickedUpLoad : DispatchStage.deliveredLoad;
                  }
                  break;
                }
              }
            }
          }

          setState(() {});

          if (openNav) {
            if (Platform.isIOS || _consentEngine!.userConsentState == ConsentUserReply.granted) {
              startNavigate(
                  GeoCoordinates(loadData!.stops[currentStopIndex].coordinates.coordinates.last,
                      loadData!.stops[currentStopIndex].coordinates.coordinates.first),
                  loadData!.stops[currentStopIndex]);

              openNav = false;
            } else {
              _requestConsent();
            }
          }

          /* if (currentStopIndex == -1) {
            // todo handle the case where the load is delivered
            currentStopIndex = loadData!.stops.length - 1;
            nextStage = loadData!.stops[currentStopIndex].stopType == "Pickup"
                ? DispatchStage.pickedUpLoad
                : DispatchStage.deliveredLoad;
          }*/

          // showUploadBOLDialog();
        }

        if (state is UpdateStopState) {
          showToast(context, "Success", false);
          LoaderDialog().hide();
          callBloc(BlocProvider.of<DispatcherBloc>(context).add(NewDispatcherLoadEvent(true)));
        }

        if (state is StopRejectionState) {
          LoaderDialog().hide();
          if (state.type == 0) {
            showLoadDeliveredDialog();
          } else {
            navigate(context, DispatchRejectionApprovalScreen(), true);
          }
        }

        if (state is UploadBOLState) {
          LoaderDialog().hide();

          if (loadData!.stops[currentStopIndex].latestStatus == "2" && loadData!.stops[currentStopIndex].stopType == "Pickup") {
            var bodyMap = {"stopId": loadData!.stops[currentStopIndex].id, "status": getNextStatus()};

            callBloc(BlocProvider.of<DispatcherBloc>(context).add(UpdateStopStatusEvent(body: bodyMap)));
          } else {
            loadData!.stops[currentStopIndex].bolDoc = "-";
            showLoadStatusDialog();
          }
        }

        if (state is UploadReceiptState) {
          LoaderDialog().hide();
          showLoadDeliveredDialog();
        }

        if (state is AutoLogoutFailure) {
          logoutUser(context);
        }
      },
      child: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : loadData == null
              ? NoRecordWidget()
              : Stack(
                  children: [
                    Column(
                      children: [
                        if (!fullScreen)
                          Container(
                            height: 40,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: AppColors.isDark(context) ? Colors.white : Colors.black)),
                            child: Center(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                      child: TextFormField(
                                        readOnly: true,
                                        onTap: () {
                                          navigate(
                                              context,
                                              SearchNearbyScreen(
                                                currentAddress: '',
                                              ),
                                              false);
                                        },
                                        decoration: const InputDecoration(hintText: "Search", isCollapsed: true, border: InputBorder.none),
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.search,
                                    color: AppColors.isDark(context) ? Colors.white : Colors.black,
                                  ),
                                  const SizedBox(
                                    width: 8,
                                  )
                                ],
                              ),
                            ),
                          ).paddingBottom(16),
                        mapLoadingError
                            ? buildMapErrorView().expand()
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Stack(
                                  children: [
                                    HereMap(onMapCreated: _onMapCreated),
                                    Positioned(
                                      bottom: fullScreen ? 5.h : 3.h,
                                      right: 8,
                                      left: 8,
                                      child: Column(
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                children: [
                                                  currentStopIndex == -1
                                                      ? SizedBox.shrink()
                                                      : GestureDetector(
                                                          onTap: () {
                                                            if (Platform.isIOS || _consentEngine!.userConsentState == ConsentUserReply.granted) {
                                                              if (loadData!.status.toLowerCase() == "redeliver") {
                                                                startNavigate(
                                                                    GeoCoordinates(loadData!.newStop!.coordinates.coordinates.last,
                                                                        loadData!.newStop!.coordinates.coordinates.first),
                                                                    loadData!.newStop!);

                                                                // navigate(
                                                                //     context,
                                                                //     NavigateToPlace(
                                                                //       destination: GeoCoordinates(
                                                                //           loadData!
                                                                //               .newStop!
                                                                //               .coordinates
                                                                //               .coordinates
                                                                //               .last,
                                                                //           loadData!
                                                                //               .newStop!
                                                                //               .coordinates
                                                                //               .coordinates
                                                                //               .first),
                                                                //       message:
                                                                //           'Calculating route',
                                                                //       stopId: loadData!
                                                                //           .newStop!
                                                                //           .id
                                                                //           .toString(),
                                                                //     ),
                                                                //     false);
                                                              } else {
                                                                startNavigate(
                                                                    GeoCoordinates(loadData!.stops[currentStopIndex].coordinates.coordinates.last,
                                                                        loadData!.stops[currentStopIndex].coordinates.coordinates.first),
                                                                    loadData!.stops[currentStopIndex]);

                                                                /* navigate(
                                                                    context,
                                                                    NavigateToPlace(
                                                                      destination: GeoCoordinates(
                                                                          loadData!
                                                                              .stops[
                                                                                  currentStopIndex]
                                                                              .coordinates
                                                                              .coordinates
                                                                              .last,
                                                                          loadData!
                                                                              .stops[currentStopIndex]
                                                                              .coordinates
                                                                              .coordinates
                                                                              .first),
                                                                      message:
                                                                          'Calculating route',
                                                                      stopId: loadData!
                                                                          .stops[
                                                                              currentStopIndex]
                                                                          .id
                                                                          .toString(),
                                                                    ),
                                                                    false);*/
                                                              }
                                                            } else {
                                                              _requestConsent();
                                                            }
                                                          },
                                                          child: Image.asset(
                                                            height: 42,
                                                            width: 42,
                                                            AppColors.isDark(context)
                                                                ? "assets/images/ic_nav_dark.png"
                                                                : "assets/images/ic_nav_light.png",
                                                          )),
                                                  12.height,
                                                  GestureDetector(
                                                      onTap: () {
                                                        mapController!.camera.lookAtPoint(currentLocation.value);
                                                      },
                                                      child: Image.asset(
                                                          height: 42,
                                                          width: 42,
                                                          AppColors.isDark(context)
                                                              ? "assets/images/ic_current_loc_dark.png"
                                                              : "assets/images/ic_current_loc.png")),
                                                ],
                                              ),
                                              Column(
                                                children: [
                                                  GestureDetector(
                                                    onTap: () {
                                                      if (showWeather) {
                                                        showWeather = false;
                                                        _rasterMapLayerStyle?.setEnabled(false);
                                                      } else {
                                                        showWeather = true;
                                                        _rasterMapLayerStyle?.setEnabled(true);
                                                      }

                                                      setState(() {});
                                                      mapController!.mapScene.reloadScene();
                                                    },
                                                    child: Container(
                                                        height: 42,
                                                        width: 42,
                                                        decoration: boxDecorationRoundedWithShadow(1000,
                                                            backgroundColor:
                                                                showWeather ? AppColors.getPrimaryColor(context) : AppColors.blackWhiteText(context)),
                                                        child: Icon(
                                                          Icons.cloud,
                                                          color: showWeather ? Colors.white : AppColors.whiteBlacktext(context),
                                                        )),
                                                  ),
                                                  12.height,
                                                  GestureDetector(
                                                      onTap: () {

                                                      },
                                                      child: SizedBox(
                                                        height: 42,
                                                        width: 42,
                                                        child: Image.asset("assets/iballbtn.png"),
                                                      )),
                                                ],
                                              ),
                                            ],
                                          ),
                                          16.height,
                                        ],
                                      ),
                                    ),
                                    Align(
                                        alignment: Alignment.topRight,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              fullScreen = !fullScreen;
                                            });

                                            FBroadcast.instance().broadcast(Constant.dispatchMapScreenState, value: fullScreen);
                                          },
                                          child: Container(
                                            width: 42,
                                            height: 42,
                                            decoration: boxDecorationWithRoundedCorners(backgroundColor: AppColors.getPrimaryColor(context)),
                                            padding: EdgeInsets.all(12),
                                            margin: EdgeInsets.all(12),
                                            child: SvgPicture.asset(fullScreen ? "assets/images/ic_minimize.svg" : "assets/images/ic_maximize.svg"),
                                          ),
                                        )),
                                  ],
                                )).paddingBottom(Device.screenType == ScreenType.mobile ? 10.h : 11.h).expand(),
                      ],
                    ).paddingSymmetric(horizontal: fullScreen ? 0 : 16),
                    loadData!.status.toLowerCase() == "redeliver" ? buildReDeliverBottomSheet() : buildOnRouteBottomSheet(),
                  ],
                ),
    );
  }

  void _onMapCreated(HereMapController hereMapController) async {
    try {
      hereMapController.mapScene.loadSceneForMapScheme(AppColors.isDark(context) ? MapScheme.liteNight : MapScheme.liteDay, (MapError? error) async {
        if (error != null) {
          toast(error.toString());
          return;
        }

        /* var res = await ApiService.instance.customGet(
          "https://tile.openweathermap.org/map/wind_new/0/0/0.png?appid=3dc19ed353bbd4bdf0c0cd8e13545cde",
          false);
      // Define a MapTileLayer instance for weather tiles
      MapImageOverlay tileLayer = MapImageOverlay(Point2D(0, 0),
          MapImage.withPixelDataAndImageFormat(res.bodyBytes, ImageFormat.png));

      // Add tile layer on top of the base map
      hereMapController.mapScene.addMapImageOverlay(tileLayer);*/
      });

      mapController = hereMapController;

      hereMapController.mapScene.enableFeatures({
        MapFeatures.trafficFlow: MapFeatureModes.trafficFlowWithFreeFlow,
        MapFeatures.lowSpeedZones: MapFeatureModes.lowSpeedZonesAll,
        MapFeatures.landmarks: MapFeatureModes.landmarksTextured,
        MapFeatures.vehicleRestrictions: MapFeatureModes.vehicleRestrictionsActive,
        MapFeatures.landmarks: MapFeatureModes.landmarksTextured,
        MapFeatures.roadExitLabels: MapFeatureModes.roadExitLabelsAll,
        MapFeatures.terrain: MapFeatureModes.terrain3d
      });

      try {
        String dataSourceName = "myRasterDataSourceTonerStyle";
        _rasterDataSourceStyle = _createRasterDataSource(dataSourceName);
        _rasterMapLayerStyle = _createMapLayer(dataSourceName);
        _rasterMapLayerStyle?.setEnabled(false);
      } catch (e) {
        debugPrint(e.toString());
      }

      _addMarkers();

      Future.delayed(Duration(seconds: 5), () {
        if (mounted) {
          mapLoadingError = mapController == null;
          setState(() {});
        }
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  RasterDataSource _createRasterDataSource(String dataSourceName) {
    String templateUrl = "https://tile.openweathermap.org/map/temp_new/{z}/{x}/{y}.png?appid=3dc19ed353bbd4bdf0c0cd8e13545cde";

    // The storage levels available for this data source. Supported range [0, 31].
    List<int> storageLevels = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16];
    RasterDataSourceProviderConfiguration rasterProviderConfig = RasterDataSourceProviderConfiguration.withDefaults(
        TileUrlProviderFactory.fromXyzUrlTemplate(templateUrl)!, TilingScheme.quadTreeMercator, storageLevels);

    // If you want to add transparent layers then set this to true.
    rasterProviderConfig.hasAlphaChannel = false;

    // Raster tiles are stored in a separate cache on the device.
    String path = "cache/raster/mycustomlayer";
    int maxDiskSizeInBytes = 1024 * 1024 * 128; // 128 MB
    RasterDataSourceCacheConfiguration cacheConfig = RasterDataSourceCacheConfiguration(path, maxDiskSizeInBytes);

    // Note that this will make the raster source already known to the passed map view.
    return RasterDataSource(mapController!.mapContext, RasterDataSourceConfiguration.withDefaults(dataSourceName, rasterProviderConfig, cacheConfig));
  }

  MapLayer _createMapLayer(String dataSourceName) {
    // The layer should be rendered on top of other layers except for the "labels" layer
    // so that we don't overlap the raster layer over POI markers.
    MapLayerPriority priority = MapLayerPriorityBuilder().renderedBeforeLayer("labels").build();

    // And it should be visible for all zoom levels.
    MapLayerVisibilityRange range = MapLayerVisibilityRange(0, 22 + 1);

    try {
      // Build and add the layer to the map.
      MapLayer mapLayer = MapLayerBuilder()
          .forMap(mapController!.hereMapControllerCore) // mandatory parameter
          .withName("${dataSourceName}Layer") // mandatory parameter
          .withDataSource(dataSourceName, MapContentType.rasterImage)
          .withPriority(priority)
          .withVisibilityRange(range)
          .build();
      return mapLayer;
    } on MapLayerBuilderInstantiationException {
      throw Exception("MapLayer creation failed.");
    }
  }

  void _addMarkers() async {
    if (mapController == null) {
      return;
    }

    MapImage mapImage = await _createMapImage();

    // Add route through all points
    if (loadData!.status.toLowerCase() == "redeliver") {
      coordinateData.add(currentLocation.value);
      coordinateData.add(GeoCoordinates(loadData!.newStop!.coordinates.coordinates.last, loadData!.newStop!.coordinates.coordinates.first));

      addMapMarker(GeoCoordinates(loadData!.newStop!.coordinates.coordinates.last, loadData!.newStop!.coordinates.coordinates.first), mapImage,
          mapController!, 1, 1, loadData!.newStop!.id.toString());
    } else {
      for (var element in loadData!.stops) {
        coordinateData.add(GeoCoordinates(element.coordinates.coordinates.last, element.coordinates.coordinates.first));
      }

      var pickUps = loadData!.stops.where((data) => data.stopType == "Pickup");
      var drops = loadData!.stops.where((data) => data.stopType != "Pickup");

      pickUps.forEachIndexed((index, element) {
        addMapMarker(GeoCoordinates(element.coordinates.coordinates.last, element.coordinates.coordinates.first), mapImage, mapController!, index + 1,
            0, element.id.toString());
      });

      drops.forEachIndexed((index, element) {
        addMapMarker(GeoCoordinates(element.coordinates.coordinates.last, element.coordinates.coordinates.first), mapImage, mapController!, index + 1,
            1, element.id.toString());
      });

      // Add pickup dot
      MapImage pickupImage = await _createPickupDotImage();
      MapMarker pickupDotMarker =
          MapMarker(GeoCoordinates(pickUps.first.coordinates.coordinates.last, pickUps.first.coordinates.coordinates.first), pickupImage);
      mapController!.mapScene.addMapMarker(pickupDotMarker);

      // Add drop dot
      MapImage dropImage = await _createDropOffDotImage();
      MapMarker dropDotMarker =
          MapMarker(GeoCoordinates(drops.first.coordinates.coordinates.last, drops.last.coordinates.coordinates.first), dropImage);
      mapController!.mapScene.addMapMarker(dropDotMarker);
    }

    // Add Current marker
    MapImage currentPinImage = await _createCurrentImage();
    MapMarker currentLocMarker = MapMarker(currentLocation.value, currentPinImage);
    mapController!.mapScene.addMapMarker(currentLocMarker);

    addRoute(coordinateData, mapController!);

    _setTapGestureHandler();

    getRemainingTime();
  }

  void _setTapGestureHandler() {
    mapController!.gestures.tapListener = TapListener((Point2D touchPoint) {
      _pickMapMarker(touchPoint);
    });
  }

  void _pickMapMarker(Point2D touchPoint) {
    double radiusInPixel = 2;
    mapController!.pickMapItems(touchPoint, radiusInPixel, (pickMapItemsResult) async {
      if (widgetPin != null) {
        widgetPin!.unpin();
        widgetPin = null;
      }

      if (pickMapItemsResult == null) {
        return;
      }

      // Note that 3D map markers can't be picked yet. Only marker, polygon and polyline map items are pick able.
      List<MapMarker> mapMarkerList = pickMapItemsResult.markers;
      int listLength = mapMarkerList.length;
      if (listLength == 0) {
        debugPrint("No map markers found.");
        return;
      }

      MapMarker topmostMapMarker = mapMarkerList.first;
      Metadata? metadata = topmostMapMarker.metadata;
      if (metadata != null) {
        String message = metadata.getString("key_poi") ?? "-1";

        if (message == "-1") {
          toast("No location info found");
          return;
        }

        var stop = loadData!.stops.firstWhereOrNull((element) => element.id.toString() == message);

        var res = await getDistanceDuration(topmostMapMarker.coordinates);

        widgetPin = mapController!.pinWidget(_createWidget(stop!, res), topmostMapMarker.coordinates);
        widgetPin?.anchor = Anchor2D.withHorizontalAndVertical(0.5, 1.5);
        return;
      }

      toast("No metadata attached.");
    });
  }

  Widget _createWidget(Stop stop, Map<String, String> data) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.isDark(context) ? Colors.white : Color(0xffEAF9FF),
            border: Border.all(color: Color(0xff363640)),
          ),
          child: Row(
            children: [
              Container(
                decoration:
                    BoxDecoration(borderRadius: BorderRadius.circular(100), color: stop.stopType == "Pickup" ? Colors.green : Colors.redAccent),
                height: 48,
                width: 48,
                padding: EdgeInsets.all(8),
                child: SvgPicture.asset(
                  "assets/images/ic_vehicles.svg",
                  colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
              ),
              12.width,
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "${data["distance"]} miles, ${data["duration"]}",
                    style: AppTextStyles.textSmallNormal.copyWith(color: AppColors.getPrimaryColor(context)),
                  ),
                ),
                SizedBox(
                  width: MediaQuery.sizeOf(context).width * 0.65,
                  child: Text(
                    stop.location,
                    style: AppTextStyles.textSmallNormal.copyWith(color: Colors.black),
                  ).expand(),
                )
              ])
            ],
          ),
        ),
        RotatedBox(
          quarterTurns: 2,
          child: SvgPicture.asset(
            "assets/images/ic_triangle.svg",
            color: AppColors.isDark(context) ? Colors.white : Color(0xff363641),
          ),
        )
      ],
    );
  }

  Future<MapImage> _createMapImage() async {
    ByteData fileData = await rootBundle.load('assets/images/map-pin.svg');
    Uint8List pixelData = fileData.buffer.asUint8List();
    int width = Device.screenType == ScreenType.tablet ? 7.5.w.round() : 11.w.round(); // Set desired width
    int height = 9.h.round(); // Set desired height
    return MapImage.withImageDataImageFormatWidthAndHeight(pixelData, ImageFormat.png, width, height);
  }

  Future<MapImage> _createCurrentImage() async {
    ByteData fileData = await rootBundle.load("assets/images/pin.png");
    Uint8List pixelData = fileData.buffer.asUint8List();
    int width = 18.w.round(); // Set desired width
    int height = 18.w.round(); // Set desired height
    return MapImage.withImageDataImageFormatWidthAndHeight(pixelData, ImageFormat.png, width, height);
  }

  Future<MapImage> _createPickupDotImage() async {
    ByteData fileData = await rootBundle.load('assets/images/ic_pickup_dot.svg');
    Uint8List pixelData = fileData.buffer.asUint8List();
    int width = 7.w.round(); // Set desired width
    int height = 7.w.round(); // Set desired height
    return MapImage.withImageDataImageFormatWidthAndHeight(pixelData, ImageFormat.png, width, height);
  }

  Future<MapImage> _createDropOffDotImage() async {
    ByteData fileData = await rootBundle.load('assets/images/ic_drop_dot.svg');
    Uint8List pixelData = fileData.buffer.asUint8List();
    int width = 7.w.round(); // Set desired width
    int height = 7.w.round(); // Set desired height
    return MapImage.withImageDataImageFormatWidthAndHeight(pixelData, ImageFormat.png, width, height);
  }

  void addRoute(List<GeoCoordinates> coordinates, HereMapController hereMapController) {
    if (kDebugMode) {
      debugPrint("Called add route");
    }

    List<here.Waypoint> wayPoints = coordinates.map((coord) {
      return here.Waypoint.withDefaults(coord);
    }).toList();

    routingEngine.calculateTruckRoute(wayPoints, here.TruckOptions(), (error, routing) {
      if (error == null) {
        var route = routing!.first;
        GeoPolyline routeGeoPoly = route.geometry;
        double polywidth = 5.0;
        var mypolyline = MapPolyline.withRepresentation(
            routeGeoPoly,
            MapPolylineSolidRepresentation(
                MapMeasureDependentRenderSize.withSingleSize(RenderSizeUnit.pixels, polywidth), AppColors.colorPrimaryNight, LineCap.round));
        hereMapController.mapScene.addMapPolyline(mypolyline);

        // Adjust camera to fit the route
        hereMapController.zoomToLogicalViewPort(geoBox: route.boundingBox, context: context);
      } else {
        debugPrint("Error in Here map is ${error.toString()}");
      }
    });
  }

  void addMapMarker(GeoCoordinates coordinates, MapImage mapImage, HereMapController mapController, int index, int type, String id) {
    Anchor2D anchor2D = Anchor2D.withHorizontalAndVertical(0.5, 1);

    MapMarker mapMarker = MapMarker.withAnchor(coordinates, mapImage, anchor2D);
    mapMarker.drawOrder = index - 1;

    Metadata metadata = Metadata();
    metadata.setString("key_poi", id);
    mapMarker.metadata = metadata;

    MapMarkerTextStyle textStyleNew = mapMarker.textStyle;
    List<MapMarkerTextStylePlacement> placements = [];
    placements.add(MapMarkerTextStylePlacement.top);
    try {
      textStyleNew = MapMarkerTextStyle.make(22.sp, AppColors.colorPrimaryNight, 1, AppColors.colorPrimaryNight, placements);
    } on MapMarkerTextStyleInstantiationException catch (e) {
      // An error code will indicate what went wrong, for example, when negative values are set for text size.
      debugPrint("TextStyle: Error code: ${e.error.name}");
    }

    mapMarker.text = type == 0 ? "P-$index" : "D-$index";
    mapMarker.textStyle = textStyleNew;

    mapController.mapScene.addMapMarker(mapMarker);
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

  void moveToNextStage() {
    setState(() {
      // Move to the next stage based on the current stage
      switch (nextStage) {
        case DispatchStage.headedToPickup:
          nextStage = DispatchStage.checkedInPickup;
          break;
        case DispatchStage.checkedInPickup:
          nextStage = DispatchStage.pickedUpLoad;
          break;
        case DispatchStage.pickedUpLoad:
          nextStage = DispatchStage.headedToDropOff;
          break;
        case DispatchStage.headedToDropOff:
          nextStage = DispatchStage.checkedInDropOff;
          break;
        case DispatchStage.checkedInDropOff:
          nextStage = DispatchStage.deliveredLoad;
          break;
        case DispatchStage.deliveredLoad:
          nextStage = DispatchStage.headedToDropOff;
          break;
        case DispatchStage.headedToReDeliver:
          nextStage = DispatchStage.checkedInReDeliver;
          break;
        case DispatchStage.checkedInReDeliver:
          nextStage = DispatchStage.redelivered;
          break;
        case DispatchStage.redelivered:
          nextStage = DispatchStage.headedToReDeliver;
          break;
        case DispatchStage.headedToDumpAndDonate:
          nextStage = DispatchStage.checkedInDumpAndDonate;
          break;
        case DispatchStage.checkedInDumpAndDonate:
          nextStage = DispatchStage.dumpAndDonated;
          break;
        case DispatchStage.dumpAndDonated:
          nextStage = DispatchStage.headedToDumpAndDonate;
          break;
      }
    });
  }

  String getNextStatus() {
    // Return appropriate status based on the next stage
    switch (nextStage) {
      case DispatchStage.headedToPickup:
        return '1';
      case DispatchStage.checkedInPickup:
        return '2';
      case DispatchStage.pickedUpLoad:
        return '3';
      case DispatchStage.headedToDropOff:
        return '1';
      case DispatchStage.checkedInDropOff:
        return '2';
      case DispatchStage.deliveredLoad:
        return '3';
      case DispatchStage.headedToReDeliver:
        return '1';
      case DispatchStage.checkedInReDeliver:
        return '2';
      case DispatchStage.redelivered:
        return '3';
      case DispatchStage.headedToDumpAndDonate:
        return '1';
      case DispatchStage.checkedInDumpAndDonate:
        return '2';
      case DispatchStage.dumpAndDonated:
        return '3';
      default:
        return '0';
    }
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

  Future<Map<String, String>> getDistanceDuration(GeoCoordinates destination) async {
    Map<String, String> dataMap = {"distance": "0", "duration": "0"};

    var startWaypoint = Waypoint.withDefaults(currentLocation.value);
    var destinationWaypoint = Waypoint.withDefaults(destination);

    List<Waypoint> waypoints = [startWaypoint, destinationWaypoint];
    // Using Completer to wait for the asynchronous operation to complete
    Completer<void> completer = Completer<void>();

    routingEngine.calculateTruckRoute(waypoints, here.TruckOptions(), (RoutingError? routingError, List<here.Route>? routeList) async {
      if (routingError == null) {
        // When error is null, it is guaranteed that the list is not empty.
        here.Route route = routeList!.first;
        dataMap["distance"] = metersToMiles(route.lengthInMeters).toStringAsFixed(2);
        dataMap["duration"] = formatDuration(route.duration.inSeconds).toString();
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

  Future<void> showLoadStatusDialog() async {
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.black),
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Load Status",
                    style: AppTextStyles.textTitleBold.copyWith(color: Colors.white),
                  ),
                  16.height,
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      var bodyMap = {
                        "rejectionType": "No Rejection",
                      };

                      callBloc(BlocProvider.of<DispatcherBloc>(context).add(NoRejectionEvent(
                        body: bodyMap,
                        stopId: loadData!.stops[currentStopIndex].id.toString(),
                        type: 0,
                      )));
                    },
                    child: Container(
                      color: Color(0xffF2F4F4),
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            height: 20,
                            width: 20,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(1000), border: Border.all(color: AppColors.colorPrimary)),
                          ),
                          8.width,
                          Text(
                            "No Rejection",
                            style: AppTextStyles.textBodyNormal.copyWith(color: Colors.black),
                          )
                        ],
                      ),
                    ),
                  ),
                  16.height,
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      color: Color(0xffF2F4F4),
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            height: 20,
                            width: 20,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(1000), border: Border.all(color: AppColors.colorPrimary)),
                          ),
                          8.width,
                          Text(
                            "Partial Rejection",
                            style: AppTextStyles.textBodyNormal.copyWith(color: Colors.black),
                          )
                        ],
                      ),
                    ),
                  ),
                  16.height,
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      color: Color(0xffF2F4F4),
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            height: 20,
                            width: 20,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(1000), border: Border.all(color: AppColors.colorPrimary)),
                          ),
                          8.width,
                          Text(
                            "Complete Rejection",
                            style: AppTextStyles.textBodyNormal.copyWith(color: Colors.black),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        });
  }

  Future<void> showLoadDeliveredDialog() async {
    Future.delayed(Duration(seconds: 2), () {
      Navigator.pop(context);

      if (loadData!.status == "Redeliver") {
        FBroadcast.instance().broadcast(Constant.dispatchStatus, value: Constant.loadDelivered);
      } else {
        if (currentStopIndex == loadData!.stops.length - 1) {
          FBroadcast.instance().broadcast(Constant.dispatchStatus, value: Constant.loadDelivered);
        } else {
          callBloc(BlocProvider.of<DispatcherBloc>(context).add(NewDispatcherLoadEvent(true)));
        }
      }
    });

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Container(
                  height: 16.h,
                  width: 14.h,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                  child: SvgPicture.asset("assets/images/ic_check_ripple.svg").paddingAll(24),
                ),
                Container(
                  height: 16.h,
                  decoration: BoxDecoration(
                      color: Color(0xff04d684),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      )),
                  padding: EdgeInsets.only(left: 12),
                  child: Container(
                    decoration: BoxDecoration(
                        color: Color(0xff01EB90),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        )),
                    padding: EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Load Delivered!",
                          style: AppTextStyles.textBodySemiBold.copyWith(color: Colors.black),
                        ),
                        Text(
                          "You have successfully delivered the load.",
                          style: AppTextStyles.textSmallNormal.copyWith(color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ).expand(),
              ],
            ),
          );
        });
  }

  Future<void> getRemainingTime() async {
    if (loadData!.status == "Redeliver") {
      if (loadData!.newStop!.stopStatus.length <= 1) {
        var timeToReach = await getDurationFromRoute(
            GeoCoordinates(loadData!.newStop!.coordinates.coordinates.last, loadData!.newStop!.coordinates.coordinates.first));

        if (timeToReach == null) {
          loadStatus = "On time"; // If no duration was calculated, default to "On time".
        } else {
          var targetTime = DateTime.parse(loadData!.newStop!.stopDateTime).toLocal();
          var currentTime = DateTime.now();

          // Calculate the time difference (targetTime - currentTime)
          var data = targetTime.difference(currentTime);

          debugPrint("Time difference: $data");

          // Define the threshold for "on time" (±5 minutes)
          var bufferTime = Duration(minutes: 5);

          // Check if we're "On Time" (within ±5 minutes of the target)
          if (timeToReach >= data - bufferTime && timeToReach <= data + bufferTime) {
            loadStatus = "On time";
          }
          // Check if we're "Before Time" (timeToReach is less than data by more than 5 minutes)
          else if (timeToReach < data - bufferTime) {
            loadStatus = "Before Time";
          }
          // Otherwise, we're "Delayed" (timeToReach is greater than data by more than 5 minutes)
          else {
            loadStatus = "Delayed";
          }
        }
      } else {
        var targetTime = DateTime.parse(loadData!.newStop!.stopDateTime).toLocal();
        var currentTime = loadData!.newStop!.stopStatus[1].createdAt;

        // Calculate the time difference
        var data = targetTime.difference(currentTime);

        debugPrint("Time difference: $data");

        // Check if on time (within the 5-second buffer window)
        if (data.inMinutes.abs() <= 5) {
          loadStatus = "On time";
        } else {
          // Check if you're late
          if (data.isNegative) {
            loadStatus = "Delayed";
          } else {
            loadStatus = "Before Time";
          }
        }
      }
    } else {
      var currentStop = currentStopIndex == -1 ? loadData!.stops.last : loadData!.stops[currentStopIndex];

      if (currentStop.stopStatus.length <= 1) {
        var timeToReach =
            await getDurationFromRoute(GeoCoordinates(currentStop.coordinates.coordinates.last, currentStop.coordinates.coordinates.first));

        if (timeToReach == null) {
          loadStatus = "On time"; // If no duration was calculated, default to "On time".
        } else {
          var targetTime = DateTime.parse(currentStop.stopDateTime).toLocal();
          var currentTime = DateTime.now();

          // Calculate the time difference (targetTime - currentTime)
          var data = targetTime.difference(currentTime);

          debugPrint("Time difference: $data");

          // Define the threshold for "on time" (±5 minutes)
          var bufferTime = Duration(minutes: 5);

          // Check if we're "On Time" (within ±5 minutes of the target)
          if (timeToReach >= data - bufferTime && timeToReach <= data + bufferTime) {
            loadStatus = "On time";
          }
          // Check if we're "Before Time" (timeToReach is less than data by more than 5 minutes)
          else if (timeToReach < data - bufferTime) {
            loadStatus = "Before Time";
          }
          // Otherwise, we're "Delayed" (timeToReach is greater than data by more than 5 minutes)
          else {
            loadStatus = "Delayed";
          }
        }
      } else {
        var targetTime = DateTime.parse(currentStop.stopDateTime).toLocal();
        var currentTime = currentStop.stopStatus[1].createdAt;

        // Calculate the time difference
        var data = targetTime.difference(currentTime);

        debugPrint("Time difference: $data");

        // Check if on time (within the 5-second buffer window)
        if (data.inMinutes.abs() <= 5) {
          loadStatus = "On time";
        } else {
          // Check if you're late
          if (data.isNegative) {
            loadStatus = "Delayed";
          } else {
            loadStatus = "Before Time";
          }
        }
      }
    }

    setState(() {});
  }

  Future<Duration?> getDurationFromRoute(GeoCoordinates destination) async {
    // Create a Completer to wrap the asynchronous result
    Completer<Duration?> completer = Completer();

    List<here.Waypoint> wayPoints = [currentLocation.value, destination].map((coord) {
      return here.Waypoint.withDefaults(coord);
    }).toList();

    var truckOptions = here.TruckOptions();
    var routeOptions = here.RouteOptions();
    routeOptions.enableRouteHandle = true;
    truckOptions.routeOptions = routeOptions;

    // Calculate the truck route asynchronously
    routingEngine.calculateTruckRoute(
      wayPoints,
      truckOptions,
      (error, routing) {
        if (error == null) {
          var route = routing!.first;
          completer.complete(route.duration); // Complete the completer with the duration
        } else {
          toast(error.name);
          completer.completeError("Error calculating route: ${error.name}"); // Complete with error if any
        }
      },
    );

    // Return the Future from the completer
    return completer.future;
  }

  Future<void> _requestConsent() async {
    if (!Platform.isIOS) {
      // This shows a localized widget that asks the user if data can be collected or not.
      await _consentEngine?.requestUserConsent(context);
    }

    if (Platform.isIOS || _consentEngine!.userConsentState == ConsentUserReply.granted) {
      startNavigate(
          GeoCoordinates(
              loadData!.stops[currentStopIndex].coordinates.coordinates.last, loadData!.stops[currentStopIndex].coordinates.coordinates.first),
          loadData!.stops[currentStopIndex]);

      // navigate(
      //     context,
      //     NavigateToPlace(
      //       destination: GeoCoordinates(
      //           loadData!.stops[currentStopIndex].coordinates.coordinates.last,
      //           loadData!
      //               .stops[currentStopIndex].coordinates.coordinates.first),
      //       message: 'Calculating route',
      //       stopId: loadData!.stops[currentStopIndex].id.toString(),
      //     ),
      //     false);
    }
  }

  buildOnRouteBottomSheet() {
    return DraggableScrollableSheet(
        key: _sheet,
        initialChildSize: 0.15,
        minChildSize: 0.15,
        maxChildSize: 0.5,
        expand: true,
        snap: true,
        snapSizes: const [0.5],
        controller: _controller,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
                boxShadow: defaultBoxShadow(),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                border: Border.all(color: AppColors.isDark(context) ? AppColors.colorPrimaryNight : Color(0xff72DEFF)),
                color: AppColors.isDark(context) ? AppColors.darkBackground : Color(0xffFAFEFF)),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                children: [
                  Container(
                    width: 20.w,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    margin: EdgeInsets.only(top: 8),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Est. time",
                                style: AppTextStyles.textSmallNormal,
                              ),
                              Text(
                                getFormattedDate("hh:mm a", DateTime.parse(loadData!.stops.last.stopDateTime), true),
                                style: AppTextStyles.textTitleBold.copyWith(color: Color(0xff1EB980)),
                              ),
                              Text(
                                "(${getFormattedDate("MMMM dd yyyy", DateTime.parse(loadData!.stops.last.stopDateTime), true)})",
                                style: AppTextStyles.textSmallBold.copyWith(color: AppColors.getPrimaryColor(context)),
                              ),
                            ],
                          ).expand(flex: 3),
                          Column(
                            children: [
                              Container(
                                height: 8,
                                width: 8,
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(color: AppColors.getPrimaryColor(context))),
                              ),
                              Container(
                                height: 6.h,
                                width: 2,
                                color: AppColors.getPrimaryColor(context),
                              ),
                              Container(
                                height: 8,
                                width: 8,
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(color: AppColors.getPrimaryColor(context))),
                              ),
                            ],
                          ).expand(flex: 2),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Total Miles",
                                style: AppTextStyles.textSmallNormal,
                              ),
                              4.height,
                              Text(
                                (loadData!.loadMiles?.driverMiles.loadedMiles ?? 0.0).toString(),
                                style: AppTextStyles.textSmallBold,
                              ),
                              8.height,
                              Text(
                                "Total Trip Hours",
                                style: AppTextStyles.textSmallNormal,
                              ),
                              4.height,
                              RichText(
                                  text: TextSpan(
                                      text: "${convertToHours(int.tryParse(loadData!.loadMiles?.hours ?? "0") ?? 0)} Hrs",
                                      style: AppTextStyles.textSmallBold.copyWith(color: AppColors.blackWhiteText(context)),
                                      children: [
                                    TextSpan(
                                      text: " ($loadStatus)",
                                      style: AppTextStyles.textSmallNormal
                                          .copyWith(color: loadStatus == "Delayed" ? AppColors.appRedColor : AppColors.appGreenColor),
                                    )
                                  ])),
                            ],
                          ).expand(flex: 3),
                        ],
                      ),
                      12.height,
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SvgPicture.asset("assets/images/ic_current_pin.svg").paddingTop(6),
                          8.width,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Current Location",
                                style: AppTextStyles.textSmallNormal.copyWith(fontSize: 15.sp),
                              ),
                              Text(
                                currentAddress,
                                style: AppTextStyles.textSmallBold.copyWith(fontSize: 15.sp),
                              ),
                            ],
                          ).expand()
                        ],
                      ),
                      8.height,
                      Column(
                        children: loadData!.stops.where((data) => data.stopType == "Pickup").mapIndexed((index, element) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SvgPicture.asset("assets/images/ic_pickup_pin.svg").paddingTop(6),
                              8.width,
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Pick Up - ${index + 1}",
                                    style: AppTextStyles.textSmallNormal.copyWith(fontSize: 15.sp),
                                  ),
                                  Text(
                                    element.location,
                                    style: AppTextStyles.textSmallBold.copyWith(fontSize: 15.sp),
                                  ),
                                ],
                              ).expand()
                            ],
                          );
                        }).toList(),
                      ),
                      8.height,
                      Column(
                        children: loadData!.stops.where((data) => data.stopType != "Pickup").mapIndexed((index, element) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SvgPicture.asset(index == loadData!.stops.where((data) => data.stopType != "Pickup").length - 1
                                      ? "assets/images/ic_last_drop_pin.svg"
                                      : "assets/images/ic_drop_pin.svg")
                                  .paddingTop(6),
                              8.width,
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Drop Off - ${index + 1}",
                                    style: AppTextStyles.textSmallNormal.copyWith(fontSize: 15.sp),
                                  ),
                                  Text(
                                    element.location,
                                    style: AppTextStyles.textSmallBold.copyWith(fontSize: 15.sp),
                                  ),
                                ],
                              ).expand()
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  ).paddingAll(16),
                ],
              ),
            ),
          );
        });
  }

  buildReDeliverBottomSheet() {
    return DraggableScrollableSheet(
        key: _sheet,
        initialChildSize: 0.15,
        minChildSize: 0.15,
        maxChildSize: 0.4,
        expand: true,
        snap: true,
        snapSizes: const [0.4],
        controller: _controller,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
                boxShadow: defaultBoxShadow(),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                border: Border.all(color: Color(0xff72DEFF)),
                color: AppColors.isDark(context) ? AppColors.darkBackground : Color(0xffFAFEFF)),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                children: [
                  Container(
                    width: 20.w,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    margin: EdgeInsets.only(top: 8),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Est. time",
                                style: AppTextStyles.textSmallNormal,
                              ),
                              Text(
                                getFormattedDate("hh:mm a", loadData!.assignedJobs.endTime, true),
                                style: AppTextStyles.textTitleBold.copyWith(color: Color(0xff1EB980)),
                              ),
                              Text(
                                "(${getFormattedDate("MMMM dd yyyy", loadData!.assignedJobs.endTime, true)})",
                                style: AppTextStyles.textSmallBold.copyWith(color: AppColors.colorPrimaryNight),
                              ),
                            ],
                          ).expand(flex: 3),
                          Column(
                            children: [
                              Container(
                                height: 8,
                                width: 8,
                                decoration: BoxDecoration(
                                    color: Colors.white, borderRadius: BorderRadius.circular(100), border: Border.all(color: AppColors.colorPrimary)),
                              ),
                              Container(
                                height: 6.h,
                                width: 2,
                                color: AppColors.colorPrimary,
                              ),
                              Container(
                                height: 8,
                                width: 8,
                                decoration: BoxDecoration(
                                    color: Colors.white, borderRadius: BorderRadius.circular(100), border: Border.all(color: AppColors.colorPrimary)),
                              ),
                            ],
                          ).expand(flex: 2),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Total Miles",
                                style: AppTextStyles.textSmallNormal,
                              ),
                              4.height,
                              Text(
                                loadData!.newStop!.miles,
                                style: AppTextStyles.textSmallBold,
                              ),
                              8.height,
                              Text(
                                "Total Trip Hours",
                                style: AppTextStyles.textSmallNormal,
                              ),
                              4.height,
                              RichText(
                                  text: TextSpan(
                                      text: "${convertToHours(int.tryParse(loadData!.loadMiles?.hours ?? "0") ?? 0)} Hrs",
                                      style: AppTextStyles.textSmallBold.copyWith(color: Colors.black),
                                      children: [
                                    TextSpan(
                                      text: " ($loadStatus)",
                                      style: AppTextStyles.textSmallNormal
                                          .copyWith(color: loadStatus == "Delayed" ? AppColors.appRedColor : AppColors.appGreenColor),
                                    )
                                  ])),
                            ],
                          ).expand(flex: 3),
                        ],
                      ),
                      12.height,
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SvgPicture.asset("assets/images/ic_current_pin.svg").paddingTop(6),
                          8.width,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Current Location",
                                style: AppTextStyles.textSmallNormal.copyWith(fontSize: 15.sp),
                              ),
                              Text(
                                currentAddress,
                                style: AppTextStyles.textSmallBold.copyWith(fontSize: 15.sp),
                              ),
                            ],
                          ).expand()
                        ],
                      ),
                      8.height,
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SvgPicture.asset("assets/images/ic_last_drop_pin.svg").paddingTop(6),
                          8.width,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Redelivered",
                                style: AppTextStyles.textSmallNormal.copyWith(fontSize: 15.sp),
                              ),
                              Text(
                                loadData!.newStop!.location,
                                style: AppTextStyles.textSmallBold.copyWith(fontSize: 15.sp),
                              ),
                            ],
                          ).expand()
                        ],
                      )
                    ],
                  ).paddingAll(16),
                ],
              ),
            ),
          );
        });
  }

  void handleCtaClick() {
    if (nextStage != DispatchStage.headedToPickup &&
        nextStage != DispatchStage.headedToDropOff &&
        nextStage != DispatchStage.headedToReDeliver &&
        nextStage != DispatchStage.headedToDumpAndDonate) {
      var distanceToStartPoint = loadData!.status == "Redeliver"
          ? calculateDistance(
              originLat: currentLocation.value.latitude,
              originLng: currentLocation.value.longitude,
              destLat: loadData!.newStop!.coordinates.coordinates.last,
              destLng: loadData!.newStop!.coordinates.coordinates.first)
          : calculateDistance(
              originLat: currentLocation.value.latitude,
              originLng: currentLocation.value.longitude,
              destLat: loadData!.stops[currentStopIndex].coordinates.coordinates.last,
              destLng: loadData!.stops[currentStopIndex].coordinates.coordinates.first);

      if (distanceToStartPoint > (geoFenceDistance / 1000)) {
        showToast(context, "Please reach at the location to perform the action", true);
        return;
      }
    }

    if (nextStage == DispatchStage.pickedUpLoad && loadData!.stops[currentStopIndex].bolDoc.isEmptyOrNull) {
    } else if (nextStage == DispatchStage.redelivered) {
    } else if (nextStage == DispatchStage.dumpAndDonated) {
    } else if (nextStage == DispatchStage.deliveredLoad) {
      if (loadData!.stops[currentStopIndex].bolDoc.isEmptyOrNull) {
      } else {
        showLoadStatusDialog();
      }
    } else {
      var bodyMap = {
        "stopId": loadData!.status == "Redeliver" ? loadData!.newStop!.id : loadData!.stops[currentStopIndex].id,
        "status": getNextStatus()
      };

      if (nextStage == DispatchStage.headedToPickup ||
          nextStage == DispatchStage.headedToDropOff ||
          nextStage == DispatchStage.headedToDumpAndDonate ||
          nextStage == DispatchStage.headedToReDeliver) {
        openNav = true;
      }

      callBloc(BlocProvider.of<DispatcherBloc>(context).add(UpdateStopStatusEvent(body: bodyMap)));
    }
  }

  Widget buildMapErrorView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Lottie.asset("assets/lottie/globe.json", height: 28.h, width: 28.h),
        Text(
          "Error while loading HereMap,\nTry restarting the app",
          textAlign: TextAlign.center,
          style: AppTextStyles.textBodySemiBold,
        ),
        SizedBox(
          height: 12.h,
        ),
      ],
    );
  }

  startNavigate(GeoCoordinates destination, Stop stopData) {
    bool gettingRoute = true;

    LoaderDialog().show(context, "Creating route");

    List<here.Waypoint> wayPoints = [currentLocation.value, destination].map((coord) {
      return here.Waypoint.withDefaults(coord);
    }).toList();

    var truckOptions = here.TruckOptions();
    var routeOptions = here.RouteOptions();
    routeOptions.enableRouteHandle = true;
    truckOptions.routeOptions = routeOptions;

    routingEngine.calculateTruckRoute(
      wayPoints,
      truckOptions,
      (error, routing) async {
        LoaderDialog().hide();
        gettingRoute = false;

        if (error == null) {
          var route = routing!.first;
          var res = await navigate(
              context,
              NavigationScreen(
                route: route,
                wayPoints: wayPoints,
                stop: stopData,
                index: currentStopIndex,
              ),
              false);
          if (res == "playCheck" && stopData.stopStatus.length < 2) {
            Future.delayed(Duration(seconds: 1), () {
              TextToSpeechService.speak("You can now check in into ${stopData.stopType} location");
            });
          }
        } else {
          toast(error.name);
        }
      },
    );

    Future.delayed(Duration(seconds: 8), () {
      if (mounted && gettingRoute) {
        debugPrint("Closing loader now, No response from Here Maps");
        LoaderDialog().hide();
      }
    });
  }
}
