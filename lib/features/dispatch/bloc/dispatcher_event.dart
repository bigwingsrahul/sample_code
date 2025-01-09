part of 'dispatcher_bloc.dart';

@immutable
sealed class DispatcherEvent extends Equatable {
  const DispatcherEvent();

  @override
  List<Object> get props => [];
}

class NewDispatcherLoadEvent extends DispatcherEvent {
  final bool emitLoader;
  const NewDispatcherLoadEvent(this.emitLoader);

  @override
  List<Object> get props => [];
}

class UpcomingDispatcherLoadEvent extends DispatcherEvent {

  final bool? showJobDone;
  final bool emitLoader;

  const UpcomingDispatcherLoadEvent(this.emitLoader, {this.showJobDone});

  @override
  List<Object> get props => [];
}

class AcceptOrRejectDispatchEvent extends DispatcherEvent {
  final String loadId;
  final Map<String, dynamic> body;

  const AcceptOrRejectDispatchEvent(this.loadId, this.body);

  @override
  List<Object> get props => [loadId, body];
}

class StartTripEvent extends DispatcherEvent {
  final Map<String, dynamic> body;
  final String loadId;

  const StartTripEvent(this.loadId, this.body);

  @override
  List<Object> get props => [loadId, body];
}

class UpdateStopStatusEvent extends DispatcherEvent {
  final Map<String, dynamic> body;

  const UpdateStopStatusEvent({required this.body});

  @override
  List<Object> get props => [body];
}

class UploadBOLEvent extends DispatcherEvent {
  final int stopId;
  final XFile file;

  const UploadBOLEvent({required this.stopId, required this.file});

  @override
  List<Object> get props => [stopId, file];
}

class NoRejectionEvent extends DispatcherEvent {
  final String stopId;
  final int type;
  final Map<String, dynamic> body;

  const NoRejectionEvent({required this.body, required this.stopId, required this.type});

  @override
  List<Object> get props => [body, stopId, type];
}

class StopRejectionEvent extends DispatcherEvent {
  final String stopId;
  final int type;
  final RejectionRequestModel rejectionRequestModel;

  const StopRejectionEvent({required this.stopId, required this.rejectionRequestModel, required this.type});

  @override
  List<Object> get props => [stopId, rejectionRequestModel, type];
}

class UploadReceiptEvent extends DispatcherEvent {
  final int stopId;
  final XFile file;

  const UploadReceiptEvent({required this.stopId, required this.file});

  @override
  List<Object> get props => [stopId, file];
}

class UploadRejectDocEvent extends DispatcherEvent {
  final bool isProduct;
  final XFile file;

  const UploadRejectDocEvent({required this.file, required this.isProduct});

  @override
  List<Object> get props => [file];
}