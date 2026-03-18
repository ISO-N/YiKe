package com.kariscode.yike.ui.component

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExtendedFloatingActionButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.kariscode.yike.ui.theme.YikeBestContainer
import com.kariscode.yike.ui.theme.YikeCriticalContainer
import com.kariscode.yike.ui.theme.YikeSuccessContainer
import com.kariscode.yike.ui.theme.YikeWarningContainer

/**
 * 主按钮承担页面最重要动作，统一封装后能让异步状态和层级关系在各页面保持一致。
 */
@Composable
fun YikePrimaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true
) {
    Button(
        onClick = onClick,
        modifier = modifier.height(48.dp),
        enabled = enabled,
        shape = RoundedCornerShape(18.dp),
        colors = ButtonDefaults.buttonColors(
            containerColor = MaterialTheme.colorScheme.primary,
            contentColor = MaterialTheme.colorScheme.onPrimary
        )
    ) {
        Text(text = text)
    }
}

/**
 * 次按钮统一用于辅助操作，避免“返回/浏览/取消”在不同页面使用不一致的样式语义。
 */
@Composable
fun YikeSecondaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true
) {
    OutlinedButton(
        onClick = onClick,
        modifier = modifier.height(48.dp),
        enabled = enabled,
        shape = RoundedCornerShape(18.dp)
    ) {
        Text(text = text)
    }
}

/**
 * 危险按钮把高风险操作明确染成错误语义，是为了降低删除和恢复类操作的误触概率。
 */
@Composable
fun YikeDangerButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true
) {
    Button(
        onClick = onClick,
        modifier = modifier.height(48.dp),
        enabled = enabled,
        shape = RoundedCornerShape(18.dp),
        colors = ButtonDefaults.buttonColors(
            containerColor = MaterialTheme.colorScheme.errorContainer,
            contentColor = MaterialTheme.colorScheme.onErrorContainer
        )
    ) {
        Text(text = text)
    }
}

/**
 * 评分按钮根据掌握度切换色阶，是为了让“完全不会/很轻松”在视觉上立刻形成强弱区分。
 */
@Composable
fun YikeRatingButton(
    text: String,
    containerColor: Color,
    contentColor: Color,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true
) {
    Button(
        onClick = onClick,
        modifier = modifier.height(52.dp),
        enabled = enabled,
        shape = RoundedCornerShape(18.dp),
        colors = ButtonDefaults.buttonColors(
            containerColor = containerColor,
            contentColor = contentColor
        )
    ) {
        Text(text = text, fontWeight = FontWeight.SemiBold)
    }
}

/**
 * 统一 FAB 样式能让新增卡组和新增卡片保持同一种“主入口但不压过页面主任务”的语气。
 */
@Composable
fun YikeFab(
    text: String,
    onClick: () -> Unit
) {
    ExtendedFloatingActionButton(
        onClick = onClick,
        containerColor = MaterialTheme.colorScheme.tertiaryContainer,
        contentColor = MaterialTheme.colorScheme.onTertiaryContainer
    ) {
        Text(text)
    }
}

/**
 * 进度条被单独封装，是为了让首页节奏、复习完成度和后续异步状态都能复用同一视觉表达。
 */
@Composable
fun YikeProgressBar(
    progress: Float,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(6.dp)
            .clip(CircleShape)
            .background(MaterialTheme.colorScheme.surfaceContainerHighest)
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth(progress.coerceIn(0f, 1f))
                .height(6.dp)
                .clip(CircleShape)
                .background(
                    Brush.horizontalGradient(
                        colors = listOf(
                            MaterialTheme.colorScheme.primary,
                            MaterialTheme.colorScheme.primary.copy(alpha = 0.72f)
                        )
                    )
                )
        )
    }
}

/**
 * 评分色板集中定义，是为了让复习页调用处只表达语义，而不重复散落具体颜色常量。
 */
object YikeRatingPalette {
    val criticalContainer: Color = YikeCriticalContainer
    val warningContainer: Color = YikeWarningContainer
    val successContainer: Color = YikeSuccessContainer
    val bestContainer: Color = YikeBestContainer
}

