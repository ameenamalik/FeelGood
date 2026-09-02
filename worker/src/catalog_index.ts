// Auto-generated catalog index from FeelGood/Content/catalog.json

export interface CatalogSessionItem {
  id: string;
  title: string;
  subtitle: string;
  durationMin: number;
  intensity: "gentle" | "moderate" | "dynamic";
  course: "appetizer" | "main" | "side" | "dessert" | "special";
  activity: string;
  places: string[];
  bodyFocus: string[];
  intents: string[];
  equipment: string[];
}

export const CATALOG_SESSIONS: CatalogSessionItem[] = [
  {
    "id": "app-box-breathing",
    "title": "Four rounds of box breathing",
    "subtitle": "Two minutes, anywhere, eyes open or closed",
    "durationMin": 2,
    "intensity": "gentle",
    "course": "appetizer",
    "activity": "breathwork",
    "places": [
      "home",
      "outdoors",
      "gym"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "calm"
    ],
    "equipment": [
      "none"
    ]
  },
  {
    "id": "app-neck-shoulder-release",
    "title": "Neck and shoulder release",
    "subtitle": "For the hours you spent looking at a screen",
    "durationMin": 3,
    "intensity": "gentle",
    "course": "appetizer",
    "activity": "stretching",
    "places": [
      "home",
      "gym"
    ],
    "bodyFocus": [
      "neckShoulders"
    ],
    "intents": [
      "calm",
      "mobilize"
    ],
    "equipment": [
      "none"
    ]
  },
  {
    "id": "app-hip-openers",
    "title": "Three minutes for your hips",
    "subtitle": "Undo a day of sitting",
    "durationMin": 4,
    "intensity": "gentle",
    "course": "appetizer",
    "activity": "stretching",
    "places": [
      "home",
      "gym",
      "studio"
    ],
    "bodyFocus": [
      "hips"
    ],
    "intents": [
      "mobilize",
      "calm"
    ],
    "equipment": [
      "mat"
    ]
  },
  {
    "id": "app-legs-up-the-wall",
    "title": "Legs up the wall",
    "subtitle": "The five minutes that reset everything",
    "durationMin": 5,
    "intensity": "gentle",
    "course": "appetizer",
    "activity": "breathwork",
    "places": [
      "home"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "calm"
    ],
    "equipment": [
      "mat"
    ]
  },
  {
    "id": "app-jump-rope-ninety",
    "title": "Ninety seconds of jump rope",
    "subtitle": "Short, bouncy, and good for your bones",
    "durationMin": 2,
    "intensity": "moderate",
    "course": "appetizer",
    "activity": "jumpRope",
    "places": [
      "home",
      "outdoors",
      "gym"
    ],
    "bodyFocus": [
      "lowerBody"
    ],
    "intents": [
      "energize"
    ],
    "equipment": [
      "rope"
    ]
  },
  {
    "id": "app-farmers-carry",
    "title": "Carry something heavy",
    "subtitle": "Three minutes that your grip will thank you for",
    "durationMin": 3,
    "intensity": "moderate",
    "course": "appetizer",
    "activity": "carries",
    "places": [
      "home",
      "gym"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "weights"
    ]
  },
  {
    "id": "app-morning-qigong",
    "title": "Five minutes of qi gong",
    "subtitle": "Slow, standing, and surprisingly waking",
    "durationMin": 5,
    "intensity": "gentle",
    "course": "appetizer",
    "activity": "qigong",
    "places": [
      "home",
      "outdoors"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "calm",
      "energize"
    ],
    "equipment": [
      "none"
    ]
  },
  {
    "id": "main-pilates-gentle-10",
    "title": "Ten gentle minutes on the mat",
    "subtitle": "Small, doable, still counts",
    "durationMin": 10,
    "intensity": "gentle",
    "course": "main",
    "activity": "pilates",
    "places": [
      "home",
      "gym",
      "studio"
    ],
    "bodyFocus": [
      "core"
    ],
    "intents": [
      "strengthen",
      "mobilize"
    ],
    "equipment": [
      "mat"
    ]
  },
  {
    "id": "main-pilates-core-20",
    "title": "Twenty minutes of mat Pilates",
    "subtitle": "Controlled, core-led, no equipment",
    "durationMin": 20,
    "intensity": "moderate",
    "course": "main",
    "activity": "pilates",
    "places": [
      "home",
      "gym",
      "studio"
    ],
    "bodyFocus": [
      "core"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "mat"
    ]
  },
  {
    "id": "main-pilates-full-30",
    "title": "Thirty minutes, full body",
    "subtitle": "The one that leaves you taller",
    "durationMin": 30,
    "intensity": "moderate",
    "course": "main",
    "activity": "pilates",
    "places": [
      "home",
      "gym",
      "studio"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "strengthen",
      "energize"
    ],
    "equipment": [
      "mat"
    ]
  },
  {
    "id": "main-strength-express-15",
    "title": "Fifteen minutes with weights",
    "subtitle": "Short, loaded, effective",
    "durationMin": 15,
    "intensity": "moderate",
    "course": "main",
    "activity": "strength",
    "places": [
      "home",
      "gym"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "weights"
    ]
  },
  {
    "id": "main-strength-full-30",
    "title": "Thirty minutes, full strength",
    "subtitle": "The proper one",
    "durationMin": 30,
    "intensity": "dynamic",
    "course": "main",
    "activity": "strength",
    "places": [
      "home",
      "gym"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "weights"
    ]
  },
  {
    "id": "main-qigong-20",
    "title": "Twenty minutes of qi gong",
    "subtitle": "Standing, slow, and quietly restorative",
    "durationMin": 20,
    "intensity": "gentle",
    "course": "main",
    "activity": "qigong",
    "places": [
      "home",
      "outdoors"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "calm",
      "mobilize"
    ],
    "equipment": [
      "none"
    ]
  },
  {
    "id": "main-mobility-20",
    "title": "Twenty minutes of stretching",
    "subtitle": "For the days everything feels tight",
    "durationMin": 20,
    "intensity": "gentle",
    "course": "main",
    "activity": "stretching",
    "places": [
      "home",
      "gym",
      "studio"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "mobilize",
      "calm"
    ],
    "equipment": [
      "mat"
    ]
  },
  {
    "id": "main-walk-30",
    "title": "A thirty minute walk",
    "subtitle": "Outside, phone in your pocket",
    "durationMin": 30,
    "intensity": "gentle",
    "course": "main",
    "activity": "walking",
    "places": [
      "outdoors"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "calm",
      "energize"
    ],
    "equipment": [
      "outdoor"
    ]
  },
  {
    "id": "main-dance-20",
    "title": "Twenty minutes of dancing",
    "subtitle": "No choreography, no mirror",
    "durationMin": 20,
    "intensity": "moderate",
    "course": "main",
    "activity": "dance",
    "places": [
      "home"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "play",
      "energize"
    ],
    "equipment": [
      "none"
    ]
  },
  {
    "id": "main-yoga-flow-20",
    "title": "Twenty minutes of flow",
    "subtitle": "Warm, steady, breath-led",
    "durationMin": 20,
    "intensity": "gentle",
    "course": "main",
    "activity": "yoga",
    "places": [
      "home",
      "gym",
      "studio"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "mobilize",
      "calm"
    ],
    "equipment": [
      "mat"
    ]
  },
  {
    "id": "main-bike-45",
    "title": "A forty-five minute ride",
    "subtitle": "Steady, outside, nowhere in particular",
    "durationMin": 45,
    "intensity": "moderate",
    "course": "main",
    "activity": "biking",
    "places": [
      "outdoors"
    ],
    "bodyFocus": [
      "lowerBody"
    ],
    "intents": [
      "energize"
    ],
    "equipment": [
      "bike",
      "outdoor"
    ]
  },
  {
    "id": "side-calf-stretch-kettle",
    "title": "Calf stretch while the kettle boils",
    "subtitle": "Two birds",
    "durationMin": 5,
    "intensity": "gentle",
    "course": "side",
    "activity": "stretching",
    "places": [
      "home"
    ],
    "bodyFocus": [
      "lowerBody"
    ],
    "intents": [
      "mobilize"
    ],
    "equipment": [
      "none"
    ]
  },
  {
    "id": "side-walk-the-call",
    "title": "Walk your next call",
    "subtitle": "Same call, different body",
    "durationMin": 10,
    "intensity": "gentle",
    "course": "side",
    "activity": "walking",
    "places": [
      "home",
      "outdoors"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "energize"
    ],
    "equipment": [
      "none"
    ]
  },
  {
    "id": "side-desk-shoulder-reset",
    "title": "Shoulder reset between meetings",
    "subtitle": "Five minutes, no floor needed",
    "durationMin": 5,
    "intensity": "gentle",
    "course": "side",
    "activity": "stretching",
    "places": [
      "home",
      "gym"
    ],
    "bodyFocus": [
      "neckShoulders"
    ],
    "intents": [
      "mobilize",
      "calm"
    ],
    "equipment": [
      "none"
    ]
  },
  {
    "id": "side-single-leg-balance",
    "title": "Stand on one leg while you brush your teeth",
    "subtitle": "Free balance practice",
    "durationMin": 5,
    "intensity": "gentle",
    "course": "side",
    "activity": "strength",
    "places": [
      "home"
    ],
    "bodyFocus": [
      "lowerBody"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "none"
    ]
  },
  {
    "id": "side-skater-bounds",
    "title": "Five minutes of skater bounds",
    "subtitle": "Quick feet, side to side",
    "durationMin": 5,
    "intensity": "moderate",
    "course": "side",
    "activity": "agility",
    "places": [
      "home",
      "outdoors",
      "gym"
    ],
    "bodyFocus": [
      "lowerBody"
    ],
    "intents": [
      "energize"
    ],
    "equipment": [
      "none"
    ]
  },
  {
    "id": "side-carry-the-shopping",
    "title": "Carry the shopping in one trip",
    "subtitle": "Grip work that was happening anyway",
    "durationMin": 5,
    "intensity": "gentle",
    "course": "side",
    "activity": "carries",
    "places": [
      "home",
      "outdoors"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "none"
    ]
  },
  {
    "id": "dessert-three-songs",
    "title": "Dance to three songs",
    "subtitle": "That's it. That's the session.",
    "durationMin": 10,
    "intensity": "gentle",
    "course": "dessert",
    "activity": "dance",
    "places": [
      "home"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "play"
    ],
    "equipment": [
      "none"
    ]
  },
  {
    "id": "dessert-shower-and-legs-up",
    "title": "Long shower, then legs up the wall",
    "subtitle": "The good kind of doing nothing",
    "durationMin": 10,
    "intensity": "gentle",
    "course": "dessert",
    "activity": "breathwork",
    "places": [
      "home"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "calm"
    ],
    "equipment": [
      "none"
    ]
  },
  {
    "id": "dessert-sunlight-walk",
    "title": "Ten minutes in the light",
    "subtitle": "Especially good early",
    "durationMin": 10,
    "intensity": "gentle",
    "course": "dessert",
    "activity": "walking",
    "places": [
      "outdoors"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "calm",
      "energize"
    ],
    "equipment": [
      "outdoor"
    ]
  },
  {
    "id": "dessert-skate",
    "title": "Go for a skate",
    "subtitle": "Because it's fun, which is the point",
    "durationMin": 20,
    "intensity": "moderate",
    "course": "dessert",
    "activity": "skating",
    "places": [
      "outdoors"
    ],
    "bodyFocus": [
      "lowerBody"
    ],
    "intents": [
      "play"
    ],
    "equipment": [
      "skates",
      "outdoor"
    ]
  },
  {
    "id": "special-swim",
    "title": "Swim",
    "subtitle": "Worth planning the trip for",
    "durationMin": 45,
    "intensity": "moderate",
    "course": "special",
    "activity": "swimming",
    "places": [
      "pool"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "energize",
      "calm"
    ],
    "equipment": [
      "pool"
    ]
  },
  {
    "id": "special-reformer-class",
    "title": "A reformer class",
    "subtitle": "Book it, put it in the calendar",
    "durationMin": 45,
    "intensity": "moderate",
    "course": "special",
    "activity": "pilates",
    "places": [
      "studio"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "reformer"
    ]
  },
  {
    "id": "special-pickleball",
    "title": "Play pickleball",
    "subtitle": "Quick feet, and a laugh",
    "durationMin": 45,
    "intensity": "moderate",
    "course": "special",
    "activity": "racquet",
    "places": [
      "outdoors"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "play",
      "energize"
    ],
    "equipment": [
      "outdoor"
    ]
  },
  {
    "id": "special-climb",
    "title": "A climbing session",
    "subtitle": "New patterns, strong hands",
    "durationMin": 45,
    "intensity": "moderate",
    "course": "special",
    "activity": "climbing",
    "places": [
      "gym",
      "outdoors"
    ],
    "bodyFocus": [
      "upperBody"
    ],
    "intents": [
      "strengthen",
      "play"
    ],
    "equipment": [
      "outdoor"
    ]
  },
  {
    "id": "side-gym-carry-the-floor",
    "title": "Two heavy things, one lap",
    "subtitle": "The simplest thing in the building",
    "durationMin": 5,
    "intensity": "gentle",
    "course": "side",
    "activity": "carries",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "main-gym-machines-20",
    "title": "Twenty minutes on the machines",
    "subtitle": "Nothing to set up, nothing to balance",
    "durationMin": 20,
    "intensity": "moderate",
    "course": "main",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "main-gym-floor-30",
    "title": "Thirty minutes on the gym floor",
    "subtitle": "The whole body, one round at a time",
    "durationMin": 30,
    "intensity": "dynamic",
    "course": "main",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "side-gym-pull-8",
    "title": "Eight minutes of pulling",
    "subtitle": "For a back that spent the day at a desk",
    "durationMin": 8,
    "intensity": "gentle",
    "course": "side",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "back",
      "upperBody"
    ],
    "intents": [
      "strengthen",
      "mobilize"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "dessert-gym-sauna-and-stretch",
    "title": "Sauna, then the quiet mat in the corner",
    "subtitle": "The part of the membership nobody uses",
    "durationMin": 15,
    "intensity": "gentle",
    "course": "dessert",
    "activity": "breathwork",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "calm"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "dessert-living-room-floor-unwind",
    "title": "Living room floor unwind",
    "subtitle": "Ten minutes off your feet",
    "durationMin": 10,
    "intensity": "gentle",
    "course": "dessert",
    "activity": "breathwork",
    "places": [
      "home"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "calm",
      "play"
    ],
    "equipment": [
      "none"
    ]
  },
  {
    "id": "dessert-barefoot-breath",
    "title": "Barefoot porch breath",
    "subtitle": "Five minutes of fresh air and stillness",
    "durationMin": 5,
    "intensity": "gentle",
    "course": "dessert",
    "activity": "breathwork",
    "places": [
      "home",
      "outdoors"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "calm",
      "play"
    ],
    "equipment": [
      "none"
    ]
  },
  {
    "id": "dessert-favorite-playlist-groove",
    "title": "Favorite playlist groove",
    "subtitle": "Two songs, zero rules",
    "durationMin": 8,
    "intensity": "gentle",
    "course": "dessert",
    "activity": "breathwork",
    "places": [
      "home"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "play",
      "energize"
    ],
    "equipment": [
      "none"
    ]
  },
  {
    "id": "dessert-tea-and-quiet-stretch",
    "title": "Tea and quiet floor stretch",
    "subtitle": "Gentle restorative unwinding",
    "durationMin": 10,
    "intensity": "gentle",
    "course": "dessert",
    "activity": "breathwork",
    "places": [
      "home"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "calm"
    ],
    "equipment": [
      "none"
    ]
  },
  {
    "id": "dessert-park-bench-stretch",
    "title": "Park bench quiet stretch",
    "subtitle": "Ten minutes in the open air",
    "durationMin": 10,
    "intensity": "gentle",
    "course": "dessert",
    "activity": "stretching",
    "places": [
      "outdoors"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "calm",
      "play"
    ],
    "equipment": [
      "outdoor"
    ]
  },
  {
    "id": "side-doorway-chest-opener",
    "title": "Doorway chest and spine opener",
    "subtitle": "Counteract hours of sitting",
    "durationMin": 5,
    "intensity": "gentle",
    "course": "side",
    "activity": "stretching",
    "places": [
      "home",
      "gym"
    ],
    "bodyFocus": [
      "upperBody"
    ],
    "intents": [
      "calm",
      "strengthen"
    ],
    "equipment": [
      "none"
    ]
  },
  {
    "id": "side-toothbrush-calf-raises",
    "title": "Calf raises while brushing teeth",
    "subtitle": "Two minutes of ankle and calf strength",
    "durationMin": 5,
    "intensity": "gentle",
    "course": "side",
    "activity": "strength",
    "places": [
      "home"
    ],
    "bodyFocus": [
      "lowerBody"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "none"
    ]
  },
  {
    "id": "side-desk-wrist-reset",
    "title": "Desk wrist and forearm reset",
    "subtitle": "Five minutes for tired hands and forearms",
    "durationMin": 5,
    "intensity": "gentle",
    "course": "side",
    "activity": "stretching",
    "places": [
      "home",
      "gym"
    ],
    "bodyFocus": [
      "upperBody"
    ],
    "intents": [
      "calm"
    ],
    "equipment": [
      "none"
    ]
  },
  {
    "id": "side-stairs-step-ups",
    "title": "Five minutes of stairs",
    "subtitle": "Quick leg drive on the bottom step",
    "durationMin": 5,
    "intensity": "gentle",
    "course": "side",
    "activity": "agility",
    "places": [
      "home",
      "outdoors",
      "gym"
    ],
    "bodyFocus": [
      "lowerBody"
    ],
    "intents": [
      "energize",
      "strengthen"
    ],
    "equipment": [
      "none"
    ]
  },
  {
    "id": "side-quick-block-loop",
    "title": "One lap around the block",
    "subtitle": "Fresh air between tasks",
    "durationMin": 8,
    "intensity": "gentle",
    "course": "side",
    "activity": "walking",
    "places": [
      "outdoors"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "energize",
      "calm"
    ],
    "equipment": [
      "outdoor"
    ]
  },
  {
    "id": "yt-kNbJJOJumlM",
    "title": "Ten minutes, side abs and inner thighs",
    "subtitle": "A quick, focused burn for the obliques and thighs",
    "durationMin": 10,
    "intensity": "moderate",
    "course": "main",
    "activity": "pilates",
    "places": [
      "home",
      "gym",
      "studio"
    ],
    "bodyFocus": [
      "core"
    ],
    "intents": [
      "strengthen",
      "energize"
    ],
    "equipment": [
      "mat"
    ]
  },
  {
    "id": "yt-huL9JFjDwVI",
    "title": "Twenty-five minutes, full body beginner mat Pilates",
    "subtitle": "A steady, whole-body flow to build core strength",
    "durationMin": 25,
    "intensity": "moderate",
    "course": "main",
    "activity": "pilates",
    "places": [
      "home",
      "gym",
      "studio"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "strengthen",
      "mobilize"
    ],
    "equipment": [
      "mat"
    ]
  },
  {
    "id": "yt-bE0ssPhfBfg",
    "title": "Eleven minutes, Pilates arms with weights",
    "subtitle": "Sculpt and strengthen your shoulders and posture",
    "durationMin": 12,
    "intensity": "moderate",
    "course": "main",
    "activity": "pilates",
    "places": [
      "home",
      "gym",
      "studio"
    ],
    "bodyFocus": [
      "upperBody"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "mat",
      "weights"
    ]
  },
  {
    "id": "yt-grzqpN2bNTs",
    "title": "Fifteen minutes, core and glutes hourglass flow",
    "subtitle": "A quick, low-impact sequence for the waist and hips",
    "durationMin": 15,
    "intensity": "moderate",
    "course": "main",
    "activity": "pilates",
    "places": [
      "home",
      "gym",
      "studio"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "strengthen",
      "energize"
    ],
    "equipment": [
      "mat"
    ]
  },
  {
    "id": "yt-UDuZNDwQrqI",
    "title": "Twenty-five minutes, gentle stress-relief flow",
    "subtitle": "Slow down, move mindfully, and release tension",
    "durationMin": 25,
    "intensity": "gentle",
    "course": "main",
    "activity": "pilates",
    "places": [
      "home",
      "gym",
      "studio"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "calm",
      "mobilize"
    ],
    "equipment": [
      "mat"
    ]
  },
  {
    "id": "yt-nZaHiSEXqrg",
    "title": "Fifteen minutes, quick full body reset",
    "subtitle": "A fast and efficient flow to wake up the whole body",
    "durationMin": 15,
    "intensity": "moderate",
    "course": "main",
    "activity": "pilates",
    "places": [
      "home",
      "gym",
      "studio"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "energize",
      "mobilize"
    ],
    "equipment": [
      "mat"
    ]
  },
  {
    "id": "yt-5m-hvk7D6QI",
    "title": "Forty-one minutes, full body sculpt with weights",
    "subtitle": "A comprehensive, strength-focused Pilates session",
    "durationMin": 41,
    "intensity": "dynamic",
    "course": "main",
    "activity": "pilates",
    "places": [
      "home",
      "gym",
      "studio"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "strengthen",
      "energize"
    ],
    "equipment": [
      "mat",
      "weights"
    ]
  },
  {
    "id": "yt-en2Zs4n4yio",
    "title": "Twenty-four minutes, legs and glutes focus",
    "subtitle": "A mat-based burn targeting the lower body",
    "durationMin": 24,
    "intensity": "moderate",
    "course": "main",
    "activity": "pilates",
    "places": [
      "home",
      "gym",
      "studio"
    ],
    "bodyFocus": [
      "lowerBody"
    ],
    "intents": [
      "strengthen",
      "mobilize"
    ],
    "equipment": [
      "mat"
    ]
  },
  {
    "id": "yt-l31iSekrSPw",
    "title": "Twelve minutes, tight core and abs",
    "subtitle": "A focused core-strengthening mat routine",
    "durationMin": 12,
    "intensity": "moderate",
    "course": "main",
    "activity": "pilates",
    "places": [
      "home",
      "gym",
      "studio"
    ],
    "bodyFocus": [
      "core"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "mat"
    ]
  },
  {
    "id": "yt-K3ZQF0VFcNk",
    "title": "Twenty minutes, core and glutes flow",
    "subtitle": "Target the core and hips with this mat routine",
    "durationMin": 20,
    "intensity": "moderate",
    "course": "main",
    "activity": "pilates",
    "places": [
      "home",
      "gym",
      "studio"
    ],
    "bodyFocus": [
      "core"
    ],
    "intents": [
      "strengthen",
      "energize"
    ],
    "equipment": [
      "mat"
    ]
  },
  {
    "id": "yt-HTDFOwzCs4g",
    "title": "Twenty-three minutes, low impact beginner Pilates",
    "subtitle": "A gentle, full-body mat flow with zero jumping",
    "durationMin": 23,
    "intensity": "gentle",
    "course": "main",
    "activity": "pilates",
    "places": [
      "home",
      "gym",
      "studio"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "mobilize",
      "calm"
    ],
    "equipment": [
      "mat"
    ]
  },
  {
    "id": "yt-cItPBVsnIgw",
    "title": "Eighteen minutes, high-intensity Pilates arms",
    "subtitle": "A burn-inducing upper body sequence with no equipment",
    "durationMin": 18,
    "intensity": "moderate",
    "course": "main",
    "activity": "pilates",
    "places": [
      "home",
      "gym",
      "studio"
    ],
    "bodyFocus": [
      "upperBody"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "mat"
    ]
  }
];

export function findSessionById(id?: string): CatalogSessionItem | undefined {
  if (!id) return undefined;
  return CATALOG_SESSIONS.find(s => s.id === id);
}

export function matchBestSession(params: {
  targetDuration?: number;
  intensity?: "gentle" | "moderate" | "dynamic";
  bodyFocus?: string;
  intent?: string;
  place?: string;
  excludeId?: string;
  likedActivities?: string[];
  recoveryOwed?: boolean;
  lastFeel?: "lovedIt" | "fine" | "tooMuch";
}): CatalogSessionItem {
  let best: CatalogSessionItem = CATALOG_SESSIONS[0]!;
  let bestScore = -999;

  for (const s of CATALOG_SESSIONS) {
    if (params.excludeId && s.id === params.excludeId) continue;
    let score = 0;

    if (params.targetDuration) {
      const diff = Math.abs(s.durationMin - params.targetDuration);
      if (diff === 0) score += 20;
      else if (diff <= 3) score += 12;
      else if (diff <= 6) score += 6;
      else score -= diff;
    }

    if (params.intensity && s.intensity === params.intensity) {
      score += 10;
    }

    if (params.bodyFocus && s.bodyFocus.includes(params.bodyFocus)) {
      score += 15;
    }

    if (params.intent && s.intents.includes(params.intent)) {
      score += 10;
    }

    if (params.place && s.places.includes(params.place)) {
      score += 5;
    }

    if (s.course === "main") {
      score += 3;
    }

    // Feedback & Affinity influence
    if (params.likedActivities && params.likedActivities.includes(s.activity)) {
      score += 12;
    }

    if (params.recoveryOwed || params.lastFeel === "tooMuch") {
      if (s.intensity === "gentle") {
        score += 15;
      } else if (s.intensity === "dynamic") {
        score -= 20;
      }
    }

    if (score > bestScore) {
      bestScore = score;
      best = s;
    }
  }

  return best;
}
