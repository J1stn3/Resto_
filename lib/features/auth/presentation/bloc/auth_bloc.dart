import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/models/user.dart';
import '../../data/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repo) : super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheck);
    on<AuthLoginRequested>(_onLogin);
    on<AuthSignUpRequested>(_onSignUp);
    on<AuthLogoutRequested>(_onLogout);
  }

  final AuthRepository _repo;

  Future<void> _onCheck(AuthCheckRequested event, Emitter<AuthState> emit) async {
    if (!_repo.isAuthenticated) {
      emit(const AuthUnauthenticated());
      return;
    }
    try {
      final user = await _repo.validateSession();
      emit(AuthAuthenticated(user));
    } catch (_) {
      await _repo.logout();
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLogin(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final user = await _repo.login(event.email, event.password);
      emit(AuthAuthenticated(user));
    } catch (e) {
      final message = e.toString().replaceFirst('ApiException: ', '');
      emit(AuthError(message));
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onSignUp(AuthSignUpRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final user = await _repo.signUp(event.name, event.email, event.password);
      emit(AuthAuthenticated(user));
    } catch (e) {
      final message = e.toString().replaceFirst('ApiException: ', '');
      emit(AuthError(message));
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLogout(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    await _repo.logout();
    emit(const AuthUnauthenticated());
  }
}
