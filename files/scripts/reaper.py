import i3ipc, subprocess

reaps = {
  'FINAL FANTASY XIV': 'ffxiv',
  # Would need to implement wildcards to recognize XIVLauncher, but
  # not bothering for now since this doesn't seem to be problematic
  #'XIVLauncher': 'ffxiv',
  'EXILIUM': 'gfl2',
  'Genshin Impact': 'genshin'
};

sway = i3ipc.Connection()

def on_window_close(self, e):
  title = e.ipc_data['container']['name']

  if title in reaps:
    print('Window "%s" matches reap group, reaping %s...' % (title, reaps[title]))
    subprocess.run(['systemctl', '--user', 'stop', reaps[title]+'.scope'])
    # reset-failed so the scope doesn't linger in case of timeout
    subprocess.run(['systemctl', '--user', 'reset-failed', reaps[title]+'.scope'])
    print('Closed all remaining processes of %s.' % title)

sway.on(i3ipc.Event.WINDOW_CLOSE, on_window_close)

sway.main()
