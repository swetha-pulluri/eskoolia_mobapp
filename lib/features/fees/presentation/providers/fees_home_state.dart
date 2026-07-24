import '../../domain/models/fees_feed_item.dart';
import '../../domain/models/fees_home_data.dart';
import '../../domain/models/fees_summary.dart';

class FeesHomeState {
  final bool loading;
  final FeesSummary? summary;
  final List<FeesFeedItem> feed;
  final FeesHomeData homeData;
  final bool autoRefresh;
  final String? toast;

  const FeesHomeState({
    this.loading = true,
    this.summary,
    this.feed = const [],
    this.homeData = const FeesHomeData(),
    this.autoRefresh = false,
    this.toast,
  });

  FeesHomeState copyWith({
    bool? loading,
    FeesSummary? summary,
    List<FeesFeedItem>? feed,
    FeesHomeData? homeData,
    bool? autoRefresh,
    String? toast,
    bool clearToast = false,
  }) {
    return FeesHomeState(
      loading: loading ?? this.loading,
      summary: summary ?? this.summary,
      feed: feed ?? this.feed,
      homeData: homeData ?? this.homeData,
      autoRefresh: autoRefresh ?? this.autoRefresh,
      toast: clearToast ? null : (toast ?? this.toast),
    );
  }
}
