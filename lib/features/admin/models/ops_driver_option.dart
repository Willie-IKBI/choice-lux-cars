/// Minimal driver option for assign/reassign picker (admin).
class OpsDriverOption {
  final String id;
  final String displayName;
  final String? number;

  const OpsDriverOption({
    required this.id,
    required this.displayName,
    this.number,
  });
}
