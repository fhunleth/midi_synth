# Changelog

## 0.3.0

This release updates the Elixir and `make` code to fix many issues. The library
is the functionally the same as before, but every API call has changed. The
biggest changes are that the main module was renamed to `MIDISynth` and it's now
a `GenServer` that should be manually started or added to a supervision tree of
your choosing.

MIDI command encoders are now located in `MIDISynth.Command`. Please send PRs
back for any other commands you may want to use.

`MIDISynth.Keyboard` provides a functions for playing back simple songs.
`MIDISynth` forwards raw MIDI commands to `libfluidsynth`, so it offers a lot of
functionality. The hope is that other libraries build on this and provide the
sequencers and higher level APIs to make complex music generation possible.

Enjoy!

## 0.2.0

* New features
  * Note velocity is supported. Unspecified velocities default to 127.

## 0.1.0

Initial release
