package com.kariscode.yike.data.sync

import com.kariscode.yike.domain.model.LanSyncFailureReason
import com.kariscode.yike.domain.model.LanSyncLocalProfile
import com.kariscode.yike.domain.model.LanSyncProgress
import com.kariscode.yike.domain.model.LanSyncSessionState
import com.kariscode.yike.domain.model.LanSyncStage
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/**
 * 同步运行时状态单独收口，是为了让会话、发现和执行协作者共享同一份可变状态，
 * 同时避免这些实现再各自持有一套彼此容易漂移的临时字段。
 */
internal class LanSyncSessionRuntime(
    private val scope: CoroutineScope,
    private val crypto: LanSyncCrypto
) {
    var discoveryJob: Job? = null
    var heartbeatJob: Job? = null
    var activeSyncJob: Job? = null
    var currentPairingNonce: String = crypto.createSharedSecret()
    var currentLocalProfile: LanSyncLocalProfile = placeholderLocalProfile()
    var isApplyingChanges: Boolean = false

    val sessionState = MutableStateFlow(
        LanSyncSessionState(
            localProfile = currentLocalProfile,
            peers = emptyList(),
            isSessionActive = false,
            preview = null,
            progress = idleProgress(message = "等待开始发现"),
            activeFailure = null,
            message = null
        )
    )

    /**
     * 统一从仓储级作用域启动后台任务，是为了让发现和同步执行共享同一取消边界。
     */
    fun launch(block: suspend CoroutineScope.() -> Unit): Job = scope.launch(block = block)

    /**
     * 启动会话时集中重建配对随机数和本机档案，是为了让后续协作者只消费已准备好的运行态。
     */
    fun activateSession(localProfile: LanSyncLocalProfile) {
        currentPairingNonce = crypto.createSharedSecret()
        currentLocalProfile = localProfile
        sessionState.update {
            it.copy(
                localProfile = localProfile,
                isSessionActive = true,
                preview = null,
                progress = progressOf(stage = LanSyncStage.DISCOVERING, message = "正在发现设备"),
                activeFailure = null,
                message = null
            )
        }
    }

    /**
     * 结束会话时回到统一空态，是为了让页面再次进入同步页时拿到干净且可预测的初始状态。
     */
    fun deactivateSession() {
        sessionState.update {
            it.copy(
                peers = emptyList(),
                isSessionActive = false,
                preview = null,
                progress = idleProgress(message = "同步会话已结束"),
                activeFailure = null,
                message = null
            )
        }
    }

    /**
     * 本机身份更新统一经由运行时回写，是为了让订阅状态流的页面立即看到最新档案。
     */
    fun updateLocalProfile(localProfile: LanSyncLocalProfile) {
        currentLocalProfile = localProfile
        sessionState.update { it.copy(localProfile = localProfile) }
    }

    /**
     * 进度更新在单点完成，是为了让不同同步阶段共享同一组默认字段与清理策略。
     */
    fun setProgress(
        stage: LanSyncStage,
        message: String,
        bytesTransferred: Long = 0L,
        totalBytes: Long? = null,
        itemsProcessed: Int = 0,
        totalItems: Int? = null,
        clearPreview: Boolean = false,
        failure: LanSyncFailureReason? = null
    ) {
        sessionState.update { state ->
            state.copy(
                preview = if (clearPreview) null else state.preview,
                progress = progressOf(
                    stage = stage,
                    message = message,
                    bytesTransferred = bytesTransferred,
                    totalBytes = totalBytes,
                    itemsProcessed = itemsProcessed,
                    totalItems = totalItems
                ),
                activeFailure = failure,
                message = null
            )
        }
    }

    /**
     * 统一构造空传输统计的空闲态，是为了让初始态和停止态使用相同的进度形状。
     */
    private fun idleProgress(message: String): LanSyncProgress = progressOf(
        stage = LanSyncStage.IDLE,
        message = message
    )

    /**
     * 进度对象构造集中后，调用点可以只表达当前阶段和消息而不用重复样板字段。
     */
    private fun progressOf(
        stage: LanSyncStage,
        message: String,
        bytesTransferred: Long = 0L,
        totalBytes: Long? = null,
        itemsProcessed: Int = 0,
        totalItems: Int? = null
    ): LanSyncProgress = LanSyncProgress(
        stage = stage,
        message = message,
        bytesTransferred = bytesTransferred,
        totalBytes = totalBytes,
        itemsProcessed = itemsProcessed,
        totalItems = totalItems
    )

    /**
     * 初始占位档案保留可识别的默认值，是为了让同步页在真实档案加载前仍能稳定渲染。
     */
    private fun placeholderLocalProfile(): LanSyncLocalProfile = LanSyncLocalProfile(
        deviceId = "loading",
        displayName = "当前设备",
        shortDeviceId = "------",
        pairingCode = "------"
    )
}
