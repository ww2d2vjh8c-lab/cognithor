import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jarvis_ui/providers/config_provider.dart';
import 'package:jarvis_ui/widgets/form/form_widgets.dart';

class ChannelsPage extends StatelessWidget {
  const ChannelsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConfigProvider>(
      builder: (context, cfg, _) {
        final ch = cfg.cfg['channels'] as Map<String, dynamic>? ?? {};

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _channelCard(cfg, ch, 'cli', 'CLI', Icons.terminal),
            _channelCard(cfg, ch, 'webui', 'Web UI', Icons.web, extra: [
              JarvisNumberField(
                label: 'Port',
                value: (ch['webui_port'] as num?) ?? 8741,
                onChanged: (v) => cfg.set('channels.webui_port', v),
                min: 1024,
                max: 65535,
              ),
            ]),
            _channelCard(cfg, ch, 'telegram', 'Telegram', Icons.telegram,
                extra: [
              JarvisListField(
                label: 'Whitelist',
                value: _toStringList(ch['telegram_whitelist']),
                onChanged: (v) => cfg.set('channels.telegram_whitelist', v),
                placeholder: 'User ID',
              ),
            ]),
            _channelCard(cfg, ch, 'slack', 'Slack', Icons.tag, extra: [
              JarvisTextField(
                label: 'Default Channel',
                value: (ch['slack_default_channel'] ?? '').toString(),
                onChanged: (v) => cfg.set('channels.slack_default_channel', v),
              ),
            ]),
            _channelCard(cfg, ch, 'discord', 'Discord', Icons.discord,
                extra: [
              JarvisTextField(
                label: 'Channel ID',
                value: (ch['discord_channel_id'] ?? '').toString(),
                onChanged: (v) => cfg.set('channels.discord_channel_id', v),
                description: 'Stored as string to prevent precision loss',
              ),
            ]),
            _channelCard(cfg, ch, 'whatsapp', 'WhatsApp', Icons.chat,
                extra: [
              JarvisTextField(
                label: 'Default Chat',
                value: (ch['whatsapp_default_chat'] ?? '').toString(),
                onChanged: (v) =>
                    cfg.set('channels.whatsapp_default_chat', v),
              ),
              JarvisTextField(
                label: 'Phone Number ID',
                value: (ch['whatsapp_phone_number_id'] ?? '').toString(),
                onChanged: (v) =>
                    cfg.set('channels.whatsapp_phone_number_id', v),
              ),
              JarvisNumberField(
                label: 'Webhook Port',
                value: (ch['whatsapp_webhook_port'] as num?) ?? 8742,
                onChanged: (v) =>
                    cfg.set('channels.whatsapp_webhook_port', v),
                min: 1024,
              ),
              JarvisTextField(
                label: 'Verify Token',
                value: (ch['whatsapp_verify_token'] ?? '').toString(),
                onChanged: (v) =>
                    cfg.set('channels.whatsapp_verify_token', v),
                isPassword: true,
              ),
              JarvisListField(
                label: 'Allowed Numbers',
                value: _toStringList(ch['whatsapp_allowed_numbers']),
                onChanged: (v) =>
                    cfg.set('channels.whatsapp_allowed_numbers', v),
              ),
            ]),
            _channelCard(cfg, ch, 'signal', 'Signal', Icons.lock, extra: [
              JarvisTextField(
                label: 'Default User',
                value: (ch['signal_default_user'] ?? '').toString(),
                onChanged: (v) => cfg.set('channels.signal_default_user', v),
              ),
            ]),
            _channelCard(cfg, ch, 'matrix', 'Matrix', Icons.grid_view,
                extra: [
              JarvisTextField(
                label: 'Homeserver',
                value: (ch['matrix_homeserver'] ?? '').toString(),
                onChanged: (v) => cfg.set('channels.matrix_homeserver', v),
              ),
              JarvisTextField(
                label: 'User ID',
                value: (ch['matrix_user_id'] ?? '').toString(),
                onChanged: (v) => cfg.set('channels.matrix_user_id', v),
              ),
            ]),
            _channelCard(cfg, ch, 'teams', 'Teams', Icons.groups, extra: [
              JarvisTextField(
                label: 'Default Channel',
                value: (ch['teams_default_channel'] ?? '').toString(),
                onChanged: (v) =>
                    cfg.set('channels.teams_default_channel', v),
              ),
            ]),
            _channelCard(cfg, ch, 'imessage', 'iMessage', Icons.message,
                extra: [
              JarvisTextField(
                label: 'Device ID',
                value: (ch['imessage_device_id'] ?? '').toString(),
                onChanged: (v) => cfg.set('channels.imessage_device_id', v),
              ),
            ]),
            _channelCard(
                cfg, ch, 'google_chat', 'Google Chat', Icons.chat_bubble,
                extra: [
              JarvisTextField(
                label: 'Credentials Path',
                value: (ch['google_chat_credentials_path'] ?? '').toString(),
                onChanged: (v) =>
                    cfg.set('channels.google_chat_credentials_path', v),
              ),
              JarvisListField(
                label: 'Allowed Spaces',
                value: _toStringList(ch['google_chat_allowed_spaces']),
                onChanged: (v) =>
                    cfg.set('channels.google_chat_allowed_spaces', v),
              ),
            ]),
            _channelCard(
                cfg, ch, 'mattermost', 'Mattermost', Icons.forum,
                extra: [
              JarvisTextField(
                label: 'URL',
                value: (ch['mattermost_url'] ?? '').toString(),
                onChanged: (v) => cfg.set('channels.mattermost_url', v),
              ),
              JarvisTextField(
                label: 'Token',
                value: (ch['mattermost_token'] ?? '').toString(),
                onChanged: (v) => cfg.set('channels.mattermost_token', v),
                isPassword: true,
              ),
              JarvisTextField(
                label: 'Channel',
                value: (ch['mattermost_channel'] ?? '').toString(),
                onChanged: (v) =>
                    cfg.set('channels.mattermost_channel', v),
              ),
            ]),
            _channelCard(cfg, ch, 'feishu', 'Feishu', Icons.business,
                extra: [
              JarvisTextField(
                label: 'App ID',
                value: (ch['feishu_app_id'] ?? '').toString(),
                onChanged: (v) => cfg.set('channels.feishu_app_id', v),
              ),
              JarvisTextField(
                label: 'App Secret',
                value: (ch['feishu_app_secret'] ?? '').toString(),
                onChanged: (v) => cfg.set('channels.feishu_app_secret', v),
                isPassword: true,
              ),
            ]),
            _channelCard(cfg, ch, 'irc', 'IRC', Icons.tag, extra: [
              JarvisTextField(
                label: 'Server',
                value: (ch['irc_server'] ?? '').toString(),
                onChanged: (v) => cfg.set('channels.irc_server', v),
              ),
              JarvisNumberField(
                label: 'Port',
                value: (ch['irc_port'] as num?) ?? 6667,
                onChanged: (v) => cfg.set('channels.irc_port', v),
              ),
              JarvisTextField(
                label: 'Nick',
                value: (ch['irc_nick'] ?? '').toString(),
                onChanged: (v) => cfg.set('channels.irc_nick', v),
              ),
              JarvisListField(
                label: 'Channels',
                value: _toStringList(ch['irc_channels']),
                onChanged: (v) => cfg.set('channels.irc_channels', v),
              ),
            ]),
            _channelCard(cfg, ch, 'twitch', 'Twitch', Icons.live_tv,
                extra: [
              JarvisTextField(
                label: 'Token',
                value: (ch['twitch_token'] ?? '').toString(),
                onChanged: (v) => cfg.set('channels.twitch_token', v),
                isPassword: true,
              ),
              JarvisTextField(
                label: 'Channel',
                value: (ch['twitch_channel'] ?? '').toString(),
                onChanged: (v) => cfg.set('channels.twitch_channel', v),
              ),
              JarvisListField(
                label: 'Allowed Users',
                value: _toStringList(ch['twitch_allowed_users']),
                onChanged: (v) =>
                    cfg.set('channels.twitch_allowed_users', v),
              ),
            ]),
            const Divider(height: 32),
            // Voice config
            JarvisCollapsibleCard(
              title: 'Voice',
              icon: Icons.mic,
              children: [
                JarvisToggleField(
                  label: 'Voice Enabled',
                  value: ch['voice_enabled'] == true,
                  onChanged: (v) => cfg.set('channels.voice_enabled', v),
                ),
                ..._buildVoiceConfig(cfg, ch),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _channelCard(ConfigProvider cfg, Map<String, dynamic> ch,
      String key, String label, IconData icon,
      {List<Widget> extra = const []}) {
    final enabledKey = '${key}_enabled';
    return JarvisCollapsibleCard(
      title: label,
      icon: icon,
      badge: ch[enabledKey] == true ? 'ON' : null,
      children: [
        JarvisToggleField(
          label: 'Enabled',
          value: ch[enabledKey] == true,
          onChanged: (v) => cfg.set('channels.$enabledKey', v),
        ),
        ...extra,
      ],
    );
  }

  List<Widget> _buildVoiceConfig(
      ConfigProvider cfg, Map<String, dynamic> ch) {
    final vc = ch['voice_config'] as Map<String, dynamic>? ?? {};
    return [
      JarvisSelectField.fromStrings(
        label: 'TTS Backend',
        value: (vc['tts_backend'] ?? 'piper').toString(),
        options: const ['piper', 'espeak', 'elevenlabs'],
        onChanged: (v) => cfg.set('channels.voice_config.tts_backend', v),
      ),
      JarvisTextField(
        label: 'Piper Voice',
        value: (vc['piper_voice'] ?? 'de_DE-pavoque-low').toString(),
        onChanged: (v) => cfg.set('channels.voice_config.piper_voice', v),
      ),
      JarvisSliderField(
        label: 'Piper Length Scale',
        value: (vc['piper_length_scale'] as num?)?.toDouble() ?? 1.0,
        onChanged: (v) =>
            cfg.set('channels.voice_config.piper_length_scale', v),
        min: 0.5,
        max: 2.0,
        step: 0.1,
      ),
      JarvisTextField(
        label: 'ElevenLabs API Key',
        value: (vc['elevenlabs_api_key'] ?? '').toString(),
        onChanged: (v) =>
            cfg.set('channels.voice_config.elevenlabs_api_key', v),
        isPassword: true,
        isSecret: true,
      ),
      JarvisTextField(
        label: 'ElevenLabs Voice ID',
        value: (vc['elevenlabs_voice_id'] ?? '').toString(),
        onChanged: (v) =>
            cfg.set('channels.voice_config.elevenlabs_voice_id', v),
      ),
      JarvisToggleField(
        label: 'Wake Word Enabled',
        value: vc['wake_word_enabled'] == true,
        onChanged: (v) =>
            cfg.set('channels.voice_config.wake_word_enabled', v),
      ),
      JarvisTextField(
        label: 'Wake Word',
        value: (vc['wake_word'] ?? 'jarvis').toString(),
        onChanged: (v) => cfg.set('channels.voice_config.wake_word', v),
      ),
      JarvisSelectField.fromStrings(
        label: 'Wake Word Backend',
        value: (vc['wake_word_backend'] ?? 'browser').toString(),
        options: const ['browser', 'vosk', 'porcupine'],
        onChanged: (v) =>
            cfg.set('channels.voice_config.wake_word_backend', v),
      ),
      JarvisToggleField(
        label: 'Talk Mode',
        value: vc['talk_mode_enabled'] == true,
        onChanged: (v) =>
            cfg.set('channels.voice_config.talk_mode_enabled', v),
      ),
      JarvisToggleField(
        label: 'Auto-Listen',
        value: vc['talk_mode_auto_listen'] == true,
        onChanged: (v) =>
            cfg.set('channels.voice_config.talk_mode_auto_listen', v),
      ),
    ];
  }

  static List<String> _toStringList(dynamic v) {
    if (v is List) return v.map((e) => e.toString()).toList();
    return [];
  }
}
