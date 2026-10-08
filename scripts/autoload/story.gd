## Narrative content: prologue, codex lore, villager dialogue and the ending.
extends Node

const PROLOGUE := [
	"Before the first block was laid, there was the Prism of Ages.",
	"Within it burned five lights: Growth, Flame, Stillness, Life and the Deep. Together they held the five realms in balance, like threads of one great tapestry.",
	"The Wayfinders were its keepers. They walked between the realms through the great Gates, mending what was torn and guarding what was sacred.",
	"The greatest of them was Malric. He was the first to touch the Prism, and the first to wonder what it would be like to hold it alone.",
	"On the Night of the Hollow Star, Malric seized the Prism. Its light poured into him until nothing of the man remained. Only a crown, and the hunger that wore it.",
	"The Prism shattered. Five Shards fell into five realms, and each realm twisted around its Shard like a tree around a nail.",
	"The Wayfinders fell one by one. The Gates went dark. Malgrath, the Hollow Crown, waited in the Void for the last light to fade.",
	"But in the village of Oakhollow, beneath an old oak, a sleeper wakes with a mark glowing upon their hand...",
	"The mark of a Wayfinder.",
]

const EPILOGUE := [
	"The Hollow Crown falls. Its hunger, at last, has nothing left to eat.",
	"As Malgrath crumbles, a whisper escapes the empty crown. It is Malric's voice, small and tired: \"Thank you.\"",
	"The five Shards rise from your pack and sing together. The Prism of Ages is whole again, and its light rolls out across the five realms.",
	"The Gates blaze back to life. Villagers step out of their homes and look up at a sky that finally feels right.",
	"But the realms are endless, and the Prism's light reaches far, but never everywhere. Somewhere out past the last map, something stirs.",
	"The Wayfinder's work is never truly done.",
	"Your journey continues. Enemies grow stronger the farther you travel. Ascend, explore, and become a legend.",
]

## Codex entries, 8 per realm, discovered at lore stones and by defeating bosses.
var lore := [
	# Verdant
	{"id": "v1", "dim": "verdant", "title": "The Old Oak", "text": "Oakhollow was built around a single oak older than the realm itself. Elders say the first Wayfinder planted it as a seed taken from the Prism's own light, and that it will stand as long as one Wayfinder still walks."},
	{"id": "v2", "dim": "verdant", "title": "Song of the Gatewardens", "text": "\"Five gates, five keys, five lights in a row. / One for the green and one for the glow. / One for the frost and one for the bloom, / and one for the dark at the end of the room.\" - a children's rhyme, older than anyone remembers."},
	{"id": "v3", "dim": "verdant", "title": "The Illager Exodus", "text": "The Illagers were once scholars who lived beside the villagers in peace. When Malgrath offered them the secret of undying magic, Velkar was the first to bend the knee. Most of his clan followed. A few refused and fled to the far hills, where they are still hunted."},
	{"id": "v4", "dim": "verdant", "title": "Creeplings", "text": "No one knows where Creeplings come from. Alchemists who dissect them find only blastpowder and a strange green moss. Some theorize they are what happens when the Shard of Growth touches stone."},
	{"id": "v5", "dim": "verdant", "title": "The Wayfinder's Mark", "text": "The mark appears on the hand of one who is chosen by the Prism. It burns brighter near the Shards and near the Gates. Old texts say the mark cannot be given or taken. It can only be earned, or betrayed."},
	{"id": "v6", "dim": "verdant", "title": "Mirewood's Curse", "text": "The swamp was once a lake where lovers would row at dusk. When the Shard of Growth splintered, the lake swelled, rotted and drank the boats. Those who rowed out never rowed back."},
	{"id": "v7", "dim": "verdant", "title": "Stone That Walks", "text": "The Colossus was built to guard the Verdant Gate. It was given no will of its own, only a single command: 'Protect the light.' When the Shard of Growth fell into its chest, it came to believe that the light belonged to it."},
	{"id": "v8", "dim": "verdant", "title": "Malric's Journal I", "text": "\"Day 412. The Prism spoke to me again. It says the realms are suffering because they are divided. If one keeper held all five lights, there would be no more war, no more winter, no more death. Is it wrong to want that?\""},
	# Ember
	{"id": "e1", "dim": "ember", "title": "The Ember Empire", "text": "Before the ash, the Underrealm was home to a proud empire of smiths and glassblowers. Their capital was built inside a living volcano, and their Emperor forged his crown in its heart."},
	{"id": "e2", "dim": "ember", "title": "The Ashborn", "text": "The villagers of the Underrealm call themselves the Ashborn. They are descendants of the empire's servants who survived the eruption by hiding in deep cellars. They still bake bread in lava ovens and sing work songs to the stone."},
	{"id": "e3", "dim": "ember", "title": "Soulfire", "text": "Blue fire burns where many souls were lost. The Ashborn never warm themselves at soulfire. They say if you listen long enough you will hear your own name in its crackle."},
	{"id": "e4", "dim": "ember", "title": "Tuskguard Oath", "text": "\"Gold is strength. Strength is gold. Whoever holds the most gold holds the realm.\" The Tuskguard recite this before every battle. Grimtusk melted the imperial treasury into his armor to prove he holds the most."},
	{"id": "e5", "dim": "ember", "title": "The Last Phoenix", "text": "Phoenixes were once the messengers of the Wayfinders, carrying letters across realms in a single burning breath. Pyrrhia was the last. Malgrath bound her to the Shard of Flame so that every death brings her back crueler."},
	{"id": "e6", "dim": "ember", "title": "The Molten King", "text": "Emperor Infernus did not die in the eruption. He walked into the lava willingly, crown on his head, believing that fire would make him eternal. It did. It did not make him sane."},
	{"id": "e7", "dim": "ember", "title": "The Soulforge", "text": "Beneath the empire lies the Soulforge, where souls were hammered into armor for the emperor's guard. The Sentinel is its masterpiece: ten thousand souls, one body, no rest."},
	{"id": "e8", "dim": "ember", "title": "Malric's Journal II", "text": "\"Day 489. The others do not understand. Aeris called me a thief today. She does not see how the realms suffer apart. When I hold the Prism, I will bring her back the summer she lost. I will bring everyone back everything.\""},
	# Frost
	{"id": "f1", "dim": "frost", "title": "The Year Without Thaw", "text": "When the Shard of Stillness fell into the north, snow began to fall and did not stop. That was three hundred years ago. Children of Frostfall have never seen green grass."},
	{"id": "f2", "dim": "frost", "title": "The Pack Mother", "text": "Rimefang once led lost travelers home through blizzards. Families would leave meat on their doorsteps to thank her. Now the meat is untouched, and the travelers do not come home."},
	{"id": "f3", "dim": "frost", "title": "Queen Glaciara", "text": "She loved her people so much she could not bear to see them grow old. With the Shard's power she froze her whole court in mid-dance. They are still there, in the Glass Palace, smiling."},
	{"id": "f4", "dim": "frost", "title": "Strays", "text": "The skeletons of Frostfall are the soldiers of Glaciara's army, frozen at their posts. When the Shard woke, so did they. They still follow her last order: 'Let no one leave.'"},
	{"id": "f5", "dim": "frost", "title": "Mithril", "text": "Mithril only forms where cold is so deep that time slows down. Smiths say a blade of mithril remembers every strike it has ever made, and grows sharper with each memory."},
	{"id": "f6", "dim": "frost", "title": "The Wyrm Beneath", "text": "Before the winter, the Frostheart Wyrm slept under the glacier and dreamed of the sea. When it swallowed the Shard, it stopped dreaming. Now it only guards."},
	{"id": "f7", "dim": "frost", "title": "Aurora Hymn", "text": "The northern lights are the Prism's reflection in the sky. The villagers believe that when all five Shards are reunited, the aurora will burn so bright that winter will finally break."},
	{"id": "f8", "dim": "frost", "title": "Malric's Journal III", "text": "\"Day 501. I took the Prism tonight. It is so heavy. It speaks with five voices now and none of them are mine. Aeris, if you find this, do not come looking for me. Do not let them come looking for me.\""},
	# Spore
	{"id": "s1", "dim": "spore", "title": "The Bloom", "text": "The Shard of Life did not twist the Hollows. It overjoyed them. Everything grew, everything glowed, everything bloomed, and it has not stopped. Life without end is its own kind of death."},
	{"id": "s2", "dim": "spore", "title": "Myconids", "text": "The mushroom-folk share one great mind through threads of mycelium beneath the ground. Some colonies remain free. Others are connected to the Overgrowth Heart, and think only its thoughts."},
	{"id": "s3", "dim": "spore", "title": "Glowmoths", "text": "Glowmoths drink light. A swarm can drain a lantern in seconds and a person's warmth in minutes. Queen Lumina is said to have drunk an entire sunrise."},
	{"id": "s4", "dim": "spore", "title": "The Rot Mother", "text": "Something must eat the dead, or the Hollows would choke on endless life. The Rot Mother was the realm's answer. When the Shard came, she was asked to eat faster."},
	{"id": "s5", "dim": "spore", "title": "Bioluminite", "text": "Bioluminite crystals pulse slowly, about once every minute. Scholars believe they beat in time with the Overgrowth Heart. When the Heart stops, they say, the crystals will finally sleep."},
	{"id": "s6", "dim": "spore", "title": "The Walking Forest", "text": "The Myco Colossus is not a single creature. It is every mushroom in a forest valley, joined by roots and woken by the Shard. When it walks, the valley walks with it."},
	{"id": "s7", "dim": "spore", "title": "Aeris the Wayfinder", "text": "Aeris was the last Wayfinder before you. She followed Malric into the Void to bring him back. Her lantern was found in the Hollows, still burning, two hundred years later."},
	{"id": "s8", "dim": "spore", "title": "Malric's Journal IV", "text": "\"Day ???. I cannot remember my mother's face. The Prism took it to make room. It takes a little more each time I listen. The crown is so light now. I am so light now. Soon there will be nothing left to be heavy.\""},
	# Void
	{"id": "x1", "dim": "void", "title": "The Edge of Everything", "text": "The Void was once the realm of the Deep: the space between stars where dreams went to rest. When Malgrath came, he devoured its stars to light his throne."},
	{"id": "x2", "dim": "void", "title": "Enderlings", "text": "Enderlings are the last natives of the Void, tall and silent. They cannot bear to be looked at, because in the Void, being seen means being remembered, and remembering hurts."},
	{"id": "x3", "dim": "void", "title": "The Warden", "text": "The Warden was blinded by the Void's first darkness and learned to hunt by sound. It guards the bridge to Malgrath's islands, and it hears the heartbeat of every Wayfinder who approaches."},
	{"id": "x4", "dim": "void", "title": "Starless Night", "text": "Nihila was a star once. When Malgrath ate the sky, she was the only one who begged to serve him. She has been eating light ever since, hoping to become a star again."},
	{"id": "x5", "dim": "void", "title": "Chorus Gardens", "text": "Chorus plants grow toward wherever they are needed. The Wayfinders used them as signposts between realms. Eat a chorus fruit and you will fall, very briefly, somewhere else."},
	{"id": "x6", "dim": "void", "title": "Echo Crystals", "text": "Echo crystals record every sound in the Void. One found near the Throne still plays a voice: \"Aeris, I'm sorry. I'm so sorry. I can't stop listening.\""},
	{"id": "x7", "dim": "void", "title": "The Hollow Throne", "text": "Malgrath's throne floats at the edge of the Void, built from the bones of fallen Gates. From it, he can see every realm at once, and he has watched every one of your steps."},
	{"id": "x8", "dim": "void", "title": "Malric's Last Page", "text": "\"If a Wayfinder ever reads this: the Prism is not meant to be held. It is meant to be shared. I forgot that. Please, don't you forget it. And if you find me... set me free.\""},
]

const VILLAGER_FIRST := ["Bram", "Maren", "Tobin", "Elsa", "Gareth", "Wren", "Hollis", "Ivy", "Corin", "Fenna", "Osric", "Lyra", "Dain", "Mira", "Rowan", "Tess",
	"Alder", "Briony", "Cade", "Della", "Emeric", "Faye", "Gideon", "Hazel", "Ivo", "Juniper", "Kestrel", "Lorne", "Mabel", "Nyle", "Orla", "Percy", "Quill", "Rosa",
	"Silas", "Thea", "Ulric", "Vesna", "Wilder", "Yara", "Zeke", "Ansel", "Bryn", "Calla", "Dorian", "Edda", "Finch", "Greta", "Hugo", "Isla"]

const ROLE_LINES := {
	"elder": [
		"The Old Oak still stands. While it does, there is hope.",
		"I was a child when the Gates went dark. I never thought I'd see a Wayfinder's mark again.",
		"Every Shard you recover makes the sky a little bluer. Have you noticed?",
		"Be careful in the deep places. The Shards call to the wicked as much as the brave.",
	],
	"blacksmith": [
		"Bring me ore and emeralds and I'll make that blade sing.",
		"Good steel remembers the hand that forged it. Treat it well.",
		"I can upgrade anything that isn't already a legend. And legends too, for the right price.",
		"A dull weapon is a dead hero. Let me sharpen it up.",
	],
	"merchant": [
		"Finest wares in five realms! Well, in this village, anyway.",
		"Emeralds talk, friend. And I'm a very good listener.",
		"Mystery chests! Who knows what you'll find? Not me, I just sell them.",
		"Got resources to sell? I'll take them off your hands.",
	],
	"enchanter": [
		"Magic flows through all things. I simply... persuade it.",
		"Your enchantment points glow like little stars. Let's put them to use.",
		"Every enchantment leaves a mark on the soul of a weapon.",
		"Lapis? No, no, we use Wayfinder resonance now. Much tidier.",
	],
	"mystic": [
		"Your artifacts hunger for Arcane Dust. Feed them and they will grow.",
		"I see five lights in your future. Or is it your past?",
		"The Prism spoke to me in a dream once. It said 'hurry'.",
		"Magic is a river. Artifacts are the buckets. Bigger buckets, more river.",
	],
	"farmer": [
		"The crops won't grow right since the Shard broke. Too fast, or not at all.",
		"Monsters trampled my pumpkins again! Every night!",
		"Nothing like fresh bread after a long day of saving the world, eh?",
		"If you see any Silverleaf out there, bring it back. My wife's cough is getting worse.",
	],
	"guard": [
		"Stay sharp. They've been coming at night more often.",
		"I've held this wall for twenty years. I'm glad for the help.",
		"If you see the village bell ring, run toward it. That's where you'll be needed.",
		"Heard you're a Wayfinder. Prove it out there, not in here.",
	],
	"cartographer": [
		"The realms go on forever. I've checked. Well, I've checked a lot.",
		"Follow your compass arrow, Wayfinder. It never lies, unlike my maps.",
		"Caves are marked with dark openings in the ground. Treasure inside, if you survive.",
		"Lore stones glow faintly blue. They hold memories of the old world.",
	],
	"alchemist": [
		"Potions! Fresh potions! Only slightly explosive!",
		"Rotten Ichor is surprisingly useful. Don't ask what for.",
		"A Silverleaf tonic will put the color back in your cheeks.",
		"Mix two parts courage, one part stupidity. That's how heroes are brewed.",
	],
	"bard": [
		"I'm writing a ballad about you! I need a rhyme for 'Wayfinder'... Payfinder? Grayfinder?",
		"Have you heard the Song of the Gatewardens? Five gates, five keys...",
		"Every legend needs a bard. Every bard needs a legend. We're perfect for each other.",
		"They say Malgrath was a hero once. All the best villains were.",
	],
}

const DIM_ARRIVAL := {
	"verdant": "The Verdant Reach. Green and gentle, but the corruption creeps at its edges.",
	"ember": "Heat slams into you as you step through the Gate. The Ashen Underrealm smolders in every direction.",
	"frost": "The cold bites instantly. Snow falls in silence across the Frostfall Wastes.",
	"spore": "The air is thick with drifting light. The Sporelight Hollows hum with impossible life.",
	"void": "There is no ground beneath the islands, no stars above them. Only the Hollow Void, and the Throne waiting at its end.",
}


func lore_entry(id: String) -> Dictionary:
	for l in lore:
		if l["id"] == id:
			return l
	return {}


func lore_for_dim(dimid: String) -> Array:
	var out: Array = []
	for l in lore:
		if l["dim"] == dimid:
			out.append(l)
	return out


func role_line(role_id: String, seed_v: int) -> String:
	var lines: Array = ROLE_LINES.get(role_id, ROLE_LINES["elder"])
	return lines[absi(seed_v) % lines.size()]
