# FlacMyGame - lossless game music patcher

**Upgrade low-quality game music with lossless music from the OST!**

**Compatible games:**
* Undertale (any version)
* Deltarune Chapter 1&2

![Comparison](/spectr.png)

**Requirements:**
* A compatible game
* The game's Original Soundtrack (flac or mp3)

**Installation:**
1. Download the latest release:
	* [[For Undertale](https://github.com/sobitcorp/FlacMyGame/releases/download/v1.1.0/FlacMyGame-v1.1.0-Undertale.zip)]
	* [[For Deltarune Chapter 1&2](https://github.com/sobitcorp/FlacMyGame/releases/download/v1.1.0/FlacMyGame-v1.1.0-DeltaruneCh1+2.zip)]
2. Extract into a new folder in your Undertale or Deltarune directory *(e.g. `C:\Undertale\flacmygame` if Undertale is in `C:\Undertale` )*
3. Prepare the Original Soundtrack.
   * Undertale:
      * If the OST is included with your game (as in the Steam version), make sure it is still in your Undertale directory and named either `Undertale soundtrack` or `ost` (case-insensitive).
      * Otherwise, make a copy of the soundtrack in the `flacmygame` folder *(e.g. `C:\Undertale\flacmygame\ost`)*.
   * Deltarune Chapter 1&2:
      * Copy both the Chapter 1 OST and Chapter 2 OST into the `flacmygame` folder.
      * Optionally copy the Undertale OST there as well (you only miss out on `gameover_short.ogg` otherwise). 
4. Run `FlacMyGame.bat`.

The program will generate game-compatible near-lossless music tracks using OST music and some stock game music to fill the gaps.
No changes will be made to your game directory without first prompting you.

# Issues

Many of the OST music tracks differ quite a bit from the in-game versions. 
There are differing cuts, volume levels, fade in/outs, even some pitch differences.
A lot of effort went into reversing or covering up all these differences to have the generated music match up with the stock music.
Some noticeable looping errors in the stock game music have also been fixed.

**Undertale**

The following 22 tracks cannot be 100% recovered from the OST, so some (rather short) bits are taken from the stock in-game music:
`ruins, undynescary, birdsong, mettmusical1, mettmusical2, mettmusical3, sansdate, coretransition, endarea_parta, endarea_partb, f_part1, f_part2, f_part3, f_6s_2, f_6s_4, f_6s_5, f_finale_1_l, f_finale_2, xpart_a, cast_2, cast_4, cast_6`

The following 5 tracks differ too greatly in the OST to be replaceable:
`toriel, leave, napstachords, oogloop, piano`

The following 14 tracks do not exist in the OST:
`dance_of_dog, dogshrine_1, dogshrine_2, f_finale_1, kingdescription, menu1, menu2, menu3, menu4, menu5, predummy, ruinspiano, st_him, star`

There are also 69 non-music effect and ambient sounds that do not exist in the OST.

**Deltarune Chapter 1&2**

The following 8 tracks cannot be 100% recovered from the OST, so some (rather short) bits are taken from the stock in-game music:
`creepydoor, forest, hip_shop, prejoker, cyber_battle_end, berdly_theme, giant_queen_appears, spamton_neo_mix_ex_wip`

The following 3 tracks differ too greatly in the OST to be replaceable:
`AUDIO_DARKNESS, cyber_battle, cybercity_old`

The following 2 tracks are not lossless in the OST and game audio is of better quality:
`acid_tunnel, noelle_normal`

The following 10 tracks do not exist in the OST (some of these are not used in game):
`cybercity_alt, dogcheck, honksong, noelle, flashback_excerpt, berdly_battle_heartbeat_true, thrash_rating, man, alarm_titlescreen, spamton_house`

There are also 46 non-music effect and ambient sounds that do not exist in the OST.
