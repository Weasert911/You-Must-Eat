# You Must Eat

A first-person CCTV surveillance demo. Take the watch: fixed cameras, a mouse to swivel each feed, and anomalies that only show if you keep looking.

## How it plays

- Switch between the fixed cameras and look around each feed
- Randomized live events keep the feeds honest: camera drift, wrong-frame glitches, sensor noise
- One location — the kitchen — with objects (a chair, plates, lights) that can rearrange themselves between shots; anomaly objects are configured in `Scripts/cctv_manager.gd`

## Run it

Open `project.godot` in Godot and run the project.

## Tech

Godot 4.6 · GDScript + a glitch shader material for camera faults

## Status

Standalone prototype of a surveillance loop.
