It's about a rooted vacuum cleaner.
This device has:
- wifi
- audio card + speaker
- flash storage
- no gpu output
- no easy way to use input devices with it (keyboard, mouse, gamepad etc.)
- an owner who has set up passwordless ssh access to it (ssh host alias "robo")
  for their other linux machines

Provided the above conditions we can:

- root it - https://github.com/zvldz/vacuum

- copy some audio files over ssh

- copy some online radios playlist over ssh

- use some pathetic shell scripting to control those:

Example use case (adapt any way you see fit):

1. On Roborock create folder /mnt/data/muzika

2. In this folder we may want to have:
For music
- mp3 files
- playlist.m3u file containing paths to those mp3 files - now is the time to learn what a playlist file is all about
- muzika.sh - shuffles and plays our playlist.m3u

For online radios:
- radio.m3u - list of online radios direct streaming links (preferably mp3)
- radio.sh - shuffles the links in radio.m3u and plays the 1st that comes

muzika.sh and radio.sh run on the device: they need bash, sox (play) and
busybox in /root/bin/busybox there, and must be executable:

scp muzika.sh radio.sh robo:/mnt/data/muzika/
ssh robo 'chmod +x /mnt/data/muzika/muzika.sh /mnt/data/muzika/radio.sh'

3. On our linux desktop we have those zsh scripts:
For online radio:
- RADIO-ROBOROCK.sh

For music:
- MUSIC-ROBOROCK.sh

For unconditionally stopping the audio on demand:
- STOP-AUDIO.sh
