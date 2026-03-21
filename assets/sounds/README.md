# Sound Assets — Required Files

The app references these sound files. Add them before testing on a real device.

## Required (Core Features)

| File | Used By | Duration | Notes |
|------|---------|----------|-------|
| `siren.mp3` | SOS panic button siren | 3-5 sec (loops) | Loud, attention-grabbing emergency siren |
| `phone_ring.mp3` | Decoy call incoming ring | 3-5 sec (loops) | Realistic phone ringtone (NOT a siren) |

## Optional (Alert Sounds — Phase 2)

| File | Type |
|------|------|
| `siren_sos.mp3` | Critical alert siren |
| `general_warning.mp3` | Medium/high/low alert tone |
| `earthquake_alert.mp3` | Earthquake-specific alert |
| `flood_warning.mp3` | Flood-specific alert |
| `crash_alarm.mp3` | Crash detection alarm |
| `heart_alert.mp3` | Heart anomaly alert |
| `fall_detection.mp3` | Fall detection tone |
| `fire_alarm.mp3` | Fire alarm sound |
| `cyclone_siren.mp3` | Cyclone warning siren |

## Where to Get Free Sounds

1. **Pixabay** (Free, no attribution): https://pixabay.com/sound-effects/search/siren/
2. **Freesound.org** (CC0 licensed): https://freesound.org/search/?q=emergency+siren
3. **Zapsplat** (Free with account): https://www.zapsplat.com/sound-effect-categories/alarms-sirens/

## Fallback Behavior

The app gracefully handles missing sound files:
- **Siren missing** → Falls back to device vibration
- **Ringtone missing** → Falls back to device vibration
- **Alert sounds missing** → Logs error, continues silently
