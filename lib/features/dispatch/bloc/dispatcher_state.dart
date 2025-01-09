part of 'dispatcher_bloc.dart';

@immutable
sealed class DispatcherState extends Equatable {
  const DispatcherState();

  @override
  List<Object> get props => [];
}

final class DispatcherInitial extends DispatcherState {}

class DispatcherLoading extends DispatcherState {}

class ChangeStatusLoading extends DispatcherState {
  final String? message;

  ChangeStatusLoading({this.message});
}

class DispatcherFailure extends DispatcherState {
  final String mError;

  const DispatcherFailure({required this.mError});

  @override
  List<Object> get props => [mError];
}

class AutoLogoutFailure extends DispatcherState {}

class DispatcherResponseState extends DispatcherState {
  final DispatchLoadDataModel data;

  const DispatcherResponseState(this.data);

  @override
  List<Object> get props => [data];
}

class UpcomingDispatcherResponseState extends DispatcherState {
  final bool showJobDone;
  final DispatchLoadDataModel data;

  const UpcomingDispatcherResponseState(this.data, this.showJobDone);

  @override
  List<Object> get props => [data];
}

class AcceptRejectDispatcherState extends DispatcherState {
  final bool isSuccess;

  const AcceptRejectDispatcherState(this.isSuccess);

  @override
  List<Object> get props => [isSuccess];
}

class StartTripState extends DispatcherState {
  final bool isSuccess;
  final bool isEndTrip;

  const StartTripState(this.isSuccess, this.isEndTrip);

  @override
  List<Object> get props => [isSuccess];
}

class UpdateStopState extends DispatcherState {
  final bool isSuccess;
  final String message;

  const UpdateStopState(this.isSuccess, this.message);

  @override
  List<Object> get props => [isSuccess];
}

class UploadBOLState extends DispatcherState {
  final bool isSuccess;

  const UploadBOLState(this.isSuccess);

  @override
  List<Object> get props => [isSuccess];
}

class StopRejectionState extends DispatcherState {
  final bool isSuccess;
  final int type;

  const StopRejectionState(this.isSuccess, this.type);

  @override
  List<Object> get props => [isSuccess, type];
}

class UploadReceiptState extends DispatcherState {
  final bool isSuccess;

  const UploadReceiptState(this.isSuccess);

  @override
  List<Object> get props => [isSuccess];
}

class UploadFileLoadingState extends DispatcherState {}

class UploadFileSuccessState extends DispatcherState {
  final bool isProduct;
  final String fileUrl;

  UploadFileSuccessState({required this.fileUrl, required this.isProduct});
}

class UploadFileErrorState extends DispatcherState {
  final String mError;

  UploadFileErrorState({required this.mError});
}