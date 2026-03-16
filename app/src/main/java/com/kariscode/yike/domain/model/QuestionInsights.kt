package com.kariscode.yike.domain.model

/**
 * 题目上下文模型把卡组和卡片名称一并带出，是为了让搜索结果和今日预览能直接展示定位信息，
 * 而不需要页面层再反查层级结构。
 */
data class QuestionContext(
    val question: Question,
    val deckId: String,
    val deckName: String,
    val cardTitle: String
)

/**
 * 搜索筛选条件作为结构化对象传递，是为了让仓储扩展新筛选项时不需要不断改方法签名。
 */
data class QuestionQueryFilters(
    val keyword: String = "",
    val tag: String? = null,
    val status: QuestionStatus? = QuestionStatus.ACTIVE,
    val deckId: String? = null,
    val cardId: String? = null,
    val masteryLevel: QuestionMasteryLevel? = null
)
