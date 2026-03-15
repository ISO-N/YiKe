package com.kariscode.yike.navigation

import androidx.navigation.NavBackStackEntry

/**
 * 路由参数名集中定义，是为了让声明与读取走同一份标识，避免字符串字面量在导航图里散落复制。
 */
object NavArguments {
    const val DECK_ID = "deckId"
    const val CARD_ID = "cardId"
}

/**
 * 必填路由参数在导航层尽早失败，是为了把路由拼接错误定位在入口处，
 * 避免把空字符串继续传给页面后才在更深层暴露成难定位的问题。
 */
fun NavBackStackEntry.requireStringArg(name: String): String =
    arguments?.getString(name)
        ?: error("缺少必填导航参数: $name")

/**
 * 可选路由参数统一经由同一入口读取，是为了让“允许缺省”和“必须存在”的语义边界保持清晰。
 */
fun NavBackStackEntry.optionalStringArg(name: String): String? =
    arguments?.getString(name)
