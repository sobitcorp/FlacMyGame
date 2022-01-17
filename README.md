# Undertale near-lossless music mod

**Replace low-quality stock game music with lossless music from the Original Soundtrack!**

**Requirements:**
* Undertale (any version)
* Undertale Original Soundtrack (flac or mp3, mp3 version comes with bundled with the Steam version of the game)

**Installation:**
1. Download the latest release [[here](https://github.com/sobitcorp/musmod/releases/download/v1.0.0/musmod-undertale-v1.0.0.zip)].
2. Extract into a new folder in your Undertale directory *(e.g. `C:\Undertale\musmod` if Undertale is in `C:\Undertale` )*
3. Prepare the Original Soundtrack.
   * If the OST is included with your game (as in the Steam version), make sure it is still in your Undertale directory and named either `Undertale soundtrack` or `ost`.
   * Otherwise, make a copy of the soundtrack in the `musmod` folder *(e.g. `C:\Undertale\musmod\ost`)*.
4. Run `musmod.bat`.

The program will generate 121 game-compatible near-lossless music tracks using OST music and some stock game music to fill the gaps.
No changes will be made to your game directory without first prompting you.

![Comparison](/spectr.png)

# Issues

Many of the OST music tracks differ quite a bit from the in-game versions. 
There are differing cuts, volume levels, fade in/outs, even some pitch differences.
A lot of effort went into reversing or covering up all those differences to have the generated music match up with the stock music.

The following 22 tracks cannot be 100% recovered from the OST, so some (rather short) bits are taken from the stock in-game music:
`ruins, undynescary, birdsong, mettmusical1, mettmusical2, mettmusical3, sansdate, coretransition, endarea_parta, endarea_partb, f_part1, f_part2, f_part3, f_6s_2, f_6s_4, f_6s_5, f_finale_1_l, f_finale_2, xpart_a, cast_2, cast_4, cast_6`

The following 5 tracks differ too greatly in the OST to be replaceable:
`toriel, leave, napstachords, oogloop, piano`

The following 14 tracks don't exist in the OST:
`dance_of_dog, dogshrine_1, dogshrine_2, f_finale_1, kingdescription, menu1, menu2, menu3, menu4, menu5, predummy, ruinspiano, st_him, star`

There are also 69 non-music effect and ambient sounds that don't exist in the OST.
