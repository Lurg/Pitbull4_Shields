Shields Module for Pitbull4
===========================


Overview
--------
This module allows you to add a bar to your Pitbull4 frames, where the extra bar will show you the remaing amount (not remaining time) of any shield(s) on that target.  You can also use a Lua text to read the values and overlay those as a text element wherever you might want.  I'll show you the code that below.  It's not automatically integrated to export to just show up magically in Pitbull's list yet, though that's a TODO.

Currently it know about these shields:

<script type="text/javascript" src="http://static.wowhead.com/widgets/power.js"></script>

 * Death Knight
    - [Anti-Magic Shell](http://wowhead.com/spell=48707)
    - [Necrotic Strike](http://wowhead.com/spell=73975) (healing debuff)
    - [Blood Shield](http://wowhead.com/spell=77535)
    - [Death Barrier](http://wowhead.com/spell=115635) (friend shield from Death Coil)
    - [Shroud of Purgatory](http://wowhead.com/spell=116888)
 * Druid
    - Sorry, they took all Druid shields away!
 * Hunter
    - [Pet intervene](http://wowhead.com/spell=53476)
 * Mage
    - [Incanter's Ward](http://wowhead.com/spell=1463)
    - [Ice Barrier](http://wowhead.com/spell=11426)
 * Monk
    - [Guard](http://wowhead.com/spell=118604) ([also](http://wowhead.com/spell=115295), [and this](http://wowhead.com/spell=123402) with [Glyph of Guard](http://wowhead.com/spell=123401) and [also this](http://wowhead.com/spell=136070) with [Tier 14 4-pc](http://www.wowhead.com/spell=123159))
    - [Life Cocoon](http://wowhead.com/spell=116849)
 * Paladin
    - [Sacred Shield](http://wowhead.com/spell=65148)
    - [Illuminated Healing](http://wowhead.com/spell=86273)
    - [Guarded by the Light](http://wowhead.com/spell=88063)
    - [Delayed Judgement](http://wowhead.com/spell=105801)
 * Priest
    - [Power Word: Shield](http://wowhead.com/spell=17) ([also](http://wowhead.com/spell=123258) with [Divine Insight](http://www.wowhead.com/spell=109175))
    - [Divine Aegis](http://wowhead.com/spell=47753)
    - [Angelic Bulwark](http://wowhead.com/spell=114214)
    - [Spirit Shell](http://wowhead.com/spell=114908)
 * Shaman
    - [Stone Bulwark](http://wowhead.com/spell=114893)
 * Warlock
    - [Life Tap](http://wowhead.com/spell=1454) (with [Glyph of Life Tap](http://www.wowhead.com/item=45785), healing debuff)
    - [Twilight Ward](http://wowhead.com/spell=6229) ([also](http://wowhead.com/spell=131623))
    - [Soul Leech](http://wowhead.com/spell=108366)
    - [Sacrificial Bargain](http://wowhead.com/spell=108416)
    - [Dark Bargain](http://wowhead.com/spell=110913)
 * Warrior
    - [Shield of Fury](http://wowhead.com/spell=105909) (from [T-13 2-pc prot bonus](http://www.wowhead.com/spell=105908))
    - [Shield Barrier](http://wowhead.com/spell=112048)
 * Trinket and other object
    - [Indomitable Pride](http://wowhead.com/spell=108008)
    - [Stolen Relic of Zuldazar](http://wowhead.com/spell=138925)
    - [Soul Barrier](http://wowhead.com/spell=138979)
    - [Hydra Sputum](http://wowhead.com/spell=140380)
 * Enchants
    - [Colossus](http://wowhead.com/spell=116631)


If you know of other shields people might want to track, let me know and I'll see about adding them.  There's code in the addon which will print a message to the console when it detects a new kind of shield that it might be able to track.

It will show those shields on any unit frame the bar's enabled for, whether they're the unit that cast the shield or not.  The idea is if you're a Disc priest, you can shield your tank and know how much damage is left on that shield before you need to refresh it.


Configuration
-------------
In the Layout editor, choose a layout and go to the `Bars` tab.  You'll see another set of tabs, with one called `Shields`.  The settings for the shields bar are there.  Note that by default, `Hide empty bar` is turned on, so if you have no shield on you, you'll see nothing until you do put up a shield.


Lua Text
--------
If you want to overlay the actual value of the remaining shield, you'll need to extract the value from the shields module.  This is set up to be *fairly* easy to do.

This is how you do it:

1. Open the /pitbull config window
2. Select `Layout Editor`, then choode the layout you want to add the text element to
3. Select the `Texts` tab
4. In the `New text` box, type the name you want your text field to be called; anything you want.  I use `ShieldAmount`
5. "Type" should be `Lua texts`
6. "Attach to" wherever you want it to show up, configure it to look the way you want.  I attach to `Shields: default`, with `Middle` for location.
7. Under `Code` choose `Custom`, then in the box below, enter this code:

<pre><code>    local current=0
    for s,ss in pairs(PitBull4_Shields_combatFrame.shields) do
      current = current + (ss.cur[UnitGUID(unit)] or 0)
    end
    return string.format("|cffff0000%0.1fk",current/1000)</code></pre>

8. `Events`, you want to select `COMBAT_LOG_EVENT_UNFILTERED` and `UNIT_AURA` both.  Deselect the others.

Tada!  You're all done.  Cast a shield on yourself and see the results.

Also, note that the last line there is made to show the text as `27.8k` instead of `27814` to save some space on the narrow default bar.  You should feel free to hack that up and change it to display the way you want it to display.


License
-------
This work is licensed under a [Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License](http://creativecommons.org/licenses/by-nc-sa/3.0/).


Bugs
----
No doubt there's lots of bugs.  You can let me know about them [here](https://github.com/hughescr/Pitbull4_Shields/issues).  I might even fix them if you let me know.
