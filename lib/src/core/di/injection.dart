import 'package:get_it/get_it.dart';
import 'package:trudeals_realty_crm/src/core/network/network_client.dart';
import 'package:trudeals_realty_crm/src/core/network/mock_network_client.dart';

import 'package:trudeals_realty_crm/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:trudeals_realty_crm/src/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:trudeals_realty_crm/src/features/auth/domain/usecases/login_usecase.dart';
import 'package:trudeals_realty_crm/src/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:trudeals_realty_crm/src/features/auth/domain/usecases/logout_usecase.dart';
import 'package:trudeals_realty_crm/src/features/auth/presentation/cubits/auth_cubit.dart';

import 'package:trudeals_realty_crm/src/features/contacts/domain/repositories/contacts_repository.dart';
import 'package:trudeals_realty_crm/src/features/contacts/data/repositories/contacts_repository_impl.dart';
import 'package:trudeals_realty_crm/src/features/contacts/domain/usecases/get_contacts_usecase.dart';
import 'package:trudeals_realty_crm/src/features/contacts/domain/usecases/update_contact_stage_usecase.dart';
import 'package:trudeals_realty_crm/src/features/contacts/domain/usecases/create_contact_usecase.dart';
import 'package:trudeals_realty_crm/src/features/contacts/presentation/cubits/pipeline_cubit.dart';
import 'package:trudeals_realty_crm/src/features/contacts/presentation/cubits/contact_detail_cubit.dart';

import 'package:trudeals_realty_crm/src/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:trudeals_realty_crm/src/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:trudeals_realty_crm/src/features/dashboard/presentation/cubits/dashboard_cubit.dart';

import 'package:trudeals_realty_crm/src/features/calendar/presentation/cubits/calendar_cubit.dart';

import 'package:trudeals_realty_crm/src/features/automations/domain/repositories/workflow_repository.dart';
import 'package:trudeals_realty_crm/src/features/automations/data/repositories/workflow_repository_impl.dart';
import 'package:trudeals_realty_crm/src/features/automations/presentation/cubits/workflow_cubit.dart';
import 'package:trudeals_realty_crm/src/features/automations/logic/automation_engine.dart';

import 'package:trudeals_realty_crm/src/features/settings/domain/repositories/settings_repository.dart';
import 'package:trudeals_realty_crm/src/features/settings/data/repositories/settings_repository_impl.dart';

final getIt = GetIt.instance;

Future<void> initializeDependencies() async {
  // Logic
  getIt.registerLazySingleton<AutomationEngine>(() => AutomationEngine());

  // Networking
  getIt.registerLazySingleton<NetworkClient>(() => MockNetworkClient());

  // Repositories
  getIt
    ..registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(getIt()))
    ..registerLazySingleton<ContactsRepository>(() => ContactsRepositoryImpl(getIt()))
    ..registerLazySingleton<DashboardRepository>(() => DashboardRepositoryImpl(getIt()))
    ..registerLazySingleton<WorkflowRepository>(() => WorkflowRepositoryImpl(getIt()))
    ..registerLazySingleton<SettingsRepository>(() => SettingsRepositoryImpl(getIt()));

  // Use Cases
  getIt
    ..registerLazySingleton(() => LoginUseCase(getIt()))
    ..registerLazySingleton(() => GetCurrentUserUseCase(getIt()))
    ..registerLazySingleton(() => LogoutUseCase(getIt()))
    ..registerLazySingleton(() => GetContactsUseCase(getIt()))
    ..registerLazySingleton(() => CreateContactUseCase(getIt()))
    ..registerLazySingleton(() => UpdateContactStageUseCase(getIt()));

  // Cubits
  getIt
    ..registerLazySingleton<AuthCubit>(() => AuthCubit(getIt(), getIt(), getIt()))
    ..registerFactory<PipelineCubit>(() => PipelineCubit(getIt(), getIt()))
    ..registerFactory<ContactDetailCubit>(() => ContactDetailCubit(getIt()))
    ..registerFactory<DashboardCubit>(() => DashboardCubit(getIt()))
    ..registerFactory<CalendarCubit>(() => CalendarCubit(getIt()))
    ..registerFactory<WorkflowCubit>(() => WorkflowCubit(getIt()));
}
