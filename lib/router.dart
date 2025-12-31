import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:abayka/services/auth_repository.dart';
import 'package:abayka/screens/login_screen.dart';
import 'package:abayka/screens/signup_screen.dart';
import 'package:abayka/screens/admin/admin_dashboard_screen.dart';
import 'package:abayka/screens/admin/admin_users_screen.dart';
import 'package:abayka/screens/admin/admin_products_screen.dart';
import 'package:abayka/screens/admin/add_product_screen.dart';
import 'package:abayka/screens/user/product_details_screen.dart';
import 'package:abayka/screens/user_screen.dart';
import 'package:abayka/product.dart';
import 'package:abayka/screens/splash_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final authRepo = ref.watch(authRepositoryProvider);

  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboard(),
        routes: [
          GoRoute(
            path: 'users',
            builder: (context, state) => const UsersManagementScreen(),
          ),
          GoRoute(
            path: 'products',
            builder: (context, state) => const AdminProductsScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) {
                  final product = state.extra as Product?;
                  return AddProductScreen(product: product);
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/user',
        builder: (context, state) => const UserDashboard(),
      ),
      GoRoute(
        path: '/product/:id',
        builder: (context, state) {
          final product = state.extra as Product;
          return ProductDetailsScreen(product: product);
        },
      ),
    ],
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final hasError = authState.hasError;
      final isAuthenticated = authState.value?.session != null;
      
      if (isLoading || hasError) return null;

      final isLoginRoute = state.uri.path == '/login';
      final isRegisterRoute = state.uri.path == '/register';
      final isSplashRoute = state.uri.path == '/';

      if (!isAuthenticated) {
        return (isLoginRoute || isRegisterRoute) ? null : '/login';
      }

      if (isLoginRoute || isRegisterRoute || isSplashRoute) {
        if (authRepo.isAdmin) {
          return '/admin';
        } else {
          return '/user';
        }
      }

      // Simple role-based guard
      if (state.uri.path.startsWith('/admin') && !authRepo.isAdmin) {
        return '/user';
      }

      return null;
    },
  );
});
