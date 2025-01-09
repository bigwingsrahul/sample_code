class LoginResponse {
  bool? status;
  String? token;
  String? message;
  bool? loggedinUser;
  Data? data;

  LoginResponse({this.status, this.token, this.message, this.data});

  LoginResponse.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    token = json['token'];
    loggedinUser = json['loggedinUser'];
    message = json['message'];
    data = json['data'] == null || json['data'] is List<dynamic>
        ? null
        : Data.fromJson(json['data']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['token'] = token;
    data['loggedinUser'] = loggedinUser;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  String? yearsOfComExp;
  int? id;
  String? firstName;
  String? lastName;
  String? username;
  String? email;
  String? phoneNo;
  String? countryCode;
  String? countryENCode;
  String? password;
  String? dOB;
  String? driverId;
  String? deviceName;
  int? adminId;
  String? sSN;
  String? drivingLicenseNo;
  var twicCardNo;
  AddressDetails? addressDetails;
  String? joiningDate;
  String? licenseClass;
  List<String>? jobType;
  String? driverType;
  bool? readyForTeamUp;
  String? interests;
  String? leadSource;
  var note;
  String? profilePic;
  String? verificationToken;
  String? type;
  bool? isNew;
  var teamId;
  var teamDriverId;
  bool? hasLoad;
  bool? isTruckAssigned;
  String? loginToken;
  bool? emailVerified;
  bool? phoneVerified;
  String? theme;
  bool? isLoadAssigned;
  var loadId;
  bool? isActive;
  bool? isDeleted;
  int? createdBy;
  String? createdByRole;
  var modifiedBy;
  var modifiedByRole;
  String? createdAt;
  String? updatedAt;
  var truckId;
  var mappingId;

  Data(
      {this.yearsOfComExp,
      this.id,
      this.firstName,
      this.lastName,
      this.username,
      this.email,
      this.phoneNo,
      this.countryCode,
      this.countryENCode,
      this.password,
      this.dOB,
      this.driverId,
      this.deviceName,
      this.adminId,
      this.sSN,
      this.drivingLicenseNo,
      this.twicCardNo,
      this.addressDetails,
      this.joiningDate,
      this.licenseClass,
      this.jobType,
      this.driverType,
      this.readyForTeamUp,
      this.interests,
      this.leadSource,
      this.note,
      this.profilePic,
      this.verificationToken,
      this.type,
      this.isNew,
      this.teamId,
      this.teamDriverId,
      this.hasLoad,
      this.isTruckAssigned,
      this.loginToken,
      this.emailVerified,
      this.phoneVerified,
      this.theme,
      this.isLoadAssigned,
      this.loadId,
      this.isActive,
      this.isDeleted,
      this.createdBy,
      this.createdByRole,
      this.modifiedBy,
      this.modifiedByRole,
      this.createdAt,
      this.updatedAt,
      this.truckId,
      this.mappingId});

  Data.fromJson(Map<String, dynamic> json) {
    yearsOfComExp = json['yearsOfComExp'];
    id = json['id'];
    firstName = json['firstName'];
    lastName = json['lastName'];
    username = json['username'];
    email = json['email'];
    phoneNo = json['phoneNo'];
    countryCode = json['countryCode'];
    countryENCode = json['countryENCode'];
    password = json['password'];
    dOB = json['DOB'];
    driverId = json['driverId'];
    deviceName = json['deviceName'] ?? "";
    adminId = json['adminId'];
    sSN = json['SSN'];
    drivingLicenseNo = json['drivingLicenseNo'];
    twicCardNo = json['twicCardNo'];
    addressDetails = json['addressDetails'] != null
        ? AddressDetails.fromJson(json['addressDetails'])
        : null;
    joiningDate = json['JoiningDate'];
    licenseClass = json['licenseClass'];
    jobType = json['jobType'].cast<String>();
    driverType = json['driverType'];
    readyForTeamUp = json['readyForTeamUp'];
    interests = json['interests'];
    leadSource = json['leadSource'];
    note = json['note'];
    profilePic = json['profilePic'];
    verificationToken = json['verificationToken'];
    type = json['type'];
    isNew = json['isNew'];
    teamId = json['teamId'];
    teamDriverId = json['teamDriverId'];
    hasLoad = json['hasLoad'];
    isTruckAssigned = json['isTruckAssigned'];
    loginToken = json['loginToken'];
    emailVerified = json['emailVerified'];
    phoneVerified = json['phoneVerified'];
    theme = json['theme'];
    isLoadAssigned = json['isLoadAssigned'];
    loadId = json['loadId'];
    isActive = json['isActive'];
    isDeleted = json['isDeleted'];
    createdBy = json['createdBy'];
    createdByRole = json['createdByRole'];
    modifiedBy = json['modifiedBy'];
    modifiedByRole = json['modifiedByRole'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    truckId = json['truckId'];
    mappingId = json['mappingId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['yearsOfComExp'] = yearsOfComExp;
    data['id'] = id;
    data['firstName'] = firstName;
    data['lastName'] = lastName;
    data['username'] = username;
    data['email'] = email;
    data['phoneNo'] = phoneNo;
    data['countryCode'] = countryCode;
    data['countryENCode'] = countryENCode;
    data['password'] = password;
    data['DOB'] = dOB;
    data['driverId'] = driverId;
    data['deviceName'] = deviceName;
    data['adminId'] = adminId;
    data['SSN'] = sSN;
    data['drivingLicenseNo'] = drivingLicenseNo;
    data['twicCardNo'] = twicCardNo;
    if (addressDetails != null) {
      data['addressDetails'] = addressDetails!.toJson();
    }
    data['JoiningDate'] = joiningDate;
    data['licenseClass'] = licenseClass;
    data['jobType'] = jobType;
    data['driverType'] = driverType;
    data['readyForTeamUp'] = readyForTeamUp;
    data['interests'] = interests;
    data['leadSource'] = leadSource;
    data['note'] = note;
    data['profilePic'] = profilePic;
    data['verificationToken'] = verificationToken;
    data['type'] = type;
    data['isNew'] = isNew;
    data['teamId'] = teamId;
    data['teamDriverId'] = teamDriverId;
    data['hasLoad'] = hasLoad;
    data['isTruckAssigned'] = isTruckAssigned;
    data['loginToken'] = loginToken;
    data['emailVerified'] = emailVerified;
    data['phoneVerified'] = phoneVerified;
    data['theme'] = theme;
    data['isLoadAssigned'] = isLoadAssigned;
    data['loadId'] = loadId;
    data['isActive'] = isActive;
    data['isDeleted'] = isDeleted;
    data['createdBy'] = createdBy;
    data['createdByRole'] = createdByRole;
    data['modifiedBy'] = modifiedBy;
    data['modifiedByRole'] = modifiedByRole;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['truckId'] = truckId;
    data['mappingId'] = mappingId;
    return data;
  }
}

class AddressDetails {
  String? country;
  String? zipCode;
  String? state;
  String? city;
  String? address;

  AddressDetails(
      {this.country, this.zipCode, this.state, this.city, this.address});

  AddressDetails.fromJson(Map<String, dynamic> json) {
    country = json['country'];
    zipCode = json['zipCode'];
    state = json['state'];
    city = json['city'];
    address = json['address'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['country'] = country;
    data['zipCode'] = zipCode;
    data['state'] = state;
    data['city'] = city;
    data['address'] = address;
    return data;
  }
}
