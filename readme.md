# ff2hls

A simple application for broadcasting video or audio files from your PC to a web page, video player (e.g. MPV, VLC) or VRChat.

![](doc/icon.png)

## Dependencies

These must be available on the system path when you start the application:

- [Crystal](https://crystal-lang.org/)
- [FFmpeg](https://ffmpeg.org/)

## Broadcasting a Stream

Download the repository onto your machine and change directory into it:

```sh
git clone "https://github.com/amini-allight/ff2hls"
cd ff2hls
```

Run the application, pointing at the file you want to serve:

```sh
crystal run ./src/main.cr -- "/path/to/my-file.mp4"
```

This should produce an output like `Server online at 0.0.0.0:8000` indicating which port the server is running on. You can customize this behavior by setting the `FF2HLS_HOST` and `FF2HLS_PORT` environment variables prior to starting the server:

```sh
FF2HLS_HOST=127.0.0.1
FF2HLS_PORT=7777
crystal run ./src/main.cr -- "/path/to/my-file.mp4"
```

This will start a server only accessible to clients on the same machine (due to the host being `127.0.0.1`) and available on port 7777 instead of the default of 8000.

If your video has subtitles you may wish to burn them into the video stream otherwise they will be lost. You can do this by supplying a secondary argument that specifies the location of the subtitle file:

```sh
crystal run ./src/main.cr -- "/path/to/my-file.mp4" "/path/to/my-subtitles.srt"
```

If the subtitle stream is within the video file already you can refer to it by stream index like so:

```sh
crystal run ./src/main.cr -- "/path/to/my-file.mp4" 0
```

## Receiving a Stream (Web)

On the same machine the server is running on you can visit `http://127.0.0.1:8000/` in your browser to view the stream. On another machine you must visit `http://MY_MACHINE_IP:8000/` to view the stream where `MY_MACHINE_IP` is the remote machine's IP address. If you used `FF2HLS_PORT` to change the port then the port used in the URL will differ from the default of 8000. For the stream to be accessible outside of your local network you will probably need to forward your chosen port through your router and connect to it via your external public IP address, which is outside the scope of this readme.

**Note:** It may take around ten seconds after starting the server for the stream to become available.

## Receiving a Stream (VRChat or Video Player)

On the same machine the server is running on you can use the URL `http://127.0.0.1:8000/stream.m3u8` in VRChat or a video player to view the stream. In VRChat make sure you switch the player from "Video" mode to "Stream" mode first, if applicable. On another machine you must use `http://MY_MACHINE_IP:8000/stream.m3u8` to view the stream where `MY_MACHINE_IP` is the remote machine's IP address. If you used `FF2HLS_PORT` to change the port then the port used in the URL will differ from the default of 8000. For the stream to be accessible outside of your local network you will probably need to forward your chosen port through your router and connect to it via your external public IP address, which is outside the scope of this readme.

**Note:** It may take around ten seconds after starting the server for the stream to become available.

## Disk Usage

While running the server will create a directory called `tmp` inside of the repository where the HLS files will be stored. This can get quite large (by the time the stream the completes it will contain a full copy of your input file) but can be safely deleted after the server has shut down. If you don't delete it the server itself will clear out the directory on next launch so it can be reused.

## Desync and Delay

This stream typically has a delay of at least 10 seconds and may become desynced between clients, which can be fixed by them reloading the web page or reinitializing their player. I am not aware of a fix for either of these issues, they appear to be fundamental limitations of HLS.

## Credit & License

Developed by Amini Allight. Licensed under the AGPL 3.0.

Contains files (`res/video.min.js` and `res/video-js.min.css`) from [video.js](https://github.com/videojs/video.js) under their [license](https://github.com/videojs/video.js/blob/main/LICENSE).

This was originally inspired by somebody else's example. I'm pretty sure it was [this one](https://gist.github.com/CharlesHolbrow/8adfcf4915a9a6dd20b485228e16ead0) so thanks to Charles Holbrow for creating it.

This project is not affiliated with or endorsed by the FFmpeg project.
