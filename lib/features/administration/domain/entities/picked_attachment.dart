/// A file picked by the user for upload, kept as a plain domain value
/// (no `file_picker` package types) so the domain/data layers don't
/// depend on a specific picker implementation.
class PickedAttachment {
  final String name;
  final List<int> bytes;
  final int size;

  const PickedAttachment({required this.name, required this.bytes, required this.size});
}
