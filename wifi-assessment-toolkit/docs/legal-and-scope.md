# Legal, authorization, and scope

Wireless testing touches radio spectrum and other people's networks by nature.
The line between a professional assessment and a computer-misuse offense is
**authorization and scope** — nothing else. Treat this document as the gate you
pass through before every engagement.

## You must have, in writing, before any capture

1. **Authorization to test** the specific networks, signed by someone with the
   authority to grant it (client CISO/IT owner, or yourself for your own gear).
2. **A defined scope**: the exact SSIDs / BSSIDs / physical locations / time
   windows you are permitted to touch.
3. **Rules of engagement**: what techniques are allowed (e.g. is client
   deauthentication permitted, or PMKID-only?), blackout periods, and who to
   contact if something breaks.
4. **A get-out-of-jail contact**: name + phone of the authorizing party, carried
   on you during on-site work.

Keep these with the engagement file. If you cannot point to them, you are not
authorized — stop.

## Why the deauth question matters

Capturing a 4-way handshake traditionally involves sending deauthentication
frames to nudge a client into reconnecting. A deauth is a denial of the client's
service for the moment it is disconnected. On an engagement this is only
acceptable if the rules of engagement explicitly allow it, because it is
disruptive and it touches client devices.

For that reason this toolkit **defaults to PMKID capture**, which is *clientless*
— it asks the access point directly and disconnects nobody. Use targeted
handshake capture (with brief, single-target deauth) only when PMKID is
unavailable **and** the rules of engagement permit it. There is a hard switch in
the firmware config; leave it off unless you have written permission.

## What "in scope" means for this toolkit

The firmware reads `scope.yaml`. A capture will only run against a BSSID that is
listed there. This is enforced in code, not just documentation, so an accidental
key-press cannot start collecting from the coffee shop next door.

Fill the scope from your authorization letter — do not add a BSSID you have not
been cleared to test.

## Records to keep

For each engagement, retain:

- The signed authorization and scope.
- A capture log: timestamp, BSSID, technique, operator. (The firmware writes one
  to the SD card; keep it.)
- The analysis output and the final report.

Good record-keeping is what separates "I ran a sanctioned assessment" from
"trust me." Keep it as if you may have to show it to a lawyer, because on a bad
day you might.

## Data handling

Captures and any recovered credentials are sensitive client data. Store them
encrypted, share them only over the channel agreed with the client, and destroy
them per the engagement's data-retention terms once the report is delivered.
