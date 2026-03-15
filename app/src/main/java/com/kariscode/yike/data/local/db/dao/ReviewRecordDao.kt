package com.kariscode.yike.data.local.db.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.kariscode.yike.data.local.db.entity.ReviewRecordEntity
import kotlinx.coroutines.flow.Flow

/**
 * ReviewRecord 只允许追加写入，不允许编辑，
 * 这样才能保证复习历史可追溯，且备份恢复后的历史不会被 UI 操作意外篡改。
 */
@Dao
interface ReviewRecordDao {
    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insert(record: ReviewRecordEntity): Long

    @Query("SELECT * FROM review_record WHERE questionId = :questionId ORDER BY reviewedAt DESC")
    fun observeByQuestion(questionId: String): Flow<List<ReviewRecordEntity>>
}
