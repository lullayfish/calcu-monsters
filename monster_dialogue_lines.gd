extends RefCounted
class_name MonsterDialogueLines

# Five original lines for each playable regular monster and boss.
# Keys use texture path folder / file basename, so similar species
# can have different dialogue for regular and boss encounters.
const LINES := {
	"monster/baby_dragon": ["My fire is still buffering.", "I sneezed and toasted a marshmallow.", "Does this count as dragon training?", "My mum says I'm terrifying.", "Please ignore the tiny smoke rings."],
	"monster/bamboo": ["I'm growing through a phase.", "You can't count my rings!", "I bend, but I don't do fractions.", "I have excellent stalk options.", "My leaves are judging you."],
	"monster/bamouth": ["I brought my trunk for backup.", "Please don't count my wrinkles.", "I remember every embarrassing answer.", "My ears heard that equation.", "I am enormous in spirit."],
	"monster/beetle_leaf": ["I'm undercover as a leaf.", "Photosynthesis pays terribly.", "Don't flip me over, please.", "This leaf has fighting spirit.", "I bug people professionally."],
	"monster/bird": ["I can fly away from algebra.", "Tweet tweet. That's my defence.", "My nest is full of homework.", "I only count birdseed.", "Is this an open-beak test?"],
	"monster/candlesnake": ["My flame is very emotional.", "Don't blow on my head!", "I'm a ssscented menace.", "My wax budget is enormous.", "I'm burning through my patience."],
	"monster/centipede": ["How many shoes do I need?", "I lost count of my feet.", "My legs are doing the maths.", "Please don't ask me to dance.", "I need a shoe sponsorship."],
	"monster/crystal": ["I'm sparkling under pressure.", "My facets have facets.", "I can see a bad answer coming.", "Don't chip my confidence.", "I'm worth at least three pebbles."],
	"monster/egg": ["No cracking under pressure!", "I'm not ready to hatch yet.", "This battle is over easy.", "Please don't count your chickens.", "I feel a little scrambled."],
	"monster/electric_bat": ["I'm positively charged!", "My wings run on batteries.", "Please don't ground me.", "I'm bat at arithmetic.", "I heard that number in the dark."],
	"monster/electric_rat": ["Squeak! That's electrifying.", "My whiskers detect bad maths.", "I charge by the minute.", "I'm a very shocking rodent.", "Don't touch the tiny lightning."],
	"monster/fish": ["I'm out of my depth here.", "I only know school maths.", "Blub. A compelling argument.", "My grades are underwater.", "Is this a fishy equation?"],
	"monster/flamevil": ["My evil plan is lukewarm.", "I'm on fire! Figuratively too.", "I failed villain school twice.", "My temper has a thermostat.", "Please applaud my tiny flames."],
	"monster/frog": ["I leap to conclusions.", "Ribbit is my final answer.", "I'm toad-ally prepared.", "My tongue does long division.", "I have a pond to get back to."],
	"monster/goblin_king": ["Bow before your tiny king!", "My crown was on clearance.", "Royal arithmetic is beneath me.", "I tax every wrong answer.", "My throne is a folding chair."],
	"monster/goblinball": ["I roll with the punches.", "My strategy is mostly bouncing.", "Please don't kick the goblin.", "I'm round, not well-rounded.", "I have zero brakes."],
	"monster/goblinbat": ["I hang with questionable company.", "My wings were a bad investment.", "The goblin union sent me.", "Don't ask how I learned to fly.", "I stole these bat wings."],
	"monster/golem": ["I am rock solid at guessing.", "My thoughts are sedimentary.", "You cannot hurt my feelings. Maybe.", "I have a heart of gravel.", "My homework is set in stone."],
	"monster/hornheart": ["My horns are for decoration.", "I love you. As an opponent.", "This is a heartfelt threat.", "Please don't break my heart.", "I brought emotional support horns."],
	"monster/lamp": ["I have a bright idea!", "My electricity bill is overdue.", "I'm not a genie, sorry.", "Stop staring at my shade.", "I'm delighted to illuminate you."],
	"monster/lantern": ["I light up tense situations.", "I'm glowing with uncertainty.", "My wick is at its limit.", "I'll lead you astray politely.", "This is my brightest moment."],
	"monster/mimic": ["Surprise! I'm not furniture.", "I ate the last adventurer's map.", "Don't look inside my mouth.", "I've been practising my creak.", "The treasure was friendship. Kidding."],
	"monster/mimic_barrel": ["I'm barrel-y holding together.", "Please don't tap the keg.", "I'm full of terrible surprises.", "My disguise is airtight. Mostly.", "Someone labelled me pickles."],
	"monster/mimic_campfire": ["Pull up a seat. Hehehe.", "I'm a very warm welcome.", "Those aren't normal firewood.", "I'm cooking up trouble.", "Marshmallows cost extra."],
	"monster/miniflam": ["I am a very small threat.", "My spark has big ambitions.", "Don't put me in a jar.", "I can toast half a crouton.", "Fear my miniature inferno."],
	"monster/mole": ["I dig this battle.", "I came up for a snack.", "Your equations are underground.", "I'm a licensed tunnel expert.", "I can't see my own paws."],
	"monster/molicorn": ["My horn is mostly decorative.", "I'm a magical dirt enthusiast.", "I believe in subterranean dreams.", "Please don't step on my tunnel.", "My sparkle supply is low."],
	"monster/monkey": ["I demand more bananas.", "My maths teacher was a coconut.", "I'm just monkeying around.", "I can count to banana.", "This battle needs more swinging."],
	"monster/mount_goblin": ["I borrowed this ride.", "My mount has better grades.", "We share one brain cell.", "Are two goblins one problem?", "Please tip the driver."],
	"monster/mushroom": ["I'm a pretty fungi, actually.", "I grew here by accident.", "My spores are highly educated.", "You look like a fun-guy.", "I'm taking a little spore break."],
	"monster/mutant": ["I evolved without permission.", "My third eye failed maths.", "Please stop counting my limbs.", "This is my normal face.", "My mutation is mostly anxiety."],
	"monster/racoon": ["Your calculator looks stealable.", "I'm a professional trash critic.", "My paws are innocent!", "Is there food in that pocket?", "I washed my homework in a creek."],
	"monster/radish_plant": ["I'm rooting against you.", "Please respect my personal soil.", "I'm a very bitter vegetable.", "My leaves have stage fright.", "I grew up in a tough garden."],
	"monster/rock": ["I've been sitting here for ages.", "My hobbies include erosion.", "I am extremely grounded.", "This battle rocks. Allegedly.", "Don't take me for granite."],
	"monster/rock_crab": ["I pinch for a living.", "These claws aren't for typing.", "I'm a little shell-shocked.", "My beach house has no roof.", "Please don't boil the winner."],
	"monster/shell": ["I'm shy under pressure.", "There's no one home. Probably.", "My shell is my retirement plan.", "I refuse to come out for maths.", "I take everything personally. Inside."],
	"monster/skeleton": ["I have a bone to pick.", "My knees have left the chat.", "I'm barely holding together.", "I have zero body confidence.", "This is a grave mistake."],
	"monster/slime": ["I'm 80% water, 20% panic.", "Please don't divide me.", "I wobble under pressure.", "My résumé is slightly sticky.", "I have no bones to calculate."],
	"monster/slime_bat": ["I'm gooing places!", "My wings are very sticky.", "Don't ask how I take off.", "I splat with great elegance.", "I'm a bat with consistency issues."],
	"monster/snake": ["Sssssseven is my favourite.", "I have a sssssuspicion.", "I've got no hands to count.", "Please don't step on my tail.", "My hiss is mathematically sound."],
	"monster/snowman": ["I'm having a meltdown.", "I'm cool under pressure. Mostly.", "My nose is not a pencil.", "Please don't raise the temperature.", "I brought my own snow day."],
	"monster/spidercloud": ["I'm spinning up a forecast.", "Eight legs, zero umbrellas.", "I make my own bad weather.", "My web is cloud-based.", "Chance of spiders: unfortunately high."],
	"monster/spiritflam": ["I'm haunted by poor grades.", "Boo! No? Too subtle?", "I am a spooky little ember.", "My fire is mostly feelings.", "I used to be a birthday candle."],
	"monster/thunder_cloud": ["Forecast: mild embarrassment.", "I have stormy opinions.", "Don't rain on my equation.", "My thunder needs subtitles.", "I'm just a fluffy bad mood."],
	"monster/walking_bomb": ["No pressure. Tick tock.", "I'm a blast at parties.", "Please don't start a countdown.", "I walk very carefully.", "My fuse has trust issues."],
	"monster/walking_moon": ["I'm going through a phase.", "I moonwalk professionally.", "My craters have craters.", "Please respect my orbit.", "I need a little space."],
	"monster/worm": ["I'm outstanding in my dirt.", "I have no arms for this.", "My tunnel is rent-controlled.", "Please don't call me spaghetti.", "I wiggle when I'm nervous."],
	"boss/bamboo": ["I am the entire bamboo forest.", "My stalks are battle-tested.", "Bow before the big branch.", "I grew into a management role.", "Your calculator cannot prune me."],
	"boss/bamouth": ["Behold my mighty trunk!", "I remember every failed equation.", "My footsteps count as earthquakes.", "The tusks are non-negotiable.", "This is a mammoth problem."],
	"boss/beetle_leaf": ["My camouflage fooled entire armies.", "I am the leafiest final exam.", "My wings are battle-certified.", "You are in my garden now.", "Behold the mighty beetle dynasty."],
	"boss/butterfleye": ["I have eyes on your answers.", "My wings see EVERYTHING.", "Don't blink during this battle.", "I emerged from a math cocoon.", "My gaze is deeply unsettling."],
	"boss/candlesnake": ["My flame burns twice as bright.", "The wax throne is mine.", "I hiss in exponential notation.", "Try not to melt under pressure.", "Behold my blazing coils."],
	"boss/centipede": ["One hundred feet, one ruler.", "My shoe bill could bankrupt you.", "I trample all multiplication tables.", "Count my legs. I dare you.", "Every foot is a boss mechanic."],
	"boss/crystal": ["My facets hold ancient secrets.", "This sparkle is a warning.", "I'm harder than your final exam.", "You cannot shatter my confidence.", "Behold my perfectly cut doom."],
	"boss/dragon": ["I breathe fire, not formulas.", "My treasure is mostly coupons.", "I guard the kingdom of decimals.", "One wrong answer, extra crispy.", "Behold the most feared tax dragon."],
	"boss/electric_bat": ["I rule the stormy skies.", "My lightning has a licence.", "Prepare for a shocking exam.", "Your answers are on my radar.", "The whole cave runs on me."],
	"boss/electric_rat": ["I AM THE POWER GRID.", "My whiskers control the thunder.", "Prepare to be electro-chewed.", "I once shorted out a castle.", "My cheese is dangerously charged."],
	"boss/flamevil": ["I AM THE FINAL SPARK.", "My villain speech is on fire.", "The inferno has a syllabus.", "I demand a dramatic soundtrack.", "Your confidence will be toasted."],
	"boss/frog": ["I am king of the lily pads.", "My royal croak shakes kingdoms.", "I leap across dimensions.", "You cannot out-hop destiny.", "The pond has chosen its champion."],
	"boss/goblinbat": ["My wings blot out the moon!", "The goblin air force is here.", "I raid villages before breakfast.", "My battle cry is eeeeek!", "You are in bat territory now."],
	"boss/goblinboss": ["I've unionized every goblin.", "My crown is extremely official.", "All calculations pay tribute.", "I make the rules. Badly.", "The goblin empire demands snacks."],
	"boss/goblinmage": ["Behold my forbidden number spell.", "My wand is a stolen ruler.", "I cast ADVANCED ARITHMETIC!", "The spellbook has missing pages.", "I majored in minor inconveniences."],
	"boss/golem": ["I am a mountain with opinions.", "Your numbers cannot move me.", "My fists are solid bedrock.", "I have trained for centuries. Slowly.", "Prepare for geological consequences."],
	"boss/hatchegg": ["I hatched into a nightmare.", "You cracked the wrong egg.", "My yolk is full of vengeance.", "This is not a breakfast battle.", "I have evolved past omelettes."],
	"boss/hornheart": ["My love is a battlefield.", "These horns mean business.", "My heart beats in prime numbers.", "Prepare for emotional damage.", "Even villains need affection."],
	"boss/lamp": ["I AM THE BRIGHTEST IDEA.", "My glow fills entire kingdoms.", "I charge a fee for enlightenment.", "You cannot dim my ambition.", "My wattage is legendary."],
	"boss/mimic_fountain": ["Make a wish. It will bite.", "Every coin belongs to me.", "The water is suspiciously toothy.", "I am a highly cursed landmark.", "Your reflection looks delicious."],
	"boss/molicorn": ["Bow before the royal mole.", "My horn can pierce equations.", "I rule the glittering underground.", "Digging is a sacred art.", "You have entered my burrow."],
	"boss/mushroom": ["I AM THE SPORE EMPEROR.", "My mushroom kingdom is endless.", "Prepare for the great fungi uprising.", "My cap is bigger than your future.", "You've wandered into my mycelium."],
	"boss/mustarock": ["I am mustard-powered geology.", "My rocks are extra tangy.", "Fear the ancient condiment.", "I have a very spicy temper.", "The mountain demands hot dogs."],
	"boss/mutant": ["I have surpassed normal biology.", "Even I don't know my abilities.", "My mutations have mutations.", "I evolved beyond the answer key.", "Behold my magnificent weirdness."],
	"boss/racoon": ["I stole the royal treasury.", "My garbage empire has risen.", "Every shiny thing is MINE.", "I have three stolen calculators.", "I am the masked menace."],
	"boss/radish_plant": ["I rule the underground roots.", "My garden has no mercy.", "Prepare to be thoroughly weeded.", "I am the vegetable overlord.", "Your defeat will be organic."],
	"boss/shell": ["My shell is an ancient fortress.", "No equation can crack me.", "I have perfected hiding forever.", "You'll never reach my soft side.", "Behold the armoured menace."],
	"boss/skeleton": ["RISE, MY CALCIUM LEGION!", "I have centuries of grudges.", "You cannot break what's already dead.", "My bones spell your doom.", "This battle is to die for."],
	"boss/slime": ["I CONSUME ALL FRACTIONS.", "My goo knows no boundaries.", "One blob to rule them all.", "You cannot contain my wobble.", "My slime empire expands daily."],
	"boss/slime_bat": ["I reign over sticky skies.", "My wings drip with destiny.", "I am the airborne goo king.", "You cannot escape the splat.", "My army is highly adhesive."],
	"boss/snowman": ["WELCOME TO THE BLIZZARD.", "My snowflakes are weaponized.", "I command the frozen kingdom.", "Your calculator looks chilly.", "Winter is my full-time job."],
	"boss/spidercloud": ["My storm has eight legs.", "The forecast is web-related doom.", "I spin hurricanes for fun.", "The entire sky is my web.", "Prepare for a sticky thunderstorm."],
	"boss/spiritflam": ["I am the eternal ghostfire.", "My embers haunt the living.", "Boo! Now with extra flames.", "Your answer has been cursed.", "I burn beyond the grave."],
	"boss/thunder_cloud": ["I AM THE WHOLE WEATHER SYSTEM.", "My thunder is boss-level loud.", "I rain on EVERY parade.", "Your numbers cannot ground me.", "Brace yourself for the storm."],
	"boss/triple_goblin_king": ["Three kings. One shared brain cell.", "We demand THREE crowns!", "Our council voted for chaos.", "We all want the last snack.", "Our math votes never agree."],
	"boss/volcanocrab": ["I AM THE LAVA CRAB.", "My claws are molten fury.", "Prepare to be lightly roasted.", "The volcano is my bathtub.", "This battle is getting crusty."],
	"boss/walking_bomb": ["I AM THE FINAL COUNTDOWN.", "The fuse has been promoted.", "One wrong move and KABOOM!", "I have explosive ambitions.", "Please admire my safety goggles."],
	"boss/walking_moon": ["I control the midnight tides.", "My craters are ancient scars.", "You cannot outrun my orbit.", "The stars report directly to me.", "Behold the lunar overlord."],
	"boss/water_snake": ["My coils command the ocean.", "Prepare for a tidal hiss.", "My scales are waterproof, duh.", "I can swallow a whole wave.", "The sea itself fears my maths."]
}

static func for_texture(texture: Texture2D) -> Array[String]:
	if texture == null:
		return []
	var path: String = texture.resource_path
	var folder: String = path.get_base_dir().get_file()
	var name: String = path.get_file().get_basename()
	var key: String = folder + "/" + name
	var found: Array[String] = []
	if LINES.has(key):
		found.assign(LINES[key])
	return found
