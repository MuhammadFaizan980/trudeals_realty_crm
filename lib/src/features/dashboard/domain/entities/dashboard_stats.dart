class DashboardStats {
  final int totalLeads;
  final int newLeads;
  final int activeDeals;
  final double pipelineValue;

  const DashboardStats({
    required this.totalLeads,
    required this.newLeads,
    required this.activeDeals,
    required this.pipelineValue,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardStats &&
          runtimeType == other.runtimeType &&
          totalLeads == other.totalLeads &&
          newLeads == other.newLeads &&
          activeDeals == other.activeDeals &&
          pipelineValue == other.pipelineValue;

  @override
  int get hashCode =>
      totalLeads.hashCode ^ newLeads.hashCode ^ activeDeals.hashCode ^ pipelineValue.hashCode;
}
