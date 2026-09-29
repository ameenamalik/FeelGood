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
  },
  {
    "id": "main-band-upper-twelve",
    "title": "A band for your upper body",
    "subtitle": "A long band and a secure anchor at chest height",
    "durationMin": 12,
    "intensity": "moderate",
    "course": "main",
    "activity": "strength",
    "places": [
      "home",
      "gym"
    ],
    "bodyFocus": [
      "upperBody",
      "back"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "band"
    ]
  },
  {
    "id": "main-band-hips-twelve",
    "title": "Twelve minutes with a loop band",
    "subtitle": "Four floor and standing moves, repeated twice",
    "durationMin": 12,
    "intensity": "moderate",
    "course": "main",
    "activity": "strength",
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
      "band"
    ]
  },
  {
    "id": "main-dumbbell-arms-twelve",
    "title": "A little time for your arms",
    "subtitle": "A pair of dumbbells and a sturdy seat",
    "durationMin": 12,
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
    "id": "main-dumbbell-hips-twelve",
    "title": "Hips and legs with dumbbells",
    "subtitle": "Two rounds with a bench and room to move",
    "durationMin": 12,
    "intensity": "moderate",
    "course": "main",
    "activity": "strength",
    "places": [
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
      "gym"
    ]
  },
  {
    "id": "main-machine-push-twelve",
    "title": "A short machine push session",
    "subtitle": "Light loads and time to adjust each station",
    "durationMin": 12,
    "intensity": "moderate",
    "course": "main",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "upperBody"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "main-machine-pull-twelve",
    "title": "A short machine pull session",
    "subtitle": "Back and arms across two easy-to-follow rounds",
    "durationMin": 12,
    "intensity": "moderate",
    "course": "main",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "back",
      "upperBody"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "main-machine-legs-twelve",
    "title": "Four machines for your legs",
    "subtitle": "Set each machine to fit before starting",
    "durationMin": 12,
    "intensity": "moderate",
    "course": "main",
    "activity": "strength",
    "places": [
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
      "gym"
    ]
  },
  {
    "id": "main-cable-arms-twelve",
    "title": "Arms at the cable station",
    "subtitle": "A low pulley, a high pulley, and light loads",
    "durationMin": 12,
    "intensity": "moderate",
    "course": "main",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "upperBody"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "main-kettlebell-steady-twelve",
    "title": "A steady kettlebell session",
    "subtitle": "A kettlebell, a pair of weights, and room to carry",
    "durationMin": 12,
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
    "id": "main-assisted-pull-twelve",
    "title": "Pull with a little assistance",
    "subtitle": "An assisted pull-up machine and cable station",
    "durationMin": 12,
    "intensity": "moderate",
    "course": "main",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "upperBody",
      "back"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "main-single-leg-strength-twelve",
    "title": "One leg at a time",
    "subtitle": "A light dumbbell and a support within reach",
    "durationMin": 12,
    "intensity": "moderate",
    "course": "main",
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
      "strengthen"
    ],
    "equipment": [
      "weights"
    ]
  },
  {
    "id": "main-floor-strength-twelve",
    "title": "A small floor strength circuit",
    "subtitle": "Slow repetitions with space to recover",
    "durationMin": 12,
    "intensity": "moderate",
    "course": "main",
    "activity": "strength",
    "places": [
      "home",
      "gym"
    ],
    "bodyFocus": [
      "full",
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
    "id": "main-cable-hips-core-twelve",
    "title": "Hips and core at the cables",
    "subtitle": "A rope attachment and a single handle",
    "durationMin": 12,
    "intensity": "moderate",
    "course": "main",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "hips",
      "core"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "main-dumbbell-shoulders-twelve",
    "title": "Shoulders and upper back",
    "subtitle": "Light dumbbells, with a pause between moves",
    "durationMin": 12,
    "intensity": "moderate",
    "course": "main",
    "activity": "strength",
    "places": [
      "home",
      "gym"
    ],
    "bodyFocus": [
      "neckShoulders",
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
    "id": "main-upper-push-twenty",
    "title": "Twenty minutes of pushing",
    "subtitle": "A bench, cables, and an assisted-dip machine",
    "durationMin": 20,
    "intensity": "moderate",
    "course": "main",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "upperBody"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "main-upper-pull-fifteen",
    "title": "Pull, row, and reset",
    "subtitle": "A barbell, dumbbell bench, fixed bar, and pull-up station",
    "durationMin": 15,
    "intensity": "moderate",
    "course": "main",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "back",
      "upperBody"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "side-pull-up-practice-ten",
    "title": "Ten minutes at the pull-up bar",
    "subtitle": "For familiar pull-ups, with generous recovery",
    "durationMin": 10,
    "intensity": "dynamic",
    "course": "side",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "upperBody",
      "back"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "main-barbell-lower-twenty",
    "title": "A steady lower-body barbell session",
    "subtitle": "Light loads, rack safeties, a bench, and time to reset",
    "durationMin": 20,
    "intensity": "moderate",
    "course": "main",
    "activity": "strength",
    "places": [
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
      "gym"
    ]
  },
  {
    "id": "side-band-bench-legs-eight",
    "title": "Eight minutes for your legs",
    "subtitle": "A loop band, low bench, and clear walking space",
    "durationMin": 8,
    "intensity": "moderate",
    "course": "side",
    "activity": "strength",
    "places": [
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
      "gym"
    ]
  },
  {
    "id": "main-core-four-moves-ten",
    "title": "Four ways to work your core",
    "subtitle": "A secure hanging bar, light dumbbell, and floor space",
    "durationMin": 10,
    "intensity": "moderate",
    "course": "main",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "core"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "side-back-line-five",
    "title": "Five minutes for your back",
    "subtitle": "A back-extension bench and a comfortable floor space",
    "durationMin": 5,
    "intensity": "moderate",
    "course": "side",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "back"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "side-bodyweight-energy-eight",
    "title": "An eight-minute energy break",
    "subtitle": "Short bursts with time to catch your breath",
    "durationMin": 8,
    "intensity": "dynamic",
    "course": "side",
    "activity": "agility",
    "places": [
      "home",
      "gym"
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
    "id": "main-swing-jump-ten",
    "title": "Swings, jumps, and room to recover",
    "subtitle": "A familiar kettlebell swing and small, controlled jumps",
    "durationMin": 10,
    "intensity": "dynamic",
    "course": "main",
    "activity": "agility",
    "places": [
      "home",
      "gym"
    ],
    "bodyFocus": [
      "full",
      "lowerBody"
    ],
    "intents": [
      "energize"
    ],
    "equipment": [
      "weights"
    ]
  },
  {
    "id": "side-rowing-eight",
    "title": "Eight minutes on the rowing machine",
    "subtitle": "Legs, then body, then arms; an unhurried rhythm",
    "durationMin": 8,
    "intensity": "moderate",
    "course": "side",
    "activity": "strength",
    "places": [
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
      "gym"
    ]
  },
  {
    "id": "side-elliptical-ten",
    "title": "An easy elliptical break",
    "subtitle": "A smooth pace with light resistance",
    "durationMin": 10,
    "intensity": "moderate",
    "course": "side",
    "activity": "strength",
    "places": [
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
      "gym"
    ]
  },
  {
    "id": "main-stairs-twelve",
    "title": "Twelve minutes on the stairs",
    "subtitle": "Slow steps, with the rails within reach",
    "durationMin": 12,
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
      "energize",
      "calm"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "main-cycle-steady-fifteen",
    "title": "A steady fifteen-minute bike ride",
    "subtitle": "On a stationary bike at home or the gym",
    "durationMin": 15,
    "intensity": "moderate",
    "course": "main",
    "activity": "biking",
    "places": [
      "home",
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
      "bike"
    ]
  },
  {
    "id": "main-pool-easy-twenty",
    "title": "Twenty easy minutes in the pool",
    "subtitle": "A familiar stroke, with breaks at the wall",
    "durationMin": 20,
    "intensity": "moderate",
    "course": "main",
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
    "id": "side-incline-walk-ten",
    "title": "Ten minutes of gentle incline",
    "subtitle": "A small incline and a comfortable speed",
    "durationMin": 10,
    "intensity": "moderate",
    "course": "side",
    "activity": "walking",
    "places": [
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
      "gym"
    ]
  },
  {
    "id": "main-walk-steady-fifteen",
    "title": "A fifteen-minute walking reset",
    "subtitle": "Around the block, indoors, or along a familiar route",
    "durationMin": 15,
    "intensity": "moderate",
    "course": "main",
    "activity": "walking",
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
    "id": "main-jog-reset-twenty",
    "title": "An easy jog with walking breaks",
    "subtitle": "Four short jogs with a walk between each",
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
    "id": "main-push-up-shapes",
    "title": "Three push-up shapes",
    "subtitle": "Floor space; keep every repetition controlled",
    "durationMin": 15,
    "intensity": "moderate",
    "course": "main",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "upperBody"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "side-side-to-side-push",
    "title": "Side-to-side pushing practice",
    "subtitle": "For familiar archer, typewriter, and sweeping push-ups",
    "durationMin": 10,
    "intensity": "dynamic",
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
    "id": "main-loaded-calisthenics",
    "title": "Familiar lifts with a little extra load",
    "subtitle": "Secure loading, parallel bars, and pull-up bars; bodyweight versions should already feel steady",
    "durationMin": 12,
    "intensity": "dynamic",
    "course": "main",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "upperBody"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "side-dip-variations",
    "title": "A short dip session",
    "subtitle": "A stable bench and parallel bars; keep the shoulder range comfortable",
    "durationMin": 8,
    "intensity": "moderate",
    "course": "side",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "upperBody"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "side-incline-press-pair",
    "title": "Two incline presses",
    "subtitle": "A rack with safeties, an incline bench, and dumbbells",
    "durationMin": 9,
    "intensity": "moderate",
    "course": "side",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "upperBody"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "side-decline-press-pair",
    "title": "Two decline presses",
    "subtitle": "A secured decline bench, barbell, dumbbells, and a spotter",
    "durationMin": 9,
    "intensity": "moderate",
    "course": "side",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "upperBody"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "side-close-grip-press",
    "title": "Close-grip bench and triceps",
    "subtitle": "Bench, rack safeties or spotter, and light bars",
    "durationMin": 9,
    "intensity": "moderate",
    "course": "side",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "upperBody"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "main-fly-and-press",
    "title": "Chest arcs and a guided press",
    "subtitle": "Flat and incline benches, dumbbells, cable stacks, and a Smith machine",
    "durationMin": 12,
    "intensity": "moderate",
    "course": "main",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "upperBody"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "main-dumbbell-shoulder-rotation",
    "title": "Press and lift with dumbbells",
    "subtitle": "Light dumbbells, a supportive seat, and a weight plate",
    "durationMin": 12,
    "intensity": "moderate",
    "course": "main",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "upperBody"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "main-guided-shoulder-lifts",
    "title": "Shoulder lifts at the gym",
    "subtitle": "Cable station, lateral-raise machine, and a light bar",
    "durationMin": 12,
    "intensity": "moderate",
    "course": "main",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "upperBody"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "main-landmine-press-and-drive",
    "title": "Presses with a little leg drive",
    "subtitle": "A landmine station and a light barbell; use a push press you know",
    "durationMin": 16,
    "intensity": "dynamic",
    "course": "main",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "upperBody"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "side-pike-press-practice",
    "title": "Pike pressing practice",
    "subtitle": "A stable low box and clear wall space; practise familiar positions",
    "durationMin": 10,
    "intensity": "dynamic",
    "course": "side",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "upperBody"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "main-handstand-press-practice",
    "title": "Handstand pressing practice",
    "subtitle": "For established handstands with a controlled exit; a clear wall and padded space",
    "durationMin": 12,
    "intensity": "dynamic",
    "course": "main",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "upperBody"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "main-rear-shoulder-weights",
    "title": "A little work for the rear shoulders",
    "subtitle": "Light dumbbells and a reverse pec-deck machine",
    "durationMin": 12,
    "intensity": "moderate",
    "course": "main",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "upperBody"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "side-shoulder-blade-floor",
    "title": "Slow shoulder-blade movements",
    "subtitle": "A stable bench and floor space",
    "durationMin": 8,
    "intensity": "moderate",
    "course": "side",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "back",
      "neckShoulders"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "main-curl-bar-variations",
    "title": "A few ways to curl a bar",
    "subtitle": "Light straight and EZ bars, a preacher pad, and an incline bench",
    "durationMin": 15,
    "intensity": "moderate",
    "course": "main",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "upperBody"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "main-curl-and-grip",
    "title": "Curls and a little grip work",
    "subtitle": "Incline bench, dumbbells, a cable rope, and a light bar",
    "durationMin": 15,
    "intensity": "moderate",
    "course": "main",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "upperBody"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "main-lying-triceps",
    "title": "Triceps with dumbbells",
    "subtitle": "A stable flat bench and light dumbbells",
    "durationMin": 15,
    "intensity": "moderate",
    "course": "main",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "upperBody"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "main-cable-and-overhead-triceps",
    "title": "Cable and overhead triceps",
    "subtitle": "A cable rope and a light dumbbell",
    "durationMin": 15,
    "intensity": "moderate",
    "course": "main",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "upperBody"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "main-hanging-control",
    "title": "Controlled hanging practice",
    "subtitle": "A secure bar, assisted-chin machine, and a step for entering and leaving",
    "durationMin": 12,
    "intensity": "moderate",
    "course": "main",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "back",
      "upperBody"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "side-pull-up-grip-practice",
    "title": "Pull-up grip practice",
    "subtitle": "Secure bars and an intact load-rated towel; use familiar grips",
    "durationMin": 10,
    "intensity": "dynamic",
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
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "main-l-sit-practice",
    "title": "L-sit practice",
    "subtitle": "Stable parallel bars and a pull-up bar; start with holds you already control",
    "durationMin": 12,
    "intensity": "dynamic",
    "course": "main",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "core",
      "upperBody"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "main-supported-rows",
    "title": "Rows with support",
    "subtitle": "A load-rated doorway bar, a strong towel, and a chest-supported row station",
    "durationMin": 12,
    "intensity": "moderate",
    "course": "main",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "back"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "main-dumbbell-and-cable-rows",
    "title": "Dumbbell and cable rows",
    "subtitle": "Dumbbells and seated and single-handle cable stations",
    "durationMin": 15,
    "intensity": "moderate",
    "course": "main",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "back"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "main-barbell-row-practice",
    "title": "Barbell row practice",
    "subtitle": "Barbell, landmine, and T-bar row stations; start light",
    "durationMin": 15,
    "intensity": "dynamic",
    "course": "main",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "back"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "main-pulldown-angles",
    "title": "Three pulldown angles",
    "subtitle": "High cable station and a long band on a secure high anchor",
    "durationMin": 12,
    "intensity": "moderate",
    "course": "main",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "back"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "main-supported-single-leg",
    "title": "Single-leg control with support",
    "subtitle": "Stable handles, a low box, and a padded landing for the free knee",
    "durationMin": 18,
    "intensity": "moderate",
    "course": "main",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "lowerBody"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "main-single-leg-squat-practice",
    "title": "Single-leg squat practice",
    "subtitle": "Familiar pistol and skater squats; keep a support nearby",
    "durationMin": 16,
    "intensity": "dynamic",
    "course": "main",
    "activity": "strength",
    "places": [
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
      "gym"
    ]
  },
  {
    "id": "side-wide-and-supported-squats",
    "title": "Wide and supported squat practice",
    "subtitle": "A sissy-squat station, squat wedge, and light dumbbell",
    "durationMin": 10,
    "intensity": "dynamic",
    "course": "side",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "lowerBody"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "main-squat-stations",
    "title": "Three squat stations",
    "subtitle": "Front-rack safeties, belt-squat machine, and hack-squat machine",
    "durationMin": 12,
    "intensity": "dynamic",
    "course": "main",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "lowerBody"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "main-dumbbell-lunge-directions",
    "title": "Dumbbell lunges in different directions",
    "subtitle": "Light dumbbells and clear space in front and beside you",
    "durationMin": 12,
    "intensity": "moderate",
    "course": "main",
    "activity": "strength",
    "places": [
      "home",
      "gym"
    ],
    "bodyFocus": [
      "lowerBody"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "weights"
    ]
  },
  {
    "id": "side-small-platform-leg-work",
    "title": "Leg work with a small platform",
    "subtitle": "A stable low step or box and light dumbbells",
    "durationMin": 8,
    "intensity": "moderate",
    "course": "side",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "lowerBody"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "side-landmine-lower-body",
    "title": "Lower body at the landmine",
    "subtitle": "A secure landmine attachment and a manageable load",
    "durationMin": 9,
    "intensity": "moderate",
    "course": "side",
    "activity": "strength",
    "places": [
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
      "gym"
    ]
  },
  {
    "id": "main-smith-squat-lunge",
    "title": "Squats and lunges on the Smith machine",
    "subtitle": "Smith machine safeties and a stable low bench",
    "durationMin": 21,
    "intensity": "dynamic",
    "course": "main",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "lowerBody"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "main-deadlift-stance-practice",
    "title": "Deadlift stance practice",
    "subtitle": "Barbell, trap bar, and dumbbells; use light loads for each stance",
    "durationMin": 12,
    "intensity": "dynamic",
    "course": "main",
    "activity": "strength",
    "places": [
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
      "gym"
    ]
  },
  {
    "id": "side-hinge-at-the-rack",
    "title": "Hinges at the rack",
    "subtitle": "A Smith machine and rack with adjustable safeties",
    "durationMin": 9,
    "intensity": "moderate",
    "course": "side",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "lowerBody",
      "back"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "main-loaded-bridges",
    "title": "Loaded bridges and hip thrusts",
    "subtitle": "Padded bar, dumbbell, stable bench, and Smith machine",
    "durationMin": 12,
    "intensity": "moderate",
    "course": "main",
    "activity": "strength",
    "places": [
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
      "gym"
    ]
  },
  {
    "id": "main-hip-extension-stations",
    "title": "Hip extension at the gym",
    "subtitle": "Back-extension bench, reverse-hyper machine, and kickback machine",
    "durationMin": 15,
    "intensity": "moderate",
    "course": "main",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "hips",
      "back"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "side-hamstring-machine-pair",
    "title": "A pair of hamstring machines",
    "subtitle": "Seated and lying leg-curl machines, adjusted to fit",
    "durationMin": 6,
    "intensity": "moderate",
    "course": "side",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "lowerBody"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "main-hamstring-control",
    "title": "Hamstring control practice",
    "subtitle": "A Nordic station, stability ball, sliders, and clear floor; use familiar short ranges",
    "durationMin": 12,
    "intensity": "dynamic",
    "course": "main",
    "activity": "strength",
    "places": [
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
      "gym"
    ]
  },
  {
    "id": "main-band-floor-hips",
    "title": "Floor work with a loop band",
    "subtitle": "A loop band, stable bench, and comfortable floor space",
    "durationMin": 21,
    "intensity": "moderate",
    "course": "main",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "hips"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "main-band-hip-directions",
    "title": "Three directions with a band",
    "subtitle": "Loop and long bands, a stable seat, and a secure low anchor",
    "durationMin": 18,
    "intensity": "moderate",
    "course": "main",
    "activity": "strength",
    "places": [
      "home",
      "gym"
    ],
    "bodyFocus": [
      "hips"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "band"
    ]
  },
  {
    "id": "main-cable-hip-directions",
    "title": "Three directions at the low pulley",
    "subtitle": "An ankle cuff, low cable station, and a support for balance",
    "durationMin": 21,
    "intensity": "moderate",
    "course": "main",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "hips"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "side-side-body-floor",
    "title": "A short side-body session",
    "subtitle": "A stable bench and floor space",
    "durationMin": 10,
    "intensity": "moderate",
    "course": "side",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "hips",
      "core"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "side-calf-stations",
    "title": "Calves at three stations",
    "subtitle": "Donkey-calf, seated-calf, and leg-press machines",
    "durationMin": 8,
    "intensity": "moderate",
    "course": "side",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "lowerBody"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "main-band-core-control",
    "title": "Core control with a band",
    "subtitle": "A long band and secure low and chest-height anchors",
    "durationMin": 18,
    "intensity": "moderate",
    "course": "main",
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
      "band"
    ]
  },
  {
    "id": "main-cable-core-control",
    "title": "Core control at the cables",
    "subtitle": "A cable station with a rope and single handle",
    "durationMin": 24,
    "intensity": "moderate",
    "course": "main",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "core"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "side-core-roll-and-curl",
    "title": "Roll and curl practice",
    "subtitle": "An ab wheel, decline bench, and light plate; use ranges you control",
    "durationMin": 10,
    "intensity": "dynamic",
    "course": "side",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "core"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "side-supported-knee-lifts",
    "title": "Supported knee and leg lifts",
    "subtitle": "A captain's chair, secure hanging bar, and stable bench",
    "durationMin": 8,
    "intensity": "moderate",
    "course": "side",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "core"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "main-floor-core-shapes",
    "title": "A few floor core shapes",
    "subtitle": "Floor space and a light plate or dumbbell",
    "durationMin": 15,
    "intensity": "moderate",
    "course": "main",
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
      "weights"
    ]
  },
  {
    "id": "side-dragon-flag-practice",
    "title": "Short dragon-flag practice",
    "subtitle": "A firmly anchored bench; for a progression you already control",
    "durationMin": 8,
    "intensity": "dynamic",
    "course": "side",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "core"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "side-hands-and-carry",
    "title": "Hands, wrists, and a short carry",
    "subtitle": "Light dumbbells, a light bar, a seat, and clear walking space",
    "durationMin": 8,
    "intensity": "moderate",
    "course": "side",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "upperBody"
    ],
    "intents": [
      "strengthen"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "side-floor-movement-break",
    "title": "A floor movement break",
    "subtitle": "Clear floor space; move slowly enough to keep your balance",
    "durationMin": 8,
    "intensity": "moderate",
    "course": "side",
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
    "id": "side-quick-footwork",
    "title": "A short footwork session",
    "subtitle": "An agility ladder or flat floor markers and space to move",
    "durationMin": 10,
    "intensity": "dynamic",
    "course": "side",
    "activity": "agility",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "energize"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "side-floor-power-practice",
    "title": "Short floor power practice",
    "subtitle": "For familiar explosive push-ups; clear nonslip floor",
    "durationMin": 10,
    "intensity": "dynamic",
    "course": "side",
    "activity": "agility",
    "places": [
      "home",
      "gym"
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
    "id": "side-rope-and-erg",
    "title": "Ropes and an easy erg rhythm",
    "subtitle": "Battle ropes, air bike, and ski ergometer",
    "durationMin": 10,
    "intensity": "moderate",
    "course": "side",
    "activity": "strength",
    "places": [
      "gym"
    ],
    "bodyFocus": [
      "full"
    ],
    "intents": [
      "energize"
    ],
    "equipment": [
      "gym"
    ]
  },
  {
    "id": "main-familiar-trail-twenty",
    "title": "Twenty minutes on a familiar trail",
    "subtitle": "An easy out-and-back with secure footing",
    "durationMin": 20,
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
      "energize",
      "calm"
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
      "Set the back-extension bench so the pad supports your upper thighs and your hips can bend freely. Secure your feet.",
      "Cross your arms over your chest and hinge forward slowly at your hips, keeping your back long.",
      "Lift your torso until it lines up with your legs, without arching past that line.",
      "Lower with control through a comfortable range."
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
  },
  {
    "id": "concentration-curl",
    "name": "Concentration curl",
    "aka": [],
    "instructions": [
      "Sit on a sturdy bench with your feet apart and a dumbbell in one hand.",
      "Rest the back of your upper arm against your inner thigh.",
      "Curl the weight toward your shoulder without moving your upper arm.",
      "Lower slowly, then repeat on the other side."
    ],
    "muscles": [
      "front of the upper arms"
    ]
  },
  {
    "id": "dumbbell-shrug",
    "name": "Dumbbell shrug",
    "aka": [],
    "instructions": [
      "Stand tall with a dumbbell at each side and your arms relaxed.",
      "Lift your shoulders straight toward your ears without rolling them.",
      "Pause briefly, keeping your head level.",
      "Lower your shoulders slowly."
    ],
    "muscles": [
      "upper back",
      "neck and shoulders"
    ]
  },
  {
    "id": "cable-curl",
    "name": "Cable curl",
    "aka": [],
    "instructions": [
      "Attach a straight bar to a low cable pulley and choose a light load.",
      "Stand facing the machine with your palms up and elbows beside your ribs.",
      "Curl the bar toward your shoulders without leaning back.",
      "Lower slowly until your arms are comfortably straight."
    ],
    "muscles": [
      "front of the upper arms"
    ]
  },
  {
    "id": "cable-pull-through",
    "name": "Cable pull-through",
    "aka": [],
    "instructions": [
      "Attach a rope to a low cable pulley and stand facing away from it.",
      "Hold the rope between your legs and step forward until the cable is taut.",
      "With soft knees, send your hips back while keeping your back long.",
      "Stand tall by bringing your hips forward; finish without leaning back."
    ],
    "muscles": [
      "glutes",
      "back of the thighs"
    ]
  },
  {
    "id": "cable-front-raise",
    "name": "Cable front raise",
    "aka": [],
    "instructions": [
      "Attach a short bar to a low pulley and stand facing away with the cable between your legs.",
      "Hold the bar with both hands, keeping your elbows softly bent and ribs over your hips.",
      "Raise the bar forward to shoulder height without swinging your torso.",
      "Lower slowly with control."
    ],
    "muscles": [
      "front of the shoulders"
    ]
  },
  {
    "id": "cable-rear-delt-fly",
    "name": "Cable rear delt fly",
    "aka": [],
    "instructions": [
      "Set two pulleys just above shoulder height and stand between them.",
      "Take the left cable in your right hand and the right cable in your left hand.",
      "With softly bent elbows, open your arms out to the sides without shrugging.",
      "Return slowly, keeping your torso still."
    ],
    "muscles": [
      "back of the shoulders",
      "upper back"
    ]
  },
  {
    "id": "archer-push-up",
    "name": "Archer push up",
    "aka": [],
    "instructions": [
      "Start in a plank with your hands wider than your shoulders.",
      "Bend one elbow and shift your chest toward that hand, keeping the other arm long.",
      "Press back to the middle and alternate sides, keeping your hips level."
    ],
    "muscles": [
      "chest",
      "back of the upper arms",
      "shoulders"
    ]
  },
  {
    "id": "diamond-push-up",
    "name": "Diamond push up",
    "aka": [],
    "instructions": [
      "Set your hands close together beneath your chest, making a small diamond with your thumbs and fingers.",
      "Lower your chest while keeping your elbows near your ribs.",
      "Press up without letting your hips sag; use a smaller range if needed."
    ],
    "muscles": [
      "chest",
      "back of the upper arms",
      "shoulders"
    ]
  },
  {
    "id": "wide-push-up",
    "name": "Wide push up",
    "aka": [],
    "instructions": [
      "Start in a plank with hands a little wider than your shoulders.",
      "Bend your elbows and lower your chest with your body in a line.",
      "Press evenly through both hands to return."
    ],
    "muscles": [
      "chest",
      "back of the upper arms",
      "shoulders"
    ]
  },
  {
    "id": "decline-push-up",
    "name": "Decline push up",
    "aka": [],
    "instructions": [
      "Place your feet on a stable low bench and your hands on the floor.",
      "Lower your chest with your ribs and hips moving together.",
      "Press back up without dropping your lower back."
    ],
    "muscles": [
      "chest",
      "back of the upper arms",
      "shoulders"
    ]
  },
  {
    "id": "explosive-push-up",
    "name": "Explosive push up",
    "aka": [],
    "instructions": [
      "Start in a strong plank on a clear, nonslip floor; use this only if forceful push-ups are familiar.",
      "Lower with control, then push hard enough for your hands to leave the floor briefly.",
      "Land with soft elbows, reset your plank, and stop before your landings lose control."
    ],
    "muscles": [
      "chest",
      "back of the upper arms",
      "shoulders"
    ]
  },
  {
    "id": "weighted-push-up",
    "name": "Weighted push up",
    "aka": [],
    "instructions": [
      "Use a secure weighted vest or have a partner stabilize a light plate on your upper back, away from your neck.",
      "Lower your chest while keeping the load stable and your trunk straight.",
      "Press back up; stop immediately if the load shifts."
    ],
    "muscles": [
      "chest",
      "back of the upper arms",
      "shoulders"
    ]
  },
  {
    "id": "typewriter-push-up",
    "name": "Typewriter push up",
    "aka": [],
    "instructions": [
      "Take a wide-hand plank on a nonslip floor; use a range you already control.",
      "Lower toward one hand, then shift your chest toward the other hand while staying low.",
      "Press up and reset; alternate the side you start from."
    ],
    "muscles": [
      "chest",
      "back of the upper arms",
      "shoulders"
    ]
  },
  {
    "id": "hindu-push-up",
    "name": "Hindu push up",
    "aka": [],
    "instructions": [
      "Start with your hands and feet on the floor and your hips lifted.",
      "Bend your elbows and sweep your chest forward close to the floor, then lift your chest without forcing your back.",
      "Return your hips up to the starting shape in a controlled motion."
    ],
    "muscles": [
      "chest",
      "back of the upper arms",
      "shoulders"
    ]
  },
  {
    "id": "bench-dip",
    "name": "Bench dip",
    "aka": [],
    "instructions": [
      "Sit at the edge of a stable bench with your hands beside your hips, then move your hips just off the edge.",
      "Bend your elbows to lower a small amount, keeping your shoulders away from your ears.",
      "Press up without forcing a deep shoulder stretch; bend your knees to reduce the load."
    ],
    "muscles": [
      "chest",
      "back of the upper arms",
      "shoulders"
    ]
  },
  {
    "id": "dip",
    "name": "Dip",
    "aka": [],
    "instructions": [
      "Support yourself on secure parallel bars with your arms straight and shoulders steady.",
      "Bend your elbows and lower through a range your shoulders can control.",
      "Press back up without swinging your legs."
    ],
    "muscles": [
      "chest",
      "back of the upper arms",
      "shoulders"
    ]
  },
  {
    "id": "chest-dip",
    "name": "Chest dip",
    "aka": [],
    "instructions": [
      "Support yourself on parallel bars, leaning your torso forward slightly.",
      "Bend your elbows and lower only as far as feels comfortable at your shoulders.",
      "Press back to the starting position without bouncing."
    ],
    "muscles": [
      "chest",
      "back of the upper arms",
      "shoulders"
    ]
  },
  {
    "id": "weighted-dip",
    "name": "Weighted dip",
    "aka": [],
    "instructions": [
      "Attach a small load securely to a dip belt only if unweighted dips are already comfortable.",
      "Lower on parallel bars with control, keeping the hanging load still.",
      "Press back up and step down before fatigue changes your form."
    ],
    "muscles": [
      "chest",
      "back of the upper arms",
      "shoulders"
    ]
  },
  {
    "id": "close-grip-bench-press",
    "name": "Close grip bench press",
    "aka": [],
    "instructions": [
      "Lie on a flat bench with feet planted; use rack safeties or a spotter and a grip about shoulder width.",
      "Lower the bar toward your lower chest with your elbows near your sides.",
      "Press up smoothly while keeping your wrists stacked over your forearms."
    ],
    "muscles": [
      "chest",
      "back of the upper arms",
      "shoulders"
    ]
  },
  {
    "id": "incline-bench-press",
    "name": "Incline bench press",
    "aka": [],
    "instructions": [
      "Set a bench to a modest incline inside a rack, with safeties or a spotter.",
      "Lower the bar toward your upper chest while keeping your feet planted.",
      "Press up without lifting your hips or flaring your ribs."
    ],
    "muscles": [
      "chest",
      "back of the upper arms",
      "shoulders"
    ]
  },
  {
    "id": "decline-bench-press",
    "name": "Decline bench press",
    "aka": [],
    "instructions": [
      "Secure your legs on a decline bench and use a spotter or correctly set rack safeties.",
      "Lower the bar toward your lower chest, keeping your wrists over your elbows.",
      "Press up and rerack with control before getting out of the bench."
    ],
    "muscles": [
      "chest",
      "back of the upper arms",
      "shoulders"
    ]
  },
  {
    "id": "smith-machine-bench-press",
    "name": "Smith machine bench press",
    "aka": [],
    "instructions": [
      "Set a flat bench under the Smith bar and position the safety stops above your chest.",
      "Unlock the bar and lower it with your forearms roughly vertical.",
      "Press up, then rotate the hooks to secure the bar before leaving the bench."
    ],
    "muscles": [
      "chest",
      "back of the upper arms",
      "shoulders"
    ]
  },
  {
    "id": "dumbbell-fly",
    "name": "Dumbbell fly",
    "aka": [],
    "instructions": [
      "Lie on a flat bench with a light dumbbell in each hand above your chest.",
      "With a soft elbow bend, open your arms until your upper arms are near torso level.",
      "Bring the weights back together in an arc without changing your elbow bend."
    ],
    "muscles": [
      "chest",
      "back of the upper arms",
      "shoulders"
    ]
  },
  {
    "id": "incline-cable-fly",
    "name": "Incline cable fly",
    "aka": [],
    "instructions": [
      "Place an incline bench between two low pulleys and hold their handles above your chest.",
      "Open your arms slowly through a comfortable range, elbows softly bent.",
      "Bring the handles together over your upper chest without shrugging."
    ],
    "muscles": [
      "chest",
      "back of the upper arms",
      "shoulders"
    ]
  },
  {
    "id": "incline-dumbbell-press",
    "name": "Incline dumbbell press",
    "aka": [],
    "instructions": [
      "Sit on an incline bench with dumbbells at shoulder level and feet planted.",
      "Press both weights upward with your wrists over your elbows.",
      "Lower slowly beside your upper chest without flaring your ribs."
    ],
    "muscles": [
      "chest",
      "back of the upper arms",
      "shoulders"
    ]
  },
  {
    "id": "decline-dumbbell-press",
    "name": "Decline dumbbell press",
    "aka": [],
    "instructions": [
      "Secure yourself on a decline bench and bring two manageable dumbbells beside your chest.",
      "Press the weights up with your forearms vertical.",
      "Lower with control and get help handling the weights when entering or leaving the bench."
    ],
    "muscles": [
      "chest",
      "back of the upper arms",
      "shoulders"
    ]
  },
  {
    "id": "arnold-press",
    "name": "Arnold press",
    "aka": [],
    "instructions": [
      "Stand tall with light dumbbells in front of your shoulders, palms toward you.",
      "Press overhead while gradually turning your palms forward.",
      "Lower while reversing the turn, keeping your ribs down."
    ],
    "muscles": [
      "shoulders",
      "back of the upper arms"
    ]
  },
  {
    "id": "seated-dumbbell-press",
    "name": "Seated dumbbell press",
    "aka": [],
    "instructions": [
      "Sit against a supportive bench with feet planted and dumbbells beside your shoulders.",
      "Press overhead without leaning farther back.",
      "Lower slowly until the weights return to shoulder level."
    ],
    "muscles": [
      "shoulders",
      "back of the upper arms"
    ]
  },
  {
    "id": "landmine-press",
    "name": "Landmine press",
    "aka": [],
    "instructions": [
      "Secure a bar in a landmine attachment and hold the free end at one shoulder in a staggered stance.",
      "Press the bar upward and forward without twisting your ribs.",
      "Lower to your shoulder, then repeat on the other side."
    ],
    "muscles": [
      "shoulders",
      "back of the upper arms"
    ]
  },
  {
    "id": "push-press",
    "name": "Push press",
    "aka": [],
    "instructions": [
      "Hold a light bar at your shoulders with feet about hip width.",
      "Make a shallow knee dip, drive through your legs, and press the bar overhead.",
      "Lower to your shoulders with soft knees and reset before the next repetition."
    ],
    "muscles": [
      "shoulders",
      "back of the upper arms"
    ]
  },
  {
    "id": "pike-push-up",
    "name": "Pike push up",
    "aka": [],
    "instructions": [
      "Start with hands and feet on the floor, hips high, and head between your arms.",
      "Bend your elbows and lower your head toward a point slightly in front of your hands.",
      "Push the floor away to lift back up; keep the range controlled."
    ],
    "muscles": [
      "shoulders",
      "back of the upper arms"
    ]
  },
  {
    "id": "feet-elevated-pike-push-up",
    "name": "Feet elevated pike push up",
    "aka": [],
    "instructions": [
      "Place your feet on a secure low box and your hands on the floor, hips high.",
      "Bend your elbows to lower your head between and slightly ahead of your hands.",
      "Press back up, keeping weight through your palms rather than your head."
    ],
    "muscles": [
      "shoulders",
      "back of the upper arms"
    ]
  },
  {
    "id": "handstand-push-up",
    "name": "Handstand push up",
    "aka": [],
    "instructions": [
      "Use only a handstand you can already enter, balance, and exit safely, with a clear padded practice area.",
      "Bend your elbows through a small controlled range while maintaining your balance.",
      "Press tall again without resting weight on your head; come down before control fades."
    ],
    "muscles": [
      "shoulders",
      "back of the upper arms"
    ]
  },
  {
    "id": "wall-handstand-push-up",
    "name": "Wall handstand push up",
    "aka": [],
    "instructions": [
      "Use a familiar wall-supported handstand with hands on a nonslip surface and heels lightly touching the wall.",
      "Lower through a range you control, keeping your head clear of the floor.",
      "Press up without arching your back, then exit the handstand in control."
    ],
    "muscles": [
      "shoulders",
      "back of the upper arms"
    ]
  },
  {
    "id": "wall-walk",
    "name": "Wall walk",
    "aka": [],
    "instructions": [
      "Begin in a plank with your feet at a clear wall, using a setup and exit you already know.",
      "Walk your feet a little way up the wall as your hands move toward it.",
      "Reverse the steps slowly; stop at an angle where you can still keep your trunk steady."
    ],
    "muscles": [
      "shoulders",
      "back of the upper arms"
    ]
  },
  {
    "id": "plate-front-raise",
    "name": "Plate front raise",
    "aka": [],
    "instructions": [
      "Stand tall holding a light plate at its sides in front of your thighs.",
      "Raise it forward to shoulder height with a soft bend in your elbows.",
      "Lower slowly without leaning back or swinging."
    ],
    "muscles": [
      "shoulders",
      "back of the upper arms"
    ]
  },
  {
    "id": "cable-lateral-raise",
    "name": "Cable lateral raise",
    "aka": [],
    "instructions": [
      "Stand between low pulleys and hold the handles with arms by your sides.",
      "Lift your arms outward to about shoulder height, elbows softly bent.",
      "Lower slowly without shrugging or swaying."
    ],
    "muscles": [
      "shoulders",
      "back of the upper arms"
    ]
  },
  {
    "id": "machine-lateral-raise",
    "name": "Machine lateral raise",
    "aka": [],
    "instructions": [
      "Adjust the seat so the machine pads sit comfortably against your upper arms.",
      "Raise your arms sideways toward shoulder height.",
      "Lower the pads slowly, keeping your shoulders relaxed."
    ],
    "muscles": [
      "shoulders",
      "back of the upper arms"
    ]
  },
  {
    "id": "upright-row",
    "name": "Upright row",
    "aka": [],
    "instructions": [
      "Hold a light bar in front of your thighs with a comfortable, moderately wide grip.",
      "Draw the bar upward close to your body, stopping before your elbows rise above shoulder height.",
      "Lower smoothly; use a smaller range if your shoulders feel crowded."
    ],
    "muscles": [
      "shoulders",
      "back of the upper arms"
    ]
  },
  {
    "id": "bent-over-rear-delt-raise",
    "name": "Bent-over rear delt raise",
    "aka": [],
    "instructions": [
      "Hold light dumbbells and hinge forward with soft knees and a long back.",
      "Open your arms out to the sides with softly bent elbows.",
      "Lower slowly without lifting your torso."
    ],
    "muscles": [
      "upper back",
      "back of the shoulders"
    ]
  },
  {
    "id": "rear-delt-fly",
    "name": "Standing rear delt fly",
    "aka": [],
    "instructions": [
      "Stand holding light dumbbells and hinge at your hips until your chest faces the floor.",
      "Raise the weights out to the sides, keeping your neck in line with your back.",
      "Return slowly without swinging the weights."
    ],
    "muscles": [
      "upper back",
      "back of the shoulders"
    ]
  },
  {
    "id": "reverse-pec-deck",
    "name": "Reverse pec deck",
    "aka": [],
    "instructions": [
      "Sit facing the chest pad and adjust the handles to shoulder height.",
      "Open your arms out and back while keeping your chest against the pad.",
      "Return slowly without shrugging."
    ],
    "muscles": [
      "upper back",
      "back of the shoulders"
    ]
  },
  {
    "id": "prone-t-raise",
    "name": "Prone t raise",
    "aka": [],
    "instructions": [
      "Lie face down on a stable bench with arms hanging and very light weights if desired.",
      "Raise your arms out to the sides into a T shape while keeping your head neutral.",
      "Lower slowly without arching your back."
    ],
    "muscles": [
      "upper back",
      "back of the shoulders"
    ]
  },
  {
    "id": "prone-y-raise",
    "name": "Prone y raise",
    "aka": [],
    "instructions": [
      "Lie face down on the floor with your arms reaching diagonally overhead.",
      "Lift your arms slightly into a Y shape without lifting your chin.",
      "Lower slowly and keep your ribs supported on the floor."
    ],
    "muscles": [
      "upper back",
      "back of the shoulders"
    ]
  },
  {
    "id": "reverse-snow-angel",
    "name": "Reverse snow angel",
    "aka": [],
    "instructions": [
      "Lie face down with arms by your sides and forehead hovering just above the floor.",
      "Lift your hands slightly and sweep your arms out and overhead through a comfortable arc.",
      "Reverse the sweep without raising your chest or shrugging."
    ],
    "muscles": [
      "upper back",
      "back of the shoulders"
    ]
  },
  {
    "id": "scapular-push-up",
    "name": "Scapular push up",
    "aka": [],
    "instructions": [
      "Hold a plank with your elbows straight and hands under your shoulders.",
      "Let your chest lower slightly between your shoulder blades, then push the floor away to spread them.",
      "Keep your elbows straight and your hips still throughout."
    ],
    "muscles": [
      "upper back",
      "back of the shoulders"
    ]
  },
  {
    "id": "shrug",
    "name": "Barbell shrug",
    "aka": [],
    "instructions": [
      "Stand holding a bar in front of your thighs with arms straight.",
      "Lift your shoulders straight upward without rolling them or bending your elbows.",
      "Lower slowly and keep your head level."
    ],
    "muscles": [
      "upper back",
      "back of the shoulders"
    ]
  },
  {
    "id": "drag-curl",
    "name": "Drag curl",
    "aka": [],
    "instructions": [
      "Stand with an underhand grip on a light bar, arms long at your sides.",
      "Slide the bar close to your torso as your elbows move a little behind you.",
      "Lower along the same path without leaning back."
    ],
    "muscles": [
      "front of the upper arms",
      "forearms"
    ]
  },
  {
    "id": "ez-bar-curl",
    "name": "EZ-bar curl",
    "aka": [],
    "instructions": [
      "Stand holding the angled grips of an EZ bar with your palms facing mostly up.",
      "Curl toward your shoulders while keeping your elbows near your sides.",
      "Lower slowly without swinging your torso."
    ],
    "muscles": [
      "front of the upper arms",
      "forearms"
    ]
  },
  {
    "id": "incline-dumbbell-curl",
    "name": "Incline dumbbell curl",
    "aka": [],
    "instructions": [
      "Sit against an incline bench with a dumbbell in each hand and arms hanging.",
      "Curl the weights without moving your upper arms forward.",
      "Lower slowly through a comfortable elbow range."
    ],
    "muscles": [
      "front of the upper arms",
      "forearms"
    ]
  },
  {
    "id": "preacher-curl",
    "name": "Preacher curl",
    "aka": [],
    "instructions": [
      "Adjust the preacher bench so your upper arms rest fully on its pad.",
      "Curl a light bar toward your shoulders without lifting your arms off the pad.",
      "Lower gently, stopping short of forcing your elbows straight."
    ],
    "muscles": [
      "front of the upper arms",
      "forearms"
    ]
  },
  {
    "id": "spider-curl",
    "name": "Spider curl",
    "aka": [],
    "instructions": [
      "Lie chest down on an incline bench with your arms hanging and a light bar in your hands.",
      "Curl the bar without moving your upper arms.",
      "Lower slowly while your chest stays supported."
    ],
    "muscles": [
      "front of the upper arms",
      "forearms"
    ]
  },
  {
    "id": "reverse-curl",
    "name": "Reverse curl",
    "aka": [],
    "instructions": [
      "Stand holding a light bar with palms facing down and elbows by your sides.",
      "Curl upward without bending your wrists back.",
      "Lower slowly and keep your grip comfortable."
    ],
    "muscles": [
      "front of the upper arms",
      "forearms"
    ]
  },
  {
    "id": "rope-hammer-curl",
    "name": "Rope hammer curl",
    "aka": [],
    "instructions": [
      "Attach a rope to a low pulley and hold its ends with palms facing each other.",
      "Curl the rope toward your shoulders with your upper arms still.",
      "Lower slowly until your elbows are comfortably straight."
    ],
    "muscles": [
      "front of the upper arms",
      "forearms"
    ]
  },
  {
    "id": "skull-crusher",
    "name": "Skull crusher",
    "aka": [],
    "instructions": [
      "Lie on a flat bench with a light bar above your chest and use a spotter when handling it.",
      "Bend at your elbows to bring the bar toward the space just behind your head.",
      "Straighten your elbows without swinging your upper arms."
    ],
    "muscles": [
      "back of the upper arms"
    ]
  },
  {
    "id": "dumbbell-skull-crusher",
    "name": "Dumbbell skull crusher",
    "aka": [],
    "instructions": [
      "Lie on a flat bench with a dumbbell in each hand above your shoulders, palms facing each other.",
      "Bend your elbows to lower the weights beside your head.",
      "Straighten your elbows slowly without flaring them widely."
    ],
    "muscles": [
      "back of the upper arms"
    ]
  },
  {
    "id": "single-dumbbell-skullcrusher",
    "name": "Single-dumbbell skull crusher",
    "aka": [],
    "instructions": [
      "Lie on a flat bench holding one dumbbell securely with both hands above your chest.",
      "Bend your elbows and lower the weight toward the space behind your head.",
      "Extend your elbows without letting your upper arms swing."
    ],
    "muscles": [
      "back of the upper arms"
    ]
  },
  {
    "id": "overhead-tricep-extension",
    "name": "Cable overhead tricep extension",
    "aka": [],
    "instructions": [
      "Face away from a cable station with a rope handle held behind your head.",
      "Keep your upper arms near your ears and straighten your elbows against the cable.",
      "Bend your elbows slowly to return without arching your back."
    ],
    "muscles": [
      "back of the upper arms"
    ]
  },
  {
    "id": "single-arm-dumbbell-tricep-extension",
    "name": "Single arm dumbbell tricep extension",
    "aka": [],
    "instructions": [
      "Stand tall holding a light dumbbell overhead in one hand.",
      "Bend your elbow to lower the weight behind your head while keeping your upper arm steady.",
      "Straighten the elbow, then repeat on the other side."
    ],
    "muscles": [
      "back of the upper arms"
    ]
  },
  {
    "id": "rope-tricep-pushdown",
    "name": "Rope tricep pushdown",
    "aka": [],
    "instructions": [
      "Face a high pulley and hold the rope ends with elbows beside your ribs.",
      "Straighten your elbows to press the rope down, separating its ends slightly.",
      "Let the rope rise slowly without letting your elbows drift forward."
    ],
    "muscles": [
      "back of the upper arms"
    ]
  },
  {
    "id": "tricep-kickback",
    "name": "Tricep kickback",
    "aka": [],
    "instructions": [
      "Support one hand and knee on a bench, holding a light dumbbell with your other elbow bent beside your ribs.",
      "Straighten the working elbow so the weight moves behind you.",
      "Bend the elbow slowly, keeping the upper arm still; repeat on the other side."
    ],
    "muscles": [
      "back of the upper arms"
    ]
  },
  {
    "id": "active-hang",
    "name": "Active hang",
    "aka": [],
    "instructions": [
      "Grip a secure pull-up bar and use a step to enter the hang.",
      "With elbows straight, draw your shoulders gently down away from your ears.",
      "Hold briefly while breathing, then return to the step before your grip tires."
    ],
    "muscles": [
      "upper back",
      "front of the upper arms",
      "grip"
    ]
  },
  {
    "id": "scapular-pull-up",
    "name": "Scapular pull up",
    "aka": [],
    "instructions": [
      "Hang from a secure bar with straight elbows and a step within reach.",
      "Draw your shoulder blades down to lift your body slightly without bending your elbows.",
      "Return slowly to the longer hang and step down when needed."
    ],
    "muscles": [
      "upper back",
      "front of the upper arms",
      "grip"
    ]
  },
  {
    "id": "assisted-chin-up",
    "name": "Assisted chin up",
    "aka": [],
    "instructions": [
      "Set an assisted pull-up machine to a comfortable counterweight and grip with palms toward you.",
      "Pull your chest upward without swinging your legs or shrugging.",
      "Lower slowly and dismount using the machine steps."
    ],
    "muscles": [
      "upper back",
      "front of the upper arms",
      "grip"
    ]
  },
  {
    "id": "negative-pull-up",
    "name": "Negative pull up",
    "aka": [],
    "instructions": [
      "Use a sturdy step to reach the top of a pull-up with your chin above a secure bar.",
      "Lift your feet from the step and lower slowly until your elbows are straight.",
      "Return to the step to reset instead of jumping into the next repetition."
    ],
    "muscles": [
      "upper back",
      "front of the upper arms",
      "grip"
    ]
  },
  {
    "id": "neutral-grip-pull-up",
    "name": "Neutral grip pull up",
    "aka": [],
    "instructions": [
      "Grip parallel pull-up handles with palms facing each other.",
      "Pull up smoothly while keeping your legs still.",
      "Lower with control and step down before your grip fails."
    ],
    "muscles": [
      "upper back",
      "front of the upper arms",
      "grip"
    ]
  },
  {
    "id": "commando-pull-up",
    "name": "Commando pull up",
    "aka": [],
    "instructions": [
      "Stand beneath a secure bar and grip it with one hand just in front of the other.",
      "Pull up so your head passes to one side of the bar without twisting your neck.",
      "Lower, then use the other side of the bar; reverse your hand order between sets."
    ],
    "muscles": [
      "upper back",
      "front of the upper arms",
      "grip"
    ]
  },
  {
    "id": "l-sit-pull-up",
    "name": "L-sit pull-up",
    "aka": [],
    "instructions": [
      "Hang from a secure bar and raise your straight legs in front, using this only if both positions are familiar.",
      "Hold the legs steady while pulling your upper body toward the bar.",
      "Lower slowly and step down before your trunk or grip loses control."
    ],
    "muscles": [
      "upper back",
      "front of the upper arms",
      "grip"
    ]
  },
  {
    "id": "weighted-pull-up",
    "name": "Weighted pull up",
    "aka": [],
    "instructions": [
      "Attach a small load securely to a dip belt only when bodyweight pull-ups are well controlled.",
      "With palms away, pull without kicking or swinging the load.",
      "Lower smoothly and use a step to dismount."
    ],
    "muscles": [
      "upper back",
      "front of the upper arms",
      "grip"
    ]
  },
  {
    "id": "weighted-chin-up",
    "name": "Weighted chin up",
    "aka": [],
    "instructions": [
      "Secure a small load to a dip belt and grip the bar with palms toward you.",
      "Pull upward with a steady trunk and no swinging.",
      "Lower with control, then return to a step before releasing the bar."
    ],
    "muscles": [
      "upper back",
      "front of the upper arms",
      "grip"
    ]
  },
  {
    "id": "towel-pull-up",
    "name": "Towel pull up",
    "aka": [],
    "instructions": [
      "Drape a strong intact towel over a load-rated pull-up bar and grip both hanging ends.",
      "Pull up while keeping the towel and your legs steady.",
      "Lower slowly and step down before your grip slips."
    ],
    "muscles": [
      "upper back",
      "front of the upper arms",
      "grip"
    ]
  },
  {
    "id": "doorway-row",
    "name": "Doorway row",
    "aka": [],
    "instructions": [
      "Use a securely installed, load-rated doorway bar at chest height; do not rely on decorative trim.",
      "Lean back with feet planted and pull your chest toward the bar.",
      "Straighten your arms slowly while keeping your body in a line."
    ],
    "muscles": [
      "upper back",
      "front of the upper arms",
      "grip"
    ]
  },
  {
    "id": "towel-row",
    "name": "Towel row",
    "aka": [],
    "instructions": [
      "Sit with legs extended and loop a strong towel around the soles of both feet, holding an end in each hand.",
      "Gently pull your elbows back as your feet resist, keeping your spine tall.",
      "Ease the pull without jerking; keep the towel secure around your feet."
    ],
    "muscles": [
      "upper back",
      "front of the upper arms",
      "grip"
    ]
  },
  {
    "id": "chest-supported-row",
    "name": "Chest supported row",
    "aka": [],
    "instructions": [
      "Lie against the chest pad of a rowing bench or machine with feet supported.",
      "Pull the handles toward your lower ribs without lifting your chest off the pad.",
      "Lower slowly and allow your arms to lengthen."
    ],
    "muscles": [
      "upper back",
      "front of the upper arms",
      "grip"
    ]
  },
  {
    "id": "dumbbell-bent-over-row",
    "name": "Dumbbell bent over row",
    "aka": [],
    "instructions": [
      "Stand holding two dumbbells and hinge at your hips with soft knees.",
      "Pull both weights toward your hips while keeping your back long.",
      "Lower slowly without standing up between pulls."
    ],
    "muscles": [
      "upper back",
      "front of the upper arms",
      "grip"
    ]
  },
  {
    "id": "single-arm-cable-row",
    "name": "Single arm cable row",
    "aka": [],
    "instructions": [
      "Face a pulley near waist height and hold its handle in one hand with a staggered stance.",
      "Pull the handle toward your ribs without rotating your torso.",
      "Let your arm lengthen slowly, then change hands."
    ],
    "muscles": [
      "upper back",
      "front of the upper arms",
      "grip"
    ]
  },
  {
    "id": "seated-row",
    "name": "Seated row with a cable",
    "aka": [],
    "instructions": [
      "Sit facing a low cable pulley with feet supported and knees soft.",
      "Pull the handle toward your lower ribs while keeping your torso upright.",
      "Reach forward from your shoulders without rounding your lower back."
    ],
    "muscles": [
      "upper back",
      "front of the upper arms",
      "grip"
    ]
  },
  {
    "id": "pendlay-row",
    "name": "Pendlay row",
    "aka": [],
    "instructions": [
      "Stand over a bar on the floor and hinge until your torso is near horizontal with a long back.",
      "Pull the bar toward your lower ribs without snapping your torso upward.",
      "Return the bar to the floor and reset between repetitions."
    ],
    "muscles": [
      "upper back",
      "front of the upper arms",
      "grip"
    ]
  },
  {
    "id": "meadows-row",
    "name": "Meadows row",
    "aka": [],
    "instructions": [
      "Secure a bar in a landmine and stand side-on to the loaded end, bracing your free hand on your thigh.",
      "Hinge forward and row the sleeve toward your outer ribs with one hand.",
      "Lower slowly without twisting, then repeat on the other side."
    ],
    "muscles": [
      "upper back",
      "front of the upper arms",
      "grip"
    ]
  },
  {
    "id": "t-bar-row",
    "name": "T bar row",
    "aka": [],
    "instructions": [
      "Straddle the T-bar row machine, hinge at your hips, and take the handles with knees soft.",
      "Pull the handles toward your ribs while holding your torso steady.",
      "Lower with control rather than letting the plates drop."
    ],
    "muscles": [
      "upper back",
      "front of the upper arms",
      "grip"
    ]
  },
  {
    "id": "close-grip-lat-pulldown",
    "name": "Close grip lat pulldown",
    "aka": [],
    "instructions": [
      "Sit at a pulldown station with thighs secured and take the close parallel handle.",
      "Pull toward your upper chest without leaning far back.",
      "Let your arms lengthen slowly while keeping your shoulders comfortable."
    ],
    "muscles": [
      "upper back",
      "front of the upper arms",
      "grip"
    ]
  },
  {
    "id": "straight-arm-pulldown",
    "name": "Straight arm pulldown",
    "aka": [],
    "instructions": [
      "Face a high pulley holding a bar or rope with arms long and knees soft.",
      "Pull the handle in an arc toward your thighs without bending your elbows much.",
      "Return slowly without arching your lower back."
    ],
    "muscles": [
      "upper back",
      "front of the upper arms",
      "grip"
    ]
  },
  {
    "id": "banded-lat-pulldown",
    "name": "Banded lat pulldown",
    "aka": [],
    "instructions": [
      "Secure a long resistance band to a load-rated high anchor and kneel or sit beneath it.",
      "Draw your elbows down toward your sides without leaning back.",
      "Let your arms rise slowly while keeping tension controlled."
    ],
    "muscles": [
      "upper back",
      "front of the upper arms",
      "grip"
    ]
  },
  {
    "id": "assisted-pistol-squat",
    "name": "Assisted pistol squat",
    "aka": [],
    "instructions": [
      "Hold a secure support and stand on one leg with the other reaching forward.",
      "Sit down on the standing leg through a range you can control, using your hands for assistance.",
      "Press up through your whole foot, then repeat on the other side."
    ],
    "muscles": [
      "front of the thighs",
      "glutes"
    ]
  },
  {
    "id": "pistol-squat",
    "name": "Pistol squat",
    "aka": [],
    "instructions": [
      "Stand on one leg with the other reaching forward, using only a depth you already control.",
      "Bend the standing knee and lower your hips without dropping into the bottom.",
      "Stand back up with your heel grounded; change sides after your set."
    ],
    "muscles": [
      "front of the thighs",
      "glutes"
    ]
  },
  {
    "id": "single-leg-box-squat",
    "name": "Single leg box squat",
    "aka": [],
    "instructions": [
      "Stand in front of a stable box on one foot, other leg reaching forward.",
      "Sit back slowly until your hips touch the box without collapsing onto it.",
      "Push through the standing foot to rise, then switch legs."
    ],
    "muscles": [
      "front of the thighs",
      "glutes"
    ]
  },
  {
    "id": "shrimp-squat",
    "name": "Shrimp squat",
    "aka": [],
    "instructions": [
      "Hold a secure support with one hand and bend one knee behind you.",
      "Lower on the standing leg until the rear knee approaches a pad, keeping your balance.",
      "Press back up through the front foot, then repeat on the other side."
    ],
    "muscles": [
      "front of the thighs",
      "glutes"
    ]
  },
  {
    "id": "skater-squat",
    "name": "Skater squat",
    "aka": [],
    "instructions": [
      "Stand on one leg with the other knee bent behind you and a pad within reach of that knee.",
      "Sit back and bend the standing leg, letting the rear knee approach the pad.",
      "Stand up without pushing off the back foot, then switch legs."
    ],
    "muscles": [
      "front of the thighs",
      "glutes"
    ]
  },
  {
    "id": "sissy-squat",
    "name": "Sissy squat",
    "aka": [],
    "instructions": [
      "Use a purpose-built sissy-squat station with shins supported and feet secured, starting without added weight.",
      "Lean back as you bend your knees through a small familiar range, keeping hips extended.",
      "Return with control; do not force extra depth or bounce at the bottom."
    ],
    "muscles": [
      "front of the thighs",
      "glutes"
    ]
  },
  {
    "id": "cossack-squat",
    "name": "Cossack squat",
    "aka": [],
    "instructions": [
      "Take a wide stance with feet planted and hands in front of your chest.",
      "Shift your hips toward one foot as that knee bends and the other leg lengthens.",
      "Push back to the middle and alternate sides, keeping the working heel down."
    ],
    "muscles": [
      "front of the thighs",
      "glutes"
    ]
  },
  {
    "id": "front-squat",
    "name": "Front squat",
    "aka": [],
    "instructions": [
      "Set a bar in a front-rack position with elbows lifted and rack safeties in place.",
      "Bend your knees and hips together, keeping your torso upright and heels grounded.",
      "Stand up without dropping your elbows or collapsing your chest."
    ],
    "muscles": [
      "front of the thighs",
      "glutes"
    ]
  },
  {
    "id": "heel-elevated-goblet-squat",
    "name": "Heel elevated goblet squat",
    "aka": [],
    "instructions": [
      "Place both heels on a secure squat wedge and hold a dumbbell at your chest.",
      "Lower into a squat with knees tracking in the direction of your toes.",
      "Push through your feet to stand, keeping the wedge still."
    ],
    "muscles": [
      "front of the thighs",
      "glutes"
    ]
  },
  {
    "id": "belt-squat",
    "name": "Belt squat",
    "aka": [],
    "instructions": [
      "Fit the belt-squat machine belt around your hips and stand securely on its platform.",
      "Release the machine as instructed and squat through a comfortable range.",
      "Stand tall, then secure the load before taking the belt off."
    ],
    "muscles": [
      "front of the thighs",
      "glutes"
    ]
  },
  {
    "id": "hack-squat",
    "name": "Hack squat",
    "aka": [],
    "instructions": [
      "Set your back and shoulders against the machine pads with feet planted on its platform.",
      "Release the locks and lower by bending your knees, keeping your hips against the pad.",
      "Push back up without snapping your knees straight, then engage the locks before stepping out."
    ],
    "muscles": [
      "front of the thighs",
      "glutes"
    ]
  },
  {
    "id": "dumbbell-sumo-squat",
    "name": "Dumbbell sumo squat",
    "aka": [],
    "instructions": [
      "Stand wide with toes slightly turned out, holding one dumbbell between your legs.",
      "Bend your knees and hips together, keeping your chest lifted.",
      "Stand by pressing through both feet without letting your knees collapse inward."
    ],
    "muscles": [
      "front of the thighs",
      "glutes"
    ]
  },
  {
    "id": "dumbbell-curtsy-lunge",
    "name": "Dumbbell curtsy lunge",
    "aka": [],
    "instructions": [
      "Hold light dumbbells at your sides and stand with feet hip width.",
      "Step one foot diagonally behind you and lower into a shallow controlled lunge.",
      "Push through the front foot to stand and alternate legs."
    ],
    "muscles": [
      "front of the thighs",
      "glutes"
    ]
  },
  {
    "id": "dumbbell-lateral-lunge",
    "name": "Dumbbell lateral lunge",
    "aka": [],
    "instructions": [
      "Hold dumbbells at your sides and stand tall.",
      "Step sideways, sit into that hip, and keep the trailing leg long.",
      "Push off the working foot to return to the middle and alternate sides."
    ],
    "muscles": [
      "front of the thighs",
      "glutes"
    ]
  },
  {
    "id": "deficit-reverse-lunge",
    "name": "Deficit reverse lunge",
    "aka": [],
    "instructions": [
      "Stand on a secure low platform with a light dumbbell in each hand.",
      "Step one foot back onto the floor and bend both knees through a comfortable range.",
      "Drive through the front foot to return to the platform; alternate legs."
    ],
    "muscles": [
      "front of the thighs",
      "glutes"
    ]
  },
  {
    "id": "front-foot-elevated-split-squat",
    "name": "Front foot elevated split squat",
    "aka": [],
    "instructions": [
      "Place the front foot on a secure low platform with the other foot behind you; hold light dumbbells if comfortable.",
      "Bend both knees, lowering straight down without losing balance.",
      "Push through the front foot to rise, then repeat on the other side."
    ],
    "muscles": [
      "front of the thighs",
      "glutes"
    ]
  },
  {
    "id": "step-down",
    "name": "Step down",
    "aka": [],
    "instructions": [
      "Stand on a low stable step with one foot near its edge and a support within reach.",
      "Bend the standing knee until the free heel lightly touches the floor.",
      "Push through the foot on the step to rise, then change sides."
    ],
    "muscles": [
      "front of the thighs",
      "glutes"
    ]
  },
  {
    "id": "landmine-squat",
    "name": "Landmine squat",
    "aka": [],
    "instructions": [
      "Secure a bar in a landmine and hold its free end with both hands at your chest.",
      "Sit down into a squat while keeping your heels grounded.",
      "Stand smoothly and keep the bar close to your chest."
    ],
    "muscles": [
      "front of the thighs",
      "glutes"
    ]
  },
  {
    "id": "smith-machine-squat",
    "name": "Smith machine squat",
    "aka": [],
    "instructions": [
      "Position the Smith bar across your upper back and set safety stops for your chosen depth.",
      "Unlock the bar and squat with heels planted and knees following your toes.",
      "Stand up and lock the hooks before stepping away."
    ],
    "muscles": [
      "front of the thighs",
      "glutes"
    ]
  },
  {
    "id": "smith-machine-split-squat",
    "name": "Smith machine split squat",
    "aka": [],
    "instructions": [
      "Place the Smith bar across your upper back with safety stops set and feet in a split stance.",
      "Bend both knees to lower, keeping your front foot planted.",
      "Rise smoothly, secure the bar, and reset your stance for the other leg."
    ],
    "muscles": [
      "front of the thighs",
      "glutes"
    ]
  },
  {
    "id": "smith-machine-bulgarian-split-squat",
    "name": "Smith machine bulgarian split squat",
    "aka": [],
    "instructions": [
      "Set the Smith bar and safety stops, then rest your rear foot on a stable low bench.",
      "Bend the front leg through a range you control without twisting under the bar.",
      "Stand up, secure the hooks, and change sides."
    ],
    "muscles": [
      "front of the thighs",
      "glutes"
    ]
  },
  {
    "id": "smith-machine-reverse-lunge",
    "name": "Smith machine reverse lunge",
    "aka": [],
    "instructions": [
      "Stand under the Smith bar with safety stops set and your feet hip width.",
      "Step one leg back and bend both knees while keeping the front foot planted.",
      "Push through the front foot to stand and alternate legs; rerack before leaving."
    ],
    "muscles": [
      "front of the thighs",
      "glutes"
    ]
  },
  {
    "id": "sumo-deadlift",
    "name": "Sumo deadlift",
    "aka": [],
    "instructions": [
      "Stand over a bar with a wide stance, toes out slightly, and hands gripping inside your knees.",
      "Brace your trunk and push through the floor to stand with the bar close.",
      "Lower with control and reset on the floor without rounding your back."
    ],
    "muscles": [
      "glutes",
      "back of the thighs"
    ]
  },
  {
    "id": "trap-bar-deadlift",
    "name": "Trap bar deadlift",
    "aka": [],
    "instructions": [
      "Stand inside the trap bar and take its handles with knees bent and back long.",
      "Push through your feet to stand tall without leaning backward.",
      "Lower the bar by bending your hips and knees, then reset."
    ],
    "muscles": [
      "glutes",
      "back of the thighs"
    ]
  },
  {
    "id": "dumbbell-sumo-deadlift",
    "name": "Dumbbell sumo deadlift",
    "aka": [],
    "instructions": [
      "Stand wide holding a dumbbell in each hand between your legs.",
      "Hinge and bend your knees to lower the weights, keeping your back long.",
      "Push through your feet to stand without leaning back."
    ],
    "muscles": [
      "glutes",
      "back of the thighs"
    ]
  },
  {
    "id": "landmine-romanian-deadlift",
    "name": "Landmine romanian deadlift",
    "aka": [],
    "instructions": [
      "Secure a bar in a landmine and hold the free end with both hands in front of you.",
      "Soften your knees and send your hips back as the bar lowers close to your legs.",
      "Bring your hips forward to stand without rounding or overextending your back."
    ],
    "muscles": [
      "glutes",
      "back of the thighs"
    ]
  },
  {
    "id": "smith-machine-romanian-deadlift",
    "name": "Smith machine romanian deadlift",
    "aka": [],
    "instructions": [
      "Hold the Smith bar in front of your thighs and set safety stops below your intended range.",
      "With knees soft, send your hips back as the bar lowers along your legs.",
      "Stand tall using your hips and secure the bar before releasing it."
    ],
    "muscles": [
      "glutes",
      "back of the thighs"
    ]
  },
  {
    "id": "rack-pull",
    "name": "Rack pull",
    "aka": [],
    "instructions": [
      "Set a bar on rack safeties just below knee height and stand close to it.",
      "Brace your trunk and stand up with the bar, keeping it near your legs.",
      "Return the bar to the safeties gently and reset without bouncing."
    ],
    "muscles": [
      "glutes",
      "back of the thighs"
    ]
  },
  {
    "id": "barbell-glute-bridge",
    "name": "Barbell glute bridge",
    "aka": [],
    "instructions": [
      "Lie on your back with knees bent, feet flat, and a padded bar across your hips.",
      "Lift your hips until your thighs and torso line up without arching your back.",
      "Lower slowly and keep the bar steady with your hands."
    ],
    "muscles": [
      "glutes",
      "back of the thighs"
    ]
  },
  {
    "id": "dumbbell-glute-bridge",
    "name": "Dumbbell glute bridge",
    "aka": [],
    "instructions": [
      "Lie on your back with feet planted and a dumbbell resting securely across your hips.",
      "Lift your hips while keeping your ribs down.",
      "Lower slowly and hold the weight in place throughout."
    ],
    "muscles": [
      "glutes",
      "back of the thighs"
    ]
  },
  {
    "id": "smith-machine-hip-thrust",
    "name": "Smith machine hip thrust",
    "aka": [],
    "instructions": [
      "Place a stable bench behind you, pad the Smith bar over your hips, and set the stops.",
      "With upper back supported and feet planted, raise your hips until your torso and thighs line up.",
      "Lower with control, then lock the bar before moving out."
    ],
    "muscles": [
      "glutes",
      "back of the thighs"
    ]
  },
  {
    "id": "glute-focused-back-extension",
    "name": "Glute focused back extension",
    "aka": [],
    "instructions": [
      "Set a back-extension bench below your hip crease and secure your feet.",
      "Hinge forward, then lift your torso by extending your hips with a gentle glute squeeze.",
      "Stop when your body is in line and lower slowly without arching past that point."
    ],
    "muscles": [
      "glutes",
      "back of the thighs"
    ]
  },
  {
    "id": "reverse-hyperextension",
    "name": "Reverse hyperextension",
    "aka": [],
    "instructions": [
      "Lie face down on a reverse-hyperextension machine with your hips at the pad edge and hands gripping its handles.",
      "Raise your legs behind you through a small controlled arc without swinging.",
      "Lower slowly and keep your torso supported throughout."
    ],
    "muscles": [
      "glutes",
      "back of the thighs"
    ]
  },
  {
    "id": "lying-leg-curl",
    "name": "Lying leg curl",
    "aka": [],
    "instructions": [
      "Lie face down on the leg-curl machine with knees aligned to its pivot and the roller above your heels.",
      "Bend your knees to bring the roller toward your hips without lifting your pelvis.",
      "Straighten your knees slowly without letting the stack slam."
    ],
    "muscles": [
      "glutes",
      "back of the thighs"
    ]
  },
  {
    "id": "seated-leg-curl",
    "name": "Seated leg curl",
    "aka": [],
    "instructions": [
      "Adjust the seated leg-curl machine so knees align with its pivot and thighs are secured by the pad.",
      "Bend your knees to draw your heels down and back.",
      "Return slowly while keeping your hips against the seat."
    ],
    "muscles": [
      "glutes",
      "back of the thighs"
    ]
  },
  {
    "id": "nordic-hamstring-curl",
    "name": "Nordic hamstring curl",
    "aka": [],
    "instructions": [
      "Kneel on padding with your ankles secured in a purpose-built station and hands ready in front.",
      "Keeping hips extended, lean forward only as far as you can control.",
      "Catch yourself gently with your hands and use them to help return; start with a very short range."
    ],
    "muscles": [
      "glutes",
      "back of the thighs"
    ]
  },
  {
    "id": "stability-ball-hamstring-curl",
    "name": "Stability ball hamstring curl",
    "aka": [],
    "instructions": [
      "Lie on your back with heels on a stability ball and arms resting on the floor.",
      "Lift your hips and draw the ball toward you by bending your knees.",
      "Roll the ball away slowly without dropping or arching your hips, then lower to rest."
    ],
    "muscles": [
      "glutes",
      "back of the thighs"
    ]
  },
  {
    "id": "towel-hamstring-curl",
    "name": "Towel hamstring curl",
    "aka": [],
    "instructions": [
      "Lie on your back with heels on sliders or a folded towel on a smooth, clear floor.",
      "Lift your hips and slide your heels toward you by bending your knees.",
      "Slide out a short distance with control, then lower your hips to rest."
    ],
    "muscles": [
      "glutes",
      "back of the thighs"
    ]
  },
  {
    "id": "lying-hamstring-walkout",
    "name": "Lying hamstring walkout",
    "aka": [],
    "instructions": [
      "Lie on your back with knees bent and feet flat, then lift into a low bridge.",
      "Take tiny alternating heel steps away from your hips while keeping the pelvis level.",
      "Walk the heels back in and lower to rest before your back starts to arch."
    ],
    "muscles": [
      "glutes",
      "back of the thighs"
    ]
  },
  {
    "id": "machine-glute-kickback",
    "name": "Machine glute kickback",
    "aka": [],
    "instructions": [
      "Adjust the machine pad and brace your torso, placing one foot against its working platform.",
      "Press that leg back from the hip without twisting or arching your back.",
      "Return slowly and repeat on the other side."
    ],
    "muscles": [
      "glutes",
      "back of the thighs"
    ]
  },
  {
    "id": "banded-donkey-kick",
    "name": "Banded donkey kick",
    "aka": [],
    "instructions": [
      "Loop a band above your knees and start on hands and knees with your back level.",
      "Keep one knee bent and lift that thigh behind you without arching your back.",
      "Lower slowly and repeat on the other side."
    ],
    "muscles": [
      "glutes",
      "outer hips"
    ]
  },
  {
    "id": "banded-fire-hydrant",
    "name": "Banded fire hydrant",
    "aka": [],
    "instructions": [
      "Start on hands and knees with a loop band above both knees.",
      "Lift one bent knee out to the side without tipping your pelvis.",
      "Lower with control and repeat on the other side."
    ],
    "muscles": [
      "glutes",
      "outer hips"
    ]
  },
  {
    "id": "banded-frog-pump",
    "name": "Banded frog pump",
    "aka": [],
    "instructions": [
      "Lie on your back with a loop band above your knees, soles together and knees opened comfortably.",
      "Lift your hips a small distance while pressing gently outward into the band.",
      "Lower slowly and keep your ribs down."
    ],
    "muscles": [
      "glutes",
      "outer hips"
    ]
  },
  {
    "id": "banded-hip-thrust",
    "name": "Banded hip thrust",
    "aka": [],
    "instructions": [
      "Place a loop band above your knees and support your upper back on a stable bench.",
      "With feet flat, lift your hips and keep gentle outward pressure against the band.",
      "Lower without letting your knees collapse inward or your back arch."
    ],
    "muscles": [
      "glutes",
      "outer hips"
    ]
  },
  {
    "id": "banded-kickback",
    "name": "Banded kickback",
    "aka": [],
    "instructions": [
      "Attach a long band securely near floor height and loop it around one ankle; hold a support.",
      "Move the working leg backward from your hip without leaning or rotating.",
      "Bring the foot back slowly and switch legs."
    ],
    "muscles": [
      "glutes",
      "outer hips"
    ]
  },
  {
    "id": "banded-seated-hip-abduction",
    "name": "Banded seated hip abduction",
    "aka": [],
    "instructions": [
      "Sit tall on a stable seat with a loop band above your knees and feet planted.",
      "Open your knees against the band without rolling onto the edges of your feet.",
      "Bring the knees back slowly while keeping tension controlled."
    ],
    "muscles": [
      "glutes",
      "outer hips"
    ]
  },
  {
    "id": "banded-standing-hip-abduction",
    "name": "Banded standing hip abduction",
    "aka": [],
    "instructions": [
      "Stand with a loop band around your ankles and a support within reach.",
      "Move one leg sideways without leaning your torso or turning your toes upward.",
      "Return slowly and repeat on the other side."
    ],
    "muscles": [
      "glutes",
      "outer hips"
    ]
  },
  {
    "id": "cable-kickback",
    "name": "Cable kickback",
    "aka": [],
    "instructions": [
      "Attach an ankle cuff to a low pulley and hold the machine for balance.",
      "Move that leg behind you from the hip while keeping your back and pelvis still.",
      "Return slowly and switch legs."
    ],
    "muscles": [
      "glutes",
      "outer hips"
    ]
  },
  {
    "id": "cable-standing-hip-abduction",
    "name": "Cable standing hip abduction",
    "aka": [],
    "instructions": [
      "Stand side-on to a low pulley with an ankle cuff on the leg farther from the machine.",
      "Move the cuffed leg sideways away from the stack without leaning.",
      "Return with control, then change sides."
    ],
    "muscles": [
      "glutes",
      "outer hips"
    ]
  },
  {
    "id": "side-lying-hip-abduction",
    "name": "Side-lying hip abduction",
    "aka": [],
    "instructions": [
      "Lie on your side with hips stacked and the top leg long.",
      "Lift the top leg a short distance while keeping its toes facing forward.",
      "Lower slowly without rolling backward; repeat on the other side."
    ],
    "muscles": [
      "glutes",
      "outer hips"
    ]
  },
  {
    "id": "hip-airplane",
    "name": "Hip airplane",
    "aka": [],
    "instructions": [
      "Hold a stable support, stand on one leg, and hinge slightly forward with the other leg behind you.",
      "Rotate your pelvis gently open and closed while keeping the standing knee softly bent.",
      "Return upright and repeat on the other side without forcing the rotation."
    ],
    "muscles": [
      "glutes",
      "outer hips"
    ]
  },
  {
    "id": "cable-standing-hip-adduction",
    "name": "Cable standing hip adduction",
    "aka": [],
    "instructions": [
      "Stand side-on to a low pulley with a cuff on the ankle nearest the machine and hold a support.",
      "Draw the cuffed leg across in front of the standing leg without turning your hips.",
      "Return slowly and repeat on the other side."
    ],
    "muscles": [
      "inner thighs",
      "sides of the waist"
    ]
  },
  {
    "id": "copenhagen-plank",
    "name": "Copenhagen plank",
    "aka": [],
    "instructions": [
      "Lie on your side with your forearm on the floor and top leg supported on a sturdy bench; start with the knee supported if needed.",
      "Lift your hips into a side plank while keeping your shoulder above your elbow.",
      "Hold briefly, lower with control, and repeat on the other side."
    ],
    "muscles": [
      "inner thighs",
      "sides of the waist"
    ]
  },
  {
    "id": "donkey-calf-raise",
    "name": "Donkey calf raise",
    "aka": [],
    "instructions": [
      "Use a donkey-calf machine with its pad over your hips and forefeet on the platform.",
      "Keeping knees soft, raise your heels as high as you comfortably can.",
      "Lower your heels slowly without bouncing or shifting the pad."
    ],
    "muscles": [
      "calves"
    ]
  },
  {
    "id": "leg-press-calf-raise",
    "name": "Leg press calf raise",
    "aka": [],
    "instructions": [
      "Sit in a leg-press machine with safety stops set and the balls of your feet securely on the lower part of the platform.",
      "Keep your knees softly extended and press through your forefeet to lift your heels.",
      "Lower through a small controlled ankle range without letting your feet slip."
    ],
    "muscles": [
      "calves"
    ]
  },
  {
    "id": "seated-calf-raise",
    "name": "Seated calf raise",
    "aka": [],
    "instructions": [
      "Sit in a calf-raise machine with thighs under the pad and forefeet on its platform.",
      "Release the stop and lift your heels by pressing through your forefeet.",
      "Lower slowly, then secure the machine before getting up."
    ],
    "muscles": [
      "calves"
    ]
  },
  {
    "id": "banded-dead-bug",
    "name": "Banded dead bug",
    "aka": [],
    "instructions": [
      "Lie on your back with arms reaching upward and knees above your hips, holding a resistance band taut between your hands.",
      "Keep your ribs down as you extend one leg away, then bring it back.",
      "Alternate legs without letting your lower back lift from the floor."
    ],
    "muscles": [
      "deep core",
      "sides of the waist"
    ]
  },
  {
    "id": "banded-pallof-press",
    "name": "Band Pallof press",
    "aka": [],
    "instructions": [
      "Stand side-on to a band securely anchored at chest height, holding its ends at your chest.",
      "Press your hands forward while keeping your torso facing ahead.",
      "Bring your hands back slowly and repeat facing the other way."
    ],
    "muscles": [
      "deep core",
      "sides of the waist"
    ]
  },
  {
    "id": "banded-woodchop",
    "name": "Banded woodchop",
    "aka": [],
    "instructions": [
      "Secure a band to a low anchor and stand side-on with both hands holding it near that hip.",
      "Guide your hands diagonally across and upward while your hips and feet turn together.",
      "Return along the same path with control and repeat on the other side."
    ],
    "muscles": [
      "deep core",
      "sides of the waist"
    ]
  },
  {
    "id": "cable-pallof-hold",
    "name": "Cable Pallof hold",
    "aka": [],
    "instructions": [
      "Stand side-on to a cable at chest height and hold the handle in both hands.",
      "Press your arms forward and hold briefly without allowing the cable to rotate your torso.",
      "Bring your hands in to rest, then repeat on the other side."
    ],
    "muscles": [
      "deep core",
      "sides of the waist"
    ]
  },
  {
    "id": "cable-woodchop",
    "name": "Cable woodchop",
    "aka": [],
    "instructions": [
      "Set a cable pulley above shoulder height and stand side-on holding its handle in both hands.",
      "Draw the handle diagonally toward the opposite hip while allowing your feet and hips to turn together.",
      "Return slowly and repeat from the other side."
    ],
    "muscles": [
      "deep core",
      "sides of the waist"
    ]
  },
  {
    "id": "half-kneeling-pallof-press",
    "name": "Half-kneeling Pallof press",
    "aka": [],
    "instructions": [
      "Kneel on one knee beside a chest-height cable, holding its handle at your chest.",
      "Press both hands straight forward while keeping your pelvis and ribs facing ahead.",
      "Return slowly, then change your kneeling stance and direction."
    ],
    "muscles": [
      "deep core",
      "sides of the waist"
    ]
  },
  {
    "id": "ab-wheel",
    "name": "Ab wheel",
    "aka": [],
    "instructions": [
      "Kneel on padding with both hands on an ab wheel directly beneath your shoulders.",
      "Roll forward a short distance while keeping your ribs tucked and hips from sagging.",
      "Pull the wheel back toward your knees; stop before your lower back arches."
    ],
    "muscles": [
      "deep core",
      "sides of the waist"
    ]
  },
  {
    "id": "cable-crunch",
    "name": "Cable crunch",
    "aka": [],
    "instructions": [
      "Kneel facing a high pulley and hold a rope beside your temples.",
      "Curl your ribs toward your pelvis while keeping your hips relatively still.",
      "Uncurl slowly without pulling the rope with your arms."
    ],
    "muscles": [
      "deep core",
      "sides of the waist"
    ]
  },
  {
    "id": "captains-chair-knee-raise",
    "name": "Captains chair knee raise",
    "aka": [],
    "instructions": [
      "Support your forearms on the captain's-chair pads with your back against its support.",
      "Lift your knees toward your chest without swinging your body.",
      "Lower your legs slowly and step down to rest when needed."
    ],
    "muscles": [
      "deep core",
      "sides of the waist"
    ]
  },
  {
    "id": "hanging-leg-raise",
    "name": "Hanging leg raise",
    "aka": [],
    "instructions": [
      "Hang from a secure bar using a step to get into position.",
      "Raise your legs in front without swinging, bending your knees if needed to keep control.",
      "Lower slowly and step down before your grip tires."
    ],
    "muscles": [
      "deep core",
      "sides of the waist"
    ]
  },
  {
    "id": "decline-sit-up",
    "name": "Decline sit up",
    "aka": [],
    "instructions": [
      "Secure your legs on a shallow decline bench and cross your arms over your chest.",
      "Curl your torso upward without pulling on your neck.",
      "Lower slowly and use a shorter range if your back starts to arch."
    ],
    "muscles": [
      "deep core",
      "sides of the waist"
    ]
  },
  {
    "id": "dragon-flag",
    "name": "Dragon flag",
    "aka": [],
    "instructions": [
      "Lie on a stable bench and grip firmly behind your head; practice only a progression you already control.",
      "Lift your trunk and legs as one unit, bearing weight through your upper back rather than your neck.",
      "Lower a short distance with control, then return; bend your knees to shorten the lever."
    ],
    "muscles": [
      "deep core",
      "sides of the waist"
    ]
  },
  {
    "id": "hollow-rock",
    "name": "Hollow rock",
    "aka": [],
    "instructions": [
      "Lie on your back with ribs tucked, shoulders raised, and legs reaching away at a height you can hold.",
      "Rock gently along your rounded back while keeping the body shape steady.",
      "Rest when your lower back loses contact; bend your knees to make the shape shorter."
    ],
    "muscles": [
      "deep core",
      "sides of the waist"
    ]
  },
  {
    "id": "l-sit-hold",
    "name": "L-sit hold",
    "aka": [],
    "instructions": [
      "Support yourself on stable parallel bars with straight arms and shoulders pressed down.",
      "Lift your legs in front into an L shape, or bend your knees for a shorter hold.",
      "Lower your feet in control and rest between brief holds."
    ],
    "muscles": [
      "deep core",
      "sides of the waist"
    ]
  },
  {
    "id": "seated-knee-tuck",
    "name": "Seated knee tuck",
    "aka": [],
    "instructions": [
      "Sit on a stable bench edge with hands beside your hips and knees bent.",
      "Lean back slightly as you extend your legs, then draw your knees toward your chest.",
      "Move slowly without rounding your shoulders or letting your back collapse."
    ],
    "muscles": [
      "deep core",
      "sides of the waist"
    ]
  },
  {
    "id": "v-up",
    "name": "V up",
    "aka": [],
    "instructions": [
      "Lie on your back with arms overhead and legs extended.",
      "Lift your chest and legs toward each other, reaching toward your shins without pulling your neck.",
      "Lower with control, keeping a slight knee bend if that helps your back stay comfortable."
    ],
    "muscles": [
      "deep core",
      "sides of the waist"
    ]
  },
  {
    "id": "weighted-crunch",
    "name": "Weighted crunch",
    "aka": [],
    "instructions": [
      "Lie on your back with knees bent and hold a light plate against your chest.",
      "Curl your shoulders a short distance off the floor as your ribs move toward your pelvis.",
      "Lower slowly without pulling your head forward."
    ],
    "muscles": [
      "deep core",
      "sides of the waist"
    ]
  },
  {
    "id": "weighted-russian-twist",
    "name": "Weighted russian twist",
    "aka": [],
    "instructions": [
      "Sit with knees bent holding a light weight close to your chest; keep your feet down if needed.",
      "Turn your ribs gently from side to side, moving the weight with your torso.",
      "Keep the range small and controlled without rounding your lower back."
    ],
    "muscles": [
      "deep core",
      "sides of the waist"
    ]
  },
  {
    "id": "push-up-shoulder-tap",
    "name": "Push up shoulder tap",
    "aka": [],
    "instructions": [
      "Start in a plank with feet wider than hip width and hands under your shoulders.",
      "Perform a controlled push-up, then tap the opposite shoulder with one hand at a time.",
      "Keep your hips level, return both hands to the floor, and repeat slowly."
    ],
    "muscles": [
      "deep core",
      "sides of the waist"
    ]
  },
  {
    "id": "wrist-curl",
    "name": "Wrist curl",
    "aka": [],
    "instructions": [
      "Stand holding a light bar with palms facing forward and arms relaxed by your sides.",
      "Keeping your arms still, curl your wrists through a small comfortable range.",
      "Lower slowly without letting the bar roll out of your fingers."
    ],
    "muscles": [
      "forearms",
      "grip"
    ]
  },
  {
    "id": "wrist-extension",
    "name": "Wrist extension",
    "aka": [],
    "instructions": [
      "Sit with your forearms supported on your thighs, palms down and light dumbbells held just beyond your knees.",
      "Lift the backs of your hands by extending your wrists without moving your forearms.",
      "Lower slowly through a comfortable range."
    ],
    "muscles": [
      "forearms",
      "grip"
    ]
  },
  {
    "id": "farmer-carry",
    "name": "Farmer carry with two weights",
    "aka": [],
    "instructions": [
      "Stand holding a manageable weight in each hand with clear space to walk.",
      "Walk slowly with your shoulders relaxed and your torso upright.",
      "Turn with small steps and set the weights down before your grip tires."
    ],
    "muscles": [
      "forearms",
      "grip"
    ]
  },
  {
    "id": "crab-walk",
    "name": "Crab walk",
    "aka": [],
    "instructions": [
      "Sit with knees bent, feet flat, and hands behind you in a comfortable wrist position.",
      "Lift your hips slightly and take small steps with opposite hands and feet.",
      "Keep your shoulders comfortable and lower to the floor to rest."
    ],
    "muscles": [
      "full body",
      "legs",
      "shoulders"
    ]
  },
  {
    "id": "plank-jack",
    "name": "Plank jack",
    "aka": [],
    "instructions": [
      "Start in a plank with shoulders over your hands and a clear nonslip floor.",
      "Hop your feet apart and together while keeping your hips level.",
      "Land softly and stop the set before your trunk starts to sag."
    ],
    "muscles": [
      "full body",
      "legs",
      "shoulders"
    ]
  },
  {
    "id": "seal-jack",
    "name": "Seal jack",
    "aka": [],
    "instructions": [
      "Stand with feet together and arms reaching forward at chest height.",
      "Jump your feet apart as you open your arms sideways, then jump in as the arms meet in front.",
      "Land softly with knees bent and use a rhythm you can control."
    ],
    "muscles": [
      "full body",
      "legs",
      "shoulders"
    ]
  },
  {
    "id": "half-burpee",
    "name": "Half burpee",
    "aka": [],
    "instructions": [
      "Start standing on a clear nonslip floor, then bend down and place your hands beneath your shoulders.",
      "Step or hop your feet back to a plank, then bring them forward again.",
      "Stand up without adding a push-up or jump and repeat with control."
    ],
    "muscles": [
      "full body",
      "legs",
      "shoulders"
    ]
  },
  {
    "id": "squat-thrust",
    "name": "Squat thrust",
    "aka": [],
    "instructions": [
      "Crouch with hands planted beneath your shoulders and feet close to your hands.",
      "Step or hop both feet back to a plank, then bring them forward under your body.",
      "Stay low as you reset, keeping your back from sagging."
    ],
    "muscles": [
      "full body",
      "legs",
      "shoulders"
    ]
  },
  {
    "id": "sprawl",
    "name": "Sprawl",
    "aka": [],
    "instructions": [
      "Start standing with feet comfortably apart on a clear nonslip floor.",
      "Place your hands down, send your feet back to a wide plank, then bring them forward.",
      "Rise to stand without dropping your chest onto the floor; slow down as needed."
    ],
    "muscles": [
      "full body",
      "legs",
      "shoulders"
    ]
  },
  {
    "id": "fast-feet",
    "name": "Fast feet",
    "aka": [],
    "instructions": [
      "Stand beside a flat agility ladder or a clear line on the floor with knees softly bent.",
      "Take quick small alternating steps through the spaces while staying light on your feet.",
      "Slow down before turning and keep your gaze ahead rather than at your toes."
    ],
    "muscles": [
      "full body",
      "legs",
      "shoulders"
    ]
  },
  {
    "id": "battle-ropes",
    "name": "Battle ropes",
    "aka": [],
    "instructions": [
      "Anchor battle ropes securely and hold an end in each hand with knees softly bent.",
      "Make alternating waves with your arms while keeping your torso steady.",
      "Use short bouts and let the ropes settle before setting them down."
    ],
    "muscles": [
      "full body",
      "legs",
      "shoulders"
    ]
  },
  {
    "id": "assault-bike",
    "name": "Air bike",
    "aka": [],
    "instructions": [
      "Adjust the air-bike seat so your knees stay slightly bent at the bottom of each pedal stroke.",
      "Pedal while pushing and pulling the handles in a smooth rhythm.",
      "Reduce effort gradually before stopping and wait for the pedals to settle before stepping off."
    ],
    "muscles": [
      "full body",
      "legs",
      "shoulders"
    ]
  },
  {
    "id": "skierg",
    "name": "Ski ergometer",
    "aka": [],
    "instructions": [
      "Stand facing a ski ergometer with feet hip width and handles held above shoulder height.",
      "Pull down as you hinge slightly and bend your knees, finishing with hands beside your thighs.",
      "Rise smoothly while returning the handles upward without locking your knees."
    ],
    "muscles": [
      "full body",
      "legs",
      "shoulders"
    ]
  },
  {
    "id": "hiking",
    "name": "Hiking",
    "aka": [],
    "instructions": [
      "Choose a familiar trail, wear secure footwear, and start at an easy walking pace.",
      "Take short steady steps on slopes and watch your footing on uneven ground.",
      "Slow on descents, pause as needed, and choose a route you can comfortably return from."
    ],
    "muscles": [
      "full body",
      "legs",
      "shoulders"
    ]
  },
  {
    "id": "cat-cow-stretch",
    "name": "Cat-cow stretch",
    "aka": [],
    "instructions": [
      "Start on hands and knees with wrists under shoulders and knees under hips.",
      "Gently round your spine, then let your chest move forward into a small comfortable arch.",
      "Move slowly with your breath rather than forcing either end of the range."
    ],
    "muscles": [
      "back",
      "hips"
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
