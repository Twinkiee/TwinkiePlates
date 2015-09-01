# TwinkiePlates
TwinkiePlates is a nameplates addon for WildStar. It's been build forking a very popular addon called NPrimeNameplates (all credits given to the original author Nyan Prime) which was very well known because of its clean style, ease of use and, overall, good performances.
TwinkiePlates is all about these goals and a little more. It's been developed over several months by a player (me, Twinkie) dedicated to PvE just as much as PvP, playing several different classes (but still attached to his second love, Spellslinger) and different roles.
While I'm trying to add just as many features as they make sense, TwinkiePlates isn't, and never be, something good for everyone. There are already a good number of very good nameplates addons which offer different things ranging from a cool style to an incredible amount of options and features. TwinkiePlates doesn't aim to be better than what we already have, it's simply going to be different.

## GOALS
* Ease of use and configuration. Everything is configurable at a glance.
* Good-looking. I'm not a UI designer and, because of this, I'm sticking with what Nyan Prime did (which is top-notch). I'm adding/changing as few graphical elements as possible always trying to preserve the original look and feel.
* Clarity. Each UI has a _unique_ and _unambigous_ meaning and function.
* Smart performances; performances are a good thing until they don't hinder precious information. On the other side having a lot of information which hinder your performances is not good either. Sometimes less (information) is more (better performances). I'm always trying to balance this two key factors. Also, caching was one of the best practice Nyan Prime put in place: I'm still using it; expect an higher memory footprint than what you may have thought. Worry not, it's still pretty low.
* Maintainability. Unfortunately, I don't have much time to develope and test TwinkiePlates (and my other addons) just as much as I would. Whenever I consider introducing a new feature I also have to ponder how much work will it take to support and mantain it. Only a handful of ideas pass this exam.

## HOW TO USE/CONFIGURE

Type /tp or simply open the in-game Interface Menu (bottom-left corner button) and click on "TwinkiePlates".

## FEATURES

* Configuration matrix
  - 9 category types:
    1. Self
    2. Target
    3. Group
    4. Friendly PC
    5. Friendly NPC (it also includes friendly interactable units)
    6. Neutral PC
    7. Neutral NPC
    8. Hostile PC
    9. Hostile NPC
    
  - Global switch + 10 separate elements
    1. Nameplates: global nameplate display toggle
    2. Guild: PC guild/circle/arena-warplot team or NPC affiliation
    3. Title
    4. Health (health/shield/absorb bars)
    5. Health text
    6. Cast bar
    7. CC bar
    8. Armor (Interrupt Armor amount)
    9. Text bubble fade (whether the nameplate should fade when the unit is speaking or not)
    10. Class (a small icon diplaying the PC class or NPC rank)
    11. Level
    
  - 4 enabling conditions
    1. Always
    2. In combat only
    3. Out of combat only
    4. Never
* Hide main bars when full health/shield
* Aggro lost indicator (unit's name turns cyan when not targeting you)
* Harvesting nodes toggle
* Fade non-targeted units
* Cleanse indicator (main bars container frame)
* Dynamic positioning (when the nameplate goes off screen because the unit is too high, it gets positioned to the ground instead)
* Nameplacer addon support (more to come about Nameplacer)
* Draw distance control
* Low health threshold control
* Vertical offset control
* Style configurations
  - Smooth/segmented health bars
  - Health/shield text as flat amount or percentage
  - Font selection (CRB_Header or CRB_Interface)
  - Target indicator selection (overhead arrow or surrounding reticle)
* Different interruptable/uninterruptable cast bar colors
  

## PLANNED FEATURES

* Profiles handling
* Build/Vince Builds integration/support
* Different aggro-lost visualization options
* Multiple in-combat unit detection options 
* Colors customisation

## F.A.Q.

1. _Does nPrimeNameplates's license allow you to fork/continue the original project? Is this a legitimate project?_

No. Technically I'm not entitled to develope this project using, even partially, Nyan Prime's work. In fact I tried to get in touch with Nyan Prime asking for a permission to keep on working on his project; unfortunately I didn't receive any reply. I'm giving him all the credits for his precious work and whenever he would came back claiming any rights I'd simply acknowledge that. In the long terms it's even possible that, eventually, TwinkiePlates will completely diverge from nPrimeNameplates code/UI thus not breaking any copyrights anymore. 
For those who care, my code is freely available here (GNU GPL2): https://github.com/Twinkiee/TwinkiePlates

2. _nPrimeNameplates had more visual configurations. Why did you remove those?_

While the aspects of the nameplates and the configuration panel didn't change (that much), they've been through a significant overahaul that made most of the "legacy" visual configurations broken/obsolete. I'm not entirely against these kind of options but, at the moment, since I still have plan to add/change some UI elements they may simply become obsolete once again and not really worth the time investment.

3. _nPrimeNameplates was handling/displaying that thing in a different way. Can you revert it back?_

Well, no. At least not simply because "nPrimeNameplates was like that". TwinkiePlates is a different project.

4. _Do you accept suggestions/requests?_

Yes, they must comply to the each and every one of the 5 aforementioned goals and, in the end of the day, they need to make sense. No promises about when I'll be able to do that either.
You may want to open an issue here: https://github.com/Twinkiee/TwinkiePlates/issues
