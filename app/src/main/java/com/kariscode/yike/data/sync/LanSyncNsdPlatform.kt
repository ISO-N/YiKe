package com.kariscode.yike.data.sync

/**
 * 平台服务信息统一抽成值对象，是为了让发现逻辑测试不必直接依赖 Android NSD 对象。
 */
internal data class LanSyncPlatformServiceInfo(
    val serviceName: String,
    val serviceType: String,
    val port: Int,
    val hostAddress: String? = null
)

/**
 * 注册监听抽象出来后，主机测试就能覆盖“系统改名、自清理、失败兜底”这些高风险分支。
 */
internal interface LanSyncRegistrationListener {
    /**
     * 系统接受注册后回传最终广播名，是为了让发现层据此过滤自发现结果。
     */
    fun onServiceRegistered(service: LanSyncPlatformServiceInfo)

    /**
     * 注册失败时保留服务信息，是为了把真实失败上下文带回日志与测试断言。
     */
    fun onRegistrationFailed(service: LanSyncPlatformServiceInfo, errorCode: Int)

    /**
     * 注销成功单独回调，是为了让本地缓存和系统状态同步收口。
     */
    fun onServiceUnregistered(service: LanSyncPlatformServiceInfo)

    /**
     * 注销失败也显式暴露，是为了测试异常路径下的本地兜底行为。
     */
    fun onUnregistrationFailed(service: LanSyncPlatformServiceInfo, errorCode: Int)
}

/**
 * 发现监听接口把生命周期事件与服务事件分开，是为了让测试只关心业务相关分支而不依赖 Android 回调类。
 */
internal interface LanSyncDiscoveryListener {
    /**
     * 启动失败回调独立保留，是为了让服务能在半初始化状态下主动收口。
     */
    fun onStartDiscoveryFailed(serviceType: String, errorCode: Int)

    /**
     * 停止失败也需要被观察，是为了验证服务退出时不会残留缓存与锁。
     */
    fun onStopDiscoveryFailed(serviceType: String, errorCode: Int)

    /**
     * 启动成功事件虽然当前不驱动状态，但保留接口可以保持平台适配语义完整。
     */
    fun onDiscoveryStarted(serviceType: String)

    /**
     * 停止成功事件保留出来，是为了让适配器仍然完整映射底层生命周期。
     */
    fun onDiscoveryStopped(serviceType: String)

    /**
     * 候选服务发现事件单独暴露，是为了让服务层自己决定过滤与解析策略。
     */
    fun onServiceFound(service: LanSyncPlatformServiceInfo)

    /**
     * 服务丢失事件直接带最小信息，是为了让缓存移除逻辑在主机侧也能稳定回归。
     */
    fun onServiceLost(service: LanSyncPlatformServiceInfo)
}

/**
 * 解析监听抽象出来后，解析成功与失败都能在主机测试里精确回放。
 */
internal interface LanSyncResolveListener {
    /**
     * 解析失败保留服务信息，是为了让日志和测试都能定位具体是哪一个广播项异常。
     */
    fun onResolveFailed(service: LanSyncPlatformServiceInfo, errorCode: Int)

    /**
     * 解析成功返回 host/port 后，服务层才能把结果写入可连接列表。
     */
    fun onServiceResolved(service: LanSyncPlatformServiceInfo)
}

/**
 * NSD 平台适配层隔离 Android Framework，是为了把服务逻辑回归从系统对象里解耦出来。
 */
internal interface LanSyncNsdPlatform {
    /**
     * 注册服务时统一走适配层，是为了让主机测试能直接回放注册回调。
     */
    fun registerService(service: LanSyncPlatformServiceInfo, listener: LanSyncRegistrationListener)

    /**
     * 注销服务保持单独入口，是为了让服务层继续以监听器为生命周期句柄。
     */
    fun unregisterService(listener: LanSyncRegistrationListener)

    /**
     * 启动发现时只关心服务类型，是为了把协议常量集中留在服务层。
     */
    fun startDiscovery(serviceType: String, listener: LanSyncDiscoveryListener)

    /**
     * 停止发现继续按监听器收口，是为了和 Android NSD 的资源模型保持一致。
     */
    fun stopDiscovery(listener: LanSyncDiscoveryListener)

    /**
     * 解析动作单独抽象，是为了让测试直接构造 host/port 结果而不依赖真实网络。
     */
    fun resolveService(service: LanSyncPlatformServiceInfo, listener: LanSyncResolveListener)
}

/**
 * Multicast lock 抽象出来后，发现生命周期测试就能直接断言资源有没有正确收放。
 */
internal interface LanSyncMulticastLock {
    /**
     * 关闭引用计数能避免页面重复进入时留下难以推理的锁状态。
     */
    fun setReferenceCounted(referenceCounted: Boolean)

    /**
     * 启动发现时获取锁，是为了维持 Wi-Fi 组播可见性。
     */
    fun acquire()

    /**
     * 结束发现时释放锁，是为了防止同步页退出后继续占用系统资源。
     */
    fun release()

    /**
     * 只暴露持有状态即可满足释放判断，避免测试或服务层接触更多平台细节。
     */
    val isHeld: Boolean
}

/**
 * 锁工厂独立出来后，服务层就不需要知道 WifiManager 的具体构造细节。
 */
internal interface LanSyncMulticastLockFactory {
    /**
     * 统一用 tag 创建锁，是为了让日志和系统调试里保留稳定标识。
     */
    fun create(tag: String): LanSyncMulticastLock
}

