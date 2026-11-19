"""Story 1.4: the quieter alarm sound used while the owner is already in a meeting.

A copy of the recorded pops alarm at a quarter of its level (about 12 dB down), same length and format, so iOS
plays it like any other alarm sound but softer. AlarmKit has no volume setting, so the sound file carries it.
Run: python3 scripts/make_quiet_alarm.py  (writes App/Promptly/Sounds/quiet_alarm.wav)."""
import array
import wave

SRC = "App/Promptly/Sounds/recorded_pops_alarm.wav"
DST = "App/Promptly/Sounds/quiet_alarm.wav"
GAIN = 0.25

with wave.open(SRC) as w:
    params = w.getparams()
    assert params.sampwidth == 2 and params.comptype == "NONE", params
    samples = array.array("h", w.readframes(params.nframes))
quiet = array.array("h", (int(s * GAIN) for s in samples))
with wave.open(DST, "wb") as out:
    out.setparams(params)
    out.writeframes(quiet.tobytes())
print("wrote", DST, len(quiet), "samples")
