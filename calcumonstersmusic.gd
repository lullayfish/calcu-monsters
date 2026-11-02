extends AudioStreamPlayer

# Persistent music player. Add as an Autoload named CalcuMonstersMusic.
# The title screen starts playback, keeping the first play tied to user interaction
# when browsers block autoplay.
const NORMAL_BGM: AudioStream = preload("res://assets/8bit.mp3")

func _ready() -> void:
	stream = NORMAL_BGM
	volume_db = -18.0
	if stream is AudioStreamMP3:
		stream.loop = true

func ensure_playing() -> void:
	if not playing:
		play()
