# FS22_DynamicFieldPrices

Makes Field prices more interesting. It might make sense to look out for good deals instead of always buying the closest land.
Some NPCs are more greedy than others and their economic situation changes over time influencing the prices as well.
An extra 10% is added when buying or selling a field. This will strongly limit field flipping.
Prices change once per day.

## Price calculation
### NPCs

The game gives each field to one NPC. This mod gives each of them a permanent greediness factor and a changing factor for their economic situation.
These factors are different for each savegame but stored inbetween sessions.
Since the game never changes the connection between field and NPC, you will always buy/sell a certain field from/to the same person.
There is a game settings options to regenerate all npcs at midnight.
To completely regenerate the NPCs, you can also open dynamicFieldPrices.xml in your savegame and delete all <npc ... /> entries.  
You can also delete single entries here to only regenerate those NPCs. 

###  Greediness

The greediness factor is a number between 0.8 and 1.2 for each NPC. It will never change, unless the NPCs are reset. 
Min and Max can be changed per save in the dynamicFieldPrices.xml file in your savegame or via the game settings menu.
In the xml the value per NPC is mapped to 0..1.

### Economic situation

Each economic situation factor is a number between 0.6 and 1.6 for each NPC. It is randomly initiated once and will change daily by a small random amount.
Min and Max can be changed per save in the dynamicFieldPrices.xml file in your savegame or via the game settings menu.
In the xml the value per NPC is mapped to 0..1.

### Buy/Sell discouragement

To stop you from field flipping, a 10% extra is added when buying and substracted when selling a field.  
-> The factor is 1.1 for buying and 0.9 for selling.  
This value can also be changed in the dynamicFieldPrices.xml in your savegame or via the game settings menu.

### Formula for the Price:

The Base Price of land is calculated according to the map baselines:
baseprice = size x price_per_hectar x field_factor  
This will produce the same price as in the base game.  
It is then altered:  
actual_price = baseprice x greediness x economic x discouragement

### Difficulty

On average fields are now 21% more expensive to buy. However with some luck you can also find certain fields at almost half the original price.

## Compatibility

Compatible with FS22_BetterContracts. The displayed value is the combined discount from both mods (if BCs discounted fields option is enabled). Price factors from both mods are multiplicative (-10% DFP, -10% BC -> -19%).

## Possible future ideas

- Making a field more expensive, if it is ready to harvest

## Not doing

- Changing greediness by fulfilling/canceling contracts (or adding a extra factor for it). This is already implemented well enough by FS22_BetterContracts.
