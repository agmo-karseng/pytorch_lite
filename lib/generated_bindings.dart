// AUTO GENERATED FILE, DO NOT EDIT.
//
// Generated by `package:ffigen`.
// ignore_for_file: type=lint
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart' as pkg_ffi;

/// Bindings to `headers/example.h`.
class NativeLibrary {
  /// Holds the symbol lookup function.
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
      _lookup;

  /// The symbols are looked up in [dynamicLibrary].
  NativeLibrary(ffi.DynamicLibrary dynamicLibrary)
      : _lookup = dynamicLibrary.lookup;

  /// The symbols are looked up with [lookup].
  NativeLibrary.fromLookup(
      ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
          lookup)
      : _lookup = lookup;

  ModelLoadResult load_ml_model(
    ffi.Pointer<pkg_ffi.Utf8> model_path,
  ) {
    return _load_ml_model(
      model_path,
    );
  }

  late final _load_ml_modelPtr = _lookup<
      ffi.NativeFunction<
          ModelLoadResult Function(
              ffi.Pointer<pkg_ffi.Utf8>)>>('load_ml_model');
  late final _load_ml_model = _load_ml_modelPtr
      .asFunction<ModelLoadResult Function(ffi.Pointer<pkg_ffi.Utf8>)>();

  OutputData modelInference(
    int index,
    ffi.Pointer<ffi.Float> input_data_ptr,
  ) {
    return _modelInference(
      index,
      input_data_ptr,
    );
  }

  late final _modelInferencePtr = _lookup<
      ffi.NativeFunction<
          OutputData Function(
              ffi.Int, ffi.Pointer<ffi.Float>)>>('modelInference');
  late final _modelInference = _modelInferencePtr
      .asFunction<OutputData Function(int, ffi.Pointer<ffi.Float>)>();

  OutputData image_model_inference(
    int index,
    ffi.Pointer<ffi.UnsignedChar> data,
    int height,
    int width,
    int objectDetectionFlag,
    ffi.Pointer<ffi.Float> output_data,
  ) {
    return _image_model_inference(
      index,
      data,
      height,
      width,
      objectDetectionFlag,
      output_data,
    );
  }

  late final _image_model_inferencePtr = _lookup<
      ffi.NativeFunction<
          OutputData Function(
              ffi.Int,
              ffi.Pointer<ffi.UnsignedChar>,
              ffi.Int,
              ffi.Int,
              ffi.Int,
              ffi.Pointer<ffi.Float>)>>('image_model_inference');
  late final _image_model_inference = _image_model_inferencePtr.asFunction<
      OutputData Function(int, ffi.Pointer<ffi.UnsignedChar>, int, int, int,
          ffi.Pointer<ffi.Float>)>();
}

 class OutputData extends ffi.Struct {
  external ffi.Pointer<ffi.Float> values;

  @ffi.Int()
  external int length;

  external ffi.Pointer<pkg_ffi.Utf8> exception;
}

 class ModelLoadResult extends ffi.Struct {
  @ffi.Int()
  external int index;

  external ffi.Pointer<pkg_ffi.Utf8> exception;
}
