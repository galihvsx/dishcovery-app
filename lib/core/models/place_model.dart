class PlaceModel {
  final String? id;
  final String? resourceName;
  final DisplayName? displayName;
  final String? primaryType;
  final DisplayName? primaryTypeDisplayName;
  final String? formattedAddress;
  final String? shortFormattedAddress;
  final AddressComponents? addressComponents;
  final Location? location;
  final Viewport? viewport;
  final double? rating;
  final int? userRatingCount;
  final String? priceLevel;
  final List<String>? types;
  final String? websiteUri;
  final String? internationalPhoneNumber;
  final String? nationalPhoneNumber;
  final String? googleMapsUri;
  final OpeningHours? currentOpeningHours;
  final OpeningHours? regularOpeningHours;
  final BusinessStatus? businessStatus;
  final List<Photo>? photos;
  final AccessibilityOptions? accessibilityOptions;
  final PlusCode? plusCode;
  final int? utcOffset;
  final String? adrFormatAddress;
  final String? iconMaskBaseUri;
  final String? iconBackgroundColor;
  final List<SubDestination>? subDestinations;

  PlaceModel({
    this.id,
    this.resourceName,
    this.displayName,
    this.primaryType,
    this.primaryTypeDisplayName,
    this.formattedAddress,
    this.shortFormattedAddress,
    this.addressComponents,
    this.location,
    this.viewport,
    this.rating,
    this.userRatingCount,
    this.priceLevel,
    this.types,
    this.websiteUri,
    this.internationalPhoneNumber,
    this.nationalPhoneNumber,
    this.googleMapsUri,
    this.currentOpeningHours,
    this.regularOpeningHours,
    this.businessStatus,
    this.photos,
    this.accessibilityOptions,
    this.plusCode,
    this.utcOffset,
    this.adrFormatAddress,
    this.iconMaskBaseUri,
    this.iconBackgroundColor,
    this.subDestinations,
  });

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    return PlaceModel(
      id: json['id'],
      resourceName: json['name'],
      displayName: json['displayName'] != null
          ? DisplayName.fromJson(json['displayName'])
          : null,
      primaryType: json['primaryType'],
      primaryTypeDisplayName: json['primaryTypeDisplayName'] != null
          ? DisplayName.fromJson(json['primaryTypeDisplayName'])
          : null,
      formattedAddress: json['formattedAddress'],
      shortFormattedAddress: json['shortFormattedAddress'],
      addressComponents: json['addressComponents'] != null
          ? AddressComponents.fromJson(json['addressComponents'])
          : null,
      location: json['location'] != null
          ? Location.fromJson(json['location'])
          : null,
      viewport: json['viewport'] != null
          ? Viewport.fromJson(json['viewport'])
          : null,
      rating: json['rating']?.toDouble(),
      userRatingCount: json['userRatingCount'],
      priceLevel: json['priceLevel'],
      types: json['types'] != null ? List<String>.from(json['types']) : null,
      websiteUri: json['websiteUri'],
      internationalPhoneNumber: json['internationalPhoneNumber'],
      nationalPhoneNumber: json['nationalPhoneNumber'],
      googleMapsUri: json['googleMapsUri'],
      currentOpeningHours: json['currentOpeningHours'] != null
          ? OpeningHours.fromJson(json['currentOpeningHours'])
          : null,
      regularOpeningHours: json['regularOpeningHours'] != null
          ? OpeningHours.fromJson(json['regularOpeningHours'])
          : null,
      businessStatus: json['businessStatus'] != null
          ? BusinessStatus.fromString(json['businessStatus'])
          : null,
      photos: json['photos'] != null
          ? (json['photos'] as List).map((p) => Photo.fromJson(p)).toList()
          : null,
      accessibilityOptions: json['accessibilityOptions'] != null
          ? AccessibilityOptions.fromJson(json['accessibilityOptions'])
          : null,
      plusCode: json['plusCode'] != null
          ? PlusCode.fromJson(json['plusCode'])
          : null,
      utcOffset: json['utcOffset'],
      adrFormatAddress: json['adrFormatAddress'],
      iconMaskBaseUri: json['iconMaskBaseUri'],
      iconBackgroundColor: json['iconBackgroundColor'],
      subDestinations: json['subDestinations'] != null
          ? (json['subDestinations'] as List)
                .map((s) => SubDestination.fromJson(s))
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': resourceName,
      'displayName': displayName?.toJson(),
      'primaryType': primaryType,
      'primaryTypeDisplayName': primaryTypeDisplayName?.toJson(),
      'formattedAddress': formattedAddress,
      'shortFormattedAddress': shortFormattedAddress,
      'addressComponents': addressComponents?.toJson(),
      'location': location?.toJson(),
      'viewport': viewport?.toJson(),
      'rating': rating,
      'userRatingCount': userRatingCount,
      'priceLevel': priceLevel,
      'types': types,
      'websiteUri': websiteUri,
      'internationalPhoneNumber': internationalPhoneNumber,
      'nationalPhoneNumber': nationalPhoneNumber,
      'googleMapsUri': googleMapsUri,
      'currentOpeningHours': currentOpeningHours?.toJson(),
      'regularOpeningHours': regularOpeningHours?.toJson(),
      'businessStatus': businessStatus?.value,
      'photos': photos?.map((p) => p.toJson()).toList(),
      'accessibilityOptions': accessibilityOptions?.toJson(),
      'plusCode': plusCode?.toJson(),
      'utcOffset': utcOffset,
      'adrFormatAddress': adrFormatAddress,
      'iconMaskBaseUri': iconMaskBaseUri,
      'iconBackgroundColor': iconBackgroundColor,
      'subDestinations': subDestinations?.map((s) => s.toJson()).toList(),
    };
  }
}

class DisplayName {
  final String? text;
  final String? languageCode;

  DisplayName({this.text, this.languageCode});

  factory DisplayName.fromJson(Map<String, dynamic> json) {
    return DisplayName(text: json['text'], languageCode: json['languageCode']);
  }

  Map<String, dynamic> toJson() {
    return {'text': text, 'languageCode': languageCode};
  }
}

class Location {
  final double? latitude;
  final double? longitude;

  Location({this.latitude, this.longitude});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'latitude': latitude, 'longitude': longitude};
  }
}

class Viewport {
  final Location? low;
  final Location? high;

  Viewport({this.low, this.high});

  factory Viewport.fromJson(Map<String, dynamic> json) {
    return Viewport(
      low: json['low'] != null ? Location.fromJson(json['low']) : null,
      high: json['high'] != null ? Location.fromJson(json['high']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'low': low?.toJson(), 'high': high?.toJson()};
  }
}

class AddressComponents {
  final List<AddressComponent> components;

  AddressComponents({required this.components});

  factory AddressComponents.fromJson(List<dynamic> json) {
    return AddressComponents(
      components: json.map((c) => AddressComponent.fromJson(c)).toList(),
    );
  }

  List<Map<String, dynamic>> toJson() {
    return components.map((c) => c.toJson()).toList();
  }
}

class AddressComponent {
  final String? longText;
  final String? shortText;
  final List<String>? types;
  final String? languageCode;

  AddressComponent({
    this.longText,
    this.shortText,
    this.types,
    this.languageCode,
  });

  factory AddressComponent.fromJson(Map<String, dynamic> json) {
    return AddressComponent(
      longText: json['longText'],
      shortText: json['shortText'],
      types: json['types'] != null ? List<String>.from(json['types']) : null,
      languageCode: json['languageCode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'longText': longText,
      'shortText': shortText,
      'types': types,
      'languageCode': languageCode,
    };
  }
}

class OpeningHours {
  final bool? openNow;
  final List<Period>? periods;
  final List<String>? weekdayDescriptions;
  final List<SpecialDay>? specialDays;

  OpeningHours({
    this.openNow,
    this.periods,
    this.weekdayDescriptions,
    this.specialDays,
  });

  factory OpeningHours.fromJson(Map<String, dynamic> json) {
    return OpeningHours(
      openNow: json['openNow'],
      periods: json['periods'] != null
          ? (json['periods'] as List).map((p) => Period.fromJson(p)).toList()
          : null,
      weekdayDescriptions: json['weekdayDescriptions'] != null
          ? List<String>.from(json['weekdayDescriptions'])
          : null,
      specialDays: json['specialDays'] != null
          ? (json['specialDays'] as List)
                .map((s) => SpecialDay.fromJson(s))
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'openNow': openNow,
      'periods': periods?.map((p) => p.toJson()).toList(),
      'weekdayDescriptions': weekdayDescriptions,
      'specialDays': specialDays?.map((s) => s.toJson()).toList(),
    };
  }
}

class Period {
  final DayTime? open;
  final DayTime? close;

  Period({this.open, this.close});

  factory Period.fromJson(Map<String, dynamic> json) {
    return Period(
      open: json['open'] != null ? DayTime.fromJson(json['open']) : null,
      close: json['close'] != null ? DayTime.fromJson(json['close']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'open': open?.toJson(), 'close': close?.toJson()};
  }
}

class DayTime {
  final int? day;
  final int? hour;
  final int? minute;

  DayTime({this.day, this.hour, this.minute});

  factory DayTime.fromJson(Map<String, dynamic> json) {
    return DayTime(
      day: json['day'],
      hour: json['hour'],
      minute: json['minute'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'day': day, 'hour': hour, 'minute': minute};
  }
}

class SpecialDay {
  final String? date;

  SpecialDay({this.date});

  factory SpecialDay.fromJson(Map<String, dynamic> json) {
    return SpecialDay(date: json['date']);
  }

  Map<String, dynamic> toJson() {
    return {'date': date};
  }
}

enum BusinessStatus {
  operational('OPERATIONAL'),
  closedTemporarily('CLOSED_TEMPORARILY'),
  closedPermanently('CLOSED_PERMANENTLY');

  final String value;
  const BusinessStatus(this.value);

  static BusinessStatus? fromString(String value) {
    return BusinessStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => BusinessStatus.operational,
    );
  }
}

class Photo {
  final String? name;
  final int? widthPx;
  final int? heightPx;
  final List<AuthorAttribution>? authorAttributions;

  Photo({this.name, this.widthPx, this.heightPx, this.authorAttributions});

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      name: json['name'],
      widthPx: json['widthPx'],
      heightPx: json['heightPx'],
      authorAttributions: json['authorAttributions'] != null
          ? (json['authorAttributions'] as List)
                .map((a) => AuthorAttribution.fromJson(a))
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'widthPx': widthPx,
      'heightPx': heightPx,
      'authorAttributions': authorAttributions?.map((a) => a.toJson()).toList(),
    };
  }
}

class AuthorAttribution {
  final String? displayName;
  final String? uri;
  final String? photoUri;

  AuthorAttribution({this.displayName, this.uri, this.photoUri});

  factory AuthorAttribution.fromJson(Map<String, dynamic> json) {
    return AuthorAttribution(
      displayName: json['displayName'],
      uri: json['uri'],
      photoUri: json['photoUri'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'displayName': displayName, 'uri': uri, 'photoUri': photoUri};
  }
}

class AccessibilityOptions {
  final bool? wheelchairAccessibleParking;
  final bool? wheelchairAccessibleEntrance;
  final bool? wheelchairAccessibleRestroom;
  final bool? wheelchairAccessibleSeating;

  AccessibilityOptions({
    this.wheelchairAccessibleParking,
    this.wheelchairAccessibleEntrance,
    this.wheelchairAccessibleRestroom,
    this.wheelchairAccessibleSeating,
  });

  factory AccessibilityOptions.fromJson(Map<String, dynamic> json) {
    return AccessibilityOptions(
      wheelchairAccessibleParking: json['wheelchairAccessibleParking'],
      wheelchairAccessibleEntrance: json['wheelchairAccessibleEntrance'],
      wheelchairAccessibleRestroom: json['wheelchairAccessibleRestroom'],
      wheelchairAccessibleSeating: json['wheelchairAccessibleSeating'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wheelchairAccessibleParking': wheelchairAccessibleParking,
      'wheelchairAccessibleEntrance': wheelchairAccessibleEntrance,
      'wheelchairAccessibleRestroom': wheelchairAccessibleRestroom,
      'wheelchairAccessibleSeating': wheelchairAccessibleSeating,
    };
  }
}

class PlusCode {
  final String? globalCode;
  final String? compoundCode;

  PlusCode({this.globalCode, this.compoundCode});

  factory PlusCode.fromJson(Map<String, dynamic> json) {
    return PlusCode(
      globalCode: json['globalCode'],
      compoundCode: json['compoundCode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'globalCode': globalCode, 'compoundCode': compoundCode};
  }
}

class SubDestination {
  final String? name;
  final String? id;

  SubDestination({this.name, this.id});

  factory SubDestination.fromJson(Map<String, dynamic> json) {
    return SubDestination(name: json['name'], id: json['id']);
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'id': id};
  }
}

class PlacesSearchResponse {
  final List<PlaceModel> places;
  final String? nextPageToken;
  final String? searchQuery;
  final bool isGenericSearch;

  PlacesSearchResponse({
    required this.places,
    this.nextPageToken,
    this.searchQuery,
    this.isGenericSearch = false,
  });

  factory PlacesSearchResponse.fromJson(Map<String, dynamic> json) {
    return PlacesSearchResponse(
      places: json['places'] != null
          ? (json['places'] as List)
                .map((place) => PlaceModel.fromJson(place))
                .toList()
          : [],
      nextPageToken: json['nextPageToken'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'places': places.map((place) => place.toJson()).toList(),
      'nextPageToken': nextPageToken,
    };
  }
}
