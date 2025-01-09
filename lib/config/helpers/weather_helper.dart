import 'package:flutter/foundation.dart';
import 'package:here_sdk/core.dart';
import 'package:techtruckers/config/services/api_service.dart';
import 'package:techtruckers/features/common/models/city_item_model.dart';
import 'package:techtruckers/features/common/models/get_weather_data_model.dart';
import 'package:techtruckers/features/dispatch/models/get_city_detail_model.dart';
import 'package:techtruckers/features/dispatch/models/get_geo_bound_model.dart';

class WeatherHelper {
  const WeatherHelper();

  Future<List<CityItem>> getCitiesInRoute(List<GeoCoordinates> routePoints) async {
    List<CityItem> cities = [];
    Set<String> processedCities = {}; // Track processed cities to avoid duplicates

    debugPrint("Last Lat Lng is ${routePoints.last.latitude}, ${routePoints.last.longitude}");

    try {
      for (var geoItem in routePoints) {
        if (_isGeoItemInLastCityBoundingBox(geoItem, cities)) {
          continue;
        }

        String cityName = await _getCityNameIfNotProcessed(geoItem, processedCities);
        if (cityName.isEmpty) {
          continue;
        }

        GeoBox? geoBox = await getBoundingBoxForCity(cityName);
        if (geoBox != null) {
          cities.add(CityItem(cityName, geoItem, geoBox));
          processedCities.add(cityName); // Mark city as processed
        } else {
          debugPrint("Skipping LatLng ${geoItem.latitude}, ${geoItem.longitude}: GeoBox not found");
        }
      }
    } catch (e, stack) {
      debugPrint('Error in getCitiesInRoute: $e');
      debugPrintStack(stackTrace: stack);
    }

    return cities;
  }

  Future<CityItem?> getCityDetail(GeoCoordinates location) async {

    try {
      String cityName = await _getCityNameIfNotProcessed(location, {});
      if (cityName.isEmpty) {
        return null;
      }

      return CityItem(cityName, location, GeoBox(location, location));
    } catch (e, stack) {
      debugPrint('Error in getCitiesInRoute: $e');
      debugPrintStack(stackTrace: stack);
    }

    return null;
  }

  bool _isGeoItemInLastCityBoundingBox(GeoCoordinates geoItem, List<CityItem> cities) {
    return cities.isNotEmpty && cities.last.geoBox.containsGeoCoordinates(geoItem);
  }

  Future<String> _getCityNameIfNotProcessed(GeoCoordinates geoItem, Set<String> processedCities) async {
    String cityName = await fetchCityName(geoItem);
    if (cityName.isNotEmpty && !processedCities.contains(cityName)) {
      return cityName;
    }
    return "";
  }

  Future<GeoBox?> getBoundingBoxForCity(String city) async {
    final response = await ApiService.instance.customGet(
        "https://nominatim.openstreetmap.org/search.php?q=$city&polygon_geojson=1&format=json",
        false);

    if (response.statusCode == 200) {
      final data = getGeoBoundDataModelFromJson(response.body);
      var items = data.where((item) => item.getGeoBoundDataModelClass == "boundary").toList();

      if (items.isNotEmpty) {
        items.sort((a, b) => a.placeRank.compareTo(b.placeRank));
        return _createGeoBoxFromBoundingBox(items.first.boundingbox);
      }
    } else {
      debugPrint("Failed to fetch bounding box for city: ${response.statusCode}");
    }
    return null;
  }

  GeoBox? _createGeoBoxFromBoundingBox(List<String> boundingBox) {
    SdkContext.init(IsolateOrigin.main);

    try {
      if (boundingBox.length == 4) {
        double southLatitude = double.parse(boundingBox[0]);
        double northLatitude = double.parse(boundingBox[1]);
        double westLongitude = double.parse(boundingBox[2]);
        double eastLongitude = double.parse(boundingBox[3]);

        GeoCoordinates southWest = GeoCoordinates(southLatitude, westLongitude);
        GeoCoordinates northEast = GeoCoordinates(northLatitude, eastLongitude);
        return GeoBox(southWest, northEast);
      }
      return null;
    }catch(e){
      debugPrint(e.toString());
      return null;
    }
  }

  Future<String> fetchCityName(GeoCoordinates latLng) async {
    final response = await ApiService.instance.customGet(
        "https://nominatim.openstreetmap.org/reverse?format=json&lat=${latLng.latitude}&lon=${latLng.longitude}&zoom=18&addressdetails=1",
        false);

    if (response.statusCode == 200) {
      final data = getCityDetailModelFromJson(response.body);
      return data.address.stateDistrict ?? data.address.cityDistrict ?? "";
    } else {
      debugPrint("Failed to fetch city name: ${response.statusCode}");
      return "";
    }
  }

  GeoCoordinates getCenterPointOfGeoBox(GeoBox geoBox) {
    double centerLatitude =
        (geoBox.southWestCorner.latitude + geoBox.northEastCorner.latitude) / 2;
    double centerLongitude =
        (geoBox.southWestCorner.longitude + geoBox.northEastCorner.longitude) / 2;

    return GeoCoordinates(centerLatitude, centerLongitude);
  }

  // Function to fetch weather info for a lat lng using OpenWeatherMap API
  Future<GetWeatherDataModel?> fetchWeather(GeoCoordinates latLng) async {
    // Send the HTTP request to HERE API
    final response = await ApiService.instance.customGet(
        "https://api.openweathermap.org/data/2.5/weather?lat=${latLng.latitude}&lon=${latLng.longitude}&appid=3dc19ed353bbd4bdf0c0cd8e13545cde",
        false);

    if (response.statusCode == 200) {
      // print(response.body);
      final data = getWeatherDataModelFromJson(response.body);
      return data;
    } else {
      debugPrint(
          "Failed to fetch cities for bounding box: ${response.statusCode}");
      return null;
    }
  }

  isDanger(WeatherCondition weatherCondition) {
    switch (weatherCondition) {

      case WeatherCondition.clearSky:
      case WeatherCondition.fewClouds:
      case WeatherCondition.scatteredClouds:
      case WeatherCondition.brokenClouds:
      case WeatherCondition.overcastClouds:
        return false;

      case WeatherCondition.thunderstormWithLightRain:
      case WeatherCondition.thunderstormWithRain:
      case WeatherCondition.thunderstormWithHeavyRain:
      case WeatherCondition.lightThunderstorm:
      case WeatherCondition.thunderstorm:
      case WeatherCondition.heavyThunderstorm:
      case WeatherCondition.raggedThunderstorm:
      case WeatherCondition.thunderstormWithLightDrizzle:
      case WeatherCondition.thunderstormWithDrizzle:
      case WeatherCondition.thunderstormWithHeavyDrizzle:
      case WeatherCondition.lightDrizzle:
      case WeatherCondition.drizzle:
      case WeatherCondition.heavyDrizzle:
      case WeatherCondition.lightDrizzleRain:
      case WeatherCondition.drizzleRain:
      case WeatherCondition.heavyDrizzleRain:
      case WeatherCondition.showerRainAndDrizzle:
      case WeatherCondition.heavyShowerRainAndDrizzle:
      case WeatherCondition.showerDrizzle:
      case WeatherCondition.lightRain:
      case WeatherCondition.moderateRain:
      case WeatherCondition.heavyRain:
      case WeatherCondition.veryHeavyRain:
      case WeatherCondition.extremeRain:
      case WeatherCondition.freezingRain:
      case WeatherCondition.lightShowerRain:
      case WeatherCondition.showerRain:
      case WeatherCondition.heavyShowerRain:
      case WeatherCondition.raggedShowerRain:
      case WeatherCondition.lightSnow:
      case WeatherCondition.snow:
      case WeatherCondition.heavySnow:
      case WeatherCondition.sleet:
      case WeatherCondition.lightShowerSleet:
      case WeatherCondition.showerSleet:
      case WeatherCondition.lightRainAndSnow:
      case WeatherCondition.rainAndSnow:
      case WeatherCondition.lightShowerSnow:
      case WeatherCondition.showerSnow:
      case WeatherCondition.heavyShowerSnow:
      case WeatherCondition.mist:
      case WeatherCondition.smoke:
      case WeatherCondition.haze:
      case WeatherCondition.dustWhirls:
      case WeatherCondition.fog:
      case WeatherCondition.sand:
      case WeatherCondition.dust:
      case WeatherCondition.volcanicAsh:
      case WeatherCondition.squalls:
      case WeatherCondition.tornado:
        return true;

    // Default case to catch any unexpected values
      default:
        return true;
    }
  }

  WeatherCondition getWeatherConditionByCode(int code) {
    switch (code) {
    // Group 2xx: Thunderstorm
      case 200:
        return WeatherCondition.thunderstormWithLightRain;
      case 201:
        return WeatherCondition.thunderstormWithRain;
      case 202:
        return WeatherCondition.thunderstormWithHeavyRain;
      case 210:
        return WeatherCondition.lightThunderstorm;
      case 211:
        return WeatherCondition.thunderstorm;
      case 212:
        return WeatherCondition.heavyThunderstorm;
      case 221:
        return WeatherCondition.raggedThunderstorm;
      case 230:
        return WeatherCondition.thunderstormWithLightDrizzle;
      case 231:
        return WeatherCondition.thunderstormWithDrizzle;
      case 232:
        return WeatherCondition.thunderstormWithHeavyDrizzle;

    // Group 3xx: Drizzle
      case 300:
        return WeatherCondition.lightDrizzle;
      case 301:
        return WeatherCondition.drizzle;
      case 302:
        return WeatherCondition.heavyDrizzle;
      case 310:
        return WeatherCondition.lightDrizzleRain;
      case 311:
        return WeatherCondition.drizzleRain;
      case 312:
        return WeatherCondition.heavyDrizzleRain;
      case 313:
        return WeatherCondition.showerRainAndDrizzle;
      case 314:
        return WeatherCondition.heavyShowerRainAndDrizzle;
      case 321:
        return WeatherCondition.showerDrizzle;

    // Group 5xx: Rain
      case 500:
        return WeatherCondition.lightRain;
      case 501:
        return WeatherCondition.moderateRain;
      case 502:
        return WeatherCondition.heavyRain;
      case 503:
        return WeatherCondition.veryHeavyRain;
      case 504:
        return WeatherCondition.extremeRain;
      case 511:
        return WeatherCondition.freezingRain;
      case 520:
        return WeatherCondition.lightShowerRain;
      case 521:
        return WeatherCondition.showerRain;
      case 522:
        return WeatherCondition.heavyShowerRain;
      case 531:
        return WeatherCondition.raggedShowerRain;

    // Group 6xx: Snow
      case 600:
        return WeatherCondition.lightSnow;
      case 601:
        return WeatherCondition.snow;
      case 602:
        return WeatherCondition.heavySnow;
      case 611:
        return WeatherCondition.sleet;
      case 612:
        return WeatherCondition.lightShowerSleet;
      case 613:
        return WeatherCondition.showerSleet;
      case 615:
        return WeatherCondition.lightRainAndSnow;
      case 616:
        return WeatherCondition.rainAndSnow;
      case 620:
        return WeatherCondition.lightShowerSnow;
      case 621:
        return WeatherCondition.showerSnow;
      case 622:
        return WeatherCondition.heavyShowerSnow;

    // Group 7xx: Atmosphere
      case 701:
        return WeatherCondition.mist;
      case 711:
        return WeatherCondition.smoke;
      case 721:
        return WeatherCondition.haze;
      case 731:
        return WeatherCondition.dustWhirls;
      case 741:
        return WeatherCondition.fog;
      case 751:
        return WeatherCondition.sand;
      case 761:
        return WeatherCondition.dust;
      case 762:
        return WeatherCondition.volcanicAsh;
      case 771:
        return WeatherCondition.squalls;
      case 781:
        return WeatherCondition.tornado;

    // Group 800: Clear
      case 800:
        return WeatherCondition.clearSky;

    // Group 80x: Clouds
      case 801:
        return WeatherCondition.fewClouds;
      case 802:
        return WeatherCondition.scatteredClouds;
      case 803:
        return WeatherCondition.brokenClouds;
      case 804:
        return WeatherCondition.overcastClouds;

    // Default case if no matching code is found
      default:
        return WeatherCondition.clearSky;
    }
  }

  getWeatherIcon(WeatherCondition weatherCondition) {
    var isNight = DateTime.now().hour >= 20;

    switch (weatherCondition) {

      case WeatherCondition.clearSky:
        return isNight ? "assets/images/clear_night.png" : "assets/images/clear_day.png";
      case WeatherCondition.fewClouds:
        return isNight ? "assets/images/cloud_moon.png" : "assets/images/cloud_sun.png";
      case WeatherCondition.scatteredClouds:
      case WeatherCondition.brokenClouds:
      case WeatherCondition.overcastClouds:
        return "assets/images/cloud.png";

      case WeatherCondition.thunderstormWithLightRain:
      case WeatherCondition.thunderstormWithRain:
      case WeatherCondition.thunderstormWithHeavyRain:
      case WeatherCondition.lightThunderstorm:
      case WeatherCondition.thunderstorm:
      case WeatherCondition.heavyThunderstorm:
      case WeatherCondition.raggedThunderstorm:
      case WeatherCondition.thunderstormWithLightDrizzle:
      case WeatherCondition.thunderstormWithDrizzle:
      case WeatherCondition.thunderstormWithHeavyDrizzle:
        return "assets/images/cloud_bolt.png";

      case WeatherCondition.lightDrizzle:
      case WeatherCondition.drizzle:
      case WeatherCondition.heavyDrizzle:
      case WeatherCondition.lightDrizzleRain:
      case WeatherCondition.drizzleRain:
      case WeatherCondition.heavyDrizzleRain:
      case WeatherCondition.showerRainAndDrizzle:
      case WeatherCondition.heavyShowerRainAndDrizzle:
      case WeatherCondition.showerDrizzle:
      case WeatherCondition.lightShowerRain:
      case WeatherCondition.showerRain:
      case WeatherCondition.heavyShowerRain:
      case WeatherCondition.raggedShowerRain:
        return "assets/images/cloud_showers_heavy.png";

      case WeatherCondition.lightRain:
      case WeatherCondition.moderateRain:
      case WeatherCondition.heavyRain:
      case WeatherCondition.veryHeavyRain:
      case WeatherCondition.extremeRain:
        return "assets/images/cloud_sun_rain.png";

      case WeatherCondition.freezingRain:
      case WeatherCondition.lightSnow:
      case WeatherCondition.snow:
      case WeatherCondition.heavySnow:
      case WeatherCondition.sleet:
      case WeatherCondition.lightShowerSleet:
      case WeatherCondition.showerSleet:
      case WeatherCondition.lightRainAndSnow:
      case WeatherCondition.rainAndSnow:
      case WeatherCondition.lightShowerSnow:
      case WeatherCondition.showerSnow:
      case WeatherCondition.heavyShowerSnow:
        return "assets/images/snow.png";

      case WeatherCondition.mist:
      case WeatherCondition.smoke:
      case WeatherCondition.haze:
      case WeatherCondition.dustWhirls:
      case WeatherCondition.fog:
      case WeatherCondition.sand:
      case WeatherCondition.dust:
      case WeatherCondition.volcanicAsh:
      case WeatherCondition.squalls:
      case WeatherCondition.tornado:
        return "assets/images/smog.png";

    // Default case to catch any unexpected values
      default:
        return "assets/images/snow.png";
    }
  }

}

enum WeatherCondition {
  // Group 2xx: Thunderstorm
  thunderstormWithLightRain,
  thunderstormWithRain,
  thunderstormWithHeavyRain,
  lightThunderstorm,
  thunderstorm,
  heavyThunderstorm,
  raggedThunderstorm,
  thunderstormWithLightDrizzle,
  thunderstormWithDrizzle,
  thunderstormWithHeavyDrizzle,

  // Group 3xx: Drizzle
  lightDrizzle,
  drizzle,
  heavyDrizzle,
  lightDrizzleRain,
  drizzleRain,
  heavyDrizzleRain,
  showerRainAndDrizzle,
  heavyShowerRainAndDrizzle,
  showerDrizzle,

  // Group 5xx: Rain
  lightRain,
  moderateRain,
  heavyRain,
  veryHeavyRain,
  extremeRain,
  freezingRain,
  lightShowerRain,
  showerRain,
  heavyShowerRain,
  raggedShowerRain,

  // Group 6xx: Snow
  lightSnow,
  snow,
  heavySnow,
  sleet,
  lightShowerSleet,
  showerSleet,
  lightRainAndSnow,
  rainAndSnow,
  lightShowerSnow,
  showerSnow,
  heavyShowerSnow,

  // Group 7xx: Atmosphere
  mist,
  smoke,
  haze,
  dustWhirls,
  fog,
  sand,
  dust,
  volcanicAsh,
  squalls,
  tornado,

  // Group 800: Clear
  clearSky,

  // Group 80x: Clouds
  fewClouds,
  scatteredClouds,
  brokenClouds,
  overcastClouds,
}