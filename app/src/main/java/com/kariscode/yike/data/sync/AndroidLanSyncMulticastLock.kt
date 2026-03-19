package com.kariscode.yike.data.sync

import android.content.Context
import android.net.wifi.WifiManager

/**
 * Android multicast lock 适配集中到独立文件，是为了让发现服务的主文件只承载“同步页关心的生命周期语义”，
 * 避免业务阅读时被 WifiManager API 的平台细节打断。
 */
internal class AndroidLanSyncMulticastLockFactory(
    context: Context
) : LanSyncMulticastLockFactory {
    private val wifiManager = context.getSystemService(Context.WIFI_SERVICE) as WifiManager

    /**
     * 每次创建都返回统一包装器，是为了把平台锁状态隐藏在最小接口之后。
     */
    override fun create(tag: String): LanSyncMulticastLock =
        AndroidLanSyncMulticastLock(wifiManager.createMulticastLock(tag))
}

/**
 * Android 锁包装器只暴露服务层真正需要的操作，是为了减少测试与业务代码对 framework API 的耦合。
 */
internal class AndroidLanSyncMulticastLock(
    private val delegate: WifiManager.MulticastLock
) : LanSyncMulticastLock {
    /**
     * 关闭引用计数透传给系统锁，是为了保持线上行为和原始实现一致。
     */
    override fun setReferenceCounted(referenceCounted: Boolean) {
        delegate.setReferenceCounted(referenceCounted)
    }

    /**
     * 获取锁时直接委托系统实现，是为了保留 Wi-Fi 组播可见性的真实语义。
     */
    override fun acquire() {
        delegate.acquire()
    }

    /**
     * 释放锁继续走系统实现，是为了把资源生命周期交还给平台。
     */
    override fun release() {
        delegate.release()
    }

    /**
     * 暴露只读持有状态，是为了让服务层决定是否需要释放。
     */
    override val isHeld: Boolean
        get() = delegate.isHeld
}

