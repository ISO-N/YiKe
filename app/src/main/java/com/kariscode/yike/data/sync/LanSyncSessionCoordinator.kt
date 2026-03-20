package com.kariscode.yike.data.sync

import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.isActive

/**
 * 会话级资源启停单独收口，是为了把“什么时候广播、什么时候发现、什么时候结束后台任务”的规则
 * 固定在单一组件中，而不是散落在仓储的多个入口里。
 */
internal class LanSyncSessionCoordinator(
    private val runtime: LanSyncSessionRuntime,
    private val localProfileStore: LanSyncLocalProfileStore,
    private val journalSeeder: LanSyncJournalSeeder,
    private val nsdService: LanSyncDiscoveryService,
    private val httpServer: LanSyncTransportServer,
    private val refreshPeers: suspend (List<LanSyncDiscoveredService>) -> Unit,
    private val heartbeatTrustedPeers: suspend () -> Unit
) {
    /**
     * 启动会话时统一准备本机档案、服务广播、设备发现和心跳，是为了把局域网暴露窗口严格限制在同步页使用期间。
     */
    suspend fun startSession() {
        if (runtime.sessionState.value.isSessionActive) {
            return
        }
        journalSeeder.seedMissingChanges()
        runtime.activateSession(localProfileStore.loadProfile())
        httpServer.start()
        nsdService.registerService(
            serviceName = "yike-${runtime.currentLocalProfile.shortDeviceId.lowercase()}",
            port = httpServer.port
        )
        nsdService.startDiscovery()
        runtime.discoveryJob?.cancel()
        runtime.discoveryJob = runtime.launch {
            nsdService.services.collect { services ->
                refreshPeers(services)
            }
        }
        runtime.heartbeatJob?.cancel()
        runtime.heartbeatJob = runtime.launch {
            while (isActive) {
                delay(LanSyncConfig.HEARTBEAT_INTERVAL_MILLIS)
                runCatching { heartbeatTrustedPeers() }
                    .onFailure { throwable -> LanSyncLogger.e("Heartbeat loop failed", throwable) }
            }
        }
    }

    /**
     * 结束会话时统一停掉发现、广播和后台任务，是为了避免用户离开页面后仍持续占用网络与电量资源。
     */
    suspend fun stopSession() {
        runtime.activeSyncJob?.cancel()
        runtime.activeSyncJob = null
        runtime.discoveryJob?.cancelAndJoin()
        runtime.heartbeatJob?.cancelAndJoin()
        runtime.discoveryJob = null
        runtime.heartbeatJob = null
        nsdService.stopDiscovery()
        nsdService.unregisterService()
        httpServer.stop()
        runtime.deactivateSession()
    }

    /**
     * 本机设备名更新后立即回写运行态，是为了让页面展示与对外 hello 信息始终围绕同一份档案。
     */
    suspend fun updateLocalDisplayName(displayName: String) {
        localProfileStore.updateDisplayName(displayName)
        runtime.updateLocalProfile(localProfileStore.loadProfile())
    }
}
