package com.kariscode.yike.data.webconsole

import kotlinx.serialization.Serializable

/**
 * 学习工作区概览返回待复习规模与当前活动会话摘要，
 * 是为了让网页首页能同时表达“今天还有多少正式复习”和“是否存在可恢复的浏览器会话”。
 */
@Serializable
internal data class WebConsoleStudyWorkspacePayload(
    val dueCardCount: Int,
    val dueQuestionCount: Int,
    val activeSession: WebConsoleStudySessionSummaryPayload?
)

/**
 * 活动会话摘要只保留入口卡片需要的关键信息，
 * 是为了让概览区可以直接渲染“继续复习 / 继续练习”提示，而不必展开完整题面 payload。
 */
@Serializable
internal data class WebConsoleStudySessionSummaryPayload(
    val type: String,
    val title: String,
    val detail: String,
    val actionLabel: String
)

/**
 * 学习会话总 payload 统一承载标题、摘要与具体模式数据，
 * 是为了让前端只维护一套“当前会话”状态，而不是分裂成多条并行协议。
 */
@Serializable
internal data class WebConsoleStudySessionPayload(
    val type: String,
    val title: String,
    val summary: String,
    val review: WebConsoleReviewStudyPayload? = null,
    val practice: WebConsolePracticeStudyPayload? = null
)

/**
 * 复习视图需要同时表达卡片级与题目级进度，
 * 因此专门建模可以让前端直接围绕“当前卡 / 当前题 / 完成态”渲染。
 */
@Serializable
internal data class WebConsoleReviewStudyPayload(
    val deckName: String?,
    val cardTitle: String?,
    val cardProgressText: String,
    val questionProgressText: String,
    val completedQuestionCount: Int,
    val totalQuestionCount: Int,
    val answerVisible: Boolean,
    val currentQuestion: WebConsoleStudyQuestionPayload?,
    val isCardCompleted: Boolean,
    val isSessionCompleted: Boolean,
    val nextCardTitle: String?
)

/**
 * 练习视图需要暴露顺序模式和题位导航能力，
 * 因此单独结构化后可以避免前端自行推断“上一题/下一题是否可点”。
 */
@Serializable
internal data class WebConsolePracticeStudyPayload(
    val orderMode: String,
    val orderModeLabel: String,
    val progressText: String,
    val answerVisible: Boolean,
    val currentQuestion: WebConsolePracticeQuestionPayload?,
    val canGoPrevious: Boolean,
    val canGoNext: Boolean,
    val sessionSeed: Long?
)

/**
 * 复习题目 payload 保留显示答案后的最小展示字段，
 * 是为了让网页端与正式复习页共用“先看题，再看答，再评分”的节奏。
 */
@Serializable
internal data class WebConsoleStudyQuestionPayload(
    val questionId: String,
    val prompt: String,
    val answerText: String,
    val stageIndex: Int
)

/**
 * 练习题目 payload 同时带 deck/card 上下文，
 * 是为了让自由练习在桌面端独立工作区里仍能维持足够清晰的定位感。
 */
@Serializable
internal data class WebConsolePracticeQuestionPayload(
    val questionId: String,
    val deckName: String,
    val cardTitle: String,
    val prompt: String,
    val answerText: String
)

/**
 * 练习入口请求允许分别带 deck/card/question 范围，
 * 是为了让网页端逐步缩圈后，仍能把最终选择通过稳定协议提交给后端会话构建器。
 */
@Serializable
internal data class WebConsolePracticeStartRequest(
    val deckIds: List<String> = emptyList(),
    val cardIds: List<String> = emptyList(),
    val questionIds: List<String> = emptyList(),
    val orderMode: String = "sequential"
)

/**
 * 练习切题只暴露有限动作字符串，
 * 是为了把浏览器导航限制在可解释的“上一题/下一题”两种会话内操作。
 */
@Serializable
internal data class WebConsolePracticeNavigateRequest(
    val action: String
)

/**
 * 复习评分请求用字符串承载四档枚举，
 * 是为了让静态网页脚本能直接通过 JSON 提交，而无需理解 Kotlin 枚举的序列化细节。
 */
@Serializable
internal data class WebConsoleReviewRateRequest(
    val rating: String
)

/**
 * 学习会话类型常量集中定义在一处，
 * 是为了让前后端渲染分支、测试断言和恢复逻辑始终使用同一份标识。
 */
internal object WebConsoleStudySessionTypes {
    const val REVIEW = "review"
    const val PRACTICE = "practice"
}
