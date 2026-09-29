# Architecture

```text
Cuttlefish modem simulator
        ↓
Android radio stack
        ↓
Telephony framework
        ↓
CellularRadarRepository
        ↓
CellularRadarCell
        ↓
CellularRadarFormatter
        ↓
CellularRadarFragment
        ↓
AOSP Settings UI
```

The simulator/radio stack/framework already exist in the platform. The exported
contribution changes Settings only; it does not modify the simulator, RIL, HAL,
or framework.

## Acquisition: CellularRadarRepository

The repository uses the default-subscription TelephonyManager. When the screen
resumes or the user refreshes, it registers a TelephonyCallback.CellInfoListener
and requests information through requestCellInfoUpdate. Callbacks and UI
notifications run on the main thread.

Each session replaces the previous session. Stopping unregisters its callback,
cancels its timeout, and causes late callbacks to be ignored. There is no continuous
polling or acquisition while the page is paused. Status distinguishes loading,
ready/empty results, Location disabled, permission denial, unavailable service,
timeout, and modem errors. An error can preserve the last reported cells with
diagnostic text identifying them as earlier measurements.

The repository requests what the framework can report. It creates no cells and
contains no demo-data source.

## Immutable snapshot: CellularRadarCell

Each CellInfo becomes a technology-neutral snapshot: technology, role,
measurement timestamp, immutable identity strings/bands, and an immutable metric
map. Serving role uses connection status, falling back to registration;
unregistered cells with unknown connection status keep an explicit unknown role.

Identity comes from that cell's CellIdentity, not from a global operator name.
MCC/MNC strings retain leading zeros. PLMN exists only when both codes are valid.
NR/LTE bands come directly from getBands; they are not inferred from the channel.
NCI, CI, PCI, TAC, and other identifiers retain their technology-specific meaning.

Applicable missing metrics retain an unavailable representation. Inapplicable
metrics are omitted. Integer sentinels become the model's long sentinel; NCI
also suppresses the integer maximum used by this checkout's default NR identity.
No signal quality is synthesized from another measurement. CDMA and EVDO powers
are separate rather than combined through the generic CDMA getDbm result.

## Diagnostic text: CellularRadarFormatter

The formatter localizes labels and unavailable text, formats units, renders NR
bands as n41 and LTE bands as B41, and creates cell titles and multiline summaries.
Identifiers use their framework strings/numbers without padding or invented
values. SS and CSI metrics remain separately named; LTE RSSNR is correctly
labeled and uses the dB units exposed by this checkout.

Measurement age is calculated from elapsed realtime at display. It does not
promise fresh measurements and does not continuously tick on screen.

## Presentation: CellularRadarFragment

The DashboardFragment renders status, refresh, serving cells, and observed cells
using standard Settings preferences. It starts/stops the repository with the
screen lifecycle. It does not acquire radio data itself, infer geography, or
render a graphical radar.

CellularRadarPreferenceController preserves the Network & internet entry and
launches the fragment with its title. The current controller is declared in the
network package while its source file resides in the telephony directory; the
export preserves that existing arrangement.

## Interpretation limits

A list can contain multiple serving cells or none. An observed cell is a
framework observation, not a located antenna. NR CellInfo alone does not establish
SA/NSA deployment mode. The current simulator supplies one serving NR cell and
no observed neighbors. Missing fields remain unavailable.
