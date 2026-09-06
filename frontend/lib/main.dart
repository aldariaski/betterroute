import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
void main()=>runApp(const BetterRouteApp());
class BetterRouteApp extends StatelessWidget { const BetterRouteApp({super.key}); @override Widget build(BuildContext context)=>MaterialApp(debugShowCheckedModeBanner:false,title:'BetterRoute',theme:ThemeData(useMaterial3:true,colorSchemeSeed:Colors.blue),home:const HomeScreen()); }
