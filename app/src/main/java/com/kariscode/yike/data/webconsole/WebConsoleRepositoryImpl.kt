package com.kariscode.yike.data.webconsole

import android.content.Context
import com.kariscode.yike.core.dispatchers.AppDispatchers
import com.kariscode.yike.core.id.EntityIds
import com.kariscode.yike.core.time.TimeProvider
import com.kariscode.yike.data.backup.BackupService
import com.kariscode.yike.data.reminder.ReminderScheduler
import com.kariscode.yike.domain.model.AppSettings
import com.kariscode.yike.domain.model.Card
import com.kariscode.yike.domain.model.Deck
import com.kariscode.yike.domain.model.PracticeOrderMode
import com.kariscode.yike.domain.model.PracticeSessionArgs
import com.kariscode.yike.domain.model.Question
import com.kariscode.yike.domain.model.QuestionContext
import com.kariscode.yike.domain.model.QuestionQueryFilters
import com.kariscode.yike.domain.model.ReviewRating
import com.kariscode.yike.domain.model.QuestionStatus
import com.kariscode.yike.domain.model.ThemeMode
import com.kariscode.yike.domain.model.WebConsoleState
import com.kariscode.yike.domain.repository.AppSettingsRepository
import com.kariscode.yike.domain.repository.CardRepository
import com.kariscode.yike.domain.repository.DeckRepository
import com.kariscode.yike.domain.repository.PracticeRepository
import com.kariscode.yike.domain.repository.QuestionRepository
import com.kariscode.yike.domain.repository.ReviewRepository
import com.kariscode.yike.domain.repository.StudyInsightsRepository
import com.kariscode.yike.domain.repository.WebConsoleRepository
import com.kariscode.yike.domain.scheduler.InitialDueAtCalculator
import kotlin.random.Random
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.withContext

/**
 * 网页后台仓储把服务生命周期、登录和网页 API 统一编排，
 * 是为了让手机页、前台服务和 Ktor 路由共享同一套业务规则与状态来源。
 */
internal class WebConsoleRepositoryImpl(
    context: Context,
    private val deckRepository: DeckRepository,
    private val cardRepository: CardRepository,
    private val questionRepository: QuestionRepository,
    private val reviewRepository: ReviewRepository,
    private val practiceRepository: PracticeRepository,
    private val studyInsightsRepository: StudyInsightsRepository,
    private val appSettingsRepository: AppSettingsRepository,
    private val backupService: BackupService,
    private val reminderScheduler: ReminderScheduler,
    private val timeProvider: TimeProvider,
    private val dispatchers: AppDispatchers
) : WebConsoleRepository, WebConsoleApiHandler {
    private val runtime = WebConsoleRuntime(timeProvider = timeProvider)
    private val addressProvider = WebConsoleAddressProvider()
    private val httpServer = WebConsoleHttpServer(
        portAllocator = WebConsolePortAllocator(),
        assetLoader = WebConsoleAssetLoader(context.applicationContext),
        handler = this
    )

    /**
     * 外部统一观察运行时状态，是为了让服务、页面和通知都围绕同一份可变状态协作。
     */
    override fun observeState(): Flow<WebConsoleState> = runtime.state

    /**
     * 启动时先准备访问码与地址，再对外开放端口，是为了减少用户看到“服务已启动但地址为空”的半完成状态。
     */
    override suspend fun startServer() = withContext(dispatchers.io) {
        if (runtime.state.value.isRunning) return@withContext
        runtime.markStarting()
        runCatching {
            httpServer.start()
            val addresses = addressProvider.getAccessibleAddresses(httpServer.port)
            require(addresses.isNotEmpty()) { "未检测到可用于局域网访问的地址，请确认 Wi‑Fi 或热点已开启" }
            runtime.activate(port = httpServer.port, addresses = addresses)
        }.onFailure { throwable ->
            httpServer.stop()
            runtime.markFailure(throwable.message ?: "网页后台启动失败")
            throw throwable
        }
    }

    /**
     * 停止时连同内存会话一起清空，是为了让服务关闭后旧浏览器立即失去访问能力。
     */
    override suspend fun stopServer() = withContext(dispatchers.io) {
        httpServer.stop()
        runtime.deactivate()
    }

    /**
     * 刷新访问码后不重启端口监听，可以减少用户在同一会话内临时重新授权的等待成本。
     */
    override suspend fun refreshAccessCode() = withContext(dispatchers.io) {
        runtime.rotateAccessCode()
    }

    /**
     * 登录继续要求匹配当前访问码和本地网络来源，是为了把“显式拿到手机上的码”作为唯一放行条件。
     */
    override suspend fun login(code: String, remoteHost: String): String? = withContext(dispatchers.io) {
        if (!remoteHost.isAllowedLocalNetworkHost()) return@withContext null
        if (!runtime.matchesAccessCode(code.trim())) return@withContext null
        runtime.createSession()
    }

    /**
     * 退出登录时只移除当前会话，是为了避免同一浏览器多个标签页被无差别踢下线。
     */
    override suspend fun logout(sessionId: String?) = withContext(dispatchers.io) {
        runtime.removeSession(sessionId)
    }

    /**
     * 会话解析顺带做本地网络校验和续期，是为了把 Cookie 是否仍有效的判断收敛到同一入口。
     */
    override suspend fun resolveSession(sessionId: String, remoteHost: String): WebConsoleSessionPayload? =
        withContext(dispatchers.io) {
            if (!remoteHost.isAllowedLocalNetworkHost() || !runtime.touchSession(sessionId)) return@withContext null
            val state = runtime.state.value
            val recommendedAddress = state.addresses.firstOrNull { it.isRecommended } ?: state.addresses.firstOrNull()
            WebConsoleSessionPayload(
                displayName = "忆刻网页后台",
                port = recommendedAddress?.port ?: 0,
                activeSessionCount = state.activeSessionCount
            )
        }

    /**
     * 概览接口复用现有首页与卡组摘要口径，是为了保证网页端看到的任务规模和手机端一致。
     */
    override suspend fun getDashboard(): WebConsoleDashboardPayload = withContext(dispatchers.io) {
        val now = timeProvider.nowEpochMillis()
        val summary = questionRepository.getTodayReviewSummary(nowEpochMillis = now)
        val recentDecks = deckRepository.listRecentActiveDeckSummaries(nowEpochMillis = now, limit = 5).map { it.toDeckPayload() }
        WebConsoleDashboardPayload(
            dueCardCount = summary.dueCardCount,
            dueQuestionCount = summary.dueQuestionCount,
            recentDecks = recentDecks
        )
    }

    /**
     * 学习工作区概览继续复用正式 due 统计，并补充当前浏览器活动会话摘要，
     * 是为了让桌面入口同时回答“今天还有多少要复习”和“是否可以恢复刚才的学习”。
     */
    override suspend fun getStudyWorkspace(sessionId: String): WebConsoleStudyWorkspacePayload = withContext(dispatchers.io) {
        val now = timeProvider.nowEpochMillis()
        val summary = questionRepository.getTodayReviewSummary(nowEpochMillis = now)
        WebConsoleStudyWorkspacePayload(
            dueCardCount = summary.dueCardCount,
            dueQuestionCount = summary.dueQuestionCount,
            activeSession = runtime.getStudySession(sessionId)?.toStudySessionSummaryPayload()
        )
    }

    /**
     * 学习会话读取只从运行时内存快照恢复，是为了把“刷新恢复”明确限制在当前浏览器与当前服务生命周期内。
     */
    override suspend fun getStudySession(sessionId: String): WebConsoleStudySessionPayload? = withContext(dispatchers.io) {
        runtime.getStudySession(sessionId)?.toStudySessionPayload()
    }

    /**
     * 开始今日复习时优先恢复同一浏览器尚未结束的复习会话，
     * 是为了避免用户刷新后再次点击“开始复习”时意外丢失当前卡片进度。
     */
    override suspend fun startReviewSession(sessionId: String): WebConsoleStudySessionPayload = withContext(dispatchers.io) {
        val existing = runtime.getStudySession(sessionId)
        if (existing is WebConsoleReviewStudySession && !existing.isCompleted()) {
            return@withContext existing.toStudySessionPayload()
        }
        val now = timeProvider.nowEpochMillis()
        val dueContexts = studyInsightsRepository.listDueQuestionContexts(nowEpochMillis = now)
        require(dueContexts.isNotEmpty()) { "今日暂无待复习内容" }
        val session = WebConsoleReviewStudySession(
            cards = dueContexts.toReviewCardSnapshots(),
            currentCardIndex = 0,
            currentQuestionIndex = 0,
            questionPresentedAt = now,
            answerVisible = false,
            updatedAt = now
        )
        runtime.putStudySession(sessionId, session)
        session.toStudySessionPayload()
    }

    /**
     * 显示答案在服务端显式落一次状态，是为了让刷新恢复后仍能知道当前题是否已经进入可评分或可切题阶段。
     */
    override suspend fun revealStudyAnswer(sessionId: String): WebConsoleStudySessionPayload = withContext(dispatchers.io) {
        val now = timeProvider.nowEpochMillis()
        val updated = when (val session = runtime.getStudySession(sessionId)) {
            is WebConsoleReviewStudySession -> {
                require(!session.isCompleted() && !session.isCurrentCardCompleted()) { "当前复习会话没有可显示答案的问题" }
                require(session.currentQuestionOrNull() != null) { "当前复习会话没有可显示答案的问题" }
                session.copy(answerVisible = true, updatedAt = now)
            }

            is WebConsolePracticeStudySession -> {
                require(session.currentQuestionOrNull() != null) { "当前练习会话没有可显示答案的问题" }
                session.copy(answerVisible = true, updatedAt = now)
            }

            null -> throw IllegalStateException("当前没有可恢复的学习会话")
        }
        runtime.putStudySession(sessionId, updated)
        updated.toStudySessionPayload()
    }

    /**
     * 网页端复习评分直接委托正式复习仓储，是为了保证浏览器端与手机端继续共享同一套调度与 `ReviewRecord` 语义。
     */
    override suspend fun submitReviewRating(
        sessionId: String,
        request: WebConsoleReviewRateRequest
    ): WebConsoleStudySessionPayload = withContext(dispatchers.io) {
        val session = runtime.getStudySession(sessionId) as? WebConsoleReviewStudySession
            ?: throw IllegalStateException("当前没有进行中的复习会话")
        require(session.answerVisible) { "请先显示答案，再提交评分" }
        require(!session.isCompleted() && !session.isCurrentCardCompleted()) { "当前复习会话没有可评分的问题" }
        val currentQuestion = session.currentQuestionOrNull()
            ?: throw IllegalStateException("当前复习会话没有可评分的问题")
        val now = timeProvider.nowEpochMillis()
        reviewRepository.submitRating(
            questionId = currentQuestion.questionId,
            rating = request.rating.toReviewRating(),
            reviewedAtEpochMillis = now,
            responseTimeMs = session.questionPresentedAt
                ?.let { presentedAt -> (now - presentedAt).coerceAtLeast(0L) }
        )
        val updated = session.copy(
            currentQuestionIndex = session.currentQuestionIndex + 1,
            questionPresentedAt = null,
            answerVisible = false,
            updatedAt = now
        )
        runtime.putStudySession(sessionId, updated)
        updated.toStudySessionPayload()
    }

    /**
     * 本卡完成后继续下一张仍由服务端推进索引，是为了让桌面端刷新恢复时继续落在同一张下一卡入口上。
     */
    override suspend fun continueReviewSession(sessionId: String): WebConsoleStudySessionPayload = withContext(dispatchers.io) {
        val session = runtime.getStudySession(sessionId) as? WebConsoleReviewStudySession
            ?: throw IllegalStateException("当前没有进行中的复习会话")
        require(!session.isCompleted()) { "今日复习已经完成" }
        require(session.isCurrentCardCompleted()) { "当前卡片尚未完成，无法继续下一张" }
        val now = timeProvider.nowEpochMillis()
        val nextCardIndex = session.currentCardIndex + 1
        val updated = if (nextCardIndex >= session.cards.size) {
            session.copy(
                currentCardIndex = session.cards.size,
                currentQuestionIndex = 0,
                questionPresentedAt = null,
                answerVisible = false,
                updatedAt = now
            )
        } else {
            session.copy(
                currentCardIndex = nextCardIndex,
                currentQuestionIndex = 0,
                questionPresentedAt = now,
                answerVisible = false,
                updatedAt = now
            )
        }
        runtime.putStudySession(sessionId, updated)
        updated.toStudySessionPayload()
    }

    /**
     * 自由练习启动时强制要求显式范围，是为了让网页端空白练习页在服务端边界上就被阻断，而不是交给前端猜测。
     */
    override suspend fun startPracticeSession(
        sessionId: String,
        request: WebConsolePracticeStartRequest
    ): WebConsoleStudySessionPayload = withContext(dispatchers.io) {
        val args = PracticeSessionArgs(
            deckIds = request.deckIds,
            cardIds = request.cardIds,
            questionIds = request.questionIds,
            orderMode = request.orderMode.toPracticeOrderMode()
        ).normalized()
        require(args.hasScopedSelection()) { "请至少选择一个练习范围" }
        val questions = practiceRepository.listPracticeQuestionContexts(args)
            .toPracticeQuestionSnapshots(orderMode = args.orderMode, nowEpochMillis = timeProvider.nowEpochMillis())
        require(questions.items.isNotEmpty()) { "当前范围内没有可练习的问题，请调整范围后重试" }
        val session = WebConsolePracticeStudySession(
            orderMode = args.orderMode,
            sessionSeed = questions.seed,
            questions = questions.items,
            currentIndex = 0,
            answerVisible = false,
            updatedAt = timeProvider.nowEpochMillis()
        )
        runtime.putStudySession(sessionId, session)
        session.toStudySessionPayload()
    }

    /**
     * 练习切题保持纯内存索引移动，是为了从接口层面继续守住“不写入正式复习记录和调度字段”的只读边界。
     */
    override suspend fun navigatePracticeSession(
        sessionId: String,
        request: WebConsolePracticeNavigateRequest
    ): WebConsoleStudySessionPayload = withContext(dispatchers.io) {
        val session = runtime.getStudySession(sessionId) as? WebConsolePracticeStudySession
            ?: throw IllegalStateException("当前没有进行中的练习会话")
        val targetIndex = when (request.action.trim().lowercase()) {
            "previous" -> (session.currentIndex - 1).coerceAtLeast(0)
            "next" -> (session.currentIndex + 1).coerceAtMost(session.questions.lastIndex)
            else -> throw IllegalArgumentException("练习切题动作不合法")
        }
        val updated = session.copy(
            currentIndex = targetIndex,
            answerVisible = false,
            updatedAt = timeProvider.nowEpochMillis()
        )
        runtime.putStudySession(sessionId, updated)
        updated.toStudySessionPayload()
    }

    /**
     * 学习会话显式结束后只清理当前浏览器上下文，是为了避免同一时刻其他浏览器标签页被无差别打断。
     */
    override suspend fun endStudySession(sessionId: String): WebConsoleMutationPayload = withContext(dispatchers.io) {
        runtime.clearStudySession(sessionId)
        WebConsoleMutationPayload(message = "学习会话已结束")
    }

    /**
     * 卡组列表使用摘要查询，是为了让网页端直接拿到题量和到期量，而不是自己拼 N+1 请求。
     */
    override suspend fun listDecks(): List<WebConsoleDeckPayload> = withContext(dispatchers.io) {
        val now = timeProvider.nowEpochMillis()
        deckRepository.observeActiveDeckSummaries(now).first().map { it.toDeckPayload() }
    }

    /**
     * 卡组保存沿用现有实体 ID 与时间戳策略，是为了让网页端创建的内容继续符合手机端的读取假设。
     */
    override suspend fun upsertDeck(request: WebConsoleUpsertDeckRequest): WebConsoleMutationPayload = withContext(dispatchers.io) {
        val trimmedName = request.name.trim()
        require(trimmedName.isNotBlank()) { "卡组名称不能为空" }
        val now = timeProvider.nowEpochMillis()
        val existing = if (request.id != null) deckRepository.findById(request.id) else null
        deckRepository.upsert(
            Deck(
                id = existing?.id ?: EntityIds.newDeckId(),
                name = trimmedName,
                description = request.description,
                tags = request.tags.map(String::trim).filter(String::isNotBlank).distinct(),
                intervalStepCount = request.intervalStepCount,
                archived = existing?.archived ?: false,
                sortOrder = existing?.sortOrder ?: 0,
                createdAt = existing?.createdAt ?: now,
                updatedAt = now
            )
        )
        WebConsoleMutationPayload(message = "卡组已保存")
    }

    /**
     * 卡组先走归档而不是物理删除，是为了继续延续当前产品对内容管理的保守安全边界。
     */
    override suspend fun archiveDeck(deckId: String, archived: Boolean): WebConsoleMutationPayload = withContext(dispatchers.io) {
        deckRepository.setArchived(deckId = deckId, archived = archived, updatedAt = timeProvider.nowEpochMillis())
        WebConsoleMutationPayload(message = if (archived) "卡组已归档" else "卡组已恢复")
    }

    /**
     * 卡片列表同样复用摘要流，是为了让网页端能直接看到每张卡的题量和待复习量。
     */
    override suspend fun listCards(deckId: String): List<WebConsoleCardPayload> = withContext(dispatchers.io) {
        val now = timeProvider.nowEpochMillis()
        cardRepository.observeActiveCardSummaries(deckId, now).first().map { summary ->
            WebConsoleCardPayload(
                id = summary.card.id,
                deckId = summary.card.deckId,
                title = summary.card.title,
                description = summary.card.description,
                questionCount = summary.questionCount,
                dueQuestionCount = summary.dueQuestionCount,
                archived = summary.card.archived
            )
        }
    }

    /**
     * 卡片保存复用手机端当前默认字段，是为了让网页端创建的卡片可以无缝进入现有编辑与复习流程。
     */
    override suspend fun upsertCard(request: WebConsoleUpsertCardRequest): WebConsoleMutationPayload = withContext(dispatchers.io) {
        val trimmedTitle = request.title.trim()
        require(trimmedTitle.isNotBlank()) { "卡片标题不能为空" }
        val now = timeProvider.nowEpochMillis()
        val existing = if (request.id != null) cardRepository.findById(request.id) else null
        cardRepository.upsert(
            Card(
                id = existing?.id ?: EntityIds.newCardId(),
                deckId = existing?.deckId ?: request.deckId,
                title = trimmedTitle,
                description = request.description,
                archived = existing?.archived ?: false,
                sortOrder = existing?.sortOrder ?: 0,
                createdAt = existing?.createdAt ?: now,
                updatedAt = now
            )
        )
        WebConsoleMutationPayload(message = "卡片已保存")
    }

    /**
     * 卡片归档继续沿用现有列表过滤语义，是为了让网页端不会绕开手机端既有的风险缓冲设计。
     */
    override suspend fun archiveCard(cardId: String, archived: Boolean): WebConsoleMutationPayload = withContext(dispatchers.io) {
        cardRepository.setArchived(cardId = cardId, archived = archived, updatedAt = timeProvider.nowEpochMillis())
        WebConsoleMutationPayload(message = if (archived) "卡片已归档" else "卡片已恢复")
    }

    /**
     * 问题列表直接走单卡快照查询，是为了保持网页端编辑口径与现有问题编辑页一致。
     */
    override suspend fun listQuestions(cardId: String): List<WebConsoleQuestionPayload> = withContext(dispatchers.io) {
        questionRepository.listByCard(cardId).map { question -> question.toQuestionPayload() }
    }

    /**
     * 问题保存复用初始 due 计算和编辑态保留策略，是为了让网页端新增或修改后仍符合既有调度规则。
     */
    override suspend fun upsertQuestion(request: WebConsoleUpsertQuestionRequest): WebConsoleMutationPayload = withContext(dispatchers.io) {
        val trimmedPrompt = request.prompt.trim()
        require(trimmedPrompt.isNotBlank()) { "问题题面不能为空" }
        val now = timeProvider.nowEpochMillis()
        val initialDueAt = InitialDueAtCalculator.compute(nowEpochMillis = now)
        val existing = if (request.id != null) questionRepository.findById(request.id) else null
        val question = if (existing != null) {
            existing.copy(
                prompt = trimmedPrompt,
                answer = request.answer,
                tags = request.tags.map(String::trim).filter(String::isNotBlank).distinct(),
                updatedAt = now
            )
        } else {
            Question(
                id = EntityIds.newQuestionId(),
                cardId = request.cardId,
                prompt = trimmedPrompt,
                answer = request.answer,
                tags = request.tags.map(String::trim).filter(String::isNotBlank).distinct(),
                status = QuestionStatus.ACTIVE,
                stageIndex = 0,
                dueAt = initialDueAt,
                lastReviewedAt = null,
                reviewCount = 0,
                lapseCount = 0,
                createdAt = now,
                updatedAt = now
            )
        }
        questionRepository.upsertAll(listOf(question))
        WebConsoleMutationPayload(message = "问题已保存")
    }

    /**
     * 问题删除保持显式单项入口，是为了让危险动作在网页端也必须绑定到具体对象而不是模糊批量操作。
     */
    override suspend fun deleteQuestion(questionId: String): WebConsoleMutationPayload = withContext(dispatchers.io) {
        questionRepository.delete(questionId)
        WebConsoleMutationPayload(message = "问题已删除")
    }

    /**
     * 搜索接口直接复用题库查询仓储，是为了保证网页端和手机端的筛选结果保持同一口径。
     */
    override suspend fun search(request: WebConsoleSearchRequest): List<WebConsoleSearchResultPayload> = withContext(dispatchers.io) {
        studyInsightsRepository.searchQuestionContexts(
            QuestionQueryFilters(
                keyword = request.keyword,
                tag = request.tag,
                status = request.status?.let(QuestionStatus::fromStorageValue),
                deckId = request.deckId,
                cardId = request.cardId,
                masteryLevel = null
            )
        ).map { result ->
            WebConsoleSearchResultPayload(
                questionId = result.question.id,
                cardId = result.question.cardId,
                deckId = result.deckId,
                deckName = result.deckName,
                cardTitle = result.cardTitle,
                prompt = result.question.prompt,
                answer = result.question.answer,
                status = result.question.status.storageValue,
                stageIndex = result.question.stageIndex,
                dueAt = result.question.dueAt,
                reviewCount = result.question.reviewCount,
                lapseCount = result.question.lapseCount,
                tags = result.question.tags
            )
        }
    }

    /**
     * 统计接口直接回转为网页 DTO，是为了让桌面端在不理解手机端 ViewModel 逻辑的情况下也能稳定渲染。
     */
    override suspend fun getAnalytics(): WebConsoleAnalyticsPayload = withContext(dispatchers.io) {
        val snapshot = studyInsightsRepository.getReviewAnalytics(startEpochMillis = null)
        WebConsoleAnalyticsPayload(
            totalReviews = snapshot.totalReviews,
            againCount = snapshot.againCount,
            hardCount = snapshot.hardCount,
            goodCount = snapshot.goodCount,
            easyCount = snapshot.easyCount,
            averageResponseTimeMs = snapshot.averageResponseTimeMs,
            forgettingRate = snapshot.forgettingRate,
            deckBreakdowns = snapshot.deckBreakdowns.map {
                WebConsoleDeckAnalyticsPayload(
                    deckId = it.deckId,
                    deckName = it.deckName,
                    reviewCount = it.reviewCount,
                    forgettingRate = it.forgettingRate,
                    averageResponseTimeMs = it.averageResponseTimeMs
                )
            }
        )
    }

    /**
     * 设置读取继续走仓储快照，是为了让网页端展示出的提醒和主题配置与手机端保持同一来源。
     */
    override suspend fun getSettings(): WebConsoleSettingsPayload = withContext(dispatchers.io) {
        appSettingsRepository.getSettings().toSettingsPayload()
    }

    /**
     * 设置更新复用现有提醒重建路径，是为了避免网页端写入后漏掉后台提醒任务同步。
     */
    override suspend fun updateSettings(request: WebConsoleUpdateSettingsRequest): WebConsoleMutationPayload = withContext(dispatchers.io) {
        val current = appSettingsRepository.getSettings()
        val themeMode = ThemeMode.entries.firstOrNull { it.name == request.themeMode } ?: current.themeMode
        val updated = current.copy(
            dailyReminderEnabled = request.dailyReminderEnabled,
            dailyReminderHour = request.dailyReminderHour,
            dailyReminderMinute = request.dailyReminderMinute,
            themeMode = themeMode
        )
        appSettingsRepository.setSettings(updated)
        reminderScheduler.syncReminder(updated)
        WebConsoleMutationPayload(message = "设置已保存")
    }

    /**
     * 备份导出直接复用既有 JSON 生成链路，是为了避免网页端再维护一套独立的备份格式。
     */
    override suspend fun exportBackup(): WebConsoleBackupExportPayload = withContext(dispatchers.io) {
        WebConsoleBackupExportPayload(
            fileName = backupService.createSuggestedFileName(),
            content = backupService.exportToJsonString()
        )
    }

    /**
     * 网页端恢复直接复用既有 JSON 恢复链路并立刻重建提醒，
     * 是为了让浏览器上传与手机本地导入保持同一数据语义，而不会出现“数据已恢复但提醒仍是旧配置”的偏差。
     */
    override suspend fun restoreBackup(request: WebConsoleBackupRestoreRequest): WebConsoleMutationPayload = withContext(dispatchers.io) {
        require(request.content.isNotBlank()) { "请选择有效的备份文件后再恢复" }
        backupService.restoreFromJsonString(request.content)
        reminderScheduler.syncReminderFromRepository()
        WebConsoleMutationPayload(message = "备份已恢复，页面数据已同步更新")
    }

    /**
     * 复习摘要把“当前卡 / 完成态 / 下一步动作”压缩成工作区概览可直接展示的文案，
     * 是为了让总览卡片无需展开完整题面也能明确表达会话位置。
     */
    private fun WebConsoleStudySession.toStudySessionSummaryPayload(): WebConsoleStudySessionSummaryPayload = when (this) {
        is WebConsoleReviewStudySession -> {
            val currentCard = currentCardOrNull()
            when {
                isCompleted() -> WebConsoleStudySessionSummaryPayload(
                    type = WebConsoleStudySessionTypes.REVIEW,
                    title = "今日复习已处理完成",
                    detail = "本轮共完成 ${cards.size} 张待复习卡片",
                    actionLabel = "查看结果"
                )

                isCurrentCardCompleted() -> WebConsoleStudySessionSummaryPayload(
                    type = WebConsoleStudySessionTypes.REVIEW,
                    title = "当前卡片已完成",
                    detail = "${currentCard?.cardTitle ?: "当前卡片"} 已处理完毕，可继续下一张",
                    actionLabel = "继续复习"
                )

                else -> WebConsoleStudySessionSummaryPayload(
                    type = WebConsoleStudySessionTypes.REVIEW,
                    title = "今日复习进行中",
                    detail = "${currentCard?.cardTitle ?: "当前卡片"} · 第 ${currentQuestionIndex + 1} / ${currentCard?.questions?.size ?: 0} 题",
                    actionLabel = "恢复复习"
                )
            }
        }

        is WebConsolePracticeStudySession -> WebConsoleStudySessionSummaryPayload(
            type = WebConsoleStudySessionTypes.PRACTICE,
            title = "自由练习进行中",
            detail = "第 ${currentIndex + 1} / ${questions.size} 题 · ${orderMode.label}",
            actionLabel = "恢复练习"
        )
    }

    /**
     * 完整会话 payload 的组装集中在仓储内，是为了让前端工作区围绕稳定 DTO 渲染，而不感知运行时快照细节。
     */
    private fun WebConsoleStudySession.toStudySessionPayload(): WebConsoleStudySessionPayload = when (this) {
        is WebConsoleReviewStudySession -> {
            val currentCard = currentCardOrNull()
            val currentQuestion = currentQuestionOrNull()
            val totalQuestionCount = currentCard?.questions?.size ?: 0
            val completedQuestionCount = when {
                isCompleted() -> cards.lastOrNull()?.questions?.size ?: 0
                else -> currentQuestionIndex.coerceAtMost(totalQuestionCount)
            }
            WebConsoleStudySessionPayload(
                type = WebConsoleStudySessionTypes.REVIEW,
                title = "今日复习",
                summary = when {
                    isCompleted() -> "本轮待复习内容已全部处理完成"
                    isCurrentCardCompleted() -> "${currentCard?.cardTitle ?: "当前卡片"} 已完成，准备继续下一张"
                    else -> "${currentCard?.cardTitle ?: "当前卡片"} · 第 ${currentQuestionIndex + 1} / $totalQuestionCount 题"
                },
                review = WebConsoleReviewStudyPayload(
                    deckName = currentCard?.deckName,
                    cardTitle = currentCard?.cardTitle,
                    cardProgressText = when {
                        isCompleted() -> "全部完成"
                        else -> "第 ${currentCardIndex + 1} / ${cards.size} 张卡"
                    },
                    questionProgressText = when {
                        isCompleted() -> "本轮复习完成"
                        isCurrentCardCompleted() -> "本卡已完成"
                        else -> "第 ${currentQuestionIndex + 1} / $totalQuestionCount 题"
                    },
                    completedQuestionCount = completedQuestionCount,
                    totalQuestionCount = totalQuestionCount,
                    answerVisible = answerVisible,
                    currentQuestion = currentQuestion?.toStudyQuestionPayload(),
                    isCardCompleted = isCurrentCardCompleted(),
                    isSessionCompleted = isCompleted(),
                    nextCardTitle = cards.getOrNull(currentCardIndex + 1)?.cardTitle
                )
            )
        }

        is WebConsolePracticeStudySession -> WebConsoleStudySessionPayload(
            type = WebConsoleStudySessionTypes.PRACTICE,
            title = "自由练习",
            summary = "第 ${currentIndex + 1} / ${questions.size} 题 · ${orderMode.label}",
            practice = WebConsolePracticeStudyPayload(
                orderMode = orderMode.storageValue,
                orderModeLabel = orderMode.label,
                progressText = "第 ${currentIndex + 1} / ${questions.size} 题",
                answerVisible = answerVisible,
                currentQuestion = currentQuestionOrNull()?.toPracticeQuestionPayload(),
                canGoPrevious = currentIndex > 0,
                canGoNext = currentIndex < questions.lastIndex,
                sessionSeed = sessionSeed
            )
        )
    }

    /**
     * due 题目先按卡片稳定分组，是为了让网页端正式复习继续遵守“按卡片组织、逐题推进”的既有语义。
     */
    private fun List<QuestionContext>.toReviewCardSnapshots(): List<WebConsoleReviewCardSnapshot> = buildList {
        val grouped = linkedMapOf<String, MutableList<QuestionContext>>()
        for (context in this@toReviewCardSnapshots) {
            grouped.getOrPut(context.question.cardId) { mutableListOf() }.add(context)
        }
        grouped.values.forEach { contexts ->
            val first = contexts.first()
            add(
                WebConsoleReviewCardSnapshot(
                    deckName = first.deckName,
                    cardId = first.question.cardId,
                    cardTitle = first.cardTitle,
                    questions = contexts.map { context ->
                        WebConsoleReviewQuestionSnapshot(
                            questionId = context.question.id,
                            prompt = context.question.prompt,
                            answerText = context.question.answer.ifBlank { "无答案" },
                            stageIndex = context.question.stageIndex
                        )
                    }
                )
            )
        }
    }

    /**
     * 练习顺序在服务端一次性固化后，
     * 浏览器刷新恢复和多次上一题/下一题就不会因为重新取数而出现顺序漂移。
     */
    private fun List<QuestionContext>.toPracticeQuestionSnapshots(
        orderMode: PracticeOrderMode,
        nowEpochMillis: Long
    ): WebConsoleOrderedPracticeQuestions {
        val questions = map { context ->
            WebConsolePracticeQuestionSnapshot(
                questionId = context.question.id,
                deckName = context.deckName,
                cardTitle = context.cardTitle,
                prompt = context.question.prompt,
                answerText = context.question.answer.ifBlank { "无答案" }
            )
        }
        if (orderMode != PracticeOrderMode.RANDOM) {
            return WebConsoleOrderedPracticeQuestions(items = questions, seed = null)
        }
        val seed = nowEpochMillis xor questions.joinToString(separator = "|") { question ->
            question.questionId
        }.hashCode().toLong()
        return WebConsoleOrderedPracticeQuestions(
            items = questions.shuffled(Random(seed)),
            seed = seed
        )
    }

    /**
     * 评分字符串在服务端显式校验后，
     * 前端即使传来非法值也能得到明确反馈，而不是悄悄回退到错误分支。
     */
    private fun String.toReviewRating(): ReviewRating = ReviewRating.entries.firstOrNull { rating ->
        rating.name.equals(trim(), ignoreCase = true)
    } ?: throw IllegalArgumentException("评分参数不合法")

    /**
     * 顺序模式字符串集中解析，是为了让网页端请求体在协议层就被约束到已知集合。
     */
    private fun String.toPracticeOrderMode(): PracticeOrderMode = PracticeOrderMode.entries.firstOrNull { orderMode ->
        orderMode.storageValue == trim().lowercase()
    } ?: throw IllegalArgumentException("练习顺序不合法")

    /**
     * 复习题目 payload 转换留在仓储单点，
     * 是为了让会话恢复和评分提交后的返回都共享完全一致的题面字段。
     */
    private fun WebConsoleReviewQuestionSnapshot.toStudyQuestionPayload(): WebConsoleStudyQuestionPayload =
        WebConsoleStudyQuestionPayload(
            questionId = questionId,
            prompt = prompt,
            answerText = answerText,
            stageIndex = stageIndex
        )

    /**
     * 练习题目 payload 转换保持在单点，
     * 是为了避免前端工作区和后续测试各自复制 deck/card 上下文字段拼装。
     */
    private fun WebConsolePracticeQuestionSnapshot.toPracticeQuestionPayload(): WebConsolePracticeQuestionPayload =
        WebConsolePracticeQuestionPayload(
            questionId = questionId,
            deckName = deckName,
            cardTitle = cardTitle,
            prompt = prompt,
            answerText = answerText
        )

    /**
     * 卡组摘要到网页 DTO 的映射集中在单点，是为了避免概览页和卡组页各自拼装不同字段组合。
     */
    private fun com.kariscode.yike.domain.model.DeckSummary.toDeckPayload(): WebConsoleDeckPayload = WebConsoleDeckPayload(
        id = deck.id,
        name = deck.name,
        description = deck.description,
        tags = deck.tags,
        intervalStepCount = deck.intervalStepCount,
        cardCount = cardCount,
        questionCount = questionCount,
        dueQuestionCount = dueQuestionCount,
        archived = deck.archived
    )

    /**
     * 问题映射集中后，网页列表和编辑面板都能围绕同一份字段定义工作。
     */
    private fun Question.toQuestionPayload(): WebConsoleQuestionPayload = WebConsoleQuestionPayload(
        id = id,
        cardId = cardId,
        prompt = prompt,
        answer = answer,
        tags = tags,
        status = status.storageValue,
        stageIndex = stageIndex,
        dueAt = dueAt,
        lastReviewedAt = lastReviewedAt,
        reviewCount = reviewCount,
        lapseCount = lapseCount
    )

    /**
     * 设置回转为网页 DTO 时同时给出显示文案，是为了让前端不必重复维护主题模式映射关系。
     */
    private fun AppSettings.toSettingsPayload(): WebConsoleSettingsPayload = WebConsoleSettingsPayload(
        dailyReminderEnabled = dailyReminderEnabled,
        dailyReminderHour = dailyReminderHour,
        dailyReminderMinute = dailyReminderMinute,
        themeMode = themeMode.name,
        themeModeLabel = themeMode.displayLabel,
        backupLastAt = backupLastAt
    )
}

/**
 * 练习题目和随机种子成对返回，
 * 是为了让随机模式只在一次构建中确定顺序，并把恢复所需的 seed 一并保留下来。
 */
private data class WebConsoleOrderedPracticeQuestions(
    val items: List<WebConsolePracticeQuestionSnapshot>,
    val seed: Long?
)
