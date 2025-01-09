import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/single_child_widget.dart';
import 'package:provider/provider.dart';
import 'package:techtruckers/features/auth/bloc/auth_bloc.dart';
import 'package:techtruckers/features/dispatch/bloc/dispatcher_bloc.dart';
import 'package:techtruckers/features/navigation/application_preferences.dart';
import 'package:techtruckers/features/navigation/route_preferences_model.dart';

class BlocGenerator {
  BlocGenerator._();

  static List<SingleChildWidget> generateBloc() {
    return [
      BlocProvider<AuthBloc>(
        create: (BuildContext context) => AuthBloc(),
      ),
      BlocProvider<DispatcherBloc>(
        create: (BuildContext context) => DispatcherBloc(),
      ),
      ChangeNotifierProvider(create: (context) => RoutePreferencesModel.withDefaults()),
      ChangeNotifierProvider(create: (context) => AppPreferences()),
    ];
  }
}