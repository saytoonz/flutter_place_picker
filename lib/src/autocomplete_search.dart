import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_place_picker/flutter_place_picker.dart';
import 'package:flutter_place_picker/models/local_prediction.dart';
import 'package:flutter_place_picker/providers/place_provider.dart';
import 'package:flutter_place_picker/providers/search_provider.dart';
import 'package:flutter_place_picker/resources/get_from_server.dart';
import 'package:flutter_place_picker/resources/post_to_server.dart';
import 'package:flutter_place_picker/utils/urls.dart';
import 'package:flutter_place_picker/widgets/prediction_tile.dart';
import 'package:flutter_place_picker/providers/autocomplete_search_controller.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:provider/provider.dart';

class AutoCompleteSearch extends StatefulWidget {
  const AutoCompleteSearch(
      {Key? key,
      required this.sessionToken,
      required this.onPicked,
      required this.onLocalPredictionPicked,
      required this.appBarKey,
      this.hintText,
      this.searchingText = "Searching...",
      this.height = 40,
      this.contentPadding = EdgeInsets.zero,
      this.debounceMilliseconds,
      this.onSearchFailed,
      required this.searchBarController,
      this.autocompleteOffset,
      this.autocompleteRadius,
      this.autocompleteLanguage,
      this.autocompleteComponents,
      this.autocompleteTypes,
      this.strictBounds,
      this.region,
      this.initialSearchString,
      this.searchForInitialValue,
      this.autocompleteOnTrailingWhitespace})
      : super(key: key);

  final String? sessionToken;
  final String? hintText;
  final String? searchingText;
  final double height;
  final EdgeInsetsGeometry contentPadding;
  final int? debounceMilliseconds;
  final ValueChanged<Prediction> onPicked;
  final ValueChanged<LocalPrediction> onLocalPredictionPicked;
  final ValueChanged<String>? onSearchFailed;
  final SearchBarController searchBarController;
  final num? autocompleteOffset;
  final num? autocompleteRadius;
  final String? autocompleteLanguage;
  final List<String>? autocompleteTypes;
  final List<Component>? autocompleteComponents;
  final bool? strictBounds;
  final String? region;
  final GlobalKey appBarKey;
  final String? initialSearchString;
  final bool? searchForInitialValue;
  final bool? autocompleteOnTrailingWhitespace;

  @override
  AutoCompleteSearchState createState() => AutoCompleteSearchState();
}

class AutoCompleteSearchState extends State<AutoCompleteSearch> {
  TextEditingController controller = TextEditingController();
  FocusNode focus = FocusNode();
  OverlayEntry? overlayEntry;
  SearchProvider provider = SearchProvider();

  @override
  void initState() {
    super.initState();
    if (widget.initialSearchString != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.text = widget.initialSearchString!;
        if (widget.searchForInitialValue!) {
          _onSearchInputChange();
        }
      });
    }
    controller.addListener(_onSearchInputChange);
    focus.addListener(_onFocusChanged);

    widget.searchBarController.attach(this);
  }

  @override
  void dispose() {
    controller.removeListener(_onSearchInputChange);
    controller.dispose();

    focus.removeListener(_onFocusChanged);
    focus.dispose();
    _clearOverlay();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: provider,
      child: RoundedFrame(
        height: widget.height,
        padding: const EdgeInsets.only(right: 10),
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.black54
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 8.0,
        child: Row(
          children: [
            SizedBox(width: 10),
            Icon(Icons.search),
            SizedBox(width: 10),
            Expanded(child: _buildSearchTextField()),
            _buildTextClearIcon(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchTextField() {
    return TextField(
      controller: controller,
      focusNode: focus,
      decoration: InputDecoration(
        hintText: widget.hintText,
        border: InputBorder.none,
        isDense: true,
        contentPadding: widget.contentPadding,
      ),
    );
  }

  Widget _buildTextClearIcon() {
    return Selector<SearchProvider, String>(
        selector: (_, provider) => provider.searchTerm,
        builder: (_, data, __) {
          if (data.length > 0) {
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: GestureDetector(
                child: Icon(
                  Icons.clear,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
                onTap: () {
                  clearText();
                },
              ),
            );
          } else {
            return SizedBox(width: 10);
          }
        });
  }

  _onSearchInputChange() {
    if (!mounted) return;
    this.provider.searchTerm = controller.text;

    PlaceProvider provider = PlaceProvider.of(context, listen: false);

    if (controller.text.isEmpty) {
      provider.debounceTimer?.cancel();
      _searchPlace(controller.text);
      return;
    }

    if (controller.text.trim() == this.provider.prevSearchTerm.trim()) {
      provider.debounceTimer?.cancel();
      return;
    }

    if (!widget.autocompleteOnTrailingWhitespace! &&
        controller.text.substring(controller.text.length - 1) == " ") {
      provider.debounceTimer?.cancel();
      return;
    }

    if (provider.debounceTimer?.isActive ?? false) {
      provider.debounceTimer!.cancel();
    }

    provider.debounceTimer =
        Timer(Duration(milliseconds: widget.debounceMilliseconds!), () {
      _searchPlace(controller.text.trim());
    });
  }

  _onFocusChanged() {
    PlaceProvider provider = PlaceProvider.of(context, listen: false);
    provider.isSearchBarFocused = focus.hasFocus;
    provider.debounceTimer?.cancel();
    provider.placeSearchingState = SearchingState.Idle;
  }

  _searchPlace(String searchTerm) {
    this.provider.setPrevSearchTerm = searchTerm;

    _clearOverlay();

    if (searchTerm.length < 1) return;

    _displayOverlay(_buildSearchingOverlay());

    _performAutoCompleteSearch(searchTerm);
  }

  _clearOverlay() {
    if (overlayEntry != null) {
      overlayEntry!.remove();
      overlayEntry = null;
    }
  }

  _displayOverlay(Widget overlayChild) {
    _clearOverlay();

    final RenderBox? appBarRenderBox =
        widget.appBarKey.currentContext!.findRenderObject() as RenderBox?;
    final screenWidth = MediaQuery.of(context).size.width;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: appBarRenderBox!.size.height,
        left: screenWidth * 0.025,
        right: screenWidth * 0.025,
        child: Material(
          elevation: 4.0,
          child: overlayChild,
        ),
      ),
    );

    Overlay.of(context)!.insert(overlayEntry!);
  }

  Widget _buildSearchingOverlay() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        children: [
          SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(),
          ),
          SizedBox(width: 24),
          Expanded(
            child: Text(
              widget.searchingText ?? "Searching...",
              style: TextStyle(fontSize: 16),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPredictionOverlay({
    List<Prediction>? predictions,
    List<LocalPrediction>? localPrediction,
  }) {
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          child: Column(
            children: (predictions ?? localPrediction ?? [])
                .map(
                  (p) => PredictionTile(
                    prediction: predictions == null ? null : p as Prediction,
                    localPrediction:
                        localPrediction == null ? null : p as LocalPrediction,
                    onTap: (Prediction selectedPrediction) {
                      resetSearchBar();
                      widget.onPicked(selectedPrediction);
                    },
                    onLocPreTap: (LocalPrediction selectedPrediction) {
                      resetSearchBar();
                      widget.onLocalPredictionPicked(selectedPrediction);
                    },
                  ),
                )
                .toList(),
          ),
        ));
  }

  _performAutoCompleteSearch(String searchTerm) async {
    PlaceProvider provider = PlaceProvider.of(context, listen: false);

    if (searchTerm.isNotEmpty) {
      //! SEARCH FROM BACKEND

      String resp = await Get()
          .fromServer("${provider.serverUrl}${Urls.localMapSearch}$searchTerm");

      try {
        dynamic jRes = jsonDecode(resp);
        if (jRes["error"]) {
          widget.onSearchFailed!(jRes["msg"]);
          return;
        } else {
          if (jRes["data"].length > 0) {
            //! has data
            List<LocalPrediction> localPrediction = List<LocalPrediction>.from(
                jRes['data']
                    .map((e) => LocalPrediction.fromMap(e, searchTerm))
                    .toList());
            return _displayOverlay(
                _buildPredictionOverlay(localPrediction: localPrediction));
          } else {
            final PlacesAutocompleteResponse response =
                await provider.places.autocomplete(
              searchTerm,
              sessionToken: widget.sessionToken,
              location: provider.currentPosition == null
                  ? null
                  : Location(
                      lat: provider.currentPosition!.latitude,
                      lng: provider.currentPosition!.longitude),
              offset: widget.autocompleteOffset,
              radius: widget.autocompleteRadius,
              language: widget.autocompleteLanguage,
              types: widget.autocompleteTypes ?? const [],
              components: widget.autocompleteComponents ?? const [],
              strictbounds: widget.strictBounds ?? false,
              region: widget.region,
            );

            if (response.errorMessage?.isNotEmpty == true ||
                response.status == "REQUEST_DENIED") {
              if (widget.onSearchFailed != null) {
                widget.onSearchFailed!(response.status);
              }
              return;
            }

            //! save Predictions to local server......
            Post().toServer("${provider.serverUrl}${Urls.savePlaceId}", {
              "places": response.predictions
                  .map((e) =>
                      {'description': e.description, 'place_id': e.placeId})
                  .toList(),
            });

            _displayOverlay(
                _buildPredictionOverlay(predictions: response.predictions));
          }
        }
      } catch (e) {
        debugPrint(e.toString());
        return widget.onSearchFailed!(e.toString());
      }
    }
  }

  clearText() {
    provider.searchTerm = "";
    controller.clear();
  }

  resetSearchBar() {
    clearText();
    focus.unfocus();
  }

  clearOverlay() {
    _clearOverlay();
  }
}
