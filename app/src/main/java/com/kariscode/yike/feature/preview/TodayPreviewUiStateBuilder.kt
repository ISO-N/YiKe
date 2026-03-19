package com.kariscode.yike.feature.preview

import com.kariscode.yike.domain.model.QuestionContext
import com.kariscode.yike.domain.model.QuestionMasteryCalculator
import com.kariscode.yike.domain.model.QuestionMasteryLevel
import com.kariscode.yike.domain.model.QuestionMasterySnapshot
import kotlin.math.ceil

internal const val DEFAULT_RESPONSE_TIME_MS: Double = 15_000.0
internal const val MIN_RESPONSE_TIME_MS: Double = 10_000.0

/**
 * 预处理后的题目上下文缓存熟练度结果，是为了让分组、计数和预览项共用同一份计算，
 * 避免同一轮刷新里对同一个问题重复做多次 snapshot。
 */
private data class ResolvedDueQuestion(
    val context: QuestionContext,
    val mastery: QuestionMasterySnapshot,
    val isLowMastery: Boolean
)

/**
 * 今日预览状态组装器保持纯输入输出，是为了让任务规模、分组与估时逻辑脱离 ViewModel 生命周期独立演进。
 */
internal object TodayPreviewUiStateBuilder {
    /**
     * 预览页的汇总值与分组都从同一轮 due 列表构建，是为了保证页面上的所有数字口径一致。
     */
    fun build(
        dueQuestions: List<QuestionContext>,
        averageResponseTimeMs: Double?
    ): TodayPreviewUiState {
        val resolvedResponseTimeMs = averageResponseTimeMs
            ?.coerceAtLeast(MIN_RESPONSE_TIME_MS)
            ?: DEFAULT_RESPONSE_TIME_MS
        val resolvedQuestions = dueQuestions.map(::resolveDueQuestion)
        val deckGroups = resolvedQuestions
            .groupBy { it.context.deckId }
            .map { (_, deckQuestions) -> buildDeckGroup(deckQuestions, resolvedResponseTimeMs) }
            .sortedWith(
                compareByDescending<TodayPreviewDeckUiModel> { it.dueQuestionCount }
                    .thenBy { deck ->
                        deck.cards.flatMap { card -> card.questions }.minOfOrNull(TodayPreviewQuestionUiModel::dueAt)
                    }
            )
        return TodayPreviewUiState(
            isLoading = false,
            totalDueQuestions = dueQuestions.size,
            totalDueCards = dueQuestions.map { it.question.cardId }.distinct().size,
            totalDecks = deckGroups.size,
            estimatedMinutes = estimateMinutes(dueQuestions.size, resolvedResponseTimeMs),
            averageSecondsPerQuestion = ceil(resolvedResponseTimeMs / 1000.0).toInt(),
            lowMasteryCount = resolvedQuestions.count(ResolvedDueQuestion::isLowMastery),
            earliestDueAt = dueQuestions.minOfOrNull { it.question.dueAt },
            deckGroups = deckGroups,
            errorMessage = null
        )
    }

    /**
     * 卡组分组内部继续按卡片组织，是为了贴合“先决定学哪科，再决定做哪张卡”的使用顺序。
     */
    private fun buildDeckGroup(
        questions: List<ResolvedDueQuestion>,
        averageResponseTimeMs: Double
    ): TodayPreviewDeckUiModel {
        val cards = questions.groupBy { it.context.question.cardId }
            .map { (cardId, cardQuestions) ->
                val previewQuestions = cardQuestions
                    .sortedBy { it.context.question.dueAt }
                    .take(3)
                    .map { question ->
                        TodayPreviewQuestionUiModel(
                            questionId = question.context.question.id,
                            prompt = question.context.question.prompt,
                            dueAt = question.context.question.dueAt,
                            mastery = question.mastery
                        )
                    }
                TodayPreviewCardUiModel(
                    cardId = cardId,
                    cardTitle = cardQuestions.first().context.cardTitle,
                    dueQuestionCount = cardQuestions.size,
                    estimatedMinutes = estimateMinutes(cardQuestions.size, averageResponseTimeMs),
                    lowMasteryCount = cardQuestions.count(ResolvedDueQuestion::isLowMastery),
                    questions = previewQuestions
                )
            }
            .sortedByDescending(TodayPreviewCardUiModel::dueQuestionCount)
        return TodayPreviewDeckUiModel(
            deckId = questions.first().context.deckId,
            deckName = questions.first().context.deckName,
            dueQuestionCount = questions.size,
            estimatedMinutes = estimateMinutes(questions.size, averageResponseTimeMs),
            lowMasteryCount = questions.count(ResolvedDueQuestion::isLowMastery),
            cards = cards
        )
    }

    /**
     * 估时采用向上取整分钟，是为了让用户拿到更保守的预期，减少“实际比预览更久”的挫败感。
     */
    private fun estimateMinutes(questionCount: Int, averageResponseTimeMs: Double): Int {
        if (questionCount <= 0) return 0
        return maxOf(1, ceil(questionCount * averageResponseTimeMs / 60_000.0).toInt())
    }

    /**
     * 同一题目的熟练度与低熟练度标签在进入分组前先算好，是为了避免统计与预览项重复调用 snapshot。
     */
    private fun resolveDueQuestion(context: QuestionContext): ResolvedDueQuestion {
        val mastery = QuestionMasteryCalculator.snapshot(context.question)
        return ResolvedDueQuestion(
            context = context,
            mastery = mastery,
            isLowMastery = mastery.level == QuestionMasteryLevel.NEW || mastery.level == QuestionMasteryLevel.LEARNING
        )
    }
}
