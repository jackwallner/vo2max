package com.jackwallner.vo2max

import android.os.Bundle

import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.launch

import com.jackwallner.vo2max.ui.RootScreen

class MainActivity: ComponentActivity() {
    private val graph get()=(application as VO2Application).graph
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState);enableEdgeToEdge()
        DebugLaunchOptions.apply(this,graph,intent)
        setContent{RootScreen(graph)}
    }
    override fun onResume() {
        super.onResume()
        lifecycleScope.launch { graph.store.start() }
        lifecycleScope.launch { graph.health.refresh() }
    }
}
class PermissionsRationaleActivity: ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent { com.jackwallner.vo2max.ui.theme.VO2Theme(false) {
            androidx.compose.material3.Surface { com.jackwallner.vo2max.ui.screens.PrivacyScreen() }
        } }
    }
}
