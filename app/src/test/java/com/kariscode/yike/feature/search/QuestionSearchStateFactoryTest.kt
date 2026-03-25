package com.kariscode.yike.feature.search

import com.kariscode.yike.domain.model.QuestionStatus
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/**
 * QuestionSearchStateFactoryTest 锁定搜索状态工厂对元数据刷新的保留语义，
 * 避免后续继续压缩映射逻辑时把合法 cardId 误清空，或把失效 cardId 继续带进搜索条件。
 */
class QuestionSearchStateFactoryTest {
    /**
     * 当前 cardId 只应在新元数据里仍然存在时保留，
     * 这样用户刷新题库后不会继续带着一个界面上已不存在的筛选条件。
     */
    @Test
    fun withMetadata_preservesOnlyStillAvailableSelectedCardId() {
        val state = baseState(selectedCardId = "card_2")
        val metadata = SearchMetadata(
            tags = listOf("定义"),
            decks = listOf(SearchDeckOption(id = "deck_1", name = "数学")),
            cards = listOf(
                SearchCardOption(id = "card_1", title = "极限"),
                SearchCardOption(id = "card_2", title = "导数")
            )
        )

        val updated = QuestionSearchStateFactory.withMetadata(
            state = state,
            metadata = metadata
        )

        assertEquals("card_2", updated.selectedCardId)
        assertEquals(metadata.cards, updated.cardOptions)
        assertNull(updated.errorMessage)
    }

    /**
     * 元数据刷新后若原 cardId 已失效，应立即回退为空，
     * 这样后续搜索与可见筛选控件始终围绕同一份合法候选集工作。
     */
    @Test
    fun withMetadata_clearsSelectedCardIdWhenItIsNoLongerAvailable() {
        val state = baseState(selectedCardId = "card_missing")
        val metadata = SearchMetadata(
            tags = emptyList(),
            decks = emptyList(),
            cards = listOf(SearchCardOption(id = "card_1", title = "极限"))
        )

        val updated = QuestionSearchStateFactory.withMetadata(
            state = state,
            metadata = metadata
        )

        assertNull(updated.selectedCardId)
        assertEquals(metadata.cards, updated.cardOptions)
    }

    /**
     * 基础状态只保留工厂真正会读取的字段，
     * 这样测试可以聚焦在元数据映射和 cardId 保留规则，而不是整页状态装配噪音。
     */
    private fun baseState(selectedCardId: String?): QuestionSearchUiState = QuestionSearchUiState(
        isLoading = true,
        keyword = "",
        selectedTag = null,
        selectedStatus = QuestionStatus.ACTIVE,
        selectedDeckId = "deck_1",
        selectedCardId = selectedCardId,
        selectedMasteryLevel = null,
        availableTags = emptyList(),
        deckOptions = emptyList(),
        cardOptions = emptyList(),
        results = emptyList(),
        errorMessage = "旧错误"
    )
}
