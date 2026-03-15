package com.kariscode.yike.data.local.db.dao

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Query
import androidx.room.Upsert
import com.kariscode.yike.data.local.db.entity.QuestionEntity
import kotlinx.coroutines.flow.Flow

/**
 * QuestionDao 的查询需要显式包含 status 与 due 条件，
 * 这是为了保证“归档不出现”和“今日到期口径”在全应用范围内一致。
 */
@Dao
interface QuestionDao {
    @Upsert
    suspend fun upsertAll(questions: List<QuestionEntity>): List<Long>

    @Query("SELECT * FROM question WHERE cardId = :cardId ORDER BY createdAt ASC")
    fun observeQuestionsByCard(cardId: String): Flow<List<QuestionEntity>>

    @Query("SELECT * FROM question WHERE id = :questionId LIMIT 1")
    suspend fun findById(questionId: String): QuestionEntity?

    @Query("SELECT * FROM question WHERE status = :activeStatus AND dueAt <= :nowEpochMillis")
    suspend fun listDueQuestions(activeStatus: String, nowEpochMillis: Long): List<QuestionEntity>

    @Delete
    suspend fun delete(question: QuestionEntity): Int
}
