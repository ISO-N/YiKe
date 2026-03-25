package com.kariscode.yike.feature.search

import com.kariscode.yike.domain.model.QuestionContext
import com.kariscode.yike.domain.model.QuestionMasteryCalculator
import com.kariscode.yike.domain.model.QuestionQueryFilters
import com.kariscode.yike.domain.model.QuestionStatus

/**
 * 搜索页的元数据快照单独建模，是为了让 ViewModel 刷新时只围绕一份结构化筛选快照工作。
 */
internal data class SearchMetadata(
    val tags: List<String>,
    val decks: List<SearchDeckOption>,
    val cards: List<SearchCardOption>
)

/**
 * 搜索状态工厂把筛选转换与结果映射保持纯输入输出，是为了让检索页的状态拼装脱离协程编排代码独立演进。
 */
internal object QuestionSearchStateFactory {
    /**
     * 搜索条件由状态快照直接导出，是为了让新增筛选字段时只改一个映射入口，避免搜索与刷新口径漂移。
     */
    fun toQueryFilters(state: QuestionSearchUiState): QuestionQueryFilters = QuestionQueryFilters(
        keyword = state.keyword,
        tag = state.selectedTag,
        status = state.selectedStatus,
        deckId = state.selectedDeckId,
        cardId = state.selectedCardId,
        masteryLevel = state.selectedMasteryLevel
    )

    /**
     * 元数据与结果通常在同一轮刷新里一起回写，
     * 因此状态回写统一收敛后可以保持“保留合法 cardId”与“清空旧错误”始终一步完成。
     */
    fun withMetadata(
        state: QuestionSearchUiState,
        metadata: SearchMetadata,
        results: List<QuestionSearchResultUiModel> = state.results
    ): QuestionSearchUiState = state.copy(
            isLoading = false,
            availableTags = metadata.tags,
            deckOptions = metadata.decks,
            cardOptions = metadata.cards,
            selectedCardId = preserveSelectedCardId(
                selectedCardId = state.selectedCardId,
                cards = metadata.cards
            ),
            results = results,
            errorMessage = null
        )

    /**
     * 卡组切换后的卡片候选与错误清理总是成组变化，收口成纯转换后能避免成功与失败分支继续复制同一份字段模板。
     */
    fun withDeckSelection(
        state: QuestionSearchUiState,
        deckId: String?,
        cards: List<SearchCardOption>,
        errorMessage: String?
    ): QuestionSearchUiState = state.copy(
        selectedDeckId = deckId,
        selectedCardId = null,
        cardOptions = cards,
        errorMessage = errorMessage
    )

    /**
     * 搜索结果在工厂里统一映射熟练度与 due 状态，是为了让 ViewModel 只负责拿快照而不是逐条拼 UI 模型。
     */
    fun buildResults(
        questionContexts: List<QuestionContext>,
        nowEpochMillis: Long
    ): List<QuestionSearchResultUiModel> = questionContexts.map { context ->
        QuestionSearchResultUiModel(
            context = context,
            mastery = QuestionMasteryCalculator.snapshot(context.question),
            isDue = context.question.status == QuestionStatus.ACTIVE && context.question.dueAt <= nowEpochMillis
        )
    }

    /**
     * 当前卡片筛选只在候选列表里仍然存在时才保留，是为了避免刷新元数据后继续带着失效 cardId 做查询。
     */
    private fun preserveSelectedCardId(
        selectedCardId: String?,
        cards: List<SearchCardOption>
    ): String? {
        if (selectedCardId == null) {
            return null
        }
        val availableCardIds = cards.asSequence().map(SearchCardOption::id).toHashSet()
        return selectedCardId.takeIf(availableCardIds::contains)
    }
}
