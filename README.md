Yo. for showers.
================

Live monitoring of @TwitterBoston's showers in L6

##TODO
- ~~Websockets, instead of a ajax polling every 5 seconds~~
- ~~Hide red timer~~
- ~~Flush sound~~
- Use sound profile analysis instead of just tracking door gyroscope movement.
  - When the gyroscope detects a movement, the iPods would start listening for a certain sound pattern
  - There's a slight difference in the sound patterns emmitted by a door lock vs a door unlock and the iPod's microphone is sensitive enough to differentiate that
  - We can run realtime FFT analysis on that to determine with greater accuracy whether the door is in a lock or unlocked status.
- Persistance. Sorry, what did you say again?  
- iOS: Timer only on current view
- Queue system
