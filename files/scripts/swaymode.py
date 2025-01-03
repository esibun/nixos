import i3ipc

gamingmodeinsts = [
  'FINAL FANTASY XIV'
];

gaming = False

sway = i3ipc.Connection()

def on_window_focus(self, e):
  global gaming

  inst = e.ipc_data['container']['name']

  if not gaming and inst in gamingmodeinsts:
    sway.command('mode gaming')
    gaming = True
  elif gaming:
    sway.command('mode default')
    gaming = False

sway.on(i3ipc.Event.WINDOW_FOCUS, on_window_focus)

sway.main()
