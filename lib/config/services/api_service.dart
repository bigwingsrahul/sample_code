import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:techtruckers/config/helpers/preferences_helper.dart';
import 'package:techtruckers/utils/constant.dart';

class ApiService {
  static late ApiService _instance;

  // Singleton instance
  static ApiService get instance {
    return _instance;
  }

  // Base URL
  static const String baseUrl = 'http://54.241.221.130:8000/app/'; // Development Server URL

  // HTTP client
  http.Client client = http.Client();

  // Initialize preferences in main.dart or at app startup
  static Future<void> init() async {
    _instance = ApiService();
  }

  // GET request
  Future<http.Response> get(String endpoint, bool isToken) async {
    var url = Uri.parse(baseUrl + endpoint);
    var response = await client.get(url, headers: getHeaders(isToken));

    log('Url is >>>>>>> $url');
    log('Response is >>>>>>> ${response.body} ');
    return response;
  }

  // POST request
  Future<http.Response> post(String endpoint, bool isToken, {required Map<String, dynamic> body}) async {
    var url = Uri.parse(baseUrl + endpoint);
    var response = await client.post(url, headers: getHeaders(isToken), body: jsonEncode(body));
    log('Url is >>>>>>> $url');
    log('Request is >>>>>>> ${jsonEncode(body)}'); // Encode body map to JSON string
    log('Response is >>>>>>> ${response.body}');
    return response;
  }

  // PUT request
  Future<http.Response> put(String endpoint, bool isToken, {required Map<String, dynamic> body}) async {
    var url = Uri.parse(baseUrl + endpoint);
    var response = await client.put(url, headers: getHeaders(isToken), body: jsonEncode(body));
    log('Url is >>>>>>> $url');
    log('Request is >>>>>>> ${jsonEncode(body)}'); // Encode body map to JSON string
    log('Response is >>>>>>> ${response.body} ');
    return response;
  }

  // Custom URL GET request
  Future<http.Response> customGet(String urlStr, bool isToken) async {
    var url = Uri.parse(urlStr);
    var response = await client.get(url, headers: getHeaders(isToken));
    log('Url is >>>>>>> $url');
    log('Response is >>>>>>> ${response.body} ');
    return response;
  }

  // Auth header
  Map<String, String> getHeaders(bool isToken){
    if(isToken){
      log('Token is >>>>>>> ${PreferencesHelper.instance.getString(Constant.token)}');
      return {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': "Bearer ${PreferencesHelper.instance.getString(Constant.token, defaultValue: "")}",
      };
    }else{
      return {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'traccar'
      };
    }
  }

  Map<String, String> getMultipartHeaders(bool isToken){
    if(isToken){
      log('Token is >>>>>>> ${PreferencesHelper.instance.getString(Constant.token)}');
      return {
        'Content-Type': 'multipart/form-data',
        'Accept': 'application/json',
        'Authorization': "Bearer ${PreferencesHelper.instance.getString(Constant.token, defaultValue: "")}",
      };
    }else{
      return {
        'Content-Type': 'multipart/form-data',
        'Accept': 'application/json',
      };
    }
  }

  Future<http.Response> multipartPost(String endpoint, bool isToken, Map<String, String> fields, Iterable<http.MultipartFile> files
      ) async {
    var url = Uri.parse(baseUrl + endpoint);

    var request = http.MultipartRequest('POST', url);

    // Add headers
    request.headers.addAll(getMultipartHeaders(isToken));

    // Add fields
    request.fields.addAll(fields);

    // Add files
    request.files.addAll(files);

    var response = await client.send(request);

    var streamedResponse = await http.Response.fromStream(response);

    log('Url is >>>>>>> $url');
    log('Request body is >>>>>>> $fields');
    log('Response is >>>>>>> ${streamedResponse.body} ');

    return streamedResponse;
  }

}