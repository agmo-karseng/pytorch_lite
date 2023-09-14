#import "PytorchLitePlugin.h"
#import "pigeon.h"
#import "PrePostProcessor.h"
//#import "TorchModule.h"
#import "helpers/UIImageExtension.h"
#import <LibTorch/LibTorch.h>
#include <vector>

@interface PytorchLitePlugin () <ModelApi>

@property (nonatomic, assign) std::vector<torch::jit::Module*> modulesVector;
@property (nonatomic, strong) NSMutableArray<PrePostProcessor *> *prePostProcessors;

@end

@implementation PytorchLitePlugin


+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  PytorchLitePlugin* instance = [[PytorchLitePlugin alloc] init];
  ModelApiSetup(registrar.messenger, instance);
    // instance.modulesVector = [NSMutableArray array];
    instance.prePostProcessors = [NSMutableArray array];
}
- (NSArray<NSNumber*>*)predictImage:(void*)imageBuffer withWidth:(int)width andHeight:(int)height atIndex:(NSInteger)moduleIndex objectDetectionFlag:(NSInteger)objectDetectionFlag {
    try {
        torch::jit::Module* module = self.modulesVector[moduleIndex];
        at::Tensor tensor = torch::from_blob(imageBuffer, {1, 3, height, width}, at::kFloat);

        torch::autograd::AutoGradMode guard(false);
        at::AutoNonVariableTypeMode non_var_type_mode(true);
        
        at::Tensor outputTensor;
        if (objectDetectionFlag == 1) {
            torch::jit::IValue outputTuple = module->forward({tensor}).toTuple();
            outputTensor = outputTuple.toTuple()->elements()[0].toTensor();
        } else {
            outputTensor = module->forward({tensor}).toTensor();
        }

        float *floatBuffer = outputTensor.data_ptr<float>();
        if(!floatBuffer){
            return nil;
        }

        int prod = 1;
        for(int i = 0; i < outputTensor.sizes().size(); i++) {
            prod *= outputTensor.sizes().data()[i];  
        }

        NSMutableArray<NSNumber*>* results = [[NSMutableArray<NSNumber*> alloc] init];
        for (int i = 0; i < prod; i++) {
            [results addObject: @(floatBuffer[i])];   
        }

        return [results copy];
        
    } catch (const std::exception& e) {
        NSLog(@"%s", e.what());
        return nil; // Make sure to return nil in the case of an exception.
    }
}




- (void)getPredictionCustomIndex:(nonnull NSNumber *)index input:(nonnull NSArray<NSNumber *> *)input shape:(nonnull NSArray<NSNumber *> *)shape dtype:(nonnull NSString *)dtype completion:(nonnull void (^)(NSArray * _Nullable, FlutterError * _Nullable))completion {
    // <#code#>
}
- (nullable NSNumber *)loadModelModelPath:(nonnull NSString *)modelPath numberOfClasses:(nullable NSNumber *)numberOfClasses imageWidth:(nullable NSNumber *)imageWidth imageHeight:(nullable NSNumber *)imageHeight isObjectDetection:(nullable NSNumber *)isObjectDetection objectDetectionModelType:(nullable NSNumber *)objectDetectionModelType error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    
    NSInteger i = -1;
    @try {
        torch::jit::Module *module = new torch::jit::Module(torch::jit::load(modelPath.UTF8String));
        self.modulesVector.push_back(module);
        
if (numberOfClasses != nil && imageWidth != nil && imageHeight != nil) {
            [ self.prePostProcessors addObject:[[PrePostProcessor alloc] initWithNumberOfClasses:numberOfClasses.integerValue imageWidth:imageWidth.integerValue imageHeight:imageHeight.integerValue objectDetectionModelType:objectDetectionModelType.integerValue]];
        } else {
            if (imageWidth != nil && imageHeight != nil) {
                [ self.prePostProcessors addObject:[[PrePostProcessor alloc] initWithImageWidth:imageWidth.integerValue imageHeight:imageHeight.integerValue]];
            } else {
                [ self.prePostProcessors addObject:[[PrePostProcessor alloc] init]];
            }
        }
        i = self.modulesVector.size() - 1;
    } @catch (NSException *e) {
        NSLog(@"%@ is not a proper model: %@", modelPath, e);
        if (error != NULL) {
            *error = [FlutterError errorWithCode:@"ModelLoadingError" message:[NSString stringWithFormat:@"%@ is not a proper model", modelPath] details:e];
        }
    }

    return [NSNumber numberWithInteger:i];
}

- (void)getImagePredictionListIndex:(nonnull NSNumber *)index imageData:(nullable FlutterStandardTypedData *)imageData imageBytesList:(nullable NSArray<FlutterStandardTypedData *> *)imageBytesList imageWidthForBytesList:(nullable NSNumber *)imageWidthForBytesList imageHeightForBytesList:(nullable NSNumber *)imageHeightForBytesList mean:(nonnull NSArray<NSNumber *> *)mean std:(nonnull NSArray<NSNumber *> *)std completion:(nonnull void (^)(NSArray<NSNumber *> * _Nullable, FlutterError * _Nullable))completion {
    
    UIImage *bitmap = nil;
    if (imageData) {
        bitmap = [UIImage imageWithData:imageData.data];
        bitmap = [UIImageExtension resize:bitmap toWidth:[imageWidthForBytesList intValue] toHeight:[imageHeightForBytesList intValue]];
    } else {
        // Handle the scenario where you're given the byte list instead of imageData.
    }

    float* input = [UIImageExtension normalize:bitmap withMean:mean withSTD:std];
    NSArray<NSNumber*> *results = [self predictImage:input withWidth:[imageWidthForBytesList intValue] andHeight:[imageHeightForBytesList intValue] atIndex:[index integerValue] objectDetectionFlag:0];

    if (results) {
        completion(results, nil);
    } else {
        FlutterError *error = [FlutterError errorWithCode:@"PREDICTION_ERROR" message:@"Prediction failed" details:nil];
        completion(nil, error);
    }
}



- (void)getImagePredictionListObjectDetectionIndex:(nonnull NSNumber *)index imageData:(nullable FlutterStandardTypedData *)imageData imageBytesList:(nullable NSArray<FlutterStandardTypedData *> *)imageBytesList imageWidthForBytesList:(nullable NSNumber *)imageWidthForBytesList imageHeightForBytesList:(nullable NSNumber *)imageHeightForBytesList minimumScore:(nonnull NSNumber *)minimumScore IOUThreshold:(nonnull NSNumber *)IOUThreshold boxesLimit:(nonnull NSNumber *)boxesLimit completion:(nonnull void (^)(NSArray<ResultObjectDetection *> * _Nullable, FlutterError * _Nullable))completion {
    
    UIImage *bitmap = nil;
    PrePostProcessor *prePostProcessor = self.prePostProcessors[index.intValue];

    if (imageData) {
        bitmap = [UIImage imageWithData:imageData.data];
        bitmap = [UIImageExtension resize:bitmap toWidth:prePostProcessor.mImageWidth toHeight:prePostProcessor.mImageHeight];
    } else {
        // Handle the scenario where you're given the byte list instead of imageData.
    }

    float* input = [UIImageExtension normalize:bitmap withMean:prePostProcessor.NO_MEAN_RGB withSTD:prePostProcessor.NO_STD_RGB];
    NSArray<NSNumber*> *rawOutputs = [self predictImage:input withWidth:prePostProcessor.mImageWidth andHeight:prePostProcessor.mImageHeight atIndex:[index integerValue] objectDetectionFlag:1];

    // Convert raw outputs to ResultObjectDetection objects
    NSMutableArray<ResultObjectDetection*> *results = [prePostProcessor outputsToNMSPredictions:rawOutputs];
    
    if (results) {
        completion(results, nil);
    } else {
        FlutterError *error = [FlutterError errorWithCode:@"PREDICTION_ERROR" message:@"Prediction failed" details:nil];
        completion(nil, error);
    }
}





@end
