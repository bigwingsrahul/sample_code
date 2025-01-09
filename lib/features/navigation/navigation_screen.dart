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

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:fbroadcast/fbroadcast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/gestures.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/navigation.dart' as Navigation;
import 'package:here_sdk/routing.dart' as Routing;
import 'package:here_sdk/routing.dart';
import 'package:here_sdk/transport.dart' as Transport;
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:techtruckers/config/helpers/preferences_helper.dart';
import 'package:techtruckers/config/helpers/vincenity_calculator.dart';
import 'package:techtruckers/config/helpers/weather_helper.dart';
import 'package:techtruckers/config/services/api_service.dart';
import 'package:techtruckers/config/theme/app_colors.dart';
import 'package:techtruckers/config/theme/app_text_styles.dart';
import 'package:techtruckers/config/theme/ui_style.dart';
import 'package:techtruckers/features/common/models/city_item_model.dart';
import 'package:techtruckers/features/common/models/get_weather_data_model.dart';
import 'package:techtruckers/features/common/widgets/loader_dialog.dart';
import 'package:techtruckers/features/dispatch/models/dispatch_load_data_model.dart';
import 'package:techtruckers/features/navigation/android_notifications.dart';
import 'package:techtruckers/features/navigation/application_preferences.dart';
import 'package:techtruckers/features/navigation/ios_notifications.dart';
import 'package:techtruckers/features/navigation/location_provider_interface.dart';
import 'package:techtruckers/features/navigation/marquee_widget.dart';
import 'package:techtruckers/features/navigation/notifications_manager.dart';
import 'package:techtruckers/features/navigation/position_status_listener.dart';
import 'package:techtruckers/features/navigation/reroute_dialog.dart';
import 'package:techtruckers/features/navigation/route_preferences_model.dart';
import 'package:techtruckers/main.dart';
import 'package:techtruckers/utils/constant.dart';
import 'package:techtruckers/utils/general_functions.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'current_maneuver_widget.dart';
import 'location_utils.dart';
import 'maneuver_action_text_helper.dart';
import 'navigation_progress_widget.dart';
import 'navigation_speed_widget.dart';
import 'next_maneuver_widget.dart';
import 'rerouting_handler.dart';
import 'rerouting_indicator_widget.dart';

/// Navigation mode screen widget.
class NavigationScreen extends StatefulWidget {
  /// Initial route for navigation.
  final Routing.Route route;

  /// Waypoints lists of the route.
  final List<Routing.Waypoint> wayPoints;

  final Stop? stop;

  final int? index;

  /// Constructs a widget.
  NavigationScreen({
    super.key,
    required this.route,
    required this.wayPoints,
    this.stop,
    this.index,
  });

  @override
  _NavigationScreenState createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> with WidgetsBindingObserver implements PositioningStatusListener, LocationListener {
  static const double _kInitDistanceToEarth = 1000; // meters
  static const double _kSpeedFactor = 1.3;
  static const int _kNotificationIntervalInMilliseconds = 500;
  static const double _kDistanceToShowNextManeuver = 500;
  static const double _kTopBarHeight = 100;
  static const double _kBottomBarHeight = 230;
  static const double _kHereLogoOffset = 75;
  static const double _kPrincipalPointOffset = 160;

  // This is example code and not for real use.
  // These values are usually country specific and may vary depending on the navigation segment.
  static const double _kDefaultSpeedLimitOffset = 1;
  static const double _kDefaultSpeedLimitBoundary = 50;

  final GlobalKey _mapKey = GlobalKey();
  DeviceLocationServicesStatusNotifier? _servicesStatusNotifier;
  LocationProviderInterface? _locationProvider;
  Location? _currentLocationForLocationStatus;

  late Routing.Route _currentRoute;

  late HereMapController _hereMapController;
  late MapMarker _startMarker;
  late MapMarker _finishMarker;
  bool showSatellite = false;

  late Navigation.VisualNavigator _visualNavigator;
  bool _navigationStarted = false;
  bool _canLocateUserPosition = true;
  bool _shouldMonitorPositioning = false;

  final FlutterTts _flutterTts = FlutterTts();
  late RoutingEngine routingEngine;

  late int _remainingDistanceInMeters;
  late int _remainingDurationInSeconds;
  int _trafficDelayDurationInSeconds = 0;
  int? _currentManeuverIndex;
  int _currentManeuverDistance = 0;
  int? _nextManeuverIndex;
  int _nextManeuverDistance = 0;
  String? _currentStreetName;
  double? _currentSpeedLimit;
  double? _currentSpeed;
  Navigation.SpeedWarningStatus _speedWarningStatus = Navigation.SpeedWarningStatus.speedLimitRestored;

  late ReroutingHandler _reroutingHandler;
  bool _reroutingInProgress = false;
  late NotificationsManager _notificationsManager;

  AppLifecycleState? _appLifecycleState;
  WeatherItem? weatherItem;
  bool showWeatherDetail = false;
  String loadStatus = "";
  late StreamSubscription<FGBGType> subscription;

  bool get _canShowNotification => _appLifecycleState == AppLifecycleState.paused;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    routingEngine = RoutingEngine();
    _visualNavigator = Navigation.VisualNavigator();
    _remainingDistanceInMeters = widget.route.lengthInMeters;
    _remainingDurationInSeconds = widget.route.duration.inSeconds;
    _currentRoute = widget.route;
    _getWeatherInfo(_currentRoute);
    WidgetsBinding.instance.addObserver(this);

    FBroadcast.instance().register(Constant.navChanges, (value, callback) {
      // Check if the value is not null and contains the expected keys
      if (value != null && value["type"] != null && value["updateType"] != null && value["stopData"] != null) {
        // Print the type to confirm it's being accessed correctly
        print(value["type"].toString().toLowerCase());

        // Check if the "type" is "update" and proceed
        if (value["type"].toString().toLowerCase() == "update") {
          // Check if the "updateType" is "location"
          if (value["updateType"].toString().toLowerCase() == "location") {
            // Ensure "stopData" is a valid JSON object before parsing
            var stopDataJson = value["stopData"];
            if (stopDataJson != null) {
              try {
                // Ensure stopData is properly parsed and matches the widget's stop id
                var stopData = Stop.fromJson(jsonDecode(stopDataJson));
                if (stopData.id == widget.stop?.id) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      content: RerouteDialog(
                        onAccept: () =>
                            reRouteToNewLocation(GeoCoordinates(stopData.coordinates.coordinates.last, stopData.coordinates.coordinates.first)),
                        location: stopData.location,
                      ),
                    ),
                  );
                }
              } catch (e, stack) {
                // Catch any JSON parsing errors
                print("Error parsing stop data: $e");
                debugPrintStack(stackTrace: stack);
              }
            }
          }
        }
      } else {
        print("Received value is missing required fields: $value");
      }
    });

    if (Platform.isIOS) {
      _notificationsManager = IosNotificationsManager();
      _configTextSpeakerForIOS();
    } else {
      _notificationsManager = AndroidNotificationsManager();
    }

    _reroutingHandler = ReroutingHandler(
      visualNavigator: _visualNavigator,
      wayPoints: widget.wayPoints,
      preferences: context.read<RoutePreferencesModel>(),
      onBeginRerouting: () {
        setState(() => _reroutingInProgress = true);
        _showNotification();
      },
      onNewRoute: _onNewRoute,
      offline: Provider.of<AppPreferences>(context, listen: false).useAppOffline,
    );
    _notificationsManager.init();
  }

  @override
  void dispose() {
    _locationProvider?.removeListeners();
    _locationProvider?.stop();
    _reroutingHandler.release();
    _servicesStatusNotifier?.stop();
    _flutterTts.stop();
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    FBroadcast.instance().unregister(context);
    _notificationsManager.dismissNotification();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget? nextManeuverWidget = _reroutingInProgress || !_canLocateUserPosition ? null : _buildNextManeuver(context);
    PreferredSize? topBarWidget = _buildTopBar(context);
    double topOffset = MediaQuery.of(context).padding.top - UIStyle.popupsBorderRadius;
    final HereMapOptions options = HereMapOptions()..initialBackgroundColor = Theme.of(context).colorScheme.surface;
    options.renderMode = MapRenderMode.texture;
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, _) async {
        Future.delayed(Duration.zero, () {
          _stopNavigation();
          // Navigator.of(context).pop();
        });
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: topBarWidget,
        body: Padding(
          padding: EdgeInsets.only(
            top: topBarWidget != null ? _kTopBarHeight + topOffset : 0,
          ),
          child: Stack(
            children: [
              HereMap(
                key: _mapKey,
                options: options,
                onMapCreated: _onMapCreated,
              ),
              // if (nextManeuverWidget != null) nextManeuverWidget,
              weatherItem == null || showWeatherDetail ? SizedBox() : buildSmallWeatherCard(),
              if (_navigationStarted) _buildNavigationControls(context),
            ],
          ),
        ),
        extendBodyBehindAppBar: true,
        bottomNavigationBar: _navigationStarted
            ? SizedBox(
                height: _kBottomBarHeight,
                child: NavigationProgress(
                  routeLengthInMeters: _currentRoute.lengthInMeters,
                  remainingDistanceInMeters: _remainingDistanceInMeters,
                  remainingDurationInSeconds: _remainingDurationInSeconds,
                  loadStatus: loadStatus,
                  appointmentDate: widget.stop == null ? null : DateTime.parse(widget.stop!.stopDateTime),
                  onExit: () {
                    _stopNavigation();
                    Navigator.pop(context);
                  },
                  onMapSwitch: () {
                    showSatellite = !showSatellite;
                    _hereMapController.mapScene.loadSceneForMapScheme(
                      showSatellite ? MapScheme.satellite : MapScheme.liteDay,
                      (MapError? error) async {},
                    );
                    _hereMapController.mapScene.reloadScene();
                  },
                ),
              )
            : null,
      ),
    );
  }

  Future<void> _configTextSpeakerForIOS() async {
    await _flutterTts.setSharedInstance(true);
    await _flutterTts.setIosAudioCategory(
      IosTextToSpeechAudioCategory.playback,
      <IosTextToSpeechAudioCategoryOptions>[
        IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        IosTextToSpeechAudioCategoryOptions.duckOthers,
      ],
      IosTextToSpeechAudioMode.voicePrompt,
    );
  }

  void _onMapCreated(HereMapController hereMapController) {
    _hereMapController = hereMapController;

    mapSceneLoadSceneCallback(MapError? error) async {
      if (error != null) {
        print('Map scene not loaded. MapError: ${error.toString()}');
        return;
      }

      hereMapController.camera.lookAtPointWithMeasure(
        _currentRoute.geometry.vertices.first,
        MapMeasure(MapMeasureKind.distance, _kInitDistanceToEarth),
      );

      hereMapController.mapScene.enableFeatures({
        MapFeatures.trafficFlow: MapFeatureModes.trafficFlowWithFreeFlow,
        MapFeatures.lowSpeedZones: MapFeatureModes.lowSpeedZonesAll,
        MapFeatures.landmarks: MapFeatureModes.landmarksTextured,
        MapFeatures.vehicleRestrictions: MapFeatureModes.vehicleRestrictionsActive,
        MapFeatures.landmarks: MapFeatureModes.landmarksTextured,
        MapFeatures.roadExitLabels: MapFeatureModes.roadExitLabelsAll,
        MapFeatures.terrain: MapFeatureModes.terrain3d
      });

      hereMapController.setWatermarkLocation(
        Anchor2D.withHorizontalAndVertical(0, 1),
        Point2D(
          -hereMapController.watermarkSize.width / 2,
          -hereMapController.watermarkSize.height / 2,
        ),
      );

      setTrafficLayersVisibilityOnMap(context, hereMapController);

      _addRouteToMap();
      // bool? result = await Dialogs.askForPositionSource(context);
      // if (result == null) {
      //   // Nothing answered. Go back.
      //   Navigator.of(context).pop();
      //   return;
      // }
      //
      // if (result) {
      //   _shouldMonitorPositioning = false;
      //   _startPositioning(
      //     context,
      //     simulated: true,
      //     options: Navigation.LocationSimulatorOptions()
      //       ..speedFactor = _kSpeedFactor
      //       ..notificationInterval = Duration(milliseconds: _kNotificationIntervalInMilliseconds),
      //   );
      // } else {
      _shouldMonitorPositioning = true;
      _initialiseUserPositioning();
      _startPositioning(context);
      // }

      // on realtime locations, and platform is Android,
      // check if battery saver is on, which might effect the
      // navigation
      // _checkDeviceBatteryStatus(context, isRealTimeNavigation: !result);
      _startNavigation();
      _addGestureListeners();
    }

    loadMapScene(hereMapController, mapSceneLoadSceneCallback);
  }

/*  /// Checks and shows the battery saver warning dialog, if realtime navigation is on
  /// Only for Platform Android
  Future<void> _checkDeviceBatteryStatus(BuildContext context, {required bool isRealTimeNavigation}) async {
    if (Platform.isAndroid && context.mounted && isRealTimeNavigation) {
      final bool result = await isBatterySaverOn();
      if (result) {
        showBatterySaverWarningDialog(context);
      }
    }
  }*/

  void _addGestureListeners() {
    _hereMapController.gestures.doubleTapListener = DoubleTapListener((origin) => _enableTracking(false));
    _hereMapController.gestures.panListener = PanListener((state, origin, translation, velocity) => _enableTracking(false));
    _hereMapController.gestures.pinchRotateListener =
        PinchRotateListener((state, pinchOrigin, rotationOrigin, twoFingerDistance, rotation) => _enableTracking(false));
    _hereMapController.gestures.twoFingerPanListener = TwoFingerPanListener((state, origin, translation, velocity) => _enableTracking(false));
    _hereMapController.gestures.twoFingerTapListener = TwoFingerTapListener((origin) => _enableTracking(false));
  }

  void _enableTracking(bool enable) {
    setState(() {
      _visualNavigator.cameraBehavior = enable ? Navigation.FixedCameraBehavior() : null;
      // _visualNavigator.cameraBehavior = Navigation.FixedCameraBehavior();
    });
  }

  void _addRouteToMap() {
    int markerSize = (_hereMapController.pixelScale * UIStyle.locationMarkerSize).round();
    _startMarker = createMarkerWithImagePath(
      _currentRoute.geometry.vertices.first,
      "assets/position.svg",
      markerSize,
      markerSize,
      drawOrder: UIStyle.waypointsMarkerDrawOrder,
    );
    _hereMapController.mapScene.addMapMarker(_startMarker);

    markerSize = (_hereMapController.pixelScale * UIStyle.searchMarkerSize * 2).round();
    _finishMarker = createMarkerWithImagePath(
      _currentRoute.geometry.vertices.last,
      "assets/map_marker_big.svg",
      markerSize,
      markerSize,
      drawOrder: UIStyle.waypointsMarkerDrawOrder,
      anchor: Anchor2D.withHorizontalAndVertical(0.5, 1),
    );
    _hereMapController.mapScene.addMapMarker(_finishMarker);

    _zoomToWholeRoute();
  }

  void _zoomToWholeRoute() {
    final BuildContext? context = _mapKey.currentContext;
    if (context != null) {
      _hereMapController.zoomToLogicalViewPort(geoBox: widget.route.boundingBox, context: context);
    }
  }

  void _startNavigation() {
    _hereMapController.mapScene.removeMapMarker(_startMarker);

    _visualNavigator.isOffRoadDestinationVisible = true;
    _visualNavigator.startRendering(_hereMapController);

    _setupListeners();
    _setupVoiceTextMessages();

    _visualNavigator.route = _currentRoute;

    setState(() {
      _navigationStarted = true;
    });

    getRemainingTime();
  }

  void _setupListeners() {
    _visualNavigator.routeProgressListener = Navigation.RouteProgressListener((routeProgress) {
      List<Navigation.SectionProgress> sectionProgressList = routeProgress.sectionProgress;

      int? currentManeuverIndex;
      int currentManeuverDistance = 0;
      int? nextManeuverIndex;
      int nextManeuverDistance = 0;

      List<Navigation.ManeuverProgress> nextManeuverList = routeProgress.maneuverProgress;
      if (nextManeuverList.isNotEmpty) {
        currentManeuverIndex = nextManeuverList.first.maneuverIndex;
        currentManeuverDistance = nextManeuverList.first.remainingDistanceInMeters;

        if (nextManeuverList.length > 1) {
          nextManeuverIndex = nextManeuverList[1].maneuverIndex;
          nextManeuverDistance = nextManeuverList[1].remainingDistanceInMeters;
        }
      }

      setState(() {
        _remainingDistanceInMeters = sectionProgressList.last.remainingDistanceInMeters;
        _remainingDurationInSeconds = sectionProgressList.last.remainingDuration.inSeconds;
        _remainingDurationInSeconds = sectionProgressList.last.remainingDuration.inSeconds;
        _trafficDelayDurationInSeconds = sectionProgressList.last.trafficDelay.inSeconds;

        _currentManeuverIndex = currentManeuverIndex;
        _currentManeuverDistance = currentManeuverDistance;
        _nextManeuverIndex = nextManeuverIndex;
        _nextManeuverDistance = nextManeuverDistance;
      });
    });

    _visualNavigator.navigableLocationListener = Navigation.NavigableLocationListener((location) {
      if (_currentSpeed != location.originalLocation.speedInMetersPerSecond) {
        setState(() {
          _currentSpeed = location.originalLocation.speedInMetersPerSecond;
        });
      }
    });

    _visualNavigator.roadTextsListener = Navigation.RoadTextsListener((roadTexts) {
      if (_currentStreetName != roadTexts.names.getDefaultValue()) {
        setState(() => _currentStreetName = roadTexts.names.getDefaultValue());
      }
    });

    if (_currentRoute.requestedTransportMode != Transport.TransportMode.pedestrian) {
      _visualNavigator.speedLimitListener = Navigation.SpeedLimitListener((speedLimit) {
        if (_currentSpeedLimit != speedLimit.effectiveSpeedLimitInMetersPerSecond()) {
          setState(() => _currentSpeedLimit = speedLimit.effectiveSpeedLimitInMetersPerSecond());
        }
      });

      final Navigation.SpeedLimitOffset offset = Navigation.SpeedLimitOffset()
        ..lowSpeedOffsetInMetersPerSecond = _kDefaultSpeedLimitOffset
        ..highSpeedOffsetInMetersPerSecond = _kDefaultSpeedLimitOffset
        ..highSpeedBoundaryInMetersPerSecond = _kDefaultSpeedLimitBoundary;
      _visualNavigator.speedWarningOptions = Navigation.SpeedWarningOptions(offset);
      _visualNavigator.speedWarningListener = Navigation.SpeedWarningListener((status) async {
        if (status == Navigation.SpeedWarningStatus.speedLimitExceeded) {
          // RingtonePlayer.play(android: Android.notification, ios: Ios.triTone);

          if (PreferencesHelper.instance.containsKey("speed_call")) {
            var dateTimeStr = PreferencesHelper.instance.getString("speed_call");
            var dateTime = DateTime.parse(dateTimeStr);

            if (DateTime.now().difference(dateTime).inMinutes > 30) {
              await _flutterTts.speak("You have crossed the speed limit, Drive slow");
              PreferencesHelper.instance.setString("speed_call", DateTime.now().toIso8601String());
            }
          } else {
            _flutterTts.speak("You have crossed the speed limit, Drive slow");
            PreferencesHelper.instance.setString("speed_call", DateTime.now().toIso8601String());
          }
        }
        setState(() => _speedWarningStatus = status);
      });
    }

    _visualNavigator.destinationReachedListener = Navigation.DestinationReachedListener(() {
      _stopNavigation();
      Navigator.pop(context, "playCheck");
    });

    _visualNavigator.routeDeviationListener = _reroutingHandler;
    _visualNavigator.milestoneStatusListener = _reroutingHandler;
  }

  void _setupVoiceTextMessages() async {
    await _flutterTts.setLanguage("en-US");

    _visualNavigator.eventTextListener = Navigation.EventTextListener((Navigation.EventText eventText) {
      if (eventText.type == Navigation.TextNotificationType.maneuver) {
        _flutterTts.speak(eventText.text);

        if (_appLifecycleState == AppLifecycleState.paused && _currentManeuverIndex != null) {
          Routing.Maneuver? maneuver = _visualNavigator.getManeuver(_currentManeuverIndex!);

          if (maneuver != null) {
            _notificationsManager.showNotification(_buildManeuverNotificationBody(maneuver, text: eventText.text));
          }
        }
      }
    });
  }

  NotificationBody _buildManeuverNotificationBody(Routing.Maneuver maneuver, {String? text}) {
    return NotificationBody(
      title: _getRemainingTimeString(),
      body: text ?? maneuver.getActionText(context),
      imagePath: maneuver.action.imagePath,
      presentSound: true,
    );
  }

  NotificationBody _buildNavigationStatusNotificationBody() {
    return NotificationBody(
      title: _navigationStatus() ?? _getRemainingTimeString(),
      body: '',
      imagePath: '',
      presentSound: true,
    );
  }

  String _getRemainingTimeString() {
    String arrivalInfo =
        "${AppLocalizations.of(context)!.arrivalTimeTitle}: ${DateFormat.Hm().format(DateTime.now().add(Duration(seconds: _remainingDurationInSeconds)))}";
    return arrivalInfo;
  }

  void _stopNavigation() {
    _visualNavigator.route = null;
    _servicesStatusNotifier?.stop();
    _visualNavigator.stopRendering();
    _locationProvider?.removeListeners();
    _locationProvider?.stop();
    _notificationsManager.dismissNotification();
  }

  void _onNewRoute(Routing.Route? newRoute) {
    if (newRoute == null) {
      // rerouting failed
      setState(() => _reroutingInProgress = false);
      return;
    }

    _visualNavigator.route = null;

    _currentRoute = newRoute;
    _remainingDistanceInMeters = _currentRoute.lengthInMeters;
    _remainingDurationInSeconds = _currentRoute.duration.inSeconds;
    _currentManeuverIndex = null;
    _nextManeuverIndex = null;
    _currentManeuverDistance = 0;
    _visualNavigator.route = _currentRoute;
    _finishMarker.coordinates = newRoute.geometry.vertices.last;

    setState(() => _reroutingInProgress = false);
    _showNotification();
  }

  void _showNotification() {
    // if navigation is not started yet or app is not in background,
    // we will not show notification.
    // we will cancel notification that displayed already.
    if (!_navigationStarted || !_canShowNotification) {
      _notificationsManager.dismissNotification();
      return;
    }
    if (_navigationStatus() != null) {
      _notificationsManager.showNotification(_buildNavigationStatusNotificationBody());
    } else if (_currentManeuverIndex != null) {
      final Routing.Maneuver? maneuver = _visualNavigator.getManeuver(_currentManeuverIndex!);
      if (maneuver != null) {
        _notificationsManager.showNotification(_buildManeuverNotificationBody(maneuver));
      }
    }
  }

  String? _navigationStatus() {
    if (_shouldMonitorPositioning && !_canLocateUserPosition) {
      return AppLocalizations.of(context)!.locationWaitingForPositioning;
    } else if (_reroutingInProgress) {
      return AppLocalizations.of(context)!.navigationStatusRerouting;
    } else if (_currentManeuverIndex == null) {
      return AppLocalizations.of(context)!.navigationStatusWaitingForManeuvers;
    } else {
      return null;
    }
  }

  PreferredSize? _buildTopBar(BuildContext context) {
    if (!_navigationStarted) {
      return null;
    }

    Widget child;
    if (_navigationStatus() != null) {
      child = ReroutingIndicator(title: _navigationStatus()!);
    } else {
      Routing.Maneuver? maneuver = _visualNavigator.getManeuver(_currentManeuverIndex!);
      if (maneuver == null) {
        return null;
      }

      child = CurrentManeuver(
        action: maneuver.action,
        distance: _currentManeuverDistance,
        text: maneuver.getActionText(context),
      );
    }

    return PreferredSize(
      preferredSize: Size.fromHeight(_kTopBarHeight),
      child: AppBar(
        shape: UIStyle.bottomRoundedBorder(),
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        flexibleSpace: SafeArea(
          child: child,
        ),
      ),
    );
  }

  Widget? _buildNextManeuver(BuildContext context) {
    if (_currentManeuverDistance > _kDistanceToShowNextManeuver || _reroutingInProgress) {
      return null;
    }

    Routing.Maneuver? maneuver = _nextManeuverIndex != null ? _visualNavigator.getManeuver(_nextManeuverIndex!) : null;
    if (maneuver == null) {
      return null;
    }

    Routing.ManeuverAction action = maneuver.action;
    String text = maneuver.getActionText(context);

    return Align(
      alignment: Alignment.topCenter,
      child: Material(
        color: AppColors.getPrimaryColor(context),
        shape: UIStyle.bottomRoundedBorder(),
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.only(
            top: UIStyle.popupsBorderRadius,
          ),
          child: NextManeuver(
            action: action,
            distance: _nextManeuverDistance,
            text: text,
          ),
        ),
      ),
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_visualNavigator.cameraBehavior == null)
          Padding(
            padding: EdgeInsets.only(bottom: UIStyle.contentMarginLarge),
            child: FloatingActionButton(
              heroTag: null,
              backgroundColor: Theme.of(context).colorScheme.surface,
              onPressed: () {
                _enableTracking(true);
              },
              child: Icon(
                Icons.videocam,
                color: AppColors.blackWhiteText(context),
              ),
            ),
          ),
        Container(
          height: UIStyle.contentMarginLarge,
        ),
        if (_visualNavigator.route != null)
          SizedBox(
            height: 48,
            width: 48,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Image.asset(
                  "assets/images/weather_box.png",
                  height: 48,
                  width: 48,
                ),
                Lottie.asset("assets/lottie/weather_anim.json", fit: BoxFit.cover, height: 64, width: 64),
              ],
            ),
          ).onTap(() {
            getCurrentWeather();
          })
        // FloatingActionButton(
        //   heroTag: null,
        //   backgroundColor: UIStyle.stopNavigationButtonColor,
        //   onPressed: () async {
        //
        //   },
        //   child: Icon(
        //     Icons.close,
        //     color: UIStyle.stopNavigationButtonIconColor,
        //   ),
        // ),
      ],
    );
  }

  void _setupLogoAndPrincipalPointPosition() {
    final int margin = _currentStreetName != null ? (_kHereLogoOffset * _hereMapController.pixelScale).truncate() : 0;

    _hereMapController.setWatermarkLocation(
      Anchor2D.withHorizontalAndVertical(0.5, 1),
      Point2D(0, -(_hereMapController.watermarkSize.height / 2) - margin),
    );

    _hereMapController.camera.principalPoint = Point2D(
        _hereMapController.viewportSize.width / 2, _hereMapController.viewportSize.height - _kPrincipalPointOffset * _hereMapController.pixelScale);
  }

  Widget _buildNavigationControls(BuildContext context) {
    _setupLogoAndPrincipalPointPosition();

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(UIStyle.contentMarginLarge, UIStyle.contentMarginLarge, UIStyle.contentMarginLarge,
            UIStyle.contentMarginLarge + UIStyle.popupsBorderRadius),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.max,
          children: [
            if (_currentSpeed != null)
              NavigationSpeed(
                currentSpeed: _currentSpeed!,
                speedLimit: _currentSpeedLimit,
                speedWarningStatus: _speedWarningStatus,
              ),
            if (_currentStreetName == null) Spacer(),
            if (_currentStreetName != null)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: UIStyle.contentMarginLarge,
                    right: UIStyle.contentMarginLarge,
                  ),
                  child: Material(
                    elevation: 2,
                    color: AppColors.whiteBlacktext(context),
                    borderRadius: BorderRadius.circular(UIStyle.bigButtonHeight),
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: UIStyle.contentMarginMedium,
                        right: UIStyle.contentMarginMedium,
                      ),
                      child: SizedBox(
                        height: UIStyle.bigButtonHeight,
                        child: Center(
                          child: MarqueeWidget(
                            child: Text(
                              _currentStreetName!,
                              style: TextStyle(
                                fontSize: UIStyle.hugeFontSize,
                                color: AppColors.blackWhiteText(context),
                              ),
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            _buildButtons(context),
          ],
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_navigationStarted) {
      return;
    }
    _appLifecycleState = state;

    if (state == AppLifecycleState.paused) {
      // start notifications.
      _showNotification();
      _visualNavigator.stopRendering();
    }
    if (state == AppLifecycleState.resumed) {
      _notificationsManager.dismissNotification();
      SchedulerBinding.instance.addPostFrameCallback(
        (timeStamp) => _visualNavigator.startRendering(_hereMapController),
      );
    }
    if (state == AppLifecycleState.detached) {
      _notificationsManager.dismissNotification();
      _stopNavigation();
      Navigator.pop(context);
    }
  }

  @override
  void didDevicePositioningStatusUpdated({
    required bool isPositioningAvailable,
    required bool hasPermissionsGranted,
  }) {
    if (mounted) {
      setState(() {
        _canLocateUserPosition = isPositioningAvailable && hasPermissionsGranted;
        _startPositioning(context);
      });
    }
  }

  void _initialiseUserPositioning() {
    _servicesStatusNotifier = DeviceLocationServicesStatusNotifier();
    _servicesStatusNotifier!.start(this);
    _servicesStatusNotifier!.canLocateUserPositioning().then((value) {
      setState(() => _canLocateUserPosition = value);
    });
  }

  Future<void> _startPositioning(
    BuildContext context, {
    bool simulated = false,
    Navigation.LocationSimulatorOptions? options,
  }) async {
    _locationProvider = createLocationProvider(
      route: widget.route,
      simulated: simulated,
      simulatorOptions: options,
    );
    _locationProvider?.addListener(this);
    _locationProvider?.addListener(_visualNavigator);
    _locationProvider?.start();
  }

  @override
  void onLocationUpdated(Location location) {
    if (_currentLocationForLocationStatus == null) {
      _currentLocationForLocationStatus = location;
      _servicesStatusNotifier?.onLocationReceived(location);
    }
  }

  Future<void> _getWeatherInfo(Routing.Route route) async {
    debugPrint("Processing ${route.geometry.vertices.length}");

    if (widget.stop == null) {
      return;
    }

    if (PreferencesHelper.instance.containsKey(widget.stop!.id.toString())) {
      var lastHitTimeStr = PreferencesHelper.instance.getString("${widget.stop!.id.toString()}_time");
      var lastHitTime = DateTime.parse(lastHitTimeStr);
      if (DateTime.now().difference(lastHitTime).inMinutes < 30) {
        var res = PreferencesHelper.instance.getString(widget.stop!.id.toString());
        var cityRes = PreferencesHelper.instance.getString("${widget.stop!.id.toString()}_cities");
        var weatherData = jsonDecode(res);
        var citiesData = jsonDecode(cityRes);
        var weatherInfo = List<GetWeatherDataModel>.from(weatherData.map((x) => GetWeatherDataModel.fromJson(x)));
        var cities = List<CityItem>.from(citiesData.map((x) => CityItem.fromJson(x)));
        handleWeatherData(weatherInfo, cities);
        return;
      }
    }

    var startTime = DateTime.now();
    final List<CityItem> cities = await Isolate.run<List<CityItem>>(() async {
      await ApiService.init();
      var cities = await WeatherHelper().getCitiesInRoute(route.geometry.vertices);
      return cities;
    });
    var endTine = DateTime.now();

    debugPrint("Cities found : ${cities.length} in ${endTine.difference(startTime)}");

    final List<GetWeatherDataModel> weatherInfo = await Isolate.run<List<GetWeatherDataModel>>(() async {
      await ApiService.init();

      List<GetWeatherDataModel> weathers = [];

      for (var city in cities) {
        var res = await WeatherHelper().fetchWeather(city.location);
        if (res != null) weathers.add(res);
        await Future.delayed(Duration(seconds: 1));
      }

      return weathers;
    });

    if (weatherInfo.isNotEmpty) {
      await PreferencesHelper.instance.setString(widget.stop!.id.toString(), jsonEncode(weatherInfo));
      await PreferencesHelper.instance.setString("${widget.stop!.id.toString()}_cities", jsonEncode(cities));
      await PreferencesHelper.instance.setString("${widget.stop!.id.toString()}_time", DateTime.now().toIso8601String());
      handleWeatherData(weatherInfo, cities);
    }
  }

  void handleWeatherData(List<GetWeatherDataModel> weatherInfo, List<CityItem> cities) {
    var weatherHelper = WeatherHelper();
    GetWeatherDataModel? weatherToShow;
    for (var data in weatherInfo) {
      if (weatherHelper.isDanger(weatherHelper.getWeatherConditionByCode(data.weather.first.id))) {
        weatherToShow = data;
        break;
      }
    }

    // TODO fix the issue where location was null
    if (weatherToShow != null) {
      print(weatherToShow!.name);
      cities.forEach((data) {
        print("City ${data.city}, has ${data.location.latitude}, ${data.location.longitude}");
      });
      var cityItem = cities.firstWhereOrNull((item) => item.location == GeoCoordinates(weatherToShow!.coord.lat, weatherToShow.coord.lon));
      print("Weather Lat lng ${weatherToShow!.coord.lat}, ${weatherToShow.coord.lon}");
      print(cityItem == null);
      weatherItem = WeatherItem(cityItem, weatherToShow);
      setState(() {});
    } else {
      debugPrint("No danger weather location found");
    }
  }

  getCurrentWeather() async {
    LoaderDialog().show(context, "Fetching current weather");

    var cityItem = await WeatherHelper().getCityDetail(currentLocation.value);
    var weatherData = await WeatherHelper().fetchWeather(currentLocation.value);

    LoaderDialog().hide();

    var weatherItem = WeatherItem(cityItem, weatherData);
    showWeatherDetail = true;
    setState(() {});
    buildLargeWeatherCard(weatherItem);
  }

  buildSmallWeatherCard() {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: 80.w,
        margin: EdgeInsets.only(top: 24),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              "assets/images/weather_card_small_light.png",
              width: 80.w,
              height: 10.h,
              fit: BoxFit.cover,
            ).cornerRadiusWithClipRRect(16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        WeatherHelper().getWeatherIcon(WeatherHelper().getWeatherConditionByCode(weatherItem!.weatherData!.weather.first.id)),
                        height: 48,
                        width: 48,
                      ),
                      16.width,
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            weatherItem?.weatherData?.weather.first.main ?? "-",
                            style: AppTextStyles.textBodySemiBold.copyWith(color: AppColors.whiteBlacktext(context)),
                          ),
                          Text(
                            convertToCelsiusFromKelvin(weatherItem?.weatherData?.main.temp ?? 0.0),
                            style: AppTextStyles.textSmallTitleBold.copyWith(color: AppColors.whiteBlacktext(context)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            color: AppColors.getPrimaryColor(context),
                          ),
                          SizedBox(
                            width: 25.w,
                            child: Text(
                              weatherItem?.cityItem?.city ?? "-",
                              style: AppTextStyles.textSmallBold.copyWith(color: AppColors.whiteBlacktext(context)),
                            ),
                          )
                        ],
                      ),
                      12.height,
                      if (weatherItem?.cityItem != null)
                        Text(
                          "(${VincentyDistance.calculateDistance(currentLocation.value.latitude, currentLocation.value.longitude, weatherItem!.cityItem!.location.latitude, weatherItem!.cityItem!.location.longitude).toStringAsFixed(2)} miles)",
                          style: AppTextStyles.textSmallNormal.copyWith(color: AppColors.whiteBlacktext(context), fontSize: 15.sp),
                        )
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ).onTap(() {
        setState(() {
          showWeatherDetail = true;
        });
        buildLargeWeatherCard(weatherItem!);
      }),
    );
  }

  buildLargeWeatherCard(WeatherItem weatherItem) async {
    await showDialog(
        context: context,
        barrierColor: Colors.transparent,
        builder: (context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: SizedBox(
              width: 80.w,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    "assets/images/weather_card_large_light.png",
                    width: 80.w,
                    height: 40.h,
                    fit: BoxFit.fill,
                  ).cornerRadiusWithClipRRect(16),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      height: 40.h,
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_rounded,
                                      color: AppColors.getPrimaryColor(context),
                                    ),
                                    8.width,
                                    SizedBox(
                                      width: 30.w,
                                      child: Text(
                                        weatherItem.cityItem?.city ?? "-",
                                        style: AppTextStyles.textSmallSemiBold.copyWith(color: AppColors.whiteBlacktext(context)),
                                      ),
                                    )
                                  ],
                                ),
                                Text(
                                  "(${VincentyDistance.calculateDistance(currentLocation.value.latitude, currentLocation.value.longitude, weatherItem.cityItem!.location.latitude, weatherItem.cityItem!.location.longitude).toStringAsFixed(2)} miles)",
                                  style: AppTextStyles.textSmallSemiBold.copyWith(color: AppColors.whiteBlacktext(context)),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              Image.asset(
                                WeatherHelper().getWeatherIcon(WeatherHelper().getWeatherConditionByCode(weatherItem.weatherData!.weather.first.id)),
                                height: 100,
                                width: 100,
                              ),
                              12.height,
                              Text(
                                convertToCelsiusFromKelvin(
                                  weatherItem.weatherData?.main.temp ?? 0.0,
                                ),
                                style: AppTextStyles.textSmallTitleBold.copyWith(color: AppColors.whiteBlacktext(context)),
                              ),
                              12.height,
                              Text(
                                weatherItem.weatherData?.weather.first.main ?? "-",
                                style: AppTextStyles.textBodySemiBold.copyWith(color: AppColors.whiteBlacktext(context)),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.air,
                                      color: Colors.white,
                                      size: 36,
                                    ),
                                    8.width,
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${weatherItem.weatherData!.wind.speed} KM/H",
                                          style: AppTextStyles.textBodyBold.copyWith(color: AppColors.whiteBlacktext(context)),
                                        ),
                                        Text(
                                          "Wind",
                                          style: AppTextStyles.textSmallNormal.copyWith(color: AppColors.whiteBlacktext(context)),
                                        )
                                      ],
                                    )
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.water_drop,
                                      color: Colors.white,
                                      size: 36,
                                    ),
                                    8.width,
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${weatherItem.weatherData!.main.humidity} %",
                                          style: AppTextStyles.textBodyBold.copyWith(color: AppColors.whiteBlacktext(context)),
                                        ),
                                        Text(
                                          "Humidity",
                                          style: AppTextStyles.textSmallNormal.copyWith(color: AppColors.whiteBlacktext(context)),
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
    setState(() {
      showWeatherDetail = false;
    });
  }

  Future<void> getRemainingTime() async {
    if (widget.stop == null) {
      return;
    }

    var timeToReach = Duration(seconds: _remainingDurationInSeconds);

    var targetTime = DateTime.parse(widget.stop!.stopDateTime).toLocal();
    var currentTime = DateTime.now();

    // Calculate the time difference (targetTime - currentTime)
    var data = targetTime.difference(currentTime);

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

  reRouteToNewLocation(GeoCoordinates geoCoordinates) {
    Navigator.pop(context);
    LoaderDialog().show(context, "Calculating new route");
    List<Waypoint> wayPoints = [currentLocation.value, geoCoordinates].map((coord) {
      return Waypoint.withDefaults(coord);
    }).toList();

    routingEngine.calculateTruckRoute(wayPoints, TruckOptions(), (error, routing) {
      if (error == null) {
        LoaderDialog().hide();
        var route = routing!.first;
        _onNewRoute(route);
      } else {
        debugPrint("Error in Here map is ${error.toString()}");
      }
    });
  }
}

extension _ManeuverImagePath on Routing.ManeuverAction {
  String get imagePath {
    final String subDir = PlatformDispatcher.instance.platformBrightness == Brightness.light ? "dark" : "light";
    return "assets/maneuvers/$subDir/png/${toString().split(".").last}.png";
  }
}

/// An extension for the [HereMapController].
extension LogicalCoords on HereMapController {
  /// Zooms map area specified by [geoBox] into [viewPort] with [margin].
  void zoomGeoBoxToLogicalViewPort({
    required GeoBox geoBox,
    required Rect viewPort,
    double margin = UIStyle.contentMarginExtraHuge,
  }) {
    camera.lookAtAreaWithGeoOrientationAndViewRectangle(
        geoBox,
        GeoOrientationUpdate(double.nan, double.nan),
        Rectangle2D(
            Point2D(viewPort.left + margin, viewPort.top + margin),
            Size2D(
              (viewPort.width - margin * 2) * pixelScale,
              (viewPort.height - margin * 2) * pixelScale,
            )));
  }

  /// Zooms map area specified by [geoBox] into entire map area.
  void zoomToLogicalViewPort({
    required GeoBox geoBox,
    required BuildContext context,
  }) {
    final RenderBox box = context.findRenderObject() as RenderBox;

    zoomGeoBoxToLogicalViewPort(
      geoBox: geoBox,
      viewPort: Rect.fromLTRB(0, MediaQuery.of(context).padding.top, box.size.width, box.size.height).deflate(UIStyle.locationMarkerSize.toDouble()),
    );
  }
}
