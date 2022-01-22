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

###  Greediness

The greediness factor is a number between 0.7 and 1.5 for each NPC. It will never change, unless the dynamicFieldPrices.xml file in the samvegame is deleted.

### Economic situation

Each economic situation factor is a number between 0.7 and 1.5 for each NPC. It is randomly initiated once and will change daily by a small random amount.

### Buy/Sell discouragement

To stop you from field flipping, a 10% extra is added when buying and substracted when selling a field.
-> The factor is 1.1 for buying and 0.9 for selling.

### Formula for the Price:

The Base Price of land is calculated according to the map baselines:
baseprice = size*price_per_hectar*field_factor
This will produce the same price as in the base game
It is then altered:
actual_price = baseprice*greediness*economic*discouragement

### Difficulty

On average fields are now 33% more expensive to buy. However with some luck you can also find certain fields at almost have the original price.

## Possible future ideas

- Changing greediness by fulfilling/canceling contracts (or adding a extra factor for it)
- Making a field more expensive, if it is ready to harvest