# Changelog

## 0.4.0

* New features
  * Support specification of MIDI channels in `MIDISynth.Command`. This is a
    backwards incompatible API change if you're using `MIDISynth.Command`. The
    previous code hardcoded the channel to `0`.
  * Several new commands were added to `MIDISynth.Command`.

Thanks to Pim Kunis for these updates!

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
