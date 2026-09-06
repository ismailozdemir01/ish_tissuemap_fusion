import '../models/imaging_pipeline.dart';

enum ProcessingCapability { acquisition, preprocessing, fusion, reconstruction, aiInference, visualization }

class ProcessingRoute {
  final ProcessingLocation location;
  final Set<ProcessingCapability> capabilities;
  final String? endpoint;

  const ProcessingRoute({required this.location, required this.capabilities, this.endpoint});

  bool supports(ProcessingCapability capability) => capabilities.contains(capability);

  static const phone = ProcessingRoute(
    location: ProcessingLocation.phone,
    capabilities: {
      ProcessingCapability.acquisition,
      ProcessingCapability.preprocessing,
      ProcessingCapability.fusion,
      ProcessingCapability.reconstruction,
      ProcessingCapability.aiInference,
      ProcessingCapability.visualization,
    },
  );

  static const pc = ProcessingRoute(
    location: ProcessingLocation.pc,
    capabilities: {
      ProcessingCapability.preprocessing,
      ProcessingCapability.fusion,
      ProcessingCapability.reconstruction,
      ProcessingCapability.aiInference,
      ProcessingCapability.visualization,
    },
  );

  static const hybrid = ProcessingRoute(
    location: ProcessingLocation.hybrid,
    capabilities: ProcessingCapability.values.toSet(),
  );
}
