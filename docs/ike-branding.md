# Ike portrait and studio splash

October 9, 2026: Gerald requested the original smiling blonde-child portrait on
the story menu and Android launcher icon, with the Norbonics Games mark retained
on the loading screen. This supersedes the October 3 menu/launcher direction.

`assets/branding/ike-portrait.png` is a byte-identical copy of the existing root
`icon.png`, not a new illustration or photograph. SHA-256: `8c0dfb11a73a742f5ef2f4ad3e3c36987c59d7fd3b2e5653b889afead7f3a5a1`.
The root historical images remain excluded from exports; only the explicitly
selected portrait copy is used. The Norbonics splash image is unchanged.

The adaptive foreground centers that same 256px image on transparent 432px
canvas, with a neutral grey background. Padding leaves room for launcher masks.
The old K monochrome layer is no longer configured; there is no bespoke themed
monochrome icon in this version. The project/legacy launcher uses the portrait
directly. Android's system launch screen can initially show the launcher icon;
the subsequent in-engine loading splash retains Norbonics Games.
