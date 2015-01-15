Shields Module for Pitbull4
===========================


Overview
--------
This module allows you to add a bar to your Pitbull4 frames, where the extra bar will show you the remaing amount (not remaining time) of any shield(s) on that target.  You can also use a Lua text to overlay those as a text element wherever you might want.  I'll show you the code that below.  It's not automatically integrated to export to just show up magically in Pitbull's list yet, though that's a TODO.


New shield detection system
---------------------------

Version 2.0 is a major re-rewrite and massive code simplification, based on the relatively new UNIT_ABSORB_AMOUNT_CHANGED event and UnitGetTotalAbsorbs() API that Blizzard added in about 5.2 or so.  I'd been meaning to switch to this for a while.

This new code should now detect everything that Blizzard considers to be a damage shield, and won't need an explicit list of spellIDs to watch for.  No more "Pitbull4_Shields candidate spell" in your chat window.

One downside to this new mechanism is that the "self only" option is now not available, because the Blizzard API merges all shields into one.  I would need to keep the old UNIT_AURA based code (or parts of it) in order to estimate which user's shield is being consumed when damage is absorbed.  I think the simplicity wins over though, and I suspect 99.9% of the time you just want to know "how much damage can this unit take before its health starts to drop", and this should cover that.

Configuration
-------------
In the Layout editor, choose a layout and go to the `Bars` tab.  You'll see another set of tabs, with one called `Shields`.  The settings for the shields bar are there.  Note that by default, `Hide empty bar` is turned on, so if you have no shield on you, you'll see nothing until you do put up a shield.


Text
----
The Shield bar now will come with its own text.  If you want to show the bar but not the text, you can remove it (or reconfigure its font, size, attach to somewhere else, etc.) in the "Texts" tab for the unit you want to modify.  If you have previously used the LuaText suggestion for prior versions of this addon, you'll want to remove that, as it'll now say "{Err}" instead of what you want.


License
-------
This work is licensed under a [Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License](http://creativecommons.org/licenses/by-nc-sa/3.0/).


Bugs
----
No doubt there's lots of bugs.  You can let me know about them [here](https://github.com/Lurg/Pitbull4_Shields/issues).  I might even fix them if you let me know.
