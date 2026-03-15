package com.kariscode.yike.data.local.db.dao

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Query
import androidx.room.Upsert
import com.kariscode.yike.data.local.db.entity.CardEntity
import kotlinx.coroutines.flow.Flow

/**
 * CardDao 提供以 deckId 维度的查询，是为了让内容管理流保持“按层级加载”的稳定形态，
 * 这样 UI 只持有路由参数即可重建页面状态，避免跨页面传递大对象。
 */
@Dao
interface CardDao {
    @Upsert
    suspend fun upsert(card: CardEntity): Long

    @Query("SELECT * FROM card WHERE deckId = :deckId AND archived = 0 ORDER BY sortOrder ASC, createdAt ASC")
    fun observeActiveCards(deckId: String): Flow<List<CardEntity>>

    @Query("SELECT * FROM card WHERE id = :cardId LIMIT 1")
    suspend fun findById(cardId: String): CardEntity?

    @Query("UPDATE card SET archived = :archived, updatedAt = :updatedAt WHERE id = :cardId")
    suspend fun setArchived(cardId: String, archived: Boolean, updatedAt: Long): Int

    @Delete
    suspend fun delete(card: CardEntity): Int
}
