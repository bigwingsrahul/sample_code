import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/routing.dart' hide Route;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:pdfx/pdfx.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:techtruckers/config/theme/app_colors.dart';
import 'package:techtruckers/config/theme/app_text_styles.dart';
import 'package:techtruckers/config/helpers/preferences_helper.dart';
import 'package:techtruckers/features/auth/views/login_screen.dart';
import 'package:techtruckers/main.dart';

int toastCount = 0;

String getNormalDate(now){
  var dateData = now is String ? now : now.toString();
  String formattedDate = DateFormat('MM-dd-yyyy').format(DateTime.parse(dateData));
  return formattedDate;
}

void showToast(BuildContext context, String text, bool isError) {

  if(text.isEmpty || text == "Session Expired") {
    return;
  }

  var snackBar = SnackBar(
      backgroundColor: isError ? AppColors.appRedColor : AppColors.appGreenColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8)
      ),
      padding: EdgeInsets.all(8),
      margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.8, left: 32, right: 32),
      content: Row(
        children: [
          Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white,),
          8.width,
          Text(text, style: boldTextStyle(color: Colors.white), maxLines: 3, overflow: TextOverflow.ellipsis,).expand(),
        ],
      ));
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}


Future<dynamic> navigate(BuildContext context, Widget destination, bool isReplacement) async {
  if(isReplacement) {
    var res = await Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => destination));
    return res;
  }else{
    var res = await Navigator.push(context, MaterialPageRoute(builder: (context) => destination));
    return res;
  }
}

navigateWithNoStack(BuildContext context, Widget destination){
  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => destination), (Route<dynamic> route) => false,);
}

extension ToggleExtension on bool {
  bool toggle() => !this;
}

void callBloc(void bloc) {
  bloc;
}

logoutUser(BuildContext context) {
  // showToast(context, "Session Expired, Please login again", true);
  PreferencesHelper.instance.clear();
  navigateWithNoStack(context, LoginScreen());
}

AppBar getAppBar(bool hasDrawer, BuildContext context, {String titleText = "", PreferredSizeWidget? bottomWidget, bool? showNotifIcon}) {
  return AppBar(
    elevation: 2,
    backgroundColor: AppColors.appbarBgColor(context),
    iconTheme: IconThemeData(color: AppColors.isDark(context) ? Colors.white : AppColors.colorPrimary, size: 30),
    title: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(),
        Text(
          titleText,
          style: AppTextStyles.textBodyBold.copyWith(
            color: AppColors.isDark(context) ? Colors.white : AppColors.colorPrimary,
          ),
        ),
        (showNotifIcon ?? true) ? GestureDetector(
            onTap: () {
            },
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                Icon(
                  Icons.notifications,
                  size: 30,
                ),
                ValueListenableBuilder(valueListenable: newNotif, builder: (context, value, child) {
                  return Visibility(
                    visible: value,
                    child: Positioned(
                      top: 2,
                      right: 2,
                      child: Container(
                        height: 12,
                        width: 12,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(1000),
                            color: AppColors.appRedColor
                        ),
                      ),
                    ),
                  );
                })
              ],
            )
        ) : SizedBox()
      ],
    ),
    bottom: bottomWidget,
  );
}

String convertToHours(int seconds) {
  double hours = seconds / 3600;
  return hours.toStringAsFixed(1);
}

double metersToMiles(int meters) {
  const double metersInOneMile = 1609.344;
  return meters / metersInOneMile;
}

String formatDuration(int seconds) {
  // Calculate hours, minutes, and remaining seconds
  int hours = seconds ~/ 3600;
  seconds = seconds % 3600;
  int minutes = seconds ~/ 60;
  seconds = seconds % 60;

  // Construct the formatted duration string
  String formattedDuration = '';
  if (hours > 0) {
    formattedDuration += '$hours hrs ';
  }
  if (minutes > 0 || hours > 0) {
    formattedDuration += '$minutes mins';
  }

  if(minutes == 0 && hours == 0 && seconds > 0) {
    formattedDuration = '$seconds secs';
  }

  return formattedDuration.trim();
}

String formatDurationComplete(int seconds) {
  // Constants for time units
  const int secondsInDay = 86400; // 24 hours * 60 minutes * 60 seconds
  const int secondsInHour = 3600; // 60 minutes * 60 seconds
  const int secondsInMinute = 60; // 60 seconds

  // Calculate number of days, hours, minutes, and seconds
  int days = seconds ~/ secondsInDay;
  seconds = seconds % secondsInDay;

  int hours = seconds ~/ secondsInHour;
  seconds = seconds % secondsInHour;

  int minutes = seconds ~/ secondsInMinute;
  seconds = seconds % secondsInMinute;

  // Construct the formatted duration string
  String formattedDuration = '';

  if (days > 0) {
    formattedDuration += '$days day${days > 1 ? 's' : ''} ';
  }
  if (hours > 0) {
    formattedDuration += '$hours hr${hours > 1 ? 's' : ''} ';
  }
  if (minutes > 0 || hours > 0 || days > 0) {
    formattedDuration += '$minutes min${minutes > 1 ? 's' : ''}';
  }
  if (minutes == 0 && hours == 0 && days == 0 && seconds > 0) {
    formattedDuration = '$seconds sec${seconds > 1 ? 's' : ''}';
  }

  return formattedDuration.trim();
}

String formatDistance(int distanceInMeters) {
  if (distanceInMeters >= 1000) {
    final distanceInKm = distanceInMeters / 1000;
    return '${distanceInKm.toStringAsFixed(1)} km';  // Format to 1 decimal place for km
  } else {
    return '${distanceInMeters.toStringAsFixed(0)} m';  // Format to no decimal places for meters
  }
}

const double _earthRadius = 6371.0; // Radius of the Earth in kilometers

/// Calculate the distance between two latitude and longitude points using the Haversine formula.
///
/// [originLat] and [originLng] are the latitude and longitude of the starting point.
/// [destLat] and [destLng] are the latitude and longitude of the destination point.
double calculateDistance({
  required double originLat,
  required double originLng,
  required double destLat,
  required double destLng,
}) {
  // Convert degrees to radians
  double originLatRad = _toRadians(originLat);
  double originLngRad = _toRadians(originLng);
  double destLatRad = _toRadians(destLat);
  double destLngRad = _toRadians(destLng);

  // Difference in coordinates
  double dLat = destLatRad - originLatRad;
  double dLng = destLngRad - originLngRad;

  // Haversine formula
  double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(originLatRad) * cos(destLatRad) *
          sin(dLng / 2) * sin(dLng / 2);
  double c = 2 * atan2(sqrt(a), sqrt(1 - a));

  // Distance in kilometers
  double distance = _earthRadius * c;

  return distance;
}

/// Convert degrees to radians.
double _toRadians(double degrees) {
  return degrees * (pi / 180.0);
}

String getFormattedDate(String format, DateTime date, bool convertToLocal) {
  return DateFormat(format).format(convertToLocal ? date.toLocal() : date);
}

String convertToCelsiusFromKelvin(double temp) {
  try {
    double celsius = temp - 273.15;
    return '${celsius.ceil()}°C';
  } catch (e) {
    debugPrint(e.toString());
    return "";
  }
}

String getIconName(ManeuverAction action) {
  switch (action) {
    case ManeuverAction.depart:
      return 'depart.svg';
    case ManeuverAction.arrive:
      return 'arrive.svg';
    case ManeuverAction.leftUTurn:
      return 'left-u-turn.svg';
    case ManeuverAction.sharpLeftTurn:
      return 'sharp-left-turn.svg';
    case ManeuverAction.leftTurn:
      return 'left-turn.svg';
    case ManeuverAction.slightLeftTurn:
      return 'slight-left-turn.svg';
    case ManeuverAction.continueOn:
      return 'continue-on.svg';
    case ManeuverAction.slightRightTurn:
      return 'slight-right-turn.svg';
    case ManeuverAction.rightTurn:
      return 'right-turn.svg';
    case ManeuverAction.sharpRightTurn:
      return 'sharp-right-turn.svg';
    case ManeuverAction.rightUTurn:
      return 'right-u-turn.svg';
    case ManeuverAction.leftExit:
      return 'left-exit.svg';
    case ManeuverAction.rightExit:
      return 'right-exit.svg';
    case ManeuverAction.leftRamp:
      return 'left-ramp.svg';
    case ManeuverAction.rightRamp:
      return 'right-ramp.svg';
    case ManeuverAction.leftFork:
      return 'left-fork.svg';
    case ManeuverAction.middleFork:
      return 'middle-fork.svg';
    case ManeuverAction.rightFork:
      return 'right-fork.svg';
    case ManeuverAction.enterHighwayFromLeft:
      return 'enter-highway-left.svg';
    case ManeuverAction.enterHighwayFromRight:
      return 'enter-highway-right.svg';
    case ManeuverAction.leftRoundaboutEnter:
      return 'left-roundabout-enter.svg';
    case ManeuverAction.rightRoundaboutEnter:
      return 'right-roundabout-enter.svg';
    case ManeuverAction.leftRoundaboutPass:
      return 'left-roundabout-pass.svg';
    case ManeuverAction.rightRoundaboutPass:
      return 'right-roundabout-pass.svg';
    case ManeuverAction.leftRoundaboutExit1:
      return 'left-roundabout-exit1.svg';
    case ManeuverAction.leftRoundaboutExit2:
      return 'left-roundabout-exit2.svg';
    case ManeuverAction.leftRoundaboutExit3:
      return 'left-roundabout-exit3.svg';
    case ManeuverAction.leftRoundaboutExit4:
      return 'left-roundabout-exit4.svg';
    case ManeuverAction.leftRoundaboutExit5:
      return 'left-roundabout-exit5.svg';
    case ManeuverAction.leftRoundaboutExit6:
      return 'left-roundabout-exit6.svg';
    case ManeuverAction.leftRoundaboutExit7:
      return 'left-roundabout-exit7.svg';
    case ManeuverAction.leftRoundaboutExit8:
      return 'left-roundabout-exit8.svg';
    case ManeuverAction.leftRoundaboutExit9:
      return 'left-roundabout-exit9.svg';
    case ManeuverAction.leftRoundaboutExit10:
      return 'left-roundabout-exit10.svg';
    case ManeuverAction.leftRoundaboutExit11:
      return 'left-roundabout-exit11.svg';
    case ManeuverAction.leftRoundaboutExit12:
      return 'left-roundabout-exit12.svg';
    case ManeuverAction.rightRoundaboutExit1:
      return 'right-roundabout-exit1.svg';
    case ManeuverAction.rightRoundaboutExit2:
      return 'right-roundabout-exit2.svg';
    case ManeuverAction.rightRoundaboutExit3:
      return 'right-roundabout-exit3.svg';
    case ManeuverAction.rightRoundaboutExit4:
      return 'right-roundabout-exit4.svg';
    case ManeuverAction.rightRoundaboutExit5:
      return 'right-roundabout-exit5.svg';
    case ManeuverAction.rightRoundaboutExit6:
      return 'right-roundabout-exit6.svg';
    case ManeuverAction.rightRoundaboutExit7:
      return 'right-roundabout-exit7.svg';
    case ManeuverAction.rightRoundaboutExit8:
      return 'right-roundabout-exit8.svg';
    case ManeuverAction.rightRoundaboutExit9:
      return 'right-roundabout-exit9.svg';
    case ManeuverAction.rightRoundaboutExit10:
      return 'right-roundabout-exit10.svg';
    case ManeuverAction.rightRoundaboutExit11:
      return 'right-roundabout-exit11.svg';
    case ManeuverAction.rightRoundaboutExit12:
      return 'right-roundabout-exit12.svg';
  }
}

String ordinalSuffix(int number) {
  if (!(number >= 1 && number <= 31)) return '';

  if (number % 10 == 1 && number % 100 != 11) return 'st';
  if (number % 10 == 2 && number % 100 != 12) return 'nd';
  if (number % 10 == 3 && number % 100 != 13) return 'rd';
  return 'th';
}

String getManeuverMessage(ManeuverAction action, String roadName, int remainingDistanceInMeters) {
  // Define the base message map
  final Map<ManeuverAction, String> messageMap = {
    ManeuverAction.depart: 'Head towards',
    ManeuverAction.arrive: 'You have reached your destination/waypoint',
    ManeuverAction.leftUTurn: 'Make a U-turn',
    ManeuverAction.sharpLeftTurn: 'Turn sharply left',
    ManeuverAction.leftTurn: 'Turn left',
    ManeuverAction.slightLeftTurn: 'Turn slightly left',
    ManeuverAction.continueOn: 'Continue straight ahead',
    ManeuverAction.slightRightTurn: 'Turn slightly right',
    ManeuverAction.rightTurn: 'Turn right',
    ManeuverAction.sharpRightTurn: 'Turn sharply right',
    ManeuverAction.rightUTurn: 'Make a U-turn',
    ManeuverAction.leftExit: 'Take the exit',
    ManeuverAction.rightExit: 'Take the exit',
    ManeuverAction.leftRamp: 'Join the highway',
    ManeuverAction.rightRamp: 'Join the highway',
    ManeuverAction.leftFork: 'Keep left',
    ManeuverAction.middleFork: 'Keep middle',
    ManeuverAction.rightFork: 'Keep right',
    ManeuverAction.enterHighwayFromLeft:
    'Merge onto the highway from the left',
    ManeuverAction.enterHighwayFromRight:
    'Merge onto the highway from the right',
    ManeuverAction.leftRoundaboutEnter: 'Enter the roundabout',
    ManeuverAction.rightRoundaboutEnter: 'Enter the roundabout',
    ManeuverAction.leftRoundaboutPass: 'Pass the roundabout',
    ManeuverAction.rightRoundaboutPass: 'Pass the roundabout',
  };

  // Generate roundabout exit messages
  final Map<ManeuverAction, String> roundaboutExitMessages = {
    ManeuverAction.leftRoundaboutExit1: 'Take the 1st exit at the roundabout',
    ManeuverAction.leftRoundaboutExit2: 'Take the 2nd exit at the roundabout',
    ManeuverAction.leftRoundaboutExit3: 'Take the 3rd exit at the roundabout',
    ManeuverAction.leftRoundaboutExit4: 'Take the 4th exit at the roundabout',
    ManeuverAction.leftRoundaboutExit5: 'Take the 5th exit at the roundabout',
    ManeuverAction.leftRoundaboutExit6: 'Take the 6th exit at the roundabout',
    ManeuverAction.leftRoundaboutExit7: 'Take the 7th exit at the roundabout',
    ManeuverAction.leftRoundaboutExit8: 'Take the 8th exit at the roundabout',
    ManeuverAction.leftRoundaboutExit9: 'Take the 9th exit at the roundabout',
    ManeuverAction.leftRoundaboutExit10:
    'Take the 10th exit at the roundabout',
    ManeuverAction.leftRoundaboutExit11:
    'Take the 11th exit at the roundabout',
    ManeuverAction.leftRoundaboutExit12:
    'Take the 12th exit at the roundabout',
    ManeuverAction.rightRoundaboutExit1:
    'Take the 1st exit at the roundabout',
    ManeuverAction.rightRoundaboutExit2:
    'Take the 2nd exit at the roundabout',
    ManeuverAction.rightRoundaboutExit3:
    'Take the 3rd exit at the roundabout',
    ManeuverAction.rightRoundaboutExit4:
    'Take the 4th exit at the roundabout',
    ManeuverAction.rightRoundaboutExit5:
    'Take the 5th exit at the roundabout',
    ManeuverAction.rightRoundaboutExit6:
    'Take the 6th exit at the roundabout',
    ManeuverAction.rightRoundaboutExit7:
    'Take the 7th exit at the roundabout',
    ManeuverAction.rightRoundaboutExit8:
    'Take the 8th exit at the roundabout',
    ManeuverAction.rightRoundaboutExit9:
    'Take the 9th exit at the roundabout',
    ManeuverAction.rightRoundaboutExit10:
    'Take the 10th exit at the roundabout',
    ManeuverAction.rightRoundaboutExit11:
    'Take the 11th exit at the roundabout',
    ManeuverAction.rightRoundaboutExit12:
    'Take the 12th exit at the roundabout',
  };

  // Merge the maps
  final completeMessageMap = {}
    ..addAll(messageMap)
    ..addAll(roundaboutExitMessages);

  // Get the base message from the map
  final baseMessage = completeMessageMap[action] ?? 'Unknown maneuver';

  // Format the final message
  return '$baseMessage on $roadName in ${formatDistance(remainingDistanceInMeters)}.';
  // return '$baseMessage on $roadName';
}

const String _placeholderPattern = '({{([a-zA-Z0-9]+)}})';

/// Returns a formatted string constructed from a [template] and a list of [replacements].
String formatString(String template, List replacements) {
  final regExp = RegExp(_placeholderPattern);
  assert(
  regExp.allMatches(template).length == replacements.length, "Template and Replacements length are incompatible");

  for (final replacement in replacements) {
    template = template.replaceFirst(regExp, replacement.toString());
  }

  return template;
}

/// Creates [MapMarker] in [coordinates] using an image at [imagePath], with [width], [height], [drawOrder]
/// and [anchor].
MapMarker createMarkerWithImagePath(
    GeoCoordinates coordinates,
    String imagePath,
    int width,
    int height, {
      int? drawOrder,
      Anchor2D? anchor,
    }) {
  MapImage mapImage = MapImage.withFilePathAndWidthAndHeight(imagePath, width, height);
  MapMarker mapMarker = createMarkerWithImage(coordinates, mapImage, drawOrder: drawOrder, anchor: anchor);
  return mapMarker;
}

/// Creates [MapMarker] in [coordinates] using an [image], [drawOrder] and [anchor].
MapMarker createMarkerWithImage(
    GeoCoordinates coordinates,
    MapImage image, {
      int? drawOrder,
      Anchor2D? anchor,
    }) {
  MapMarker mapMarker = MapMarker(coordinates, image);
  if (drawOrder != null) {
    mapMarker.drawOrder = drawOrder;
  }
  if (anchor != null) {
    mapMarker.anchor = anchor;
  }

  return mapMarker;
}

/// Function loads map scene using custom map style defined in [CustomMapStyleSettings]. [MapScheme.normalDay] style is
/// used if custom map style is not defined.
void loadMapScene(
    HereMapController hereMapController,
    MapSceneLoadSceneCallback mapSceneLoadSceneCallback,
    ) {
  hereMapController.mapScene.loadSceneForMapScheme(
    MapScheme.liteDay,
    mapSceneLoadSceneCallback,
  );
}

/// Sets traffic layers visibility on the map according to option saved in preferences (or hides them if app is in
/// offline mode).
void setTrafficLayersVisibilityOnMap(BuildContext context, HereMapController hereMapController) {
  // AppPreferences appPreferences = Provider.of<AppPreferences>(context, listen: false);
  // bool enableTraffic = appPreferences.useAppOffline ? false : appPreferences.showTrafficLayers;
  // if (enableTraffic) {
    hereMapController.mapScene.enableFeatures({
      MapFeatures.trafficFlow: MapFeatureModes.trafficFlowWithFreeFlow,
      MapFeatures.trafficIncidents: MapFeatureModes.trafficIncidentsAll
    });
  // } else {
  //   hereMapController.mapScene.disableFeatures([MapFeatures.trafficFlow, MapFeatures.trafficIncidents]);
  // }
}

String getFileSize(String path) {
  final file = File(path);
  int sizeInBytes = file.lengthSync();
  if (sizeInBytes > 1000000) {
    const mb = 'MB';
    String sizeInMb = (sizeInBytes / (1024 * 1024)).toStringAsFixed(1);
    return sizeInMb + mb;
  } else {
    const kb = 'KB';
    String sizeInKB = (sizeInBytes / (1024)).toStringAsFixed(1);
    return sizeInKB + kb;
  }
}

Future<String> compressPdf(PlatformFile file) async {
  var tempDir = await getTemporaryDirectory();
  final document = await PdfDocument.openFile(file.path!);
  var pdfPagesCount = document.pagesCount;
  List<Uint8List> pagesAsImage = [];

  for (int i = 1; i <= pdfPagesCount; i++){
    var page = await document.getPage(i);
    final pageImage = await page.render(
      width: page.width * 2,
      height: page.height * 2,
      format: PdfPageImageFormat.jpeg,
      backgroundColor: '#ffffff',
    );

    var targetPath = "${tempDir.path}${file.name}_${pageImage?.pageNumber}";
    await File(targetPath).writeAsBytes(pageImage?.bytes ?? [], flush: true);
    var compressedData = await compressImageAsBytes(File(targetPath));
    if(compressedData != null) {
      pagesAsImage.add(compressedData);
      page.close();
    }else{
      page.close();
      break;
    }
  }

  final doc = pw.Document();

  List<pw.MemoryImage> listImages = pagesAsImage
      .map((element) => pw.MemoryImage(element))
      .toList();

  for (var element in listImages) {
    doc.addPage(pw.Page(build: (context) {
      return pw.Center(child: pw.Image(element));
    }));
  }

  var docPath = "${tempDir.path}/${file.name}";
  await File(docPath).writeAsBytes(await doc.save());
  return docPath;
}

Future<Uint8List?> compressImageAsBytes(File file) async {
  var result = await FlutterImageCompress.compressWithFile(
    file.absolute.path,
    minWidth: 1500,
    minHeight: 700,
    quality: 30,
  );
  return result;
}

Future<XFile?> compressImageAsFile(XFile file, String targetPath) async {
  var result = await FlutterImageCompress.compressAndGetFile(
    file.path, targetPath,
    quality: 30,
  );

  return result;
}

Future<String> convertImagesToPdf(List<String> images) async {
  var tempDir = await getTemporaryDirectory();
  final doc = pw.Document();
  List<Uint8List> pagesAsImage = [];

  for (var data in images) {
    var compressedData = await compressImageAsBytes(File(data));
    if(compressedData != null) {
      pagesAsImage.add(compressedData);
    }else{
      break;
    }}

  List<pw.MemoryImage> listImages = pagesAsImage
      .map((element) => pw.MemoryImage(element))
      .toList();

  for (var element in listImages) {
    doc.addPage(pw.Page(build: (context) {
      return pw.Center(child: pw.Image(element));
    }));
  }

  var docPath = "${tempDir.path}/${images.first.split("/").last}.pdf";
  await File(docPath).writeAsBytes(await doc.save());
  return docPath;
}

int calculateHOS(int seconds, {int driverCount = 1}) {
  // Determine available hours based on the driver count
  int driverHours = (driverCount != null && driverCount > 1) ? 22 : 11;

  // Convert seconds to total hours
  int totalHours = seconds ~/ 3600;

  // Calculate the full "days" based on the driver hours
  int quotient = totalHours ~/ driverHours;

  // Calculate the remaining hours
  int remainder = totalHours % driverHours;

  // Extract minutes from the remaining seconds
  int minutes = (seconds % 3600) ~/ 60;

  // Handle formatting: if quotient is 0, return the seconds directly
  if (quotient == 0) {
    return seconds;
  }

  // Calculate the total time in seconds (quotient * 24 hours * 60 minutes * 60 seconds) + remainder hours converted to seconds
  return (quotient * 24 * 60 * 60) + (remainder * 60 * 60) + (minutes * 60);
}
