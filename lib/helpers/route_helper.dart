import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
/*import 'package:safebusiness/screens/Auth/create_account.dart';*/
//import 'package:safebusiness/screens/Auth/forgot_password.dart';
import 'package:safebusiness/screens/Auth/login_page.dart';
import 'package:safebusiness/screens/reports.dart';

class RouteHelper {
  static final FluroRouter router = FluroRouter();

  static String home = '/home';
  static String reports = '/reports';
  static String createAccount = '/create-account';
  static String login = '/login';
  static String forgotPassword = '/forgot-password';
  static String paybill = '/pay-bill';
  static String loanFirst = '/loan-first';
  static String getloan = '/get-loan';
  static String loansPage = '/loans-page';
  static String loanPayment = '/loan-payment';
  static String manageLoans = '/manage-loans';
  static String fundAccount = '/fund-account';
  static String addSaving = '/add-savings';
  static String saccoDetails = '/sacco-details';
  static String statExpenses = '/stat-expenses';
  static String allTransactions = '/all-transactions';
  static String account = '/account';
  static String editProfile = '/edit-profile';
  static String chat = '/chat';
  static String notification = '/notification';
  static String allProducts = '/all-products';
  static String productDetails = '/product-details';
  static String categoryProductsScreen = '/category-products-screen';

  /*static final Handler _createAccountHandler = Handler(
      handlerFunc: (BuildContext? context, Map<String, dynamic> params) =>
          const CreateAccount());*/
  static final Handler _reportsHandler = Handler(
      handlerFunc: (BuildContext? context, Map<String, dynamic> params) =>
          const Report());
  static final Handler _loginHandler = Handler(
      handlerFunc: (BuildContext? context, Map<String, dynamic> params) =>
          const LoginPage());
  /*static final Handler _forgotPasswordHandler = Handler(
      handlerFunc: (BuildContext? context, Map<String, dynamic> params) =>
          const ForgotPassword());*/

  static void setupRouter() {
    /*router.define(createAccount,
        handler: _createAccountHandler, transitionType: TransitionType.fadeIn);*/
    router.define(reports,
        handler: _reportsHandler, transitionType: TransitionType.fadeIn);
    router.define(login,
        handler: _loginHandler, transitionType: TransitionType.fadeIn);
    /*router.define(forgotPassword,
        handler: _forgotPasswordHandler, transitionType: TransitionType.fadeIn);*/
  }
}
