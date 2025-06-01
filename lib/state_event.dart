import 'package:flanvas/canvas_ops.dart';
import 'package:flanvas/canvas_state.dart';

sealed class FlanvasEvent {
  void apply(FlanvasState state) => state.apply(this);
}

class RemoveOpEv extends FlanvasEvent {
  final CanvasOp op;
  final List<CanvasOp>? other;

  RemoveOpEv({required this.op, this.other});

  factory RemoveOpEv.fromList(List<CanvasOp> selectedOps) {
    return RemoveOpEv(
      op: selectedOps.first,
      other: selectedOps.skip(1).toList(),
    );
  }
}

class TransformOpEv extends FlanvasEvent {
  final TransformCanvasOp op;
  final List<CanvasOp> selectedOps;

  TransformOpEv({required this.op, required this.selectedOps});
}

class AddOpEv extends FlanvasEvent {
  final CanvasOp op;
  final List<CanvasOp>? other;
  final int? index;

  AddOpEv({required this.op, this.other, this.index});

  factory AddOpEv.fromList(List<CanvasOp> selectedOps) {
    return AddOpEv(op: selectedOps.first, other: selectedOps.skip(1).toList());
  }
}

class ReorderOpEv extends FlanvasEvent {
  final CanvasOp op;
  final int index;
  final int previousIndex;

  ReorderOpEv({
    required this.op,
    required this.index,
    required this.previousIndex,
  });
}

class UpdateAllOpsEv extends FlanvasEvent {
  final List<CanvasOp> ops;
  final List<CanvasOp> previousOps;

  UpdateAllOpsEv({required this.ops, required this.previousOps});
}
