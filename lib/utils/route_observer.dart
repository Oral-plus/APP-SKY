import 'package:flutter/material.dart';

/// Observador global para pausar video del dashboard al navegar a otra pantalla.
final RouteObserver<ModalRoute<void>> appRouteObserver =
    RouteObserver<ModalRoute<void>>();
