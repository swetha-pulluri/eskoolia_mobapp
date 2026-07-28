import '../../../administration/domain/entities/picked_attachment.dart';

/// Bundles every optional file field on the Staff form. When any of these
/// is set, the create/update request is sent as multipart (matching web's
/// own "rebuild as FormData only if a file was picked" behavior) instead
/// of plain JSON.
class StaffFilesDraft {
  final PickedAttachment? staffPhoto;
  final PickedAttachment? resume;
  final PickedAttachment? joiningLetter;
  final PickedAttachment? tenthCertificate;
  final PickedAttachment? eleventhCertificate;
  final PickedAttachment? aadharCard;
  final PickedAttachment? drivingLicenseDoc;

  const StaffFilesDraft({
    this.staffPhoto,
    this.resume,
    this.joiningLetter,
    this.tenthCertificate,
    this.eleventhCertificate,
    this.aadharCard,
    this.drivingLicenseDoc,
  });

  bool get hasAnyFile =>
      staffPhoto != null ||
      resume != null ||
      joiningLetter != null ||
      tenthCertificate != null ||
      eleventhCertificate != null ||
      aadharCard != null ||
      drivingLicenseDoc != null;
}
