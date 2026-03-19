package com.kariscode.yike.feature.card

import com.kariscode.yike.domain.model.QuestionContext
import com.kariscode.yike.domain.model.QuestionMasteryCalculator
import com.kariscode.yike.domain.model.QuestionMasteryLevel

/**
 * 卡组熟练度摘要计算保持纯函数，是为了让卡片页可以复用同一统计口径，
 * 同时把“如何按等级聚合问题”从 ViewModel 生命周期代码中抽离出来。
 */
internal object DeckMasterySummaryCalculator {
    /**
     * 熟练度摘要基于真实问题集合即时计算，是为了遵守“不写回数据库，只按字段推导”的约束。
     */
    fun calculate(questionContexts: List<QuestionContext>): DeckMasterySummary {
        val masteryCounts = questionContexts.groupBy { context ->
            QuestionMasteryCalculator.snapshot(context.question).level
        }
        return DeckMasterySummary(
            totalQuestions = questionContexts.size,
            newCount = masteryCounts[QuestionMasteryLevel.NEW]?.size ?: 0,
            learningCount = masteryCounts[QuestionMasteryLevel.LEARNING]?.size ?: 0,
            familiarCount = masteryCounts[QuestionMasteryLevel.FAMILIAR]?.size ?: 0,
            masteredCount = masteryCounts[QuestionMasteryLevel.MASTERED]?.size ?: 0
        )
    }
}
