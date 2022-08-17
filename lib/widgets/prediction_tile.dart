import 'package:flutter/material.dart';
import 'package:flutter_place_picker/models/local_prediction.dart';
import 'package:google_maps_webservice/places.dart';

class PredictionTile extends StatelessWidget {
  final Prediction? prediction;
  final LocalPrediction? localPrediction;
  final ValueChanged<Prediction>? onTap;
  final ValueChanged<LocalPrediction>? onLocPreTap;

  PredictionTile(
      {this.localPrediction, this.prediction, this.onLocPreTap, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.location_on),
      title: RichText(
        text: TextSpan(
          children: _buildPredictionText(context),
        ),
      ),
      onTap: () {
        if (onTap != null) {
          if (prediction != null) onTap!(prediction!);
          if (localPrediction != null) onLocPreTap!(localPrediction!);
        }
      },
    );
  }

  List<TextSpan> _buildPredictionText(BuildContext context) {
    final List<TextSpan> result = <TextSpan>[];
    final textColor = Theme.of(context).textTheme.bodyText2!.color;

    if (prediction != null && prediction!.matchedSubstrings.length > 0) {
      MatchedSubstring matchedSubString = prediction!.matchedSubstrings[0];
      // There is no matched string at the beginning.
      if (matchedSubString.offset > 0) {
        result.add(
          TextSpan(
            text: (prediction?.description ?? localPrediction?.formattedAddress)
                ?.substring(0, matchedSubString.offset as int?),
            style: TextStyle(
                color: textColor, fontSize: 16, fontWeight: FontWeight.w300),
          ),
        );
      }

      // Matched strings.
      result.add(
        TextSpan(
          text: (prediction?.description ?? localPrediction?.formattedAddress)
              ?.substring(matchedSubString.offset as int,
                  matchedSubString.offset + matchedSubString.length as int?),
          style: TextStyle(
              color: textColor, fontSize: 16, fontWeight: FontWeight.w500),
        ),
      );

      // Other strings.
      if (matchedSubString.offset + matchedSubString.length <
          ((prediction?.description?.length ??
                  localPrediction?.formattedAddress?.length) ??
              0)) {
        result.add(
          TextSpan(
            text: (prediction?.description ?? localPrediction?.formattedAddress)
                ?.substring(
                    matchedSubString.offset + matchedSubString.length as int),
            style: TextStyle(
                color: textColor, fontSize: 16, fontWeight: FontWeight.w300),
          ),
        );
      }
      // If there is no matched strings, but there are predicts. (Not sure if this happens though)
    } else {
      result.add(
        TextSpan(
          text: (prediction?.description ?? localPrediction?.formattedAddress),
          style: TextStyle(
              color: textColor, fontSize: 16, fontWeight: FontWeight.w300),
        ),
      );
    }

    return result;
  }
}
