package com.kariscode.yike.domain.model

/**
 * 统计页摘要把主要指标预先结构化，是为了让 ViewModel 更专注于时间范围和结论组织，
 * 而不是在页面层处理零散计数字段。
 */
data class ReviewAnalyticsSnapshot(
    val totalReviews: Int,
    val againCount: Int,
    val hardCount: Int,
    val goodCount: Int,
    val easyCount: Int,
    val averageResponseTimeMs: Double?,
    val forgettingRate: Float,
    val deckBreakdowns: List<DeckReviewAnalyticsSnapshot>
)

/**
 * 按卡组聚合的统计结果单独建模，是为了让统计页输出“下一步先处理哪个卡组”时有稳定数据来源。
 */
data class DeckReviewAnalyticsSnapshot(
    val deckId: String,
    val deckName: String,
    val reviewCount: Int,
    val forgettingRate: Float,
    val averageResponseTimeMs: Double?
)
