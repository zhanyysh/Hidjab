import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:abayka/features/auth/data/auth_repository.dart';
import 'package:abayka/features/auth/presentation/login_screen.dart';
import 'package:abayka/features/auth/presentation/register_screen.dart';
import 'package:abayka/features/admin/presentation/admin_dashboard.dart';
import 'package:abayka/features/admin/presentation/users_management_screen.dart';
import 'package:abayka/features/products/presentation/admin_products_screen.dart';
import 'package:abayka/features/products/presentation/add_product_screen.dart';
import 'package:abayka/features/shop/presentation/product_details_screen.dart';
import 'package:abayka/features/user/presentation/user_dashboard.dart';
import 'package:abayka/features/products/domain/product.dart';
import 'package:abayka/features/home/presentation/splash_screen.dart';

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
                builder: (context, state) => const AddProductScreen(),
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
