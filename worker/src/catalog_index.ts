// Auto-generated catalog index from FeelGood/Content/catalog.json
// DO NOT EDIT DIRECTLY. Run 'npm run sync:catalog' to regenerate.

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

export interface CatalogGlossaryItem {
  id: string;
  name: string;
  aka?: string[];
  instructions: string[];
  muscles: string[];
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
    "subtitle": "Short, bouncy, and over before you know it",
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
    "id": "app-loaded-carry-anything",
    "title": "Carry whatever's heavy",
    "subtitle": "Two water jugs, a laundry basket, a stack of books",
    "durationMin": 3,
    "intensity": "moderate",
    "course": "appetizer",
    "activity": "carries",
    "places": [
      "home"
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
    "id": "app-farmers-carry",
    "title": "Farmer's carry",
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
    "title": "Five minutes of qigong",
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
    "title": "Twenty minutes of qigong",
    "subtitle": "Standing, slow, and quietly settling",
    "durationMin": 20,
    "intensity": "moderate",
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
    "intensity": "moderate",
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
    "intensity": "moderate",
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
    "intensity": "moderate",
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
    "id": "dessert-three-songs",
    "title": "Dance to three songs",
    "subtitle": "That's it. That's the session.",
    "durationMin": 10,
    "intensity": "moderate",
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
    "intensity": "moderate",
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
    "intensity": "moderate",
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
    "subtitle": "Slow, gentle unwinding",
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
    "id": "app-desk-chair-squats",
    "title": "Desk chair squat breaks",
    "subtitle": "Wake up sleepy glutes and hips right at your office chair",
    "durationMin": 3,
    "intensity": "moderate",
    "course": "appetizer",
    "activity": "strength",
    "places": [
      "home",
      "gym"
    ],
    "bodyFocus": [
      "lowerBody",
      "hips"
    ],
    "intents": [
      "mobilize",
      "energize"
    ],
    "equipment": [
      "none"
    ]
  },
  {
    "id": "app-desk-hip-glute-reset",
    "title": "Hip flexor & glute reset",
    "subtitle": "Open up the front of your hips and your lower back after hours of sitting",
    "durationMin": 4,
    "intensity": "gentle",
    "course": "appetizer",
    "activity": "stretching",
    "places": [
      "home",
      "gym"
    ],
    "bodyFocus": [
      "hips",
      "back",
      "lowerBody"
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
    "id": "main-desk-worker-posture-flow",
    "title": "All-day desk worker reset",
    "subtitle": "Fifteen minutes for after a long sit: deep squat holds, wall angels, thoracic openers, and lunge pulses",
    "durationMin": 15,
    "intensity": "moderate",
    "course": "main",
    "activity": "stretching",
    "places": [
      "home",
      "gym"
    ],
    "bodyFocus": [
      "full",
      "back",
      "hips",
      "neckShoulders"
    ],
    "intents": [
      "mobilize",
      "strengthen",
      "energize"
    ],
    "equipment": [
      "none"
    ]
  },
  {
    "id": "side-desk-micro-squats",
    "title": "Coffee break counter squats",
    "subtitle": "Turn waiting for the kettle or microwave into a few easy squats",
    "durationMin": 2,
    "intensity": "moderate",
    "course": "side",
    "activity": "strength",
    "places": [
      "home",
      "gym"
    ],
    "bodyFocus": [
      "lowerBody"
    ],
    "intents": [
      "energize",
      "play"
    ],
    "equipment": [
      "none"
    ]
  },
  {
    "id": "app-single-song-dance",
    "title": "The single-song dance party",
    "subtitle": "Blast your favorite track and dance completely uninhibited for 3 minutes",
    "durationMin": 3,
    "intensity": "moderate",
    "course": "appetizer",
    "activity": "dance",
    "places": [
      "home"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "joy",
      "play",
      "energize"
    ],
    "equipment": [
      "none"
    ]
  },
  {
    "id": "app-sunlight-strut",
    "title": "Sunlight strut",
    "subtitle": "Step outside barefoot onto the grass or porch for a 5-minute deep-breathing session",
    "durationMin": 5,
    "intensity": "gentle",
    "course": "appetizer",
    "activity": "walking",
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
    "id": "app-desk-escape-stretch",
    "title": "Desk escape stretch",
    "subtitle": "Quick neck, shoulder, and wrist stretches",
    "durationMin": 5,
    "intensity": "gentle",
    "course": "appetizer",
    "activity": "stretching",
    "places": [
      "home",
      "gym"
    ],
    "bodyFocus": [
      "neckShoulders",
      "upperBody"
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
    "id": "app-power-explosions",
    "title": "Power explosions",
    "subtitle": "Fast jumping jacks or bodyweight squats to wake yourself up",
    "durationMin": 3,
    "intensity": "moderate",
    "course": "appetizer",
    "activity": "strength",
    "places": [
      "home",
      "gym",
      "outdoors"
    ],
    "bodyFocus": [
      "full",
      "lowerBody"
    ],
    "intents": [
      "energize",
      "play"
    ],
    "equipment": [
      "none"
    ]
  },
  {
    "id": "side-active-posture-shift",
    "title": "Active posture shift",
    "subtitle": "Stand, pace, or sit on a ball for your next call",
    "durationMin": 20,
    "intensity": "gentle",
    "course": "side",
    "activity": "walking",
    "places": [
      "home"
    ],
    "bodyFocus": [
      "core",
      "lowerBody"
    ],
    "intents": [
      "mobilize",
      "energize"
    ],
    "equipment": [
      "none"
    ]
  },
  {
    "id": "main-discovery-walk",
    "title": "The discovery walk",
    "subtitle": "Map out a brand new neighborhood route or trail for a novelty boost",
    "durationMin": 25,
    "intensity": "moderate",
    "course": "main",
    "activity": "walking",
    "places": [
      "outdoors"
    ],
    "bodyFocus": [
      "full",
      "lowerBody"
    ],
    "intents": [
      "joy",
      "play",
      "energize"
    ],
    "equipment": [
      "outdoor"
    ]
  },
  {
    "id": "main-mindful-yoga-flow",
    "title": "Mindful yoga flow",
    "subtitle": "Unroll your mat for a structured 30-minute Vinyasa & deep Yin breathing session",
    "durationMin": 30,
    "intensity": "moderate",
    "course": "main",
    "activity": "yoga",
    "places": [
      "home",
      "studio"
    ],
    "bodyFocus": [
      "full",
      "hips",
      "back"
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
    "id": "main-sweat-investment",
    "title": "Full-body strength circuit",
    "subtitle": "30-minute targeted kettlebell circuit or high-intensity bodyweight strength",
    "durationMin": 30,
    "intensity": "dynamic",
    "course": "main",
    "activity": "strength",
    "places": [
      "home",
      "gym"
    ],
    "bodyFocus": [
      "full",
      "lowerBody",
      "core"
    ],
    "intents": [
      "strengthen",
      "energize"
    ],
    "equipment": [
      "weights",
      "mat"
    ]
  },
  {
    "id": "main-local-studio-session",
    "title": "Local studio session",
    "subtitle": "Book an intro movement class or group fitness session for community energy",
    "durationMin": 45,
    "intensity": "moderate",
    "course": "main",
    "activity": "dance",
    "places": [
      "studio"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "joy",
      "energize",
      "play"
    ],
    "equipment": [
      "none"
    ]
  },
  {
    "id": "des-guided-foam-rolling",
    "title": "Guided foam rolling",
    "subtitle": "Roll out sore muscles while catching up on a single 15-minute video",
    "durationMin": 15,
    "intensity": "gentle",
    "course": "dessert",
    "activity": "stretching",
    "places": [
      "home"
    ],
    "bodyFocus": [
      "lowerBody",
      "back",
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
    "id": "des-luxury-recovery-soak",
    "title": "Luxury recovery soak",
    "subtitle": "A hot bath after moving, lights down, nowhere to be",
    "durationMin": 20,
    "intensity": "gentle",
    "course": "dessert",
    "activity": "stretching",
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
    "id": "spec-nature-immersion",
    "title": "Nature immersion hike",
    "subtitle": "Hike a scenic trail or explore a provincial/national park for a mental reset",
    "durationMin": 90,
    "intensity": "moderate",
    "course": "special",
    "activity": "walking",
    "places": [
      "outdoors"
    ],
    "bodyFocus": [
      "full",
      "lowerBody"
    ],
    "intents": [
      "calm",
      "joy",
      "energize"
    ],
    "equipment": [
      "outdoor"
    ]
  },
  {
    "id": "spec-spa-sauna-cycles",
    "title": "Spa & sauna thermal cycles",
    "subtitle": "Sauna, a cool plunge or rinse, and a long lie-down",
    "durationMin": 60,
    "intensity": "gentle",
    "course": "special",
    "activity": "stretching",
    "places": [
      "studio"
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
    "id": "spec-performance-coaching",
    "title": "1-on-1 coaching session",
    "subtitle": "A session with a trainer, built around what you want to work on",
    "durationMin": 60,
    "intensity": "moderate",
    "course": "special",
    "activity": "strength",
    "places": [
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
      "gym"
    ]
  },
  {
    "id": "app-shake-out-five",
    "title": "Five-minute shake-out",
    "subtitle": "Shake out your arms, your legs, and everything else",
    "durationMin": 5,
    "intensity": "gentle",
    "course": "appetizer",
    "activity": "agility",
    "places": [
      "home",
      "outdoors",
      "gym"
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
    "id": "app-power-pose-two",
    "title": "Two-minute power pose",
    "subtitle": "Stand tall, open your chest, and take up some space",
    "durationMin": 2,
    "intensity": "gentle",
    "course": "appetizer",
    "activity": "stretching",
    "places": [
      "home",
      "outdoors",
      "gym"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "energize",
      "calm"
    ],
    "equipment": [
      "none"
    ]
  },
  {
    "id": "main-brisk-walk-ten",
    "title": "Ten-minute brisk walk",
    "subtitle": "A quick lap at a brisk pace",
    "durationMin": 10,
    "intensity": "moderate",
    "course": "main",
    "activity": "walking",
    "places": [
      "home",
      "outdoors"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "energize",
      "mobilize"
    ],
    "equipment": [
      "none"
    ]
  },
  {
    "id": "main-qigong-12",
    "title": "Twelve minutes of qigong",
    "subtitle": "Standing, slow, and short enough for a busy day",
    "durationMin": 12,
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
    "id": "main-dance-10",
    "title": "Ten-minute dance break",
    "subtitle": "One song's worth of moving however you like",
    "durationMin": 10,
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
    "id": "main-standing-mobility-12",
    "title": "Twelve-minute standing mobility",
    "subtitle": "No mat, no floor — loosening up from your shoulders down",
    "durationMin": 12,
    "intensity": "gentle",
    "course": "main",
    "activity": "stretching",
    "places": [
      "home",
      "outdoors"
    ],
    "bodyFocus": [
      "full",
      "hips",
      "back",
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
    "id": "main-standing-strength-12",
    "title": "Twelve-minute standing strength",
    "subtitle": "Squats, lunges, and wall push-ups. No equipment, no floor",
    "durationMin": 12,
    "intensity": "moderate",
    "course": "main",
    "activity": "strength",
    "places": [
      "home"
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
    "id": "side-dance-it-out-five",
    "title": "Five-minute dance it out",
    "subtitle": "Put on your favorite track and let your body move freely",
    "durationMin": 5,
    "intensity": "moderate",
    "course": "side",
    "activity": "dance",
    "places": [
      "home"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "joy",
      "energize",
      "play"
    ],
    "equipment": [
      "none"
    ]
  },
  {
    "id": "dessert-pmr-ten",
    "title": "Progressive muscle relaxation",
    "subtitle": "Systematically tense and release from toes to crown to unwind deeply",
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
      "none",
      "mat"
    ]
  },
  {
    "id": "app-cold-water-splash",
    "title": "Cold water splash reset",
    "subtitle": "Cold water on your face, then one long, slow breath out",
    "durationMin": 1,
    "intensity": "gentle",
    "course": "appetizer",
    "activity": "breathwork",
    "places": [
      "home",
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
    "id": "side-stretch-and-breathe",
    "title": "Stretch and breathe",
    "subtitle": "Five gentle physical resets for when you have been sitting too long",
    "durationMin": 5,
    "intensity": "gentle",
    "course": "side",
    "activity": "stretching",
    "places": [
      "home",
      "gym"
    ],
    "bodyFocus": [
      "neckShoulders",
      "back"
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
    "id": "dessert-gratitude-scan-five",
    "title": "Gratitude body scan",
    "subtitle": "Five peaceful minutes appreciating everything your body carried today",
    "durationMin": 5,
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
      "joy"
    ],
    "equipment": [
      "none",
      "mat"
    ]
  },
  {
    "id": "app-jumping-jacks-two",
    "title": "Two-minute jumping jacks burst",
    "subtitle": "Quick cardio intervals to break through inertia and kickstart motivation",
    "durationMin": 2,
    "intensity": "moderate",
    "course": "appetizer",
    "activity": "agility",
    "places": [
      "home",
      "gym",
      "outdoors"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "energize",
      "play"
    ],
    "equipment": [
      "none"
    ]
  },
  {
    "id": "app-rest-box-breathing",
    "title": "Box breathing & unwind",
    "subtitle": "Untimed, anywhere, eyes open or closed",
    "durationMin": 0,
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
    "id": "main-rest-legs-up-the-wall",
    "title": "Legs up the wall & release",
    "subtitle": "Lie back, legs up, and let everything go quiet",
    "durationMin": 0,
    "intensity": "gentle",
    "course": "main",
    "activity": "stretching",
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
    "id": "side-standing-arms-five",
    "title": "Five minutes of standing arms",
    "subtitle": "Wall push-ups and chair dips. No floor, no equipment",
    "durationMin": 5,
    "intensity": "moderate",
    "course": "side",
    "activity": "strength",
    "places": [
      "home",
      "gym"
    ],
    "bodyFocus": [
      "upperBody"
    ],
    "intents": [
      "strengthen",
      "energize"
    ],
    "equipment": [
      "none"
    ]
  },
  {
    "id": "main-arms-shoulders-ten",
    "title": "Ten minutes of arms and shoulders",
    "subtitle": "Incline push-ups, dips, and plank taps. Just you and a chair",
    "durationMin": 10,
    "intensity": "moderate",
    "course": "main",
    "activity": "strength",
    "places": [
      "home",
      "gym"
    ],
    "bodyFocus": [
      "upperBody"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "none"
    ]
  },
  {
    "id": "main-push-ups-planks-fifteen",
    "title": "Fifteen minutes of push-ups and planks",
    "subtitle": "A push-up progression with planks and a slow core finish",
    "durationMin": 15,
    "intensity": "dynamic",
    "course": "main",
    "activity": "strength",
    "places": [
      "home",
      "gym"
    ],
    "bodyFocus": [
      "upperBody",
      "core"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "none"
    ]
  },
  {
    "id": "main-low-impact-circuit-ten",
    "title": "Ten minutes of low-impact circuit",
    "subtitle": "Two rounds of four easy moves. No jumping, no equipment",
    "durationMin": 10,
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
      "energize",
      "strengthen"
    ],
    "equipment": [
      "none"
    ]
  },
  {
    "id": "side-standing-core-five",
    "title": "Five minutes of standing core",
    "subtitle": "Twists, knee lifts, and side reaches. All on your feet",
    "durationMin": 5,
    "intensity": "moderate",
    "course": "side",
    "activity": "strength",
    "places": [
      "home",
      "gym"
    ],
    "bodyFocus": [
      "core"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "none"
    ]
  },
  {
    "id": "main-morning-mobility-ten",
    "title": "Ten minutes of morning mobility",
    "subtitle": "Ten easy moves to start the day. Floor, no equipment",
    "durationMin": 10,
    "intensity": "moderate",
    "course": "main",
    "activity": "stretching",
    "places": [
      "home",
      "gym"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "mobilize"
    ],
    "equipment": [
      "none"
    ]
  },
  {
    "id": "app-sitting-day-mobility-three",
    "title": "Three moves after a long sit",
    "subtitle": "Hips, spine and chest. Three minutes, no equipment",
    "durationMin": 3,
    "intensity": "gentle",
    "course": "appetizer",
    "activity": "stretching",
    "places": [
      "home",
      "gym"
    ],
    "bodyFocus": [
      "hips",
      "back"
    ],
    "intents": [
      "mobilize"
    ],
    "equipment": [
      "none"
    ]
  },
  {
    "id": "main-full-body-stretch-ten",
    "title": "Ten minutes of full-body stretches",
    "subtitle": "A run through the whole body, top to bottom",
    "durationMin": 10,
    "intensity": "gentle",
    "course": "main",
    "activity": "stretching",
    "places": [
      "home",
      "gym"
    ],
    "bodyFocus": [
      "full"
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
    "id": "side-ankle-mobility-five",
    "title": "Five minutes of ankle mobility",
    "subtitle": "Circles, calf work and a wall stretch",
    "durationMin": 5,
    "intensity": "gentle",
    "course": "side",
    "activity": "stretching",
    "places": [
      "home",
      "gym"
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
    "id": "side-arm-hand-glides-three",
    "title": "Three minutes of arm and hand glides",
    "subtitle": "Slow, easy wrist, forearm and neck moves",
    "durationMin": 3,
    "intensity": "gentle",
    "course": "side",
    "activity": "stretching",
    "places": [
      "home",
      "gym"
    ],
    "bodyFocus": [
      "upperBody",
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
    "id": "main-sixty-seconds-mobility-ten",
    "title": "Ten minutes, sixty seconds each",
    "subtitle": "Ten mobility moves, one minute apiece. Follow the timer",
    "durationMin": 10,
    "intensity": "moderate",
    "course": "main",
    "activity": "stretching",
    "places": [
      "home",
      "gym"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "mobilize"
    ],
    "equipment": [
      "none"
    ]
  },
  {
    "id": "main-morning-energy-twelve",
    "title": "Twelve-minute morning energy",
    "subtitle": "Twelve easy, bouncy moves, one minute each",
    "durationMin": 12,
    "intensity": "moderate",
    "course": "main",
    "activity": "agility",
    "places": [
      "home",
      "gym"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "energize",
      "play"
    ],
    "equipment": [
      "none"
    ]
  },
  {
    "id": "side-gentle-reset-five",
    "title": "Five-minute gentle movement reset",
    "subtitle": "Bounces, rag doll and reaches. Easy and rhythmic",
    "durationMin": 5,
    "intensity": "gentle",
    "course": "side",
    "activity": "stretching",
    "places": [
      "home",
      "gym"
    ],
    "bodyFocus": [
      "full"
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
    "id": "side-morning-floor-five",
    "title": "Five minutes of morning floor moves",
    "subtitle": "Knees to chest, twists, cat-cow and marching",
    "durationMin": 5,
    "intensity": "gentle",
    "course": "side",
    "activity": "stretching",
    "places": [
      "home",
      "gym"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "mobilize"
    ],
    "equipment": [
      "none"
    ]
  },
  {
    "id": "side-core-control-five",
    "title": "Five minutes of core control",
    "subtitle": "Slow, precise core work on the floor",
    "durationMin": 5,
    "intensity": "moderate",
    "course": "side",
    "activity": "strength",
    "places": [
      "home",
      "gym"
    ],
    "bodyFocus": [
      "core"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "none"
    ]
  },
  {
    "id": "side-gentle-core-five",
    "title": "Five minutes of gentle core",
    "subtitle": "Pelvic tilts, bridges and slow breathing",
    "durationMin": 5,
    "intensity": "gentle",
    "course": "side",
    "activity": "strength",
    "places": [
      "home",
      "gym"
    ],
    "bodyFocus": [
      "core"
    ],
    "intents": [
      "strengthen",
      "calm"
    ],
    "equipment": [
      "none"
    ]
  },
  {
    "id": "main-core-mat-twenty",
    "title": "Twenty-minute core mat workout",
    "subtitle": "Pilates-style mat work with an upbeat pace",
    "durationMin": 20,
    "intensity": "moderate",
    "course": "main",
    "activity": "pilates",
    "places": [
      "home",
      "gym"
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
    "id": "side-ab-circuit-eight",
    "title": "Eight minutes of ab circuit",
    "subtitle": "Four floor moves, two rounds",
    "durationMin": 8,
    "intensity": "moderate",
    "course": "side",
    "activity": "strength",
    "places": [
      "home",
      "gym"
    ],
    "bodyFocus": [
      "core"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "none"
    ]
  },
  {
    "id": "main-beginner-calisthenics-fifteen",
    "title": "Fifteen minutes of beginner calisthenics",
    "subtitle": "Bodyweight strength on the floor. Take breaks as you need",
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
      "none"
    ]
  },
  {
    "id": "side-triceps-five",
    "title": "Five minutes of triceps",
    "subtitle": "Chair dips and close push-ups",
    "durationMin": 5,
    "intensity": "moderate",
    "course": "side",
    "activity": "strength",
    "places": [
      "home",
      "gym"
    ],
    "bodyFocus": [
      "upperBody"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "none"
    ]
  },
  {
    "id": "main-shoulders-core-thirty",
    "title": "Thirty minutes of shoulders and core",
    "subtitle": "A longer bodyweight session. Rests are built in",
    "durationMin": 30,
    "intensity": "moderate",
    "course": "main",
    "activity": "strength",
    "places": [
      "home",
      "gym"
    ],
    "bodyFocus": [
      "upperBody",
      "core"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "none"
    ]
  },
  {
    "id": "main-dumbbell-chest-shoulders-ten",
    "title": "Ten minutes of dumbbell chest and shoulders",
    "subtitle": "Four moves, a pair of dumbbells, a floor",
    "durationMin": 10,
    "intensity": "moderate",
    "course": "main",
    "activity": "strength",
    "places": [
      "home",
      "gym"
    ],
    "bodyFocus": [
      "upperBody"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "weights"
    ]
  },
  {
    "id": "main-bed-yoga-ten",
    "title": "Ten minutes of yoga in bed",
    "subtitle": "Start where you are. Slow moves, no mat needed",
    "durationMin": 10,
    "intensity": "gentle",
    "course": "main",
    "activity": "yoga",
    "places": [
      "home",
      "gym"
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
    "id": "main-gentle-yoga-five-poses",
    "title": "Five gentle yoga poses",
    "subtitle": "A slow sequence, five poses, no rush",
    "durationMin": 10,
    "intensity": "gentle",
    "course": "main",
    "activity": "yoga",
    "places": [
      "home",
      "gym"
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
    "id": "app-two-minute-breath-pause",
    "title": "Two-minute breathing pause",
    "subtitle": "Slow breathing, seated, anywhere",
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
    "id": "app-craving-free-pause-two",
    "title": "Two-minute reset pause",
    "subtitle": "Stand, stretch and breathe. A short break from what you were doing",
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
      "calm",
      "energize"
    ],
    "equipment": [
      "none"
    ]
  },
  {
    "id": "app-pilates-breath-pelvic-three",
    "title": "Three minutes of Pilates breathing",
    "subtitle": "Ribs, breath and pelvic tilts on the mat",
    "durationMin": 3,
    "intensity": "gentle",
    "course": "appetizer",
    "activity": "pilates",
    "places": [
      "home",
      "gym"
    ],
    "bodyFocus": [
      "core"
    ],
    "intents": [
      "calm",
      "strengthen"
    ],
    "equipment": [
      "mat"
    ]
  },
  {
    "id": "side-pilates-hundred-five",
    "title": "Five minutes of Pilates warm-up",
    "subtitle": "Breath, tilts and the Hundred, head down or lifted",
    "durationMin": 5,
    "intensity": "moderate",
    "course": "side",
    "activity": "pilates",
    "places": [
      "home",
      "gym"
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
    "id": "side-pilates-back-extension-five",
    "title": "Five minutes of back extension",
    "subtitle": "Swan prep, swimming and superman on your front",
    "durationMin": 5,
    "intensity": "moderate",
    "course": "side",
    "activity": "pilates",
    "places": [
      "home",
      "gym"
    ],
    "bodyFocus": [
      "back"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "mat"
    ]
  },
  {
    "id": "side-pilates-side-lying-five",
    "title": "Five minutes of side-lying work",
    "subtitle": "Side kicks and clamshells. Hips and glutes",
    "durationMin": 5,
    "intensity": "moderate",
    "course": "side",
    "activity": "pilates",
    "places": [
      "home",
      "gym"
    ],
    "bodyFocus": [
      "hips",
      "lowerBody"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "mat"
    ]
  },
  {
    "id": "main-pilates-head-down-fifteen",
    "title": "Fifteen minutes of mat, head down",
    "subtitle": "A full mat session with no forward-flexion. Head stays on the floor",
    "durationMin": 15,
    "intensity": "moderate",
    "course": "main",
    "activity": "pilates",
    "places": [
      "home",
      "gym"
    ],
    "bodyFocus": [
      "core",
      "hips"
    ],
    "intents": [
      "strengthen",
      "calm"
    ],
    "equipment": [
      "mat"
    ]
  },
  {
    "id": "main-pilates-classic-fifteen",
    "title": "Fifteen minutes of classic mat",
    "subtitle": "Hundred, roll-up, circles, rolling and stretches",
    "durationMin": 15,
    "intensity": "moderate",
    "course": "main",
    "activity": "pilates",
    "places": [
      "home",
      "gym"
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
    "id": "main-pilates-legs-glutes-twenty",
    "title": "Twenty minutes of legs and glutes",
    "subtitle": "Bridges and side-lying work on the mat",
    "durationMin": 20,
    "intensity": "moderate",
    "course": "main",
    "activity": "pilates",
    "places": [
      "home",
      "gym"
    ],
    "bodyFocus": [
      "lowerBody",
      "hips"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "mat"
    ]
  },
  {
    "id": "main-pilates-standing-ten",
    "title": "Ten minutes of standing Pilates",
    "subtitle": "No mat, no floor. Roll-downs, leg lifts and arm work",
    "durationMin": 10,
    "intensity": "moderate",
    "course": "main",
    "activity": "pilates",
    "places": [
      "home",
      "gym"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "strengthen",
      "mobilize"
    ],
    "equipment": [
      "none"
    ]
  },
  {
    "id": "dessert-pilates-stretch-ten",
    "title": "Ten minutes of Pilates cool-down",
    "subtitle": "Slow spine work and stretches to finish",
    "durationMin": 10,
    "intensity": "gentle",
    "course": "dessert",
    "activity": "pilates",
    "places": [
      "home",
      "gym"
    ],
    "bodyFocus": [
      "back",
      "hips"
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
    "id": "main-run-walk-twenty",
    "title": "Run, walk, repeat",
    "subtitle": "Short runs with walking in between",
    "durationMin": 20,
    "intensity": "moderate",
    "course": "main",
    "activity": "running",
    "places": [
      "outdoors"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "energize"
    ],
    "equipment": [
      "outdoor"
    ]
  },
  {
    "id": "main-easy-run-twenty",
    "title": "An easy twenty-minute run",
    "subtitle": "Outside, at a pace you could chat at",
    "durationMin": 20,
    "intensity": "moderate",
    "course": "main",
    "activity": "running",
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
    "id": "main-steady-run-thirty",
    "title": "A thirty-minute steady run",
    "subtitle": "A longer run with room to settle in",
    "durationMin": 30,
    "intensity": "dynamic",
    "course": "main",
    "activity": "running",
    "places": [
      "outdoors"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "energize"
    ],
    "equipment": [
      "outdoor"
    ]
  },
  {
    "id": "side-ten-minute-jog",
    "title": "A ten-minute jog",
    "subtitle": "Around the block and back",
    "durationMin": 10,
    "intensity": "moderate",
    "course": "side",
    "activity": "running",
    "places": [
      "outdoors"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "energize"
    ],
    "equipment": [
      "outdoor"
    ]
  }
];

export const CATALOG_GLOSSARY: CatalogGlossaryItem[] = [
  {
    "id": "dead-bug",
    "name": "Dead bug",
    "aka": [
      "supine march"
    ],
    "instructions": [
      "Lie on your back with your knees bent over your hips and your arms reaching to the ceiling.",
      "Press your lower back gently into the floor and keep it there the whole time.",
      "Lower one arm behind you and straighten the opposite leg toward the floor.",
      "Only go as far as you can while your back stays down. Return and switch sides."
    ],
    "muscles": [
      "deep core",
      "front of the hips"
    ]
  },
  {
    "id": "glute-bridge",
    "name": "Bridge",
    "aka": [
      "glute bridge",
      "hip bridge"
    ],
    "instructions": [
      "Lie on your back, knees bent, feet flat and hip width apart.",
      "Press through your heels and lift your hips, peeling your spine off the floor one bit at a time.",
      "Pause at the top without arching your lower back.",
      "Lower slowly, the same way you came up."
    ],
    "muscles": [
      "glutes",
      "hamstrings",
      "back of the thighs"
    ]
  },
  {
    "id": "the-hundred",
    "name": "The hundred",
    "aka": [],
    "instructions": [
      "Lie on your back with your knees bent over your hips.",
      "Lift your head and shoulders if that's comfortable, and reach your arms long by your sides.",
      "Pump your arms up and down in small movements.",
      "Breathe in for five pumps and out for five pumps, ten times."
    ],
    "muscles": [
      "deep core",
      "front of the abdomen"
    ]
  },
  {
    "id": "single-leg-stretch",
    "name": "Single leg stretch",
    "aka": [],
    "instructions": [
      "Lie on your back and draw one knee toward your chest.",
      "Extend the other leg away at whatever height keeps your lower back heavy on the floor.",
      "Switch legs smoothly, as if pedalling slowly.",
      "Keep your shoulders relaxed away from your ears."
    ],
    "muscles": [
      "deep core",
      "front of the hips"
    ]
  },
  {
    "id": "side-plank",
    "name": "Side plank",
    "aka": [],
    "instructions": [
      "Lie on your side, propped on your forearm with your elbow under your shoulder.",
      "Stack your feet, or drop the bottom knee to the floor for a version that is just as good.",
      "Lift your hips so your body makes one long line.",
      "Hold, breathing normally, then lower with control."
    ],
    "muscles": [
      "side of the waist",
      "shoulders"
    ]
  },
  {
    "id": "plank",
    "name": "Plank",
    "aka": [
      "front support"
    ],
    "instructions": [
      "Set your forearms or hands under your shoulders and step your feet back.",
      "Make one long line from your head to your heels, with your hips neither high nor sagging.",
      "Knees down is a full version, not a lesser one.",
      "Hold while you can breathe steadily, then rest."
    ],
    "muscles": [
      "deep core",
      "shoulders",
      "glutes"
    ]
  },
  {
    "id": "pelvic-tilt",
    "name": "Pelvic tilt",
    "aka": [],
    "instructions": [
      "Lie on your back with your knees bent and feet flat.",
      "Gently tilt your pelvis so your lower back flattens toward the floor.",
      "Then tilt the other way so a small arch appears.",
      "Rock slowly between the two. The movement is small."
    ],
    "muscles": [
      "deep core",
      "lower back"
    ]
  },
  {
    "id": "goblet-squat",
    "name": "Goblet squat",
    "aka": [],
    "instructions": [
      "Hold one weight against your chest with both hands.",
      "Stand with your feet a little wider than your hips, toes turned out slightly.",
      "Sit your hips down and back, keeping your chest tall.",
      "Press through the whole foot to stand up."
    ],
    "muscles": [
      "thighs",
      "glutes",
      "deep core"
    ]
  },
  {
    "id": "romanian-deadlift",
    "name": "Deadlift",
    "aka": [
      "Romanian deadlift",
      "hip hinge"
    ],
    "instructions": [
      "Stand holding weights in front of your thighs, knees softly bent.",
      "Push your hips backward and let the weights travel close down your legs.",
      "Stop when you feel a strong stretch at the back of your thighs.",
      "Drive your hips forward to stand tall again."
    ],
    "muscles": [
      "back of the thighs",
      "glutes",
      "back"
    ]
  },
  {
    "id": "bent-over-row",
    "name": "Row",
    "aka": [
      "bent-over row"
    ],
    "instructions": [
      "Hinge forward from the hips with a long back and soft knees.",
      "Let the weights hang below your shoulders.",
      "Pull your elbows back past your ribs, leading with the elbows rather than the hands.",
      "Lower slowly and repeat."
    ],
    "muscles": [
      "upper back",
      "back of the shoulders",
      "grip"
    ]
  },
  {
    "id": "overhead-press",
    "name": "Overhead press",
    "aka": [
      "shoulder press"
    ],
    "instructions": [
      "Hold the weights at shoulder height with your elbows under your wrists.",
      "Keep your ribs down so you don't arch your lower back.",
      "Press straight up until your arms are long.",
      "Lower under control to the start."
    ],
    "muscles": [
      "shoulders",
      "upper back",
      "deep core"
    ]
  },
  {
    "id": "farmers-carry",
    "name": "Carry",
    "aka": [
      "farmer's carry",
      "suitcase carry"
    ],
    "instructions": [
      "Pick up something heavy in each hand.",
      "Stand tall with your shoulders back and your ribs down.",
      "Walk slowly and evenly, breathing normally.",
      "Put the weight down before your grip gives out, not after."
    ],
    "muscles": [
      "grip",
      "shoulders",
      "deep core"
    ]
  },
  {
    "id": "jump-rope",
    "name": "Jump rope",
    "aka": [
      "skipping"
    ],
    "instructions": [
      "Stay on the balls of your feet with soft knees.",
      "Jump only just high enough to clear the rope.",
      "Keep your elbows close to your sides and turn the rope with your wrists.",
      "Without a rope, the same small bounce still counts."
    ],
    "muscles": [
      "calves",
      "ankles",
      "shoulders"
    ]
  },
  {
    "id": "single-leg-stand",
    "name": "Single leg stand",
    "aka": [
      "one-leg balance"
    ],
    "instructions": [
      "Stand on one foot with a soft knee.",
      "Fix your eyes on something still.",
      "Hold nearby support with a fingertip if you need to.",
      "Wobbling is the work, not a failure."
    ],
    "muscles": [
      "ankles",
      "hips",
      "deep core"
    ]
  },
  {
    "id": "cat-cow",
    "name": "Cat cow",
    "aka": [],
    "instructions": [
      "On hands and knees, wrists under shoulders and knees under hips.",
      "Breathe in and let your belly soften as your chest lifts.",
      "Breathe out and round your back toward the ceiling.",
      "Move with your breath rather than counting."
    ],
    "muscles": [
      "spine",
      "deep core"
    ]
  },
  {
    "id": "childs-pose",
    "name": "Child's pose",
    "aka": [],
    "instructions": [
      "Kneel and sit your hips back toward your heels.",
      "Take your knees as wide as is comfortable and reach your arms forward.",
      "Rest your forehead on the floor, a cushion or your hands.",
      "Stay for as many breaths as you like."
    ],
    "muscles": [
      "lower back",
      "hips",
      "shoulders"
    ]
  },
  {
    "id": "low-lunge",
    "name": "Low lunge",
    "aka": [],
    "instructions": [
      "Step one foot forward and lower the back knee to the floor.",
      "Bring your front knee over your ankle and let your hips sink forward.",
      "Lift your chest and breathe into the front of the back thigh.",
      "Pad the back knee with a folded towel if it's tender."
    ],
    "muscles": [
      "front of the hips",
      "thighs"
    ]
  },
  {
    "id": "figure-four-stretch",
    "name": "Figure four",
    "aka": [
      "reclined pigeon"
    ],
    "instructions": [
      "Lie on your back with both knees bent.",
      "Cross one ankle over the opposite thigh, just above the knee.",
      "Reach through and draw the supporting leg toward you.",
      "Keep your head and shoulders resting on the floor."
    ],
    "muscles": [
      "glutes",
      "outer hips"
    ]
  },
  {
    "id": "supine-hamstring-stretch",
    "name": "Hamstring stretch",
    "aka": [],
    "instructions": [
      "Lie on your back and lift one leg toward the ceiling.",
      "Loop a strap, towel or your hands around the back of that thigh.",
      "Straighten the leg only as far as it stays comfortable.",
      "Keep the other leg bent with the foot on the floor if your back prefers it."
    ],
    "muscles": [
      "back of the thighs",
      "calves"
    ]
  },
  {
    "id": "calf-stretch",
    "name": "Calf stretch",
    "aka": [],
    "instructions": [
      "Stand facing a wall or counter with your hands on it.",
      "Step one foot back and press that heel toward the floor.",
      "Keep the back leg straight for the upper calf.",
      "Then bend that knee slightly for the lower calf and achilles."
    ],
    "muscles": [
      "calves",
      "ankles"
    ]
  },
  {
    "id": "neck-side-stretch",
    "name": "Neck side stretch",
    "aka": [],
    "instructions": [
      "Sit or stand tall with your shoulders relaxed.",
      "Take one ear gently toward the same shoulder.",
      "Let the opposite shoulder stay heavy rather than lifting.",
      "Breathe into the long side of your neck. Never force it."
    ],
    "muscles": [
      "sides of the neck",
      "tops of the shoulders"
    ]
  },
  {
    "id": "chin-tuck",
    "name": "Chin tuck",
    "aka": [],
    "instructions": [
      "Sit or stand tall and look straight ahead.",
      "Draw your chin gently backward, as if making a double chin.",
      "Hold for a breath and release.",
      "The movement is small and should never hurt."
    ],
    "muscles": [
      "deep neck muscles",
      "upper back"
    ]
  },
  {
    "id": "doorway-chest-stretch",
    "name": "Doorway chest stretch",
    "aka": [],
    "instructions": [
      "Place a forearm on a door frame with your elbow at shoulder height.",
      "Step forward slightly and turn your body away from that arm.",
      "Keep your ribs down and your shoulder relaxed.",
      "Breathe, then switch sides."
    ],
    "muscles": [
      "chest",
      "front of the shoulders"
    ]
  },
  {
    "id": "downward-dog",
    "name": "Downward-Facing Dog",
    "aka": [
      "downward dog",
      "down dog",
      "adho mukha svanasana"
    ],
    "instructions": [
      "Start on all fours with hands shoulder-width apart and knees under hips.",
      "Tuck your toes and press through your palms to lift your hips high.",
      "Lengthen your spine into an inverted V-shape, letting your neck relax.",
      "Reach your heels toward the floor and take steady, calming breaths."
    ],
    "muscles": [
      "hamstrings",
      "calves",
      "shoulders",
      "spine"
    ]
  },
  {
    "id": "thoracic-rotation",
    "name": "Book opener",
    "aka": [
      "thoracic rotation"
    ],
    "instructions": [
      "Lie on your side with your knees bent and stacked, arms reaching in front of you.",
      "Slide the top hand along the bottom one, then open it wide toward the floor behind you.",
      "Let your eyes follow your hand.",
      "Keep your knees stacked and stay where you can still breathe easily."
    ],
    "muscles": [
      "upper back",
      "chest"
    ]
  },
  {
    "id": "tree-pose",
    "name": "Tree pose",
    "aka": [],
    "instructions": [
      "Stand tall and shift your weight onto one foot.",
      "Rest the other foot on your ankle, calf or inner thigh, never on the knee.",
      "Find something still to look at.",
      "Hold a wall or chair for as long as it's useful."
    ],
    "muscles": [
      "ankles",
      "hips",
      "deep core"
    ]
  },
  {
    "id": "legs-up-the-wall",
    "name": "Legs up the wall",
    "aka": [],
    "instructions": [
      "Sit sideways next to a wall, then swing your legs up it as you lie down.",
      "Bring your hips as close to the wall as is comfortable.",
      "Rest your arms wide and let the floor take your weight.",
      "Come out slowly by bending your knees and rolling to one side."
    ],
    "muscles": [
      "lower back",
      "legs"
    ]
  },
  {
    "id": "forearm-stretch",
    "name": "Forearm stretch",
    "aka": [],
    "instructions": [
      "Extend one arm in front of you with the palm facing down.",
      "Use the other hand to gently draw the fingers toward you, then away.",
      "Hold each direction for a few slow breaths.",
      "Repeat on the other side."
    ],
    "muscles": [
      "forearms",
      "wrists"
    ]
  },
  {
    "id": "lat-pulldown",
    "name": "Lat pulldown",
    "aka": [
      "pulldown"
    ],
    "instructions": [
      "Sit facing the machine with your thighs under the pads and take a wide hold of the bar.",
      "Sit tall and pull the bar down towards your collarbone, leading with your elbows.",
      "Let your shoulder blades slide down as the bar comes towards you.",
      "Let the bar rise all the way back up under control before the next one."
    ],
    "muscles": [
      "sides of the back",
      "upper arms"
    ]
  },
  {
    "id": "seated-cable-row",
    "name": "Seated row",
    "aka": [
      "cable row"
    ],
    "instructions": [
      "Sit with your feet on the platform and your knees softly bent.",
      "Hold the handle with your arms straight and your back long.",
      "Pull the handle towards your ribs, letting your shoulder blades come together.",
      "Straighten your arms slowly and let your back stay long the whole time."
    ],
    "muscles": [
      "middle of the back",
      "back of the shoulders",
      "upper arms"
    ]
  },
  {
    "id": "leg-press",
    "name": "Leg press",
    "aka": [],
    "instructions": [
      "Sit back in the seat with your feet flat on the platform, about hip width apart.",
      "Push the platform away through your whole foot until your legs are nearly straight.",
      "Stop short of locking your knees.",
      "Bend your knees slowly to bring the platform back, keeping your lower back on the seat."
    ],
    "muscles": [
      "front of the thighs",
      "back of the thighs",
      "glutes"
    ]
  },
  {
    "id": "chest-press",
    "name": "Chest press",
    "aka": [
      "machine press"
    ],
    "instructions": [
      "Sit with your back against the pad and the handles roughly level with the middle of your chest.",
      "Set your elbows a little below shoulder height rather than straight out to the sides.",
      "Press the handles away until your arms are nearly straight.",
      "Let them come back slowly until you feel a gentle stretch across your chest."
    ],
    "muscles": [
      "chest",
      "front of the shoulders",
      "back of the upper arms"
    ]
  },
  {
    "id": "bodyweight-squat",
    "name": "Squat",
    "aka": [
      "air squat",
      "chair squat"
    ],
    "instructions": [
      "Stand with your feet about hip width apart, toes turned out a little.",
      "Send your hips back and down as if sitting into a chair behind you.",
      "Go as low as feels comfortable, keeping your heels on the floor and your chest lifted.",
      "Press through your whole foot to stand back up."
    ],
    "muscles": [
      "front of the thighs",
      "glutes",
      "deep core"
    ]
  },
  {
    "id": "calf-raise",
    "name": "Calf raise",
    "aka": [
      "heel raise"
    ],
    "instructions": [
      "Stand tall with your feet hip width apart, a hand on a wall or counter if you like.",
      "Rise up onto the balls of your feet, lifting your heels as high as they go.",
      "Pause at the top for a moment.",
      "Lower your heels slowly all the way down."
    ],
    "muscles": [
      "calves",
      "ankles"
    ]
  },
  {
    "id": "single-leg-calf-raise",
    "name": "Single leg calf raise",
    "aka": [],
    "instructions": [
      "Stand on one foot near a wall for balance, the other foot lifted behind you.",
      "Rise up onto the ball of your standing foot.",
      "Pause at the top, then lower with control.",
      "Do the same number on the other leg."
    ],
    "muscles": [
      "calves",
      "ankles"
    ]
  },
  {
    "id": "jumping-jack",
    "name": "Jumping jack",
    "aka": [
      "star jump"
    ],
    "instructions": [
      "Stand with your feet together and your arms by your sides.",
      "Jump your feet out wide while swinging your arms overhead.",
      "Jump back to the start in one movement.",
      "Keep a soft bend in your knees and land lightly. Step instead of jump if you prefer."
    ],
    "muscles": [
      "legs",
      "shoulders",
      "heart and lungs"
    ]
  },
  {
    "id": "high-knees",
    "name": "High knees",
    "aka": [],
    "instructions": [
      "Stand tall and start jogging on the spot.",
      "Drive each knee up toward hip height, swinging the opposite arm.",
      "Stay light on the balls of your feet.",
      "Go at whatever pace you can keep steady."
    ],
    "muscles": [
      "front of the hips",
      "front of the thighs",
      "heart and lungs"
    ]
  },
  {
    "id": "mountain-climber",
    "name": "Mountain climber",
    "aka": [],
    "instructions": [
      "Start in a high plank with your hands under your shoulders.",
      "Draw one knee in toward your chest, then switch legs.",
      "Keep your hips level with your shoulders, not lifted or sagging.",
      "Slow is fine. Speed up only if your hips stay steady."
    ],
    "muscles": [
      "deep core",
      "shoulders",
      "front of the hips"
    ]
  },
  {
    "id": "push-up",
    "name": "Push-up",
    "aka": [
      "press-up"
    ],
    "instructions": [
      "Start in a high plank with your hands slightly wider than your shoulders.",
      "Lower your chest toward the floor, elbows pointing back at an angle rather than straight out.",
      "Keep your body in one line from head to heels.",
      "Press the floor away to come back up."
    ],
    "muscles": [
      "chest",
      "front of the shoulders",
      "back of the upper arms",
      "deep core"
    ]
  },
  {
    "id": "knee-push-up",
    "name": "Knee push-up",
    "aka": [],
    "instructions": [
      "Start on your hands and knees, then walk your hands forward until your body is a straight line from head to knees.",
      "Lower your chest toward the floor with your elbows angled back.",
      "Keep your hips in line with your shoulders and knees.",
      "Press back up. This is a full push-up with less weight to move."
    ],
    "muscles": [
      "chest",
      "front of the shoulders",
      "back of the upper arms"
    ]
  },
  {
    "id": "incline-push-up",
    "name": "Incline push-up",
    "aka": [],
    "instructions": [
      "Place your hands on a bench, counter, or sturdy chair, shoulder width apart.",
      "Walk your feet back until your body is a straight line.",
      "Lower your chest toward the surface, elbows angled back.",
      "Press away to return. The higher the surface, the easier it is."
    ],
    "muscles": [
      "chest",
      "front of the shoulders",
      "back of the upper arms"
    ]
  },
  {
    "id": "wall-push-up",
    "name": "Wall push-up",
    "aka": [],
    "instructions": [
      "Stand an arm's length from a wall and place your palms on it at shoulder height.",
      "Bend your elbows and bring your chest toward the wall.",
      "Keep your body in one line from head to heels.",
      "Press back to the start."
    ],
    "muscles": [
      "chest",
      "front of the shoulders",
      "back of the upper arms"
    ]
  },
  {
    "id": "forward-lunge",
    "name": "Forward lunge",
    "aka": [],
    "instructions": [
      "Stand tall, then take a big step forward with one foot.",
      "Bend both knees so your back knee drops toward the floor.",
      "Keep your front knee over your ankle and your torso upright.",
      "Push off the front foot to return, then switch sides."
    ],
    "muscles": [
      "front of the thighs",
      "glutes",
      "back of the thighs"
    ]
  },
  {
    "id": "reverse-lunge",
    "name": "Reverse lunge",
    "aka": [],
    "instructions": [
      "Stand tall, then step one foot back behind you.",
      "Lower your back knee toward the floor, keeping your front shin upright.",
      "Keep your weight in your front heel.",
      "Push through the front foot to stand, then switch sides."
    ],
    "muscles": [
      "front of the thighs",
      "glutes",
      "back of the thighs"
    ]
  },
  {
    "id": "lateral-lunge",
    "name": "Side lunge",
    "aka": [
      "lateral lunge"
    ],
    "instructions": [
      "Stand with your feet wide apart, toes forward.",
      "Bend one knee and sit your hips back over that foot, keeping the other leg straight.",
      "Keep both feet flat and your chest lifted.",
      "Push back to the middle and switch sides."
    ],
    "muscles": [
      "inner thighs",
      "glutes",
      "front of the thighs"
    ]
  },
  {
    "id": "curtsy-lunge",
    "name": "Curtsy lunge",
    "aka": [],
    "instructions": [
      "Stand tall, then step one foot back and across behind the other, as if curtsying.",
      "Bend both knees and lower until the back knee hovers near the floor.",
      "Keep your hips facing forward.",
      "Push through the front foot to return, then switch sides."
    ],
    "muscles": [
      "glutes",
      "outer hips",
      "front of the thighs"
    ]
  },
  {
    "id": "walking-lunge",
    "name": "Walking lunge",
    "aka": [],
    "instructions": [
      "Step forward into a lunge, back knee dropping toward the floor.",
      "Push through the front foot and bring the back leg through into the next lunge.",
      "Keep your torso upright and your steps controlled.",
      "Continue forward, alternating legs."
    ],
    "muscles": [
      "front of the thighs",
      "glutes",
      "back of the thighs"
    ]
  },
  {
    "id": "wall-sit",
    "name": "Wall sit",
    "aka": [],
    "instructions": [
      "Lean your back against a wall and walk your feet out in front of you.",
      "Slide down until your knees are bent at roughly a right angle, or higher if you prefer.",
      "Keep your back flat against the wall and your knees over your ankles.",
      "Hold, breathing steadily, then push up to stand."
    ],
    "muscles": [
      "front of the thighs",
      "glutes"
    ]
  },
  {
    "id": "bird-dog",
    "name": "Bird dog",
    "aka": [],
    "instructions": [
      "Start on your hands and knees, wrists under shoulders and knees under hips.",
      "Reach one arm forward and the opposite leg back until both are level with your body.",
      "Keep your hips square and your back still.",
      "Return slowly and switch sides."
    ],
    "muscles": [
      "deep core",
      "lower back",
      "glutes"
    ]
  },
  {
    "id": "bear-plank",
    "name": "Bear plank",
    "aka": [
      "bear hold"
    ],
    "instructions": [
      "Start on your hands and knees with your knees under your hips.",
      "Tuck your toes and lift your knees a few centimetres off the floor.",
      "Keep your back flat and your hips level with your shoulders.",
      "Hold, breathing normally, then set your knees down."
    ],
    "muscles": [
      "deep core",
      "shoulders",
      "front of the thighs"
    ]
  },
  {
    "id": "plank-shoulder-tap",
    "name": "Plank shoulder tap",
    "aka": [],
    "instructions": [
      "Start in a high plank with your feet a little wider than usual.",
      "Lift one hand and tap the opposite shoulder.",
      "Keep your hips still, without rocking side to side.",
      "Set the hand down and switch."
    ],
    "muscles": [
      "deep core",
      "shoulders"
    ]
  },
  {
    "id": "side-plank-hip-dip",
    "name": "Side plank dips",
    "aka": [],
    "instructions": [
      "Set up in a side plank on your forearm, feet stacked or staggered.",
      "Lower your hip toward the floor without touching it.",
      "Lift back up to a straight line.",
      "Repeat, then switch sides."
    ],
    "muscles": [
      "side of the waist",
      "shoulders"
    ]
  },
  {
    "id": "crunch",
    "name": "Crunch",
    "aka": [],
    "instructions": [
      "Lie on your back with your knees bent and your feet flat.",
      "Rest your fingertips lightly behind your head or across your chest.",
      "Lift your head and shoulders a little off the floor, curling your ribs toward your hips.",
      "Lower slowly. Keep your neck relaxed the whole time."
    ],
    "muscles": [
      "front of the abdomen"
    ]
  },
  {
    "id": "reverse-crunch",
    "name": "Reverse crunch",
    "aka": [],
    "instructions": [
      "Lie on your back with your knees bent over your hips and your arms by your sides.",
      "Curl your knees toward your chest so your hips lift slightly off the floor.",
      "Move slowly rather than swinging.",
      "Lower your hips back down with control."
    ],
    "muscles": [
      "lower abdomen",
      "deep core"
    ]
  },
  {
    "id": "bicycle-crunch",
    "name": "Bicycle crunch",
    "aka": [],
    "instructions": [
      "Lie on your back with your hands lightly behind your head and your knees lifted.",
      "Bring one knee in as you rotate the opposite elbow toward it.",
      "Extend the other leg out long.",
      "Switch sides in a slow pedalling rhythm."
    ],
    "muscles": [
      "front of the abdomen",
      "sides of the waist"
    ]
  },
  {
    "id": "lying-leg-raise",
    "name": "Leg raise",
    "aka": [
      "lying leg raise"
    ],
    "instructions": [
      "Lie on your back with your legs straight and your hands under your hips if it helps.",
      "Press your lower back gently into the floor.",
      "Lift both legs toward the ceiling, keeping them as straight as is comfortable.",
      "Lower slowly, stopping before your back starts to arch."
    ],
    "muscles": [
      "lower abdomen",
      "front of the hips"
    ]
  },
  {
    "id": "heel-tap",
    "name": "Heel tap",
    "aka": [],
    "instructions": [
      "Lie on your back with your knees bent and your feet flat, arms by your sides.",
      "Lift your head and shoulders slightly.",
      "Reach one hand down to tap the heel on the same side, bending sideways at the waist.",
      "Come back to centre and reach to the other side."
    ],
    "muscles": [
      "sides of the waist",
      "front of the abdomen"
    ]
  },
  {
    "id": "flutter-kick",
    "name": "Flutter kick",
    "aka": [],
    "instructions": [
      "Lie on your back with your hands under your hips and your legs straight.",
      "Lift both legs a little way off the floor.",
      "Kick them up and down in small, quick movements.",
      "Keep your lower back pressed down. Stop when it starts to lift."
    ],
    "muscles": [
      "lower abdomen",
      "front of the hips"
    ]
  },
  {
    "id": "hollow-body-hold",
    "name": "Hollow hold",
    "aka": [
      "hollow body"
    ],
    "instructions": [
      "Lie on your back and press your lower back into the floor.",
      "Lift your shoulders and legs a little off the floor, arms reaching past your ears or by your sides.",
      "Keep your back flat. Bend your knees to make it easier.",
      "Hold, breathing steadily, then rest."
    ],
    "muscles": [
      "deep core",
      "front of the abdomen"
    ]
  },
  {
    "id": "superman",
    "name": "Superman",
    "aka": [
      "back lift"
    ],
    "instructions": [
      "Lie face down with your arms stretched out in front of you.",
      "Lift your arms, chest, and legs a little way off the floor at the same time.",
      "Keep your neck long by looking at the floor.",
      "Lower slowly and repeat."
    ],
    "muscles": [
      "lower back",
      "glutes",
      "upper back"
    ]
  },
  {
    "id": "superman-hold",
    "name": "Superman hold",
    "aka": [],
    "instructions": [
      "Lie face down with your arms stretched out in front of you.",
      "Lift your arms, chest, and legs off the floor together.",
      "Hold there, looking at the floor to keep your neck relaxed.",
      "Breathe steadily, then lower everything down."
    ],
    "muscles": [
      "lower back",
      "glutes",
      "upper back"
    ]
  },
  {
    "id": "clamshell",
    "name": "Clamshell",
    "aka": [],
    "instructions": [
      "Lie on your side with your knees bent and your feet together, hips stacked.",
      "Keeping your feet touching, lift your top knee toward the ceiling.",
      "Do not let your top hip roll backward.",
      "Lower slowly, then switch sides after your set."
    ],
    "muscles": [
      "outer hips",
      "glutes"
    ]
  },
  {
    "id": "fire-hydrant",
    "name": "Fire hydrant",
    "aka": [],
    "instructions": [
      "Start on your hands and knees, wrists under shoulders and knees under hips.",
      "Keeping the knee bent, lift one leg out to the side.",
      "Keep your hips level and your back still.",
      "Lower slowly. Switch sides after your set."
    ],
    "muscles": [
      "outer hips",
      "glutes"
    ]
  },
  {
    "id": "donkey-kick",
    "name": "Donkey kick",
    "aka": [],
    "instructions": [
      "Start on your hands and knees with your back flat.",
      "Keeping the knee bent, press one foot up toward the ceiling.",
      "Stop when your thigh is in line with your body, before your back arches.",
      "Lower with control. Switch sides after your set."
    ],
    "muscles": [
      "glutes",
      "back of the thighs"
    ]
  },
  {
    "id": "side-lying-leg-raise",
    "name": "Side-lying leg lift",
    "aka": [
      "side leg raise"
    ],
    "instructions": [
      "Lie on your side with your legs straight and stacked, head resting on your arm.",
      "Lift your top leg toward the ceiling, keeping it straight and your toes pointing forward.",
      "Keep your hips stacked rather than rolling back.",
      "Lower slowly. Switch sides after your set."
    ],
    "muscles": [
      "outer hips",
      "glutes"
    ]
  },
  {
    "id": "glute-bridge-march",
    "name": "Bridge march",
    "aka": [],
    "instructions": [
      "Lie on your back, knees bent, feet flat, and lift your hips into a bridge.",
      "Keeping your hips level, lift one foot a few centimetres off the floor.",
      "Set it down and lift the other.",
      "Move slowly. Your hips should not dip or tilt."
    ],
    "muscles": [
      "glutes",
      "deep core",
      "back of the thighs"
    ]
  },
  {
    "id": "single-leg-glute-bridge",
    "name": "Single leg bridge",
    "aka": [],
    "instructions": [
      "Lie on your back with one knee bent and foot flat, the other leg extended or lifted.",
      "Press through the planted heel and lift your hips.",
      "Keep your hips level at the top.",
      "Lower slowly. Switch sides after your set."
    ],
    "muscles": [
      "glutes",
      "back of the thighs",
      "deep core"
    ]
  },
  {
    "id": "frog-pump",
    "name": "Frog pump",
    "aka": [],
    "instructions": [
      "Lie on your back with the soles of your feet together and your knees dropped out to the sides.",
      "Keep your heels close to your hips.",
      "Press through the outer edges of your feet and lift your hips.",
      "Lower and repeat in a steady rhythm."
    ],
    "muscles": [
      "glutes"
    ]
  },
  {
    "id": "inchworm",
    "name": "Inchworm",
    "aka": [],
    "instructions": [
      "Stand tall, then fold forward and place your hands on the floor.",
      "Walk your hands out until you reach a high plank.",
      "Walk your feet toward your hands, keeping your legs as straight as is comfortable.",
      "Stand up and repeat."
    ],
    "muscles": [
      "back of the thighs",
      "shoulders",
      "deep core"
    ]
  },
  {
    "id": "bear-crawl",
    "name": "Bear crawl",
    "aka": [],
    "instructions": [
      "Start on your hands and knees, then lift your knees just off the floor.",
      "Step one hand and the opposite foot forward at the same time.",
      "Keep your hips low and your back flat.",
      "Crawl forward, then backward if you have room."
    ],
    "muscles": [
      "shoulders",
      "deep core",
      "front of the thighs"
    ]
  },
  {
    "id": "burpee",
    "name": "Burpee",
    "aka": [],
    "instructions": [
      "From standing, crouch and place your hands on the floor.",
      "Step or jump your feet back into a plank.",
      "Step or jump your feet back in toward your hands.",
      "Stand up, adding a jump at the top if you like."
    ],
    "muscles": [
      "legs",
      "chest",
      "deep core",
      "heart and lungs"
    ]
  },
  {
    "id": "jump-squat",
    "name": "Jump squat",
    "aka": [],
    "instructions": [
      "Stand with your feet hip width apart and lower into a squat.",
      "Push through your feet and jump straight up.",
      "Land softly with bent knees, straight back into the squat.",
      "Rest between jumps if you need to. Landing quietly matters more than height."
    ],
    "muscles": [
      "front of the thighs",
      "glutes",
      "calves"
    ]
  },
  {
    "id": "skater-hop",
    "name": "Skater hop",
    "aka": [],
    "instructions": [
      "Stand on one foot with a slight bend in the knee.",
      "Hop sideways onto the other foot, swinging the free leg behind you.",
      "Land softly and hold the balance for a moment.",
      "Hop back the other way and keep alternating."
    ],
    "muscles": [
      "glutes",
      "outer hips",
      "ankles"
    ]
  },
  {
    "id": "lateral-shuffle",
    "name": "Side shuffle",
    "aka": [
      "lateral shuffle"
    ],
    "instructions": [
      "Stand with your feet apart and your knees slightly bent.",
      "Take quick side steps in one direction, keeping your feet from crossing.",
      "Stay low with your chest lifted.",
      "Shuffle back the other way."
    ],
    "muscles": [
      "outer hips",
      "front of the thighs",
      "calves"
    ]
  },
  {
    "id": "russian-twist",
    "name": "Seated twist",
    "aka": [
      "Russian twist"
    ],
    "instructions": [
      "Sit on the floor with your knees bent and lean back slightly, keeping your back straight.",
      "Hold your hands together in front of your chest.",
      "Rotate your torso to one side, then the other.",
      "Keep your feet down for an easier version, or lift them for more challenge."
    ],
    "muscles": [
      "sides of the waist",
      "deep core"
    ]
  },
  {
    "id": "toe-touch",
    "name": "Forward fold",
    "aka": [
      "toe touch"
    ],
    "instructions": [
      "Stand with your feet hip width apart.",
      "Hinge at your hips and let your upper body fold toward the floor.",
      "Bend your knees as much as you need to. Let your head and arms hang.",
      "Roll back up slowly, one part of your spine at a time."
    ],
    "muscles": [
      "back of the thighs",
      "lower back"
    ]
  },
  {
    "id": "step-up",
    "name": "Step-up",
    "aka": [],
    "instructions": [
      "Stand facing a step, bench, or sturdy box.",
      "Place one whole foot on it and press through that heel to step up.",
      "Bring the other foot up to meet it, standing tall at the top.",
      "Step back down with control and switch the leading leg."
    ],
    "muscles": [
      "front of the thighs",
      "glutes"
    ]
  },
  {
    "id": "chair-dip",
    "name": "Chair dip",
    "aka": [
      "tricep dip"
    ],
    "instructions": [
      "Sit on the edge of a sturdy chair with your hands gripping the seat beside your hips.",
      "Walk your feet forward and lift your hips off the seat.",
      "Bend your elbows to lower your hips toward the floor, keeping them close to the chair.",
      "Press back up until your arms are straight."
    ],
    "muscles": [
      "back of the upper arms",
      "front of the shoulders"
    ]
  },
  {
    "id": "back-extension",
    "name": "Back extension",
    "aka": [],
    "instructions": [
      "Lie face down with your hands lightly beside your head or under your chin.",
      "Lift your chest a little way off the floor, using your back rather than pushing with your arms.",
      "Keep your feet on the floor and your neck relaxed.",
      "Lower slowly and repeat."
    ],
    "muscles": [
      "lower back",
      "glutes"
    ]
  },
  {
    "id": "dead-hang",
    "name": "Dead hang",
    "aka": [],
    "instructions": [
      "Grip a bar with both hands, palms facing away, about shoulder width apart.",
      "Let your body hang with your arms straight and your feet off the floor.",
      "Relax your shoulders toward your ears, or draw them down for a little more work.",
      "Hold for as long as your grip is comfortable, then step down."
    ],
    "muscles": [
      "grip",
      "forearms",
      "shoulders"
    ]
  },
  {
    "id": "inverted-row",
    "name": "Inverted row",
    "aka": [
      "bodyweight row"
    ],
    "instructions": [
      "Lie under a sturdy bar or table edge and grip it with both hands.",
      "Keep your body in one straight line from head to heels.",
      "Pull your chest up toward the bar, squeezing your shoulder blades together.",
      "Lower slowly. Bend your knees and walk your feet in to make it easier."
    ],
    "muscles": [
      "upper back",
      "back of the shoulders",
      "upper arms"
    ]
  },
  {
    "id": "pull-up",
    "name": "Pull-up",
    "aka": [],
    "instructions": [
      "Hang from a bar with your palms facing away and hands a little wider than your shoulders.",
      "Pull your chest toward the bar, leading with your elbows.",
      "Keep your legs still rather than swinging.",
      "Lower all the way down slowly."
    ],
    "muscles": [
      "sides of the back",
      "upper arms",
      "grip"
    ]
  },
  {
    "id": "chin-up",
    "name": "Chin-up",
    "aka": [],
    "instructions": [
      "Hang from a bar with your palms facing you and hands about shoulder width apart.",
      "Pull yourself up until your chin passes the bar.",
      "Keep your body steady without swinging.",
      "Lower slowly until your arms are straight."
    ],
    "muscles": [
      "upper arms",
      "sides of the back",
      "grip"
    ]
  },
  {
    "id": "hanging-knee-raise",
    "name": "Hanging knee raise",
    "aka": [],
    "instructions": [
      "Hang from a bar with your arms straight.",
      "Draw both knees up toward your chest.",
      "Move slowly to avoid swinging.",
      "Lower your legs with control."
    ],
    "muscles": [
      "lower abdomen",
      "front of the hips",
      "grip"
    ]
  },
  {
    "id": "arm-circles",
    "name": "Arm circles",
    "aka": [],
    "instructions": [
      "Stand tall with your arms out to the sides at shoulder height.",
      "Make small circles forward, letting them grow gradually larger.",
      "Keep your shoulders down away from your ears.",
      "Reverse the direction for the same amount of time."
    ],
    "muscles": [
      "shoulders",
      "upper back"
    ]
  },
  {
    "id": "butterfly-stretch",
    "name": "Butterfly stretch",
    "aka": [],
    "instructions": [
      "Sit on the floor with the soles of your feet together and your knees out to the sides.",
      "Hold your feet and sit up tall.",
      "Let your knees soften toward the floor without pushing them.",
      "Breathe here. Lean forward from the hips for a little more."
    ],
    "muscles": [
      "inner thighs",
      "hips"
    ]
  },
  {
    "id": "cross-body-shoulder-stretch",
    "name": "Cross-body shoulder stretch",
    "aka": [],
    "instructions": [
      "Bring one arm straight across your chest.",
      "Use the other hand to gently press the arm closer to you.",
      "Keep the shoulder you are stretching down and relaxed.",
      "Hold, then switch arms."
    ],
    "muscles": [
      "back of the shoulders",
      "upper back"
    ]
  },
  {
    "id": "hamstring-stretch",
    "name": "Standing hamstring stretch",
    "aka": [],
    "instructions": [
      "Place one heel on a low step or the floor in front of you, leg straight and toes up.",
      "Keep your back straight and hinge forward slightly at your hips.",
      "Stop when you feel the back of the thigh lengthen.",
      "Hold and breathe, then switch legs."
    ],
    "muscles": [
      "back of the thighs",
      "calves"
    ]
  },
  {
    "id": "kneeling-hip-flexor-stretch",
    "name": "Kneeling hip flexor stretch",
    "aka": [],
    "instructions": [
      "Kneel on one knee with the other foot flat in front of you, like a low lunge.",
      "Tuck your tailbone under slightly and shift your hips forward.",
      "Keep your chest lifted. You should feel the front of the kneeling hip open.",
      "Hold and breathe, then switch sides."
    ],
    "muscles": [
      "front of the hips",
      "front of the thighs"
    ]
  },
  {
    "id": "leg-swings-stretch",
    "name": "Leg swings",
    "aka": [],
    "instructions": [
      "Stand next to a wall and rest a hand on it for balance.",
      "Swing the outside leg forward and back in a relaxed motion.",
      "Let the swing grow a little larger as your hip loosens.",
      "Switch legs. Try side-to-side swings too if you like."
    ],
    "muscles": [
      "hips",
      "back of the thighs",
      "front of the hips"
    ]
  },
  {
    "id": "seated-forward-fold-stretch",
    "name": "Seated forward fold",
    "aka": [
      "spine stretch forward"
    ],
    "instructions": [
      "Sit tall with your legs straight out in front of you, feet flexed.",
      "Reach your arms forward and fold from your hips, then let your spine round.",
      "Go only as far as feels easy. Bend your knees if you need to.",
      "Breathe here, then roll back up slowly."
    ],
    "muscles": [
      "back of the thighs",
      "lower back",
      "spine"
    ]
  },
  {
    "id": "standing-quad-stretch",
    "name": "Standing quad stretch",
    "aka": [],
    "instructions": [
      "Stand tall, holding a wall or chair for balance if you like.",
      "Bend one knee and hold that foot behind you.",
      "Keep your knees together and your hips facing forward.",
      "Hold and breathe, then switch legs."
    ],
    "muscles": [
      "front of the thighs",
      "front of the hips"
    ]
  },
  {
    "id": "torso-twist-stretch",
    "name": "Standing twist",
    "aka": [
      "torso twist"
    ],
    "instructions": [
      "Stand with your feet hip width apart and your knees soft.",
      "Let your arms relax and turn your upper body to one side.",
      "Let your arms swing loosely with the turn.",
      "Turn to the other side and keep going in an easy rhythm."
    ],
    "muscles": [
      "spine",
      "sides of the waist"
    ]
  },
  {
    "id": "wall-calf-stretch",
    "name": "Wall calf stretch",
    "aka": [],
    "instructions": [
      "Stand facing a wall with your hands on it.",
      "Step one foot back, keeping that heel down and the leg straight.",
      "Lean toward the wall until you feel the calf of the back leg lengthen.",
      "Hold and breathe, then switch legs."
    ],
    "muscles": [
      "calves",
      "ankles"
    ]
  },
  {
    "id": "worlds-greatest-stretch",
    "name": "World's greatest stretch",
    "aka": [
      "lunge with twist"
    ],
    "instructions": [
      "Step into a long lunge and place both hands on the floor inside your front foot.",
      "Drop your back knee to the floor if you like.",
      "Lift the hand nearest your front foot and reach it toward the ceiling, turning your chest to follow it.",
      "Return the hand, then switch sides."
    ],
    "muscles": [
      "hips",
      "upper back",
      "back of the thighs"
    ]
  },
  {
    "id": "band-pull-apart",
    "name": "Band pull-apart",
    "aka": [],
    "instructions": [
      "Hold a band in front of you at shoulder height with your hands about shoulder width apart.",
      "Pull your hands apart until the band touches your chest, squeezing your shoulder blades together.",
      "Keep your arms straight and your shoulders down.",
      "Return slowly to the start."
    ],
    "muscles": [
      "upper back",
      "back of the shoulders"
    ]
  },
  {
    "id": "banded-clamshell",
    "name": "Band clamshell",
    "aka": [],
    "instructions": [
      "Loop a band just above your knees and lie on your side with your knees bent and feet together.",
      "Keeping your feet touching, lift your top knee against the band.",
      "Do not let your top hip roll backward.",
      "Lower slowly. Switch sides after your set."
    ],
    "muscles": [
      "outer hips",
      "glutes"
    ]
  },
  {
    "id": "banded-glute-bridge",
    "name": "Band bridge",
    "aka": [],
    "instructions": [
      "Loop a band just above your knees and lie on your back, knees bent and feet flat.",
      "Press your knees gently outward against the band.",
      "Lift your hips, squeezing your glutes at the top.",
      "Lower slowly while keeping the knees pressing out."
    ],
    "muscles": [
      "glutes",
      "outer hips",
      "back of the thighs"
    ]
  },
  {
    "id": "banded-lateral-walk",
    "name": "Band side walk",
    "aka": [
      "lateral band walk"
    ],
    "instructions": [
      "Loop a band around your legs, just above the knees or around the ankles.",
      "Bend your knees slightly and step one foot out to the side.",
      "Follow with the other foot, keeping tension in the band the whole time.",
      "Take several steps one way, then come back."
    ],
    "muscles": [
      "outer hips",
      "glutes"
    ]
  },
  {
    "id": "banded-monster-walk",
    "name": "Monster walk",
    "aka": [],
    "instructions": [
      "Loop a band around your legs, just above the knees or at the ankles.",
      "Bend your knees slightly and walk forward with wide, deliberate steps.",
      "Keep the band stretched so your knees stay pressed outward.",
      "Walk backward the same way."
    ],
    "muscles": [
      "outer hips",
      "glutes"
    ]
  },
  {
    "id": "banded-squat",
    "name": "Band squat",
    "aka": [],
    "instructions": [
      "Loop a band just above your knees and stand with your feet hip width apart.",
      "Sit your hips back and down into a squat.",
      "Press your knees outward against the band the whole way.",
      "Stand back up, keeping the knees from caving in."
    ],
    "muscles": [
      "front of the thighs",
      "glutes",
      "outer hips"
    ]
  },
  {
    "id": "banded-row",
    "name": "Band row",
    "aka": [],
    "instructions": [
      "Sit with your legs out in front and loop a band around your feet, or anchor it in front of you.",
      "Hold the ends with your arms extended.",
      "Pull your elbows back past your ribs, squeezing your shoulder blades together.",
      "Return slowly with control."
    ],
    "muscles": [
      "upper back",
      "back of the shoulders",
      "upper arms"
    ]
  },
  {
    "id": "banded-face-pull",
    "name": "Band face pull",
    "aka": [],
    "instructions": [
      "Anchor a band at about face height and hold an end in each hand.",
      "Pull the band toward your face, elbows high and wide.",
      "Finish with your hands beside your ears and your shoulder blades squeezed together.",
      "Return slowly."
    ],
    "muscles": [
      "back of the shoulders",
      "upper back"
    ]
  },
  {
    "id": "bicep-curl",
    "name": "Bicep curl",
    "aka": [],
    "instructions": [
      "Stand tall holding a weight in each hand, palms facing forward.",
      "Bend your elbows to bring the weights up toward your shoulders.",
      "Keep your elbows close to your sides and your upper arms still.",
      "Lower slowly to the start."
    ],
    "muscles": [
      "front of the upper arms",
      "forearms"
    ]
  },
  {
    "id": "hammer-curl",
    "name": "Hammer curl",
    "aka": [],
    "instructions": [
      "Stand tall holding a weight in each hand with your palms facing your body.",
      "Curl the weights up, keeping your palms facing in the whole time.",
      "Keep your elbows by your sides.",
      "Lower slowly."
    ],
    "muscles": [
      "front of the upper arms",
      "forearms"
    ]
  },
  {
    "id": "lateral-raise",
    "name": "Lateral raise",
    "aka": [],
    "instructions": [
      "Stand tall with a light weight in each hand by your sides.",
      "Raise your arms out to the sides until they reach shoulder height.",
      "Keep a slight bend in your elbows and lead with them, not the hands.",
      "Lower slowly."
    ],
    "muscles": [
      "shoulders"
    ]
  },
  {
    "id": "front-raise",
    "name": "Front raise",
    "aka": [],
    "instructions": [
      "Stand tall with a light weight in each hand resting against your thighs.",
      "Raise one or both arms straight in front of you to shoulder height.",
      "Keep your torso still rather than leaning back.",
      "Lower slowly."
    ],
    "muscles": [
      "front of the shoulders"
    ]
  },
  {
    "id": "standing-dumbbell-press",
    "name": "Dumbbell overhead press",
    "aka": [],
    "instructions": [
      "Stand tall holding a weight in each hand at shoulder height, palms forward.",
      "Press the weights straight up until your arms are extended.",
      "Keep your ribs down and avoid arching your lower back.",
      "Lower back to your shoulders with control."
    ],
    "muscles": [
      "shoulders",
      "back of the upper arms",
      "upper back"
    ]
  },
  {
    "id": "dumbbell-bench-press",
    "name": "Dumbbell bench press",
    "aka": [],
    "instructions": [
      "Lie on a bench holding a weight in each hand at chest level.",
      "Press the weights up until your arms are straight above your chest.",
      "Lower them slowly until your elbows are level with the bench.",
      "Keep your feet flat and your lower back relaxed."
    ],
    "muscles": [
      "chest",
      "front of the shoulders",
      "back of the upper arms"
    ]
  },
  {
    "id": "one-arm-dumbbell-row",
    "name": "Single arm row",
    "aka": [
      "one-arm row"
    ],
    "instructions": [
      "Rest one hand and knee on a bench, the other foot on the floor, back flat.",
      "Hold a weight in the free hand with the arm hanging straight.",
      "Pull the weight up toward your hip, elbow close to your body.",
      "Lower slowly. Switch sides after your set."
    ],
    "muscles": [
      "upper back",
      "sides of the back",
      "upper arms"
    ]
  },
  {
    "id": "dumbbell-romanian-deadlift",
    "name": "Dumbbell deadlift",
    "aka": [
      "dumbbell hip hinge"
    ],
    "instructions": [
      "Stand tall holding a weight in each hand in front of your thighs.",
      "Push your hips back and let the weights slide down your legs, keeping your back flat.",
      "Stop when you feel the back of your thighs stretch.",
      "Drive your hips forward to stand back up."
    ],
    "muscles": [
      "back of the thighs",
      "glutes",
      "lower back"
    ]
  },
  {
    "id": "single-leg-romanian-deadlift",
    "name": "Single leg deadlift",
    "aka": [],
    "instructions": [
      "Stand on one leg with a weight in the opposite hand, or no weight at all.",
      "Hinge forward at the hips, letting the free leg extend behind you.",
      "Keep your back flat and your hips level.",
      "Return to standing. Switch sides after your set."
    ],
    "muscles": [
      "back of the thighs",
      "glutes",
      "ankles"
    ]
  },
  {
    "id": "split-squat",
    "name": "Split squat",
    "aka": [],
    "instructions": [
      "Stand with one foot well in front of the other, as if paused in a lunge.",
      "Lower straight down until your back knee is near the floor.",
      "Keep your front shin upright and your torso tall.",
      "Push through the front foot to rise. Switch legs after your set."
    ],
    "muscles": [
      "front of the thighs",
      "glutes"
    ]
  },
  {
    "id": "bulgarian-split-squat",
    "name": "Rear foot elevated split squat",
    "aka": [
      "Bulgarian split squat"
    ],
    "instructions": [
      "Stand in front of a bench and rest the top of one foot on it behind you.",
      "Lower your hips until your front thigh is close to level with the floor.",
      "Keep your front knee over your ankle and your torso upright.",
      "Press up through the front foot. Switch legs after your set."
    ],
    "muscles": [
      "front of the thighs",
      "glutes"
    ]
  },
  {
    "id": "dumbbell-hip-thrust",
    "name": "Dumbbell hip thrust",
    "aka": [],
    "instructions": [
      "Sit on the floor with your upper back against a bench and a weight resting across your hips.",
      "Plant your feet flat and drive your hips up until your body is level.",
      "Squeeze your glutes at the top without arching your back.",
      "Lower slowly."
    ],
    "muscles": [
      "glutes",
      "back of the thighs"
    ]
  },
  {
    "id": "dumbbell-overhead-tricep-extension",
    "name": "Overhead tricep extension",
    "aka": [],
    "instructions": [
      "Hold one weight with both hands and raise it above your head.",
      "Bend your elbows to lower the weight behind your head.",
      "Keep your elbows pointing forward and close to your ears.",
      "Straighten your arms to lift the weight back up."
    ],
    "muscles": [
      "back of the upper arms"
    ]
  },
  {
    "id": "dumbbell-side-bend",
    "name": "Side bend",
    "aka": [],
    "instructions": [
      "Stand tall with a weight in one hand, or no weight at all.",
      "Slide the hand down the side of your leg, bending sideways at the waist.",
      "Keep your hips still and avoid leaning forward or back.",
      "Return to upright. Switch sides after your set."
    ],
    "muscles": [
      "sides of the waist"
    ]
  },
  {
    "id": "kettlebell-swing",
    "name": "Kettlebell swing",
    "aka": [],
    "instructions": [
      "Stand with your feet a little wider than your hips and the kettlebell on the floor in front of you.",
      "Hinge at the hips and swing the bell back between your legs.",
      "Snap your hips forward to swing it up to about chest height, arms relaxed.",
      "Let it swing back and repeat in a rhythm. Your hips do the work, not your arms."
    ],
    "muscles": [
      "glutes",
      "back of the thighs",
      "deep core"
    ]
  },
  {
    "id": "kettlebell-romanian-deadlift",
    "name": "Kettlebell deadlift",
    "aka": [],
    "instructions": [
      "Stand with a kettlebell between your feet.",
      "Hinge at your hips, keeping your back flat, and grip the handle.",
      "Drive your hips forward to stand tall with the bell.",
      "Lower it back down the same way, hips back first."
    ],
    "muscles": [
      "back of the thighs",
      "glutes",
      "lower back"
    ]
  },
  {
    "id": "squat",
    "name": "Barbell squat",
    "aka": [
      "back squat"
    ],
    "instructions": [
      "Rest the bar across your upper back and stand with your feet about shoulder width apart.",
      "Sit your hips back and down, keeping your chest up and your heels planted.",
      "Go as low as you can while your back stays neutral.",
      "Drive through your whole foot to stand."
    ],
    "muscles": [
      "front of the thighs",
      "glutes",
      "deep core"
    ]
  },
  {
    "id": "deadlift",
    "name": "Barbell deadlift",
    "aka": [],
    "instructions": [
      "Stand with the bar over the middle of your feet and grip it just outside your legs.",
      "Flatten your back, lift your chest, and push the floor away with your legs.",
      "Keep the bar close to your body as you stand up tall.",
      "Lower it by pushing your hips back, then bending your knees."
    ],
    "muscles": [
      "back of the thighs",
      "glutes",
      "back",
      "grip"
    ]
  },
  {
    "id": "bench-press",
    "name": "Barbell bench press",
    "aka": [],
    "instructions": [
      "Lie on the bench with the bar above your eyes and your feet flat.",
      "Grip the bar a little wider than shoulder width and unrack it over your chest.",
      "Lower the bar to your chest with your elbows angled slightly in.",
      "Press it back up until your arms are straight."
    ],
    "muscles": [
      "chest",
      "front of the shoulders",
      "back of the upper arms"
    ]
  },
  {
    "id": "hip-thrust",
    "name": "Barbell hip thrust",
    "aka": [],
    "instructions": [
      "Sit on the floor with your upper back against a bench and the bar across your hips, padded.",
      "Plant your feet and drive your hips up until your thighs and torso are level.",
      "Squeeze your glutes at the top, chin tucked, ribs down.",
      "Lower slowly."
    ],
    "muscles": [
      "glutes",
      "back of the thighs"
    ]
  },
  {
    "id": "barbell-row",
    "name": "Barbell row",
    "aka": [],
    "instructions": [
      "Hold the bar with your hands about shoulder width apart and hinge forward at the hips, back flat.",
      "Pull the bar toward your lower ribs, elbows travelling back.",
      "Squeeze your shoulder blades together at the top.",
      "Lower slowly without rounding your back."
    ],
    "muscles": [
      "upper back",
      "sides of the back",
      "upper arms"
    ]
  },
  {
    "id": "good-morning",
    "name": "Good morning",
    "aka": [],
    "instructions": [
      "Rest a light bar across your upper back with your feet hip width apart.",
      "Push your hips back and hinge forward, keeping your back flat and knees soft.",
      "Stop when you feel the back of your thighs stretch.",
      "Drive your hips forward to stand tall."
    ],
    "muscles": [
      "back of the thighs",
      "glutes",
      "lower back"
    ]
  },
  {
    "id": "leg-extension",
    "name": "Leg extension",
    "aka": [],
    "instructions": [
      "Sit in the machine with the pad resting on your shins and your back against the seat.",
      "Straighten your legs to lift the pad, pausing at the top.",
      "Keep the movement smooth rather than kicking.",
      "Lower slowly to the start."
    ],
    "muscles": [
      "front of the thighs"
    ]
  },
  {
    "id": "leg-curl",
    "name": "Leg curl",
    "aka": [
      "hamstring curl"
    ],
    "instructions": [
      "Set up in the machine with the pad resting just above your heels.",
      "Bend your knees to pull the pad toward your glutes.",
      "Keep your hips pressed into the seat or bench.",
      "Straighten slowly to return."
    ],
    "muscles": [
      "back of the thighs"
    ]
  },
  {
    "id": "hip-abduction-machine",
    "name": "Hip abduction machine",
    "aka": [],
    "instructions": [
      "Sit in the machine with the pads on the outside of your knees.",
      "Press your legs apart against the pads.",
      "Pause at the widest point.",
      "Bring your legs back together slowly."
    ],
    "muscles": [
      "outer hips",
      "glutes"
    ]
  },
  {
    "id": "hip-adduction-machine",
    "name": "Hip adduction machine",
    "aka": [],
    "instructions": [
      "Sit in the machine with the pads on the inside of your knees, legs open.",
      "Squeeze your legs together against the pads.",
      "Pause when your knees meet.",
      "Open slowly back to the start."
    ],
    "muscles": [
      "inner thighs"
    ]
  },
  {
    "id": "machine-chest-press",
    "name": "Machine chest press",
    "aka": [],
    "instructions": [
      "Sit with your back against the pad and the handles at chest height.",
      "Press the handles forward until your arms are nearly straight.",
      "Keep your shoulders down and your wrists straight.",
      "Return slowly."
    ],
    "muscles": [
      "chest",
      "front of the shoulders",
      "back of the upper arms"
    ]
  },
  {
    "id": "machine-row",
    "name": "Machine row",
    "aka": [],
    "instructions": [
      "Sit with your chest against the pad and grip the handles.",
      "Pull the handles toward you, elbows travelling back past your ribs.",
      "Squeeze your shoulder blades together.",
      "Return slowly until your arms are straight."
    ],
    "muscles": [
      "upper back",
      "back of the shoulders",
      "upper arms"
    ]
  },
  {
    "id": "machine-shoulder-press",
    "name": "Machine shoulder press",
    "aka": [],
    "instructions": [
      "Sit with your back against the pad and the handles at shoulder height.",
      "Press the handles up until your arms are nearly straight.",
      "Keep your ribs down and your neck relaxed.",
      "Lower slowly."
    ],
    "muscles": [
      "shoulders",
      "back of the upper arms"
    ]
  },
  {
    "id": "pec-deck",
    "name": "Pec deck",
    "aka": [
      "chest fly machine"
    ],
    "instructions": [
      "Sit with your back against the pad and your forearms or hands on the arms of the machine.",
      "Bring the arms together in front of your chest in a hugging motion.",
      "Pause when they meet.",
      "Open slowly, stopping before your shoulders strain."
    ],
    "muscles": [
      "chest",
      "front of the shoulders"
    ]
  },
  {
    "id": "standing-calf-raise",
    "name": "Standing calf raise machine",
    "aka": [],
    "instructions": [
      "Stand under the pads with the balls of your feet on the platform and your heels hanging off.",
      "Rise up onto your toes as high as you can.",
      "Pause at the top.",
      "Lower your heels below the platform slowly."
    ],
    "muscles": [
      "calves"
    ]
  },
  {
    "id": "assisted-pull-up",
    "name": "Assisted pull-up",
    "aka": [],
    "instructions": [
      "Set the counterweight, then kneel or stand on the platform and grip the bar.",
      "Pull yourself up until your chin is near the bar.",
      "Keep your body steady.",
      "Lower slowly until your arms are straight."
    ],
    "muscles": [
      "sides of the back",
      "upper arms",
      "grip"
    ]
  },
  {
    "id": "assisted-dip",
    "name": "Assisted dip",
    "aka": [],
    "instructions": [
      "Set the counterweight, then kneel on the platform and grip the handles.",
      "Bend your elbows to lower your body, keeping them close to your sides.",
      "Lean forward slightly.",
      "Press back up until your arms are straight."
    ],
    "muscles": [
      "back of the upper arms",
      "chest",
      "front of the shoulders"
    ]
  },
  {
    "id": "wide-grip-lat-pulldown",
    "name": "Wide grip pulldown",
    "aka": [],
    "instructions": [
      "Sit at the machine and grip the bar wider than your shoulders.",
      "Pull the bar down to your upper chest, elbows travelling down and back.",
      "Keep your chest lifted and avoid leaning far back.",
      "Return slowly until your arms are straight."
    ],
    "muscles": [
      "sides of the back",
      "upper arms"
    ]
  },
  {
    "id": "face-pull",
    "name": "Face pull",
    "aka": [],
    "instructions": [
      "Set a rope attachment at about face height and hold an end in each hand.",
      "Pull the rope toward your face, elbows high and wide.",
      "Finish with your hands beside your ears and your shoulder blades squeezed together.",
      "Return slowly."
    ],
    "muscles": [
      "back of the shoulders",
      "upper back"
    ]
  },
  {
    "id": "cable-fly",
    "name": "Cable fly",
    "aka": [],
    "instructions": [
      "Stand between two cable stacks with a handle in each hand, arms out to the sides.",
      "Step forward slightly and bring your hands together in front of your chest in an arc.",
      "Keep a soft bend in your elbows the whole way.",
      "Open your arms slowly to return."
    ],
    "muscles": [
      "chest",
      "front of the shoulders"
    ]
  },
  {
    "id": "tricep-pushdown",
    "name": "Tricep pushdown",
    "aka": [],
    "instructions": [
      "Stand at a cable machine holding the bar or rope at chest height, elbows by your sides.",
      "Push your hands down until your arms are straight.",
      "Keep your elbows pinned in place and your shoulders down.",
      "Return slowly."
    ],
    "muscles": [
      "back of the upper arms"
    ]
  },
  {
    "id": "pallof-press",
    "name": "Pallof press",
    "aka": [],
    "instructions": [
      "Stand side-on to a cable or band anchored at chest height and hold the handle at your chest.",
      "Press your hands straight out in front of you.",
      "Resist the pull that tries to twist you toward the anchor.",
      "Bring your hands back to your chest. Switch sides after your set."
    ],
    "muscles": [
      "deep core",
      "sides of the waist"
    ]
  },
  {
    "id": "walking",
    "name": "Walking",
    "aka": [],
    "instructions": [
      "Stand tall and look ahead rather than down.",
      "Let your arms swing naturally.",
      "Find a pace where you could still hold a conversation.",
      "Keep going for the time you planned."
    ],
    "muscles": [
      "legs",
      "heart and lungs"
    ]
  },
  {
    "id": "running",
    "name": "Running",
    "aka": [
      "jogging"
    ],
    "instructions": [
      "Start with a few minutes of easy walking.",
      "Pick up into a jog with short, quick steps and relaxed shoulders.",
      "Breathe in a rhythm that feels natural.",
      "Slow to a walk to finish."
    ],
    "muscles": [
      "legs",
      "heart and lungs"
    ]
  },
  {
    "id": "cycling",
    "name": "Cycling",
    "aka": [
      "bike"
    ],
    "instructions": [
      "Set the seat so your knee has a slight bend at the bottom of the pedal stroke.",
      "Start pedalling at an easy resistance.",
      "Keep your upper body relaxed and your hands light on the bars.",
      "Adjust resistance so the effort feels steady."
    ],
    "muscles": [
      "front of the thighs",
      "glutes",
      "calves",
      "heart and lungs"
    ]
  },
  {
    "id": "rowing",
    "name": "Rowing machine",
    "aka": [
      "erg"
    ],
    "instructions": [
      "Sit with your feet strapped in, knees bent, and arms straight holding the handle.",
      "Push with your legs first, then lean back slightly, then pull the handle to your ribs.",
      "Return in reverse: arms out, lean forward, then bend your knees.",
      "Keep a smooth, unhurried rhythm."
    ],
    "muscles": [
      "legs",
      "back",
      "upper arms",
      "heart and lungs"
    ]
  },
  {
    "id": "elliptical",
    "name": "Elliptical",
    "aka": [
      "cross trainer"
    ],
    "instructions": [
      "Step on and hold the moving handles or the fixed ones.",
      "Push through your feet in a smooth gliding motion.",
      "Stand tall rather than leaning on the handles.",
      "Adjust resistance until the effort feels steady."
    ],
    "muscles": [
      "legs",
      "glutes",
      "heart and lungs"
    ]
  },
  {
    "id": "stair-climber",
    "name": "Stair climber",
    "aka": [
      "step machine"
    ],
    "instructions": [
      "Step on and start at a slow speed.",
      "Place your whole foot on each step and push through your heel.",
      "Rest your hands lightly on the rails without leaning on them.",
      "Adjust the speed so you can keep going for the whole time."
    ],
    "muscles": [
      "glutes",
      "front of the thighs",
      "calves",
      "heart and lungs"
    ]
  },
  {
    "id": "treadmill-incline-walk",
    "name": "Incline walk",
    "aka": [
      "treadmill walk"
    ],
    "instructions": [
      "Start the treadmill at a slow walking pace.",
      "Raise the incline a little at a time until the walk feels like a gentle hill.",
      "Stand tall and swing your arms rather than holding the rails.",
      "Lower the incline for the last minute to finish."
    ],
    "muscles": [
      "glutes",
      "calves",
      "back of the thighs",
      "heart and lungs"
    ]
  },
  {
    "id": "swimming",
    "name": "Swimming",
    "aka": [],
    "instructions": [
      "Start with a few easy lengths to settle into the water.",
      "Use whichever stroke feels comfortable.",
      "Breathe in a steady rhythm.",
      "Rest at the wall whenever you need to."
    ],
    "muscles": [
      "shoulders",
      "back",
      "legs",
      "heart and lungs"
    ]
  },
  {
    "id": "qigong-lifting-the-sky",
    "name": "Lifting the Sky",
    "aka": [
      "lifting the sky",
      "qi gong lifting the sky",
      "ba duan jin"
    ],
    "instructions": [
      "Stand tall with feet shoulder-width apart and knees soft.",
      "Rest your hands in front of your belly, palms facing up.",
      "Inhale as your hands float up along your chest and turn upward overhead.",
      "Exhale as you press palms gently toward the sky, then lower smoothly."
    ],
    "muscles": [
      "shoulders",
      "spine",
      "chest",
      "core"
    ]
  },
  {
    "id": "qigong-drawing-the-bow",
    "name": "Drawing the bow",
    "aka": [
      "draw the bow",
      "qi gong drawing the bow"
    ],
    "instructions": [
      "Stand with your feet a little wider than your shoulders and bend your knees slightly. Go only as low as feels comfortable.",
      "Point your right hand out to the right, with your index finger and thumb making an L shape, and look toward it.",
      "Bend your left arm and pull the elbow back, as if drawing a bow. Breathe in as you pull.",
      "Breathe out as you let the pull go, then repeat slowly. Switch sides for the next step."
    ],
    "muscles": [
      "shoulders",
      "upper back",
      "legs"
    ]
  },
  {
    "id": "qigong-turning-the-waist",
    "name": "Turning the waist",
    "aka": [
      "waist turning",
      "swinging arms"
    ],
    "instructions": [
      "Stand with your feet hip-width apart and your knees slightly bent.",
      "Let your arms hang loose, like ropes.",
      "Turn your upper body to the right, then to the left, letting your arms swing around you.",
      "Keep your feet planted and breathe normally."
    ],
    "muscles": [
      "core",
      "spine",
      "hips"
    ]
  },
  {
    "id": "qigong-cloud-hands",
    "name": "Cloud hands",
    "aka": [
      "cloud hands",
      "qi gong cloud hands"
    ],
    "instructions": [
      "Stand with your feet shoulder-width apart and your knees slightly bent.",
      "Shift your weight onto your right foot. Raise your right hand to chest height with the palm facing you, and rest your left hand near your belly.",
      "Slowly shift your weight to your left foot as your hands trade places: the left hand rises and the right hand lowers.",
      "Keep going back and forth slowly, like wiping a big window, and breathe easily."
    ],
    "muscles": [
      "legs",
      "core",
      "shoulders"
    ]
  },
  {
    "id": "qigong-holding-the-ball",
    "name": "Holding the ball",
    "aka": [
      "holding the ball",
      "embrace the tree"
    ],
    "instructions": [
      "Stand with your feet hip-width apart and your knees slightly bent.",
      "Lift your arms in front of your chest as if hugging a large beach ball, with your fingertips pointing toward each other.",
      "Let your shoulders drop and keep your elbows slightly lower than your hands.",
      "Stay still and breathe slowly."
    ],
    "muscles": [
      "shoulders",
      "legs",
      "core"
    ]
  },
  {
    "id": "wall-angels",
    "name": "Wall angels",
    "aka": [
      "wall angel",
      "scapular wall slides"
    ],
    "instructions": [
      "Stand with your back, head, and tailbone flat against a wall, feet slightly forward.",
      "Bring your arms into a goalpost shape with elbows and backs of your hands against the wall.",
      "Slowly slide your hands upward into a wide Y shape, keeping contact with the wall.",
      "Lower your elbows with control back to shoulder height and repeat."
    ],
    "muscles": [
      "upper back",
      "shoulders",
      "posture muscles"
    ]
  },
  {
    "id": "full-body-shake",
    "name": "Full-body shake",
    "aka": [
      "shake out",
      "body shake",
      "tremoring"
    ],
    "instructions": [
      "Stand tall with feet hip-width apart and knees soft and springy.",
      "Drop your shoulders and let your arms hang completely loose beside your hips.",
      "Gently bounce through your heels and knees, letting your wrists and hands flutter.",
      "Breathe naturally and shake off physical tension from head to toe."
    ],
    "muscles": [
      "nervous system ease",
      "calves",
      "shoulders",
      "spine"
    ]
  },
  {
    "id": "deep-breath",
    "name": "Mindful breathing",
    "aka": [
      "deep breath",
      "settle and breathe",
      "box breathing",
      "centering",
      "quiet integration",
      "catch your breath",
      "mindful breath"
    ],
    "instructions": [
      "Stand tall or sit comfortably with feet grounded and spine long.",
      "Drop your shoulders away from your ears and let your hands rest loose.",
      "Take a slow, deep breath in through your nose, expanding your ribcage and belly.",
      "Exhale smoothly through your mouth or nose, letting all tension melt away."
    ],
    "muscles": [
      "diaphragm",
      "nervous system regulation",
      "posture"
    ]
  },
  {
    "id": "roll-up",
    "name": "Roll-up",
    "aka": [],
    "instructions": [
      "Lie on your back, legs long, arms overhead.",
      "Reach your arms up and slowly peel your head, then shoulders, then spine off the mat.",
      "Fold forward over your legs, then reverse slowly, one segment at a time.",
      "Bend your knees if your legs pop up.",
      "Move with your breath, not momentum."
    ],
    "muscles": [
      "deep core",
      "front of the hips"
    ]
  },
  {
    "id": "single-leg-circle",
    "name": "Single leg circle",
    "aka": [],
    "instructions": [
      "Lie on your back, one leg extended toward the ceiling, the other long or bent.",
      "Draw small circles with the raised leg, keeping your pelvis still.",
      "Reverse direction halfway, then switch legs.",
      "Keep your shoulders relaxed and your hips level."
    ],
    "muscles": [
      "deep core",
      "hips"
    ]
  },
  {
    "id": "rolling-like-a-ball",
    "name": "Rolling like a ball",
    "aka": [],
    "instructions": [
      "Sit near the front of your mat, hold your shins, and tuck your chin.",
      "Balance on your sitting bones with your feet just off the floor.",
      "Rock back to your shoulder blades and roll up again, staying round.",
      "Keep your head off the mat and never roll onto your neck."
    ],
    "muscles": [
      "deep core",
      "back"
    ]
  },
  {
    "id": "double-leg-stretch",
    "name": "Double leg stretch",
    "aka": [],
    "instructions": [
      "Lie on your back, knees to your chest, head and shoulders lifted.",
      "Reach your arms overhead and your legs long at once.",
      "Circle your arms around and hug your knees back in.",
      "Keep your lower back heavy on the mat."
    ],
    "muscles": [
      "deep core",
      "shoulders"
    ]
  },
  {
    "id": "spine-stretch-forward",
    "name": "Spine stretch forward",
    "aka": [],
    "instructions": [
      "Sit tall with your legs open about mat-width, feet flexed, arms reaching forward.",
      "Nod your chin and curve forward over an imaginary ball.",
      "Stack your spine back up one bone at a time.",
      "Keep your shoulders down and sit evenly on both sitting bones."
    ],
    "muscles": [
      "back",
      "hamstrings"
    ]
  },
  {
    "id": "pilates-swimming",
    "name": "Pilates swimming",
    "aka": [],
    "instructions": [
      "Lie on your front with your arms and legs long.",
      "Lift your arms, chest and legs slightly.",
      "Flutter opposite arm and leg up and down in small, steady beats, breathing evenly.",
      "Draw your belly in gently so your lower back doesn't sink."
    ],
    "muscles": [
      "back",
      "glutes"
    ]
  },
  {
    "id": "swan-prep",
    "name": "Swan prep",
    "aka": [],
    "instructions": [
      "Lie on your front, hands under your shoulders, elbows close.",
      "Press gently into your hands and lift your chest a little, keeping your neck long.",
      "Lower slowly.",
      "Keep the lift small and don't push hard through your hands."
    ],
    "muscles": [
      "back",
      "shoulders"
    ]
  },
  {
    "id": "side-kick",
    "name": "Side kick",
    "aka": [],
    "instructions": [
      "Lie on your side, legs slightly forward, top leg lifted to hip height.",
      "Swing the top leg forward, then reach it back without moving your torso.",
      "Keep your waist long and your hips stacked.",
      "Keep the swing small so your torso and pelvis stay still."
    ],
    "muscles": [
      "hips",
      "glutes",
      "deep core"
    ]
  },
  {
    "id": "roll-down",
    "name": "Roll down",
    "aka": [],
    "instructions": [
      "Stand tall with your feet hip-width apart.",
      "Nod your chin and slowly peel your spine forward, one segment at a time.",
      "Hang for a moment with soft knees, then stack back up slowly."
    ],
    "muscles": [
      "back",
      "hamstrings"
    ]
  },
  {
    "id": "standing-leg-lift",
    "name": "Standing leg lift",
    "aka": [],
    "instructions": [
      "Stand tall holding a wall or chair for balance.",
      "Lift one leg out to the side, keeping your hips level.",
      "Lower with control. Switch legs halfway."
    ],
    "muscles": [
      "hips",
      "glutes"
    ]
  }
];

export function findSessionById(id?: string): CatalogSessionItem | undefined {
  if (!id) return undefined;
  return CATALOG_SESSIONS.find(s => s.id === id);
}

export function findGlossaryById(id?: string): CatalogGlossaryItem | undefined {
  if (!id) return undefined;
  return CATALOG_GLOSSARY.find(g => g.id === id);
}

export function searchGlossary(query: string): CatalogGlossaryItem | undefined {
  const q = query.toLowerCase().trim();
  if (!q) return undefined;
  return CATALOG_GLOSSARY.find(g =>
    g.name.toLowerCase() === q ||
    g.id.toLowerCase() === q ||
    (g.aka && g.aka.some(a => a.toLowerCase() === q || q.includes(a.toLowerCase()))) ||
    q.includes(g.name.toLowerCase())
  );
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
  hiddenSessionIds?: string[];
  preferredIntensityTier?: "gentle" | "moderate" | "dynamic";
  topExploredActivities?: string[];
  fatigueSensitivity?: number;
  isAvailable?: (s: CatalogSessionItem) => boolean;
}): CatalogSessionItem {
  let best: CatalogSessionItem = CATALOG_SESSIONS[0]!;
  let bestScore = -999;

  for (const s of CATALOG_SESSIONS) {
    if (params.hiddenSessionIds && params.hiddenSessionIds.includes(s.id)) continue;
    if (params.excludeId && s.id === params.excludeId) continue;
    if (params.isAvailable && !params.isAvailable(s)) continue;
    let score = 0;

    if (params.targetDuration) {
      if (s.durationMin > params.targetDuration) {
        score -= (s.durationMin - params.targetDuration) * 10;
      } else {
        const diff = params.targetDuration - s.durationMin;
        if (diff === 0) score += 25;
        else if (diff <= 3) score += 15;
        else if (diff <= 5) score += 10;
        else score -= diff;
      }
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

    // Contextual Bandit Learned Preference alignment
    if (params.preferredIntensityTier && s.intensity === params.preferredIntensityTier) {
      score += 8;
    }

    if (params.topExploredActivities && params.topExploredActivities.includes(s.activity)) {
      score += 10;
    }

    if (params.fatigueSensitivity && params.fatigueSensitivity > 0.6) {
      if (s.intensity === "gentle") {
        score += 8;
      } else if (s.intensity === "dynamic") {
        score -= 10;
      }
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
