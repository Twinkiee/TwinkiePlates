# TwinkiePlates
TwinkiePlates is a nameplates addon for WildStar. It's been build forking a very popular addon called NPrimeNameplates (all credits given to the original author Nyan Prime) which was very well known because of its clean style, ease of use and, overall, good performances.
TwinkiePlates is all about these goals and a little more. It's been developed over several months by a player (me, Twinkie) dedicated to PvE just as much as PvP, playing several different classes (but still attached to his second love, Spellslinger) and different roles.
While I'm trying to add just as many features as they make sense, TwinkiePlates isn't, and never be, something good for everyone. There are already a good number of very good nameplates addons which offer different things ranging from a cool style to an incredible amount of options and features. TwinkiePlates doesn't aim to be better than what we already have, it's simply going to be different.

## GOALS
* Ease of use and configuration. Everything is configurable at a glance.
* Good-looking. I'm not a UI designer and I'm sticking with what Nyan Prime did (which is top-notch). I'm adding as few graphical elements as possible preserving the original look and feel.
* Clarity. Each UI has a _unique_ and _unambigous_ meaning and function
* Smart performances; performances are a good thing until they don't hinder precious information. Sometimes less (information) is more (better performances). Also, caching was one of the best practice Nyan Prime put in place and I'm still using it; expect an higher memory footprint than what you may have thought (yet pretty low thou)
* Maintainability. Unfortunately I don't have much time to develope and test TwinkiePlates (and my other addons) just as much as I would. Whenever I consider introducing a new feature I also have to ponder how much work will it take to support and mantain it. Only a handful of ideas pass this exam.

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
