package com.kariscode.yike.data.sync

import androidx.room.withTransaction
import com.kariscode.yike.data.local.db.YikeDatabase
import com.kariscode.yike.data.local.db.dao.CardDao
import com.kariscode.yike.data.local.db.dao.DeckDao
import com.kariscode.yike.data.local.db.dao.QuestionDao
import com.kariscode.yike.data.local.db.dao.ReviewRecordDao
import com.kariscode.yike.data.local.db.dao.SyncChangeDao
import com.kariscode.yike.data.local.db.entity.SyncChangeEntity
import com.kariscode.yike.data.mapper.toDomain
import com.kariscode.yike.domain.model.SyncChangeOperation
import com.kariscode.yike.domain.model.SyncEntityType
import com.kariscode.yike.domain.model.toSyncedAppSettings
import com.kariscode.yike.domain.repository.AppSettingsRepository

/**
 * 会话启动前把当前本地快照补进同步 journal，是为了修复“历史数据存在但从未写过 journal”时预览恒为 0 的问题，
 * 同时保持该补写过程幂等，避免每次进入同步页都重复制造同一批变更。
 */
class LanSyncJournalSeeder(
    private val database: YikeDatabase,
    private val appSettingsRepository: AppSettingsRepository,
    private val deckDao: DeckDao,
    private val cardDao: CardDao,
    private val questionDao: QuestionDao,
    private val reviewRecordDao: ReviewRecordDao,
    private val syncChangeDao: SyncChangeDao,
    private val syncChangeRecorder: LanSyncChangeRecorder,
    private val crypto: LanSyncCrypto
) {
    /**
     * 只在最新 journal 无法代表当前快照时补写，是为了兼顾首次补齐能力和后续正常增量同步的低噪音。
     */
    suspend fun seedMissingChanges() {
        val syncedSettings = appSettingsRepository.getSettings().toSyncedAppSettings()
        database.withTransaction {
            val latestChangesByKey = syncChangeDao.listAfter(afterSeq = 0L)
                .associateLatestByEntityKey()
            seedSettingsIfMissing(
                latestChange = latestChangesByKey[settingsEntityKey()],
                settings = syncedSettings
            )
            deckDao.listAll().forEach { deck ->
                val latestChange = latestChangesByKey[entityKey(SyncEntityType.DECK, deck.id)]
                if (shouldRecordUpsert(latestChange = latestChange, payloadJson = encodeDeckPayload(deck.toDomain()))) {
                    syncChangeRecorder.recordDeckUpsert(deck.toDomain())
                }
            }
            cardDao.listAll().forEach { card ->
                val latestChange = latestChangesByKey[entityKey(SyncEntityType.CARD, card.id)]
                if (shouldRecordUpsert(latestChange = latestChange, payloadJson = encodeCardPayload(card.toDomain()))) {
                    syncChangeRecorder.recordCardUpsert(card.toDomain())
                }
            }
            questionDao.listAll().forEach { question ->
                val latestChange = latestChangesByKey[entityKey(SyncEntityType.QUESTION, question.id)]
                if (shouldRecordUpsert(latestChange = latestChange, payloadJson = encodeQuestionPayload(question.toDomain()))) {
                    syncChangeRecorder.recordQuestionUpsert(question.toDomain())
                }
            }
            reviewRecordDao.listAll().forEach { reviewRecord ->
                val latestChange = latestChangesByKey[entityKey(SyncEntityType.REVIEW_RECORD, reviewRecord.id)]
                if (shouldRecordUpsert(latestChange = latestChange, payloadJson = encodeReviewRecordPayload(reviewRecord.toDomain()))) {
                    syncChangeRecorder.recordReviewRecordInsert(reviewRecord.toDomain())
                }
            }
        }
    }

    /**
     * 设置补写单独收口后，可以继续沿用内容实体相同的“看最新 journal 是否已覆盖当前快照”的规则。
     */
    private suspend fun seedSettingsIfMissing(
        latestChange: SyncChangeEntity?,
        settings: com.kariscode.yike.domain.model.SyncedAppSettings
    ) {
        if (shouldRecordUpsert(latestChange = latestChange, payloadJson = encodeSettingsPayload(settings))) {
            syncChangeRecorder.recordSettingsUpsert(
                settings = settings,
                modifiedAt = 0L
            )
        }
    }

    /**
     * 只有最新记录不是当前 upsert 快照时才补写，是为了让历史缺口得到修复而正常路径不产生重复 journal。
     */
    private fun shouldRecordUpsert(latestChange: SyncChangeEntity?, payloadJson: String): Boolean {
        val expectedHash = crypto.sha256(payloadJson)
        return latestChange?.operation != SyncChangeOperation.UPSERT.name || latestChange.payloadHash != expectedHash
    }

    /**
     * 各实体统一按 type:id 建键，是为了让“当前快照”和“最新 journal”可以在内存中稳定对齐。
     */
    private fun entityKey(entityType: SyncEntityType, entityId: String): String = "${entityType.name}:$entityId"

    /**
     * 设置使用固定 id 建键，是为了与 recorder 中的设置实体语义保持完全一致。
     */
    private fun settingsEntityKey(): String = entityKey(
        entityType = SyncEntityType.SETTINGS,
        entityId = SETTINGS_ENTITY_ID
    )

    /**
     * 设置 payload 编码集中在此处，是为了让幂等判断与真正的 journal 写入共享同一协议字段口径。
     */
    private fun encodeSettingsPayload(settings: com.kariscode.yike.domain.model.SyncedAppSettings): String =
        LanSyncJson.json.encodeToString(SyncSettingsPayload.serializer(), settings.toPayload())

    /**
     * Deck payload 编码复用正式协议模型，是为了避免回填逻辑与同步传输逻辑出现字段漂移。
     */
    private fun encodeDeckPayload(deck: com.kariscode.yike.domain.model.Deck): String =
        LanSyncJson.json.encodeToString(SyncDeckPayload.serializer(), deck.toPayload())

    /**
     * Card payload 编码保持与正式同步入口一致，是为了让 hash 判断真正反映“远端看到的实体内容”。
     */
    private fun encodeCardPayload(card: com.kariscode.yike.domain.model.Card): String =
        LanSyncJson.json.encodeToString(SyncCardPayload.serializer(), card.toPayload())

    /**
     * Question payload 编码沿用协议模型，是为了让调度字段也参与幂等比较，而不是只比较文案字段。
     */
    private fun encodeQuestionPayload(question: com.kariscode.yike.domain.model.Question): String =
        LanSyncJson.json.encodeToString(SyncQuestionPayload.serializer(), question.toPayload())

    /**
     * ReviewRecord 作为追加型事件也参与缺口补写，是为了让历史评分数据在首次同步时可以一起被看见。
     */
    private fun encodeReviewRecordPayload(reviewRecord: com.kariscode.yike.domain.model.ReviewRecord): String =
        LanSyncJson.json.encodeToString(SyncReviewRecordPayload.serializer(), reviewRecord.toPayload())

    /**
     * 最新 journal 聚合到单一字典后，回填时就不必为每个实体再次扫描完整流水。
     */
    private fun List<SyncChangeEntity>.associateLatestByEntityKey(): Map<String, SyncChangeEntity> =
        groupBy { change -> entityKey(entityType = SyncEntityType.valueOf(change.entityType), entityId = change.entityId) }
            .mapValues { (_, changes) -> changes.maxBy { change -> change.seq } }

    private companion object {
        private const val SETTINGS_ENTITY_ID: String = "app_settings"
    }
}
