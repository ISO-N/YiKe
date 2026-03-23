package com.kariscode.yike.data.webconsole

import com.kariscode.yike.domain.model.PracticeOrderMode

/**
 * 浏览器学习会话统一抽象为单一类型层级，
 * 是为了让运行时能在同一张表里管理“今日复习”和“自由练习”两种临时状态，并在刷新恢复时走同一入口。
 */
internal sealed interface WebConsoleStudySession {
    val answerVisible: Boolean
    val updatedAt: Long
}

/**
 * 复习会话把卡片队列、当前题位与完成态显式保存在内存中，
 * 是为了让网页刷新后仍能恢复到同一张卡、同一题进度，而不是重新从数据库推测用户刚才停在哪。
 */
internal data class WebConsoleReviewStudySession(
    val cards: List<WebConsoleReviewCardSnapshot>,
    val currentCardIndex: Int,
    val currentQuestionIndex: Int,
    val questionPresentedAt: Long?,
    override val answerVisible: Boolean,
    override val updatedAt: Long
) : WebConsoleStudySession

/**
 * 复习卡片快照把当前卡片下本轮需要处理的问题稳定住，
 * 是为了保证用户在刷新或短暂断线后看到的仍是同一批题，而不是被实时 due 集合打乱顺序。
 */
internal data class WebConsoleReviewCardSnapshot(
    val deckName: String,
    val cardId: String,
    val cardTitle: String,
    val questions: List<WebConsoleReviewQuestionSnapshot>
)

/**
 * 复习题目快照只保留网页端继续作答所需的最小字段，
 * 是为了让会话恢复时无需再次拼装显示答案与阶段提示。
 */
internal data class WebConsoleReviewQuestionSnapshot(
    val questionId: String,
    val prompt: String,
    val answerText: String,
    val stageIndex: Int
)

/**
 * 练习会话在开始时固定题目顺序与当前位置，
 * 是为了让随机模式也能在刷新恢复后继续沿用同一条浏览路径，而不是重新洗牌。
 */
internal data class WebConsolePracticeStudySession(
    val orderMode: PracticeOrderMode,
    val sessionSeed: Long?,
    val questions: List<WebConsolePracticeQuestionSnapshot>,
    val currentIndex: Int,
    override val answerVisible: Boolean,
    override val updatedAt: Long
) : WebConsoleStudySession

/**
 * 练习题目快照同时保留 deck/card 上下文，
 * 是为了让桌面浏览器在独立工作区里也能持续看见“我当前练的是哪一组内容”。
 */
internal data class WebConsolePracticeQuestionSnapshot(
    val questionId: String,
    val deckName: String,
    val cardTitle: String,
    val prompt: String,
    val answerText: String
)

/**
 * 当前卡片读取集中在扩展函数中，
 * 是为了让仓储在判断“卡片完成 / 会话完成 / 继续下一张”时复用同一套边界判断。
 */
internal fun WebConsoleReviewStudySession.currentCardOrNull(): WebConsoleReviewCardSnapshot? =
    cards.getOrNull(currentCardIndex)

/**
 * 当前题目读取统一依赖索引和当前卡片，
 * 是为了让答案显隐、评分提交和恢复渲染面对完全一致的题目定位逻辑。
 */
internal fun WebConsoleReviewStudySession.currentQuestionOrNull(): WebConsoleReviewQuestionSnapshot? =
    currentCardOrNull()?.questions?.getOrNull(currentQuestionIndex)

/**
 * 复习会话完成态通过越过最后一张卡来表达，
 * 是为了避免额外的布尔字段和索引状态彼此漂移。
 */
internal fun WebConsoleReviewStudySession.isCompleted(): Boolean = currentCardIndex >= cards.size

/**
 * 当前卡片完成态通过“索引已越过本卡最后一题”表达，
 * 是为了让最后一题提交后可以停留在明确的本卡完成页，而不是立即跳走。
 */
internal fun WebConsoleReviewStudySession.isCurrentCardCompleted(): Boolean {
    val currentCard = currentCardOrNull() ?: return false
    return currentQuestionIndex >= currentCard.questions.size
}

/**
 * 练习当前题读取集中封装后，
 * 网页端上一题/下一题和刷新恢复都能复用同一条索引解释规则。
 */
internal fun WebConsolePracticeStudySession.currentQuestionOrNull(): WebConsolePracticeQuestionSnapshot? =
    questions.getOrNull(currentIndex)
