import 'dart:async';
import 'dart:io' show Platform;
import 'package:http/http.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:flutter_place_picker/utils/urls.dart';
import 'package:flutter_place_picker/utils/uuid.dart';
import 'package:google_api_headers/google_api_headers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_place_picker/flutter_place_picker.dart';
import 'package:flutter_place_picker/models/local_prediction.dart';
import 'package:flutter_place_picker/src/autocomplete_search.dart';
import 'package:flutter_place_picker/providers/place_provider.dart';
import 'package:flutter_place_picker/resources/post_to_server.dart';
import 'package:flutter_place_picker/src/flutter_place_picker.dart';
import 'package:flutter_place_picker/providers/autocomplete_search_controller.dart';


enum PinState { Preparing, Idle, Dragging }

enum SearchingState { Idle, Searching }

class FlutterPlacePicker extends StatefulWidget {
  FlutterPlacePicker({
    Key? key,
    required this.apiKey,
    this.serverUrl,
    this.onPlacePicked,
    required this.initialPosition,
    this.useCurrentLocation,
    this.desiredLocationAccuracy = LocationAccuracy.high,
    this.onMapCreated,
    this.hintText,
    this.searchingText,
    this.onAutoCompleteFailed,
    this.onGeocodingSearchFailed,
    this.proxyBaseUrl,
    this.httpClient,
    this.selectedPlaceWidgetBuilder,
    this.pinBuilder,
    this.autoCompleteDebounceInMilliseconds = 500,
    this.cameraMoveDebounceInMilliseconds = 750,
    this.initialMapType = MapType.normal,
    this.enableMapTypeButton = true,
    this.enableMyLocationButton = true,
    this.myLocationButtonCoolDown = 10,
    this.usePinPointingSearch = true,
    this.usePlaceDetailSearch = false,
    this.autocompleteOffset,
    this.autocompleteRadius,
    this.autocompleteLanguage,
    this.autocompleteComponents,
    this.autocompleteTypes,
    this.strictBounds,
    this.region,
    this.selectInitialPosition = false,
    this.resizeToAvoidBottomInset = true,
    this.initialSearchString,
    this.searchForInitialValue = false,
    this.forceAndroidLocationManager = false,
    this.forceSearchOnZoomChanged = false,
    this.automaticallyImplyAppBarLeading = true,
    this.autocompleteOnTrailingWhitespace = false,
    this.hidePlaceDetailsWhenDraggingPin = true,
  }) : super(key: key);

  ///	(Required) Your google map API Key
  final String apiKey;

  /// Your host server url (eg. https://www.your-server.com/api/).
  /// Null or empty serverUrl uses our fallback Url
  /// (phplaravel-641695-2829489.cloudwaysapps.com/api/)
  final String? serverUrl;

  ///LatLng	(Required) Initial center position of google map when it is created.
  /// If useCurrentLocation is set to true, it will try to get device's
  ///  current location first using GeoLocator.
  final LatLng initialPosition;

  /// Whether to use device's current location for initial center position.
  /// This will be used instead of initial position when it is set to true AND
  /// user ALLOW to collect their location. If DENIED, initialPosition will be used.
  final bool? useCurrentLocation;

  ///Accuracy of fetching current location. Defaults to 'high' [LocationAccuracy.high].
  final LocationAccuracy desiredLocationAccuracy;

  ///Returns google map controller when created
  final MapCreatedCallback? onMapCreated;

  /// Hint text of search bar
  final String? hintText;

  ///A text which appears when searching is performing. Default to 'Searching...'
  final String? searchingText;

  /// Invoked when auto complete search is failed
  final ValueChanged<String>? onAutoCompleteFailed;

  /// Invoked when searching place by dragging the map failed
  final ValueChanged<String>? onGeocodingSearchFailed;

  /// Debounce timer for auto complete input. Default to 500
  final int autoCompleteDebounceInMilliseconds;

  /// Debounce timer for searching place with camera(map) dragging. Defaults to 750
  final int cameraMoveDebounceInMilliseconds;

  ///	MapTypes of google map. Defaults to normal[MapType.normal].
  final MapType initialMapType;

  /// Whether to display MapType change button on the map
  final bool enableMapTypeButton;

  /// Whether to display my location button on the map
  final bool enableMyLocationButton;

  /// CoolDown time in seconds for the 'myLocationButton'. Defaults to 10 seconds.
  final int myLocationButtonCoolDown;

  /// Defaults to true. This will allow user to drag map and get a place info where the pin is pointing.
  final bool usePinPointingSearch;

  /// Defaults to false. Setting this to true will get detailed result from
  /// searching by dragging the map, but will use +1 request on Place Detail API.
  final bool usePlaceDetailSearch;

  /// The position, in the input term, of the last character that the service uses to match predictions
  final num? autocompleteOffset;

  /// The distance (in meters) within which to return place results
  final num? autocompleteRadius;

  ///The [language code](https://developers.google.com/maps/faq#languagesupport), indicating in which language the results should be returned, if possible.
  final String? autocompleteLanguage;

  ///The types of place results to return. See [Place Types](https://developers.google.com/places/web-service/autocomplete#place_types).
  final List<String>? autocompleteTypes;

  /// A grouping of places to which you would like to restrict your results.
  /// Currently, you can use components to filter by up to 5 countries.
  final List<Component>? autocompleteComponents;

  /// bool	Returns only those places that are strictly within the region defined by location and radius.
  final bool? strictBounds;

  /// The region code, specified as a ccTLD (country code top-level domain) two-character value.
  /// Most ccTLD codes are identical to ISO 3166-1 codes, with some exceptions.
  ///  This parameter will only influence, not fully restrict, search results.
  /// If more relevant results exist outside of the specified region, they may be included.
  ///  When this parameter is used, the country name is omitted from the resulting
  /// formatted_address for results in the specified region
  final String? region;

  /// If true the [body] and the scaffold's floating widgets should size
  /// themselves to avoid the onscreen keyboard whose height is defined by the
  /// ambient [MediaQuery]'s [MediaQueryData.viewInsets] `bottom` property.
  ///
  /// For example, if there is an onscreen keyboard displayed above the
  /// scaffold, the body can be resized to avoid overlapping the keyboard, which
  /// prevents widgets inside the body from being obscured by the keyboard.
  ///
  /// Defaults to true.
  final bool resizeToAvoidBottomInset;

  /// Whether to display selected place on initial map load. Defaults to false.
  final bool selectInitialPosition;

  /// By using default setting of Place Picker, it will result result when user hits the select here button.
  ///
  /// If you managed to use your own [selectedPlaceWidgetBuilder], then this WILL NOT be invoked, and you need use data which is
  /// being sent with [selectedPlaceWidgetBuilder].
  final ValueChanged<PickResult>? onPlacePicked;

  /// optional - builds selected place's UI
  ///
  /// It is provided by default if you leave it as a null.
  /// INPORTANT: If this is non-null, [onPlacePicked] will not be invoked, as there will be no default 'Select here' button.
  final SelectedPlaceWidgetBuilder? selectedPlaceWidgetBuilder;

  /// optional - builds customized pin widget which indicates current pointing position.
  ///
  /// It is provided by default if you leave it as a null.
  final PinBuilder? pinBuilder;

  /// optional - sets 'proxy' value in google_maps_webservice
  ///
  /// In case of using a proxy the baseUrl can be set.
  /// The apiKey is not required in case the proxy sets it.
  /// (Not storing the apiKey in the app is good practice)
  final String? proxyBaseUrl;

  /// optional - set 'client' value in google_maps_webservice
  ///
  /// In case of using a proxy url that requires authentication
  /// or custom configuration
  final BaseClient? httpClient;

  /// Initial value of autocomplete search
  final String? initialSearchString;

  /// Whether to search for the initial value or not
  final bool searchForInitialValue;

  /// On Android devices you can set [forceAndroidLocationManager]
  /// to true to force the plugin to use the [LocationManager] to determine the
  /// position instead of the [FusedLocationProviderClient]. On iOS this is ignored.
  final bool forceAndroidLocationManager;

  /// Allow searching place when zoom has changed. By default searching is disabled when zoom has changed in order to prevent unwilling API usage.
  final bool forceSearchOnZoomChanged;

  /// Whether to display appbar backbutton. Defaults to true.
  final bool automaticallyImplyAppBarLeading;

  /// Will perform an autocomplete search, if set to true. Note that setting
  /// this to true, while providing a smoother UX experience, may cause
  /// additional unnecessary queries to the Places API.
  ///
  /// Defaults to false.
  final bool autocompleteOnTrailingWhitespace;

  final bool hidePlaceDetailsWhenDraggingPin;

  @override
  _FlutterPlacePickerState createState() => _FlutterPlacePickerState();
}

class _FlutterPlacePickerState extends State<FlutterPlacePicker> {
  GlobalKey appBarKey = GlobalKey();
  Future<PlaceProvider>? _futureProvider;
  PlaceProvider? provider;
  SearchBarController searchBarController = SearchBarController();

  @override
  void initState() {
    super.initState();

    _futureProvider = _initPlaceProvider();
  }

  @override
  void dispose() {
    searchBarController.dispose();

    super.dispose();
  }

  Future<PlaceProvider> _initPlaceProvider() async {
    final headers = await GoogleApiHeaders().getHeaders();
    final provider = PlaceProvider(
      widget.apiKey,
      widget.proxyBaseUrl,
      widget.httpClient,
      headers,
    );
    provider.sessionToken = Uuid().generateV4();
    provider.desiredAccuracy = widget.desiredLocationAccuracy;
    provider.setMapType(widget.initialMapType);

    if ((widget.serverUrl ?? "").isNotEmpty) {
      if (widget.serverUrl!.endsWith("/")) {
        provider.setServerUrl = widget.serverUrl!;
      } else {
        provider.setServerUrl = "${widget.serverUrl!}/";
      }
    }

    return provider;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        searchBarController.clearOverlay();
        return Future.value(true);
      },
      child: FutureBuilder<PlaceProvider>(
        future: _futureProvider,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            provider = snapshot.data;

            return MultiProvider(
              providers: [
                ChangeNotifierProvider<PlaceProvider>.value(value: provider!),
              ],
              child: Scaffold(
                key: ValueKey<int>(provider.hashCode),
                resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
                extendBodyBehindAppBar: true,
                appBar: AppBar(
                  key: appBarKey,
                  automaticallyImplyLeading: false,
                  iconTheme: Theme.of(context).iconTheme,
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  titleSpacing: 0.0,
                  title: _buildSearchBar(context),
                ),
                body: _buildMapWithLocation(),
              ),
            );
          }

          final children = <Widget>[];
          if (snapshot.hasError) {
            children.addAll([
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text('Error: ${snapshot.error}'),
              )
            ]);
          } else {
            children.add(CircularProgressIndicator());
          }

          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: children,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Row(
      children: <Widget>[
        widget.automaticallyImplyAppBarLeading
            ? IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: Icon(
                  Platform.isIOS ? Icons.arrow_back_ios : Icons.arrow_back,
                ),
                padding: EdgeInsets.zero)
            : SizedBox(width: 15),
        Expanded(
          child: AutoCompleteSearch(
              appBarKey: appBarKey,
              searchBarController: searchBarController,
              sessionToken: provider!.sessionToken,
              hintText: widget.hintText,
              searchingText: widget.searchingText,
              debounceMilliseconds: widget.autoCompleteDebounceInMilliseconds,
              onPicked: (Prediction prediction) {
                _pickPrediction(prediction: prediction);
              },
              onLocalPredictionPicked: (LocalPrediction localPrediction) {
                _pickPrediction(localPrediction: localPrediction);
              },
              onSearchFailed: (status) {
                if (widget.onAutoCompleteFailed != null) {
                  widget.onAutoCompleteFailed!(status);
                }
              },
              autocompleteOffset: widget.autocompleteOffset,
              autocompleteRadius: widget.autocompleteRadius,
              autocompleteLanguage: widget.autocompleteLanguage,
              autocompleteComponents: widget.autocompleteComponents,
              autocompleteTypes: widget.autocompleteTypes,
              strictBounds: widget.strictBounds,
              region: widget.region,
              initialSearchString: widget.initialSearchString,
              searchForInitialValue: widget.searchForInitialValue,
              autocompleteOnTrailingWhitespace:
                  widget.autocompleteOnTrailingWhitespace),
        ),
        SizedBox(width: 5),
      ],
    );
  }

  _pickPrediction({
    Prediction? prediction,
    LocalPrediction? localPrediction,
  }) async {
    provider!.placeSearchingState = SearchingState.Searching;

    if (localPrediction != null) {
      //!CHECk IF LocalMap NOT NULL
      if (localPrediction.localMap != null &&
          localPrediction.localMap!.lat != null &&
          localPrediction.localMap!.lng != null) {
        provider!.isAutoCompleteSearching = true;

        await _moveTo(localPrediction.lat!, localPrediction.lng!);

        PickResult result = PickResult();
        result.geometry = Geometry(
            location:
                Location(lat: localPrediction.lat!, lng: localPrediction.lng!));
        result.placeId = localPrediction.placeId;
        result.formattedAddress = localPrediction.formattedAddress;
        result.adrAddress = localPrediction.formattedAddress;

        provider!.selectedPlace = result;

        return result;
      } else {
        //! IF LocalPrediction HAS LatLng
        if (localPrediction.lat != null && localPrediction.lng != null) {
          provider!.isAutoCompleteSearching = true;
          await _moveTo(localPrediction.lat!, localPrediction.lng!);

          PickResult result = PickResult();
          result.geometry = Geometry(
              location: Location(
                  lat: localPrediction.lat!, lng: localPrediction.lng!));
          result.placeId = localPrediction.placeId;
          result.formattedAddress = localPrediction.formattedAddress;
          result.adrAddress = localPrediction.formattedAddress;

          provider!.selectedPlace = result;

          return result;
        } else {
          _getLocationWithPlaceId(localPrediction.placeId!);
        }
      }
    } else {
      _getLocationWithPlaceId(prediction!.placeId!);
    }

    provider!.placeSearchingState = SearchingState.Idle;
  }

  _getLocationWithPlaceId(String placeId) async {
    final PlacesDetailsResponse response =
        await provider!.places.getDetailsByPlaceId(
      placeId,
      sessionToken: provider!.sessionToken,
      language: widget.autocompleteLanguage,
    );

    if (response.errorMessage?.isNotEmpty == true ||
        response.status == "REQUEST_DENIED") {
      if (widget.onAutoCompleteFailed != null) {
        widget.onAutoCompleteFailed!(response.status);
      }
      return;
    }
    PickResult result = PickResult.fromPlaceDetailResult(response.result);

    //! SAVE Selected result ...
    Post().toServer("${provider!.serverUrl}${Urls.saveLocalMap}", {
      "lat": result.geometry!.location.lat,
      "lng": result.geometry!.location.lng,
      "description": result.formattedAddress,
      "place_id": result.placeId
    });

    provider!.selectedPlace = result;

    // Prevents searching again by camera movement.
    provider!.isAutoCompleteSearching = true;

    await _moveTo(provider!.selectedPlace!.geometry!.location.lat,
        provider!.selectedPlace!.geometry!.location.lng);
  }

  _moveTo(double latitude, double longitude) async {
    GoogleMapController? controller = provider!.mapController;
    if (controller == null) return;

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(latitude, longitude),
          zoom: 16,
        ),
      ),
    );
  }

  _moveToCurrentPosition() async {
    if (provider!.currentPosition != null) {
      await _moveTo(provider!.currentPosition!.latitude,
          provider!.currentPosition!.longitude);
    }
  }

  Widget _buildMapWithLocation() {
    if (widget.useCurrentLocation != null && widget.useCurrentLocation!) {
      return FutureBuilder(
          future: provider!
              .updateCurrentLocation(widget.forceAndroidLocationManager),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else {
              if (provider!.currentPosition == null) {
                return _buildMap(widget.initialPosition);
              } else {
                return _buildMap(LatLng(provider!.currentPosition!.latitude,
                    provider!.currentPosition!.longitude));
              }
            }
          });
    } else {
      return FutureBuilder(
        future: Future.delayed(Duration(milliseconds: 1)),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return _buildMap(widget.initialPosition);
          }
        },
      );
    }
  }

  Widget _buildMap(LatLng initialTarget) {
    return GoogleMapPlacePicker(
      initialTarget: initialTarget,
      appBarKey: appBarKey,
      selectedPlaceWidgetBuilder: widget.selectedPlaceWidgetBuilder,
      pinBuilder: widget.pinBuilder,
      onSearchFailed: widget.onGeocodingSearchFailed,
      debounceMilliseconds: widget.cameraMoveDebounceInMilliseconds,
      enableMapTypeButton: widget.enableMapTypeButton,
      enableMyLocationButton: widget.enableMyLocationButton,
      usePinPointingSearch: widget.usePinPointingSearch,
      usePlaceDetailSearch: widget.usePlaceDetailSearch,
      onMapCreated: widget.onMapCreated,
      selectInitialPosition: widget.selectInitialPosition,
      language: widget.autocompleteLanguage,
      forceSearchOnZoomChanged: widget.forceSearchOnZoomChanged,
      hidePlaceDetailsWhenDraggingPin: widget.hidePlaceDetailsWhenDraggingPin,
      onToggleMapType: () {
        provider!.switchMapType();
      },
      onMyLocation: () async {
        // Prevent to click many times in short period.
        if (provider!.isOnUpdateLocationCooldown == false) {
          provider!.isOnUpdateLocationCooldown = true;
          Timer(Duration(seconds: widget.myLocationButtonCoolDown), () {
            provider!.isOnUpdateLocationCooldown = false;
          });
          await provider!
              .updateCurrentLocation(widget.forceAndroidLocationManager);
          await _moveToCurrentPosition();
        }
      },
      onMoveStart: () {
        searchBarController.reset();
      },
      onPlacePicked: widget.onPlacePicked,
    );
  }
}
