package com.kariscode.yike.feature.deck

import com.kariscode.yike.core.time.TimeProvider
import com.kariscode.yike.domain.model.Deck
import com.kariscode.yike.domain.model.DeckSummary
import com.kariscode.yike.domain.repository.DeckRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * DeckListViewModel 测试锁定卡组页的关键管理语义，
 * 避免删除流程在回收站上线后又退回到直接物理删除。
 */
@OptIn(ExperimentalCoroutinesApi::class)
class DeckListViewModelTest {

    /**
     * 删除确认后应把卡组移入回收站而不是直接删库，
     * 这样用户才能通过回收站完成可恢复的删除流程。
     */
    @Test
    fun onConfirmDelete_movesDeckToRecycleBin() = runTest {
        Dispatchers.setMain(UnconfinedTestDispatcher(testScheduler))
        try {
            val repository = FakeDeckRepository()
            val item = createDeckSummary(deckId = "deck_1")
            repository.archivedDecksFlow.value = listOf(item)
            val viewModel = DeckListViewModel(
                deckRepository = repository,
                timeProvider = object : TimeProvider {
                    override fun nowEpochMillis(): Long = 321L
                }
            )

            viewModel.onDeleteDeckClick(item)
            viewModel.onConfirmDelete()
            advanceUntilIdle()

            assertEquals(1, repository.setArchivedCalls.size)
            assertEquals("deck_1", repository.setArchivedCalls.single().deckId)
            assertEquals(true, repository.setArchivedCalls.single().archived)
            assertEquals(321L, repository.setArchivedCalls.single().updatedAt)
            assertEquals(0, repository.deletedDeckIds.size)
            assertEquals("已移入回收站", viewModel.uiState.value.message)
        } finally {
            Dispatchers.resetMain()
        }
    }

    /**
     * 测试数据显式保留聚合字段，是为了让删除确认在真实列表项上下文里执行。
     */
    private fun createDeckSummary(deckId: String): DeckSummary = DeckSummary(
        deck = Deck(
            id = deckId,
            name = "英语",
            description = "",
            archived = false,
            sortOrder = 0,
            createdAt = 1L,
            updatedAt = 1L
        ),
        cardCount = 2,
        questionCount = 5,
        dueQuestionCount = 1
    )

    /**
     * FakeDeckRepository 只记录 ViewModel 本次关心的写路径，
     * 这样测试可以聚焦“删除是否变成移入回收站”这一条语义。
     */
    private class FakeDeckRepository : DeckRepository {
        val archivedDecksFlow = MutableStateFlow<List<DeckSummary>>(emptyList())
        val setArchivedCalls = mutableListOf<SetArchivedCall>()
        val deletedDeckIds = mutableListOf<String>()

        data class SetArchivedCall(val deckId: String, val archived: Boolean, val updatedAt: Long)

        override fun observeActiveDecks(): Flow<List<Deck>> = MutableStateFlow(emptyList())

        override suspend fun listActiveDecks(): List<Deck> = emptyList()

        override fun observeActiveDeckSummaries(nowEpochMillis: Long): Flow<List<DeckSummary>> = archivedDecksFlow

        override fun observeArchivedDeckSummaries(nowEpochMillis: Long): Flow<List<DeckSummary>> = MutableStateFlow(emptyList())

        override suspend fun listRecentActiveDeckSummaries(nowEpochMillis: Long, limit: Int): List<DeckSummary> = emptyList()

        override suspend fun findById(deckId: String): Deck? = null

        override suspend fun upsert(deck: Deck) = Unit

        override suspend fun setArchived(deckId: String, archived: Boolean, updatedAt: Long) {
            setArchivedCalls.add(SetArchivedCall(deckId, archived, updatedAt))
        }

        override suspend fun delete(deckId: String) {
            deletedDeckIds.add(deckId)
        }
    }
}
