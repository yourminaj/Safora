/// Alert priority levels used throughout the app.
enum AlertPriority {
  critical, // 🔴 Auto-trigger SOS, 30-sec siren
  high, // 🟠 Urgent alarm, notify contacts
  medium, // 🟡 Warning notification + vibration
  low, // 🟢 Silent notification + badge
}

/// Alert categories grouping the 127 risk types.
enum AlertCategory {
  healthMedical('Health & Medical', '🫀'),
  vehicleTransport('Vehicle & Transport', '🚗'),
  naturalDisaster('Natural Disasters', '🌍'),
  weatherEmergency('Weather Emergencies', '⛈️'),
  personalSafety('Personal Safety & Crime', '🛡️'),
  homeDomestic('Home & Domestic', '🏠'),
  workplace('Workplace Hazards', '👷'),
  waterMarine('Water & Marine', '🌊'),
  travelOutdoor('Travel & Outdoor', '🏔️'),
  environmentalChemical('Environmental & Chemical', '☢️'),
  digitalCyber('Digital & Cyber', '📱'),
  childElder('Child & Elder Safety', '👶');

  const AlertCategory(this.label, this.emoji);

  final String label;
  final String emoji;
}

/// All 127 risk types the app can detect and alert for.
///
/// Each type has a category, priority, and detection method.
enum AlertType {
  // ── Group 1: Health & Medical ──────────────────────────
  allergicReaction(
    label: 'Allergic Reaction',
    category: AlertCategory.healthMedical,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  asthmaAttack(
    label: 'Asthma Attack',
    category: AlertCategory.healthMedical,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  severebleeding(
    label: 'Severe Bleeding',
    category: AlertCategory.healthMedical,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  severeBurns(
    label: 'Severe Burns',
    category: AlertCategory.healthMedical,
    priority: AlertPriority.high,
    isFree: false,
  ),
  cardiacArrest(
    label: 'Cardiac Arrest',
    category: AlertCategory.healthMedical,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  choking(
    label: 'Choking',
    category: AlertCategory.healthMedical,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  dehydration(
    label: 'Severe Dehydration',
    category: AlertCategory.healthMedical,
    priority: AlertPriority.medium,
    isFree: false,
  ),
  diabeticCrisis(
    label: 'Diabetic Crisis',
    category: AlertCategory.healthMedical,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  drowningRisk(
    label: 'Drowning Risk',
    category: AlertCategory.healthMedical,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  drugOverdose(
    label: 'Drug Overdose',
    category: AlertCategory.healthMedical,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  epilepticSeizure(
    label: 'Epileptic Seizure',
    category: AlertCategory.healthMedical,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  fainting(
    label: 'Fainting / Syncope',
    category: AlertCategory.healthMedical,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  foodPoisoning(
    label: 'Food Poisoning',
    category: AlertCategory.healthMedical,
    priority: AlertPriority.high,
    isFree: false,
  ),
  heartAttack(
    label: 'Heart Attack',
    category: AlertCategory.healthMedical,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  heatStroke(
    label: 'Heat Stroke',
    category: AlertCategory.healthMedical,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  hypothermia(
    label: 'Hypothermia',
    category: AlertCategory.healthMedical,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  lowBloodPressure(
    label: 'Low Blood Pressure',
    category: AlertCategory.healthMedical,
    priority: AlertPriority.high,
    isFree: false,
  ),
  highBloodPressure(
    label: 'High Blood Pressure',
    category: AlertCategory.healthMedical,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  panicAttack(
    label: 'Panic Attack',
    category: AlertCategory.healthMedical,
    priority: AlertPriority.high,
    isFree: false,
  ),
  pregnancyEmergency(
    label: 'Pregnancy Emergency',
    category: AlertCategory.healthMedical,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  respiratoryFailure(
    label: 'Respiratory Failure',
    category: AlertCategory.healthMedical,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  snakeBite(
    label: 'Snake / Animal Bite',
    category: AlertCategory.healthMedical,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  stroke(
    label: 'Stroke',
    category: AlertCategory.healthMedical,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  sidsRisk(
    label: 'SIDS Risk',
    category: AlertCategory.healthMedical,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  unconsciousness(
    label: 'Unconsciousness',
    category: AlertCategory.healthMedical,
    priority: AlertPriority.critical,
    isFree: false,
  ),

  // ── Group 2: Vehicle & Transport ──────────────────────
  bicycleCrash(
    label: 'Bicycle Crash',
    category: AlertCategory.vehicleTransport,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  busAccident(
    label: 'Bus Accident',
    category: AlertCategory.vehicleTransport,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  carAccident(
    label: 'Car Accident',
    category: AlertCategory.vehicleTransport,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  cngAccident(
    label: 'CNG / Rickshaw Accident',
    category: AlertCategory.vehicleTransport,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  drowsyDriving(
    label: 'Drowsy Driving',
    category: AlertCategory.vehicleTransport,
    priority: AlertPriority.high,
    isFree: false,
  ),
  eScooterCrash(
    label: 'E-Scooter Crash',
    category: AlertCategory.vehicleTransport,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  hitAndRun(
    label: 'Hit and Run',
    category: AlertCategory.vehicleTransport,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  boatAccident(
    label: 'Boat Accident',
    category: AlertCategory.vehicleTransport,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  motorcycleCrash(
    label: 'Motorcycle Crash',
    category: AlertCategory.vehicleTransport,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  pedestrianHit(
    label: 'Pedestrian Hit',
    category: AlertCategory.vehicleTransport,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  trainAccident(
    label: 'Train Accident',
    category: AlertCategory.vehicleTransport,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  vehicleRollover(
    label: 'Vehicle Rollover',
    category: AlertCategory.vehicleTransport,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  seatbeltReminder(
    label: 'Seatbelt Reminder',
    category: AlertCategory.vehicleTransport,
    priority: AlertPriority.low,
    isFree: true,
  ),
  speedWarning(
    label: 'Speed Limit Warning',
    category: AlertCategory.vehicleTransport,
    priority: AlertPriority.medium,
    isFree: true,
  ),
  vehicleBreakdown(
    label: 'Vehicle Breakdown',
    category: AlertCategory.vehicleTransport,
    priority: AlertPriority.high,
    isFree: false,
  ),
  wrongWayDriving(
    label: 'Wrong-Way Driving',
    category: AlertCategory.vehicleTransport,
    priority: AlertPriority.critical,
    isFree: false,
  ),

  // ── Group 3: Natural Disasters ────────────────────────
  avalanche(
    label: 'Avalanche',
    category: AlertCategory.naturalDisaster,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  cyclone(
    label: 'Cyclone / Hurricane',
    category: AlertCategory.naturalDisaster,
    priority: AlertPriority.critical,
    isFree: true,
  ),
  drought(
    label: 'Drought Warning',
    category: AlertCategory.naturalDisaster,
    priority: AlertPriority.medium,
    isFree: false,
  ),
  earthquake(
    label: 'Earthquake',
    category: AlertCategory.naturalDisaster,
    priority: AlertPriority.critical,
    isFree: true,
  ),
  flood(
    label: 'Flood',
    category: AlertCategory.naturalDisaster,
    priority: AlertPriority.critical,
    isFree: true,
  ),
  hailstorm(
    label: 'Hailstorm',
    category: AlertCategory.naturalDisaster,
    priority: AlertPriority.high,
    isFree: false,
  ),
  landslide(
    label: 'Landslide',
    category: AlertCategory.naturalDisaster,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  sinkhole(
    label: 'Sinkhole',
    category: AlertCategory.naturalDisaster,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  tornado(
    label: 'Tornado',
    category: AlertCategory.naturalDisaster,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  tsunami(
    label: 'Tsunami',
    category: AlertCategory.naturalDisaster,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  volcanicEruption(
    label: 'Volcanic Eruption',
    category: AlertCategory.naturalDisaster,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  wildfire(
    label: 'Wildfire',
    category: AlertCategory.naturalDisaster,
    priority: AlertPriority.critical,
    isFree: false,
  ),

  // ── Group 4: Weather Emergencies ──────────────────────
  blizzard(
    label: 'Blizzard',
    category: AlertCategory.weatherEmergency,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  denseFog(
    label: 'Dense Fog',
    category: AlertCategory.weatherEmergency,
    priority: AlertPriority.high,
    isFree: false,
  ),
  dustStorm(
    label: 'Dust Storm',
    category: AlertCategory.weatherEmergency,
    priority: AlertPriority.high,
    isFree: false,
  ),
  extremeCold(
    label: 'Extreme Cold',
    category: AlertCategory.weatherEmergency,
    priority: AlertPriority.high,
    isFree: true,
  ),
  extremeHeat(
    label: 'Extreme Heat',
    category: AlertCategory.weatherEmergency,
    priority: AlertPriority.high,
    isFree: true,
  ),
  flashFlood(
    label: 'Flash Flood',
    category: AlertCategory.weatherEmergency,
    priority: AlertPriority.critical,
    isFree: true,
  ),
  thunderstorm(
    label: 'Thunderstorm',
    category: AlertCategory.weatherEmergency,
    priority: AlertPriority.high,
    isFree: true,
  ),
  strongWind(
    label: 'Strong Wind',
    category: AlertCategory.weatherEmergency,
    priority: AlertPriority.medium,
    isFree: false,
  ),
  uvRadiation(
    label: 'UV Radiation',
    category: AlertCategory.weatherEmergency,
    priority: AlertPriority.medium,
    isFree: false,
  ),

  // ── Group 5: Personal Safety & Crime ──────────────────
  abduction(
    label: 'Abduction',
    category: AlertCategory.personalSafety,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  activeShooter(
    label: 'Active Shooter',
    category: AlertCategory.personalSafety,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  assault(
    label: 'Assault',
    category: AlertCategory.personalSafety,
    priority: AlertPriority.critical,
    isFree: true,
  ),
  blackmail(
    label: 'Blackmail',
    category: AlertCategory.personalSafety,
    priority: AlertPriority.high,
    isFree: false,
  ),
  bombThreat(
    label: 'Bomb Threat',
    category: AlertCategory.personalSafety,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  burglary(
    label: 'Burglary',
    category: AlertCategory.personalSafety,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  carjacking(
    label: 'Carjacking',
    category: AlertCategory.personalSafety,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  domesticViolence(
    label: 'Domestic Violence',
    category: AlertCategory.personalSafety,
    priority: AlertPriority.critical,
    isFree: true,
  ),
  eveTeasing(
    label: 'Street Harassment',
    category: AlertCategory.personalSafety,
    priority: AlertPriority.critical,
    isFree: true,
  ),
  decoyCall(
    label: 'Decoy Call (Safety Exit)',
    category: AlertCategory.personalSafety,
    priority: AlertPriority.medium,
    isFree: true,
  ),
  missingPerson(
    label: 'Missing Person',
    category: AlertCategory.personalSafety,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  mugging(
    label: 'Mugging / Robbery',
    category: AlertCategory.personalSafety,
    priority: AlertPriority.critical,
    isFree: true,
  ),
  phoneSnatching(
    label: 'Phone Snatching',
    category: AlertCategory.personalSafety,
    priority: AlertPriority.high,
    isFree: false,
  ),
  protest(
    label: 'Protest / Riot',
    category: AlertCategory.personalSafety,
    priority: AlertPriority.high,
    isFree: false,
  ),
  sexualAssault(
    label: 'Sexual Assault',
    category: AlertCategory.personalSafety,
    priority: AlertPriority.critical,
    isFree: true,
  ),
  stalking(
    label: 'Stalking',
    category: AlertCategory.personalSafety,
    priority: AlertPriority.high,
    isFree: false,
  ),
  suspiciousActivity(
    label: 'Suspicious Activity',
    category: AlertCategory.personalSafety,
    priority: AlertPriority.medium,
    isFree: true,
  ),
  terrorism(
    label: 'Terrorism',
    category: AlertCategory.personalSafety,
    priority: AlertPriority.critical,
    isFree: false,
  ),

  // ── Group 6: Home & Domestic ──────────────────────────
  carbonMonoxide(
    label: 'CO Leak',
    category: AlertCategory.homeDomestic,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  electricalFire(
    label: 'Electrical Fire',
    category: AlertCategory.homeDomestic,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  gasLeak(
    label: 'Gas Leak',
    category: AlertCategory.homeDomestic,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  houseFire(
    label: 'House Fire',
    category: AlertCategory.homeDomestic,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  kitchenAccident(
    label: 'Kitchen Accident',
    category: AlertCategory.homeDomestic,
    priority: AlertPriority.high,
    isFree: false,
  ),
  structuralCollapse(
    label: 'Structural Collapse',
    category: AlertCategory.homeDomestic,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  waterPipeBurst(
    label: 'Water Pipe Burst',
    category: AlertCategory.homeDomestic,
    priority: AlertPriority.high,
    isFree: false,
  ),

  // ── Group 7: Workplace ────────────────────────────────
  chemicalSpill(
    label: 'Chemical Spill',
    category: AlertCategory.workplace,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  confinedSpace(
    label: 'Confined Space Emergency',
    category: AlertCategory.workplace,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  constructionAccident(
    label: 'Construction Accident',
    category: AlertCategory.workplace,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  electricalShock(
    label: 'Electrical Shock',
    category: AlertCategory.workplace,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  factoryMalfunction(
    label: 'Factory Malfunction',
    category: AlertCategory.workplace,
    priority: AlertPriority.high,
    isFree: false,
  ),
  loneWorker(
    label: 'Lone Worker Check-In',
    category: AlertCategory.workplace,
    priority: AlertPriority.medium,
    isFree: false,
  ),
  radiationExposure(
    label: 'Radiation Exposure',
    category: AlertCategory.workplace,
    priority: AlertPriority.critical,
    isFree: false,
  ),

  // ── Group 8: Water & Marine ───────────────────────────
  drowning(
    label: 'Drowning',
    category: AlertCategory.waterMarine,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  ripCurrent(
    label: 'Rip Current',
    category: AlertCategory.waterMarine,
    priority: AlertPriority.high,
    isFree: false,
  ),
  dangerousMarineLife(
    label: 'Dangerous Marine Life',
    category: AlertCategory.waterMarine,
    priority: AlertPriority.high,
    isFree: false,
  ),
  ferryCapsize(
    label: 'Ferry Capsizing',
    category: AlertCategory.waterMarine,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  riverFlashFlood(
    label: 'River Flash Flood',
    category: AlertCategory.waterMarine,
    priority: AlertPriority.critical,
    isFree: false,
  ),

  // ── Group 9: Travel & Outdoor ─────────────────────────
  altitudeSickness(
    label: 'Altitude Sickness',
    category: AlertCategory.travelOutdoor,
    priority: AlertPriority.high,
    isFree: false,
  ),
  animalAttack(
    label: 'Animal Attack',
    category: AlertCategory.travelOutdoor,
    priority: AlertPriority.high,
    isFree: false,
  ),
  caveCollapse(
    label: 'Cave Collapse',
    category: AlertCategory.travelOutdoor,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  dangerousRoad(
    label: 'Dangerous Road',
    category: AlertCategory.travelOutdoor,
    priority: AlertPriority.medium,
    isFree: false,
  ),
  gettingLost(
    label: 'Getting Lost',
    category: AlertCategory.travelOutdoor,
    priority: AlertPriority.high,
    isFree: false,
  ),
  hikingAccident(
    label: 'Hiking Accident',
    category: AlertCategory.travelOutdoor,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  insectBite(
    label: 'Insect / Snake Bite',
    category: AlertCategory.travelOutdoor,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  pickpocketing(
    label: 'Pickpocketing',
    category: AlertCategory.travelOutdoor,
    priority: AlertPriority.high,
    isFree: false,
  ),
  touristScam(
    label: 'Tourist Scam',
    category: AlertCategory.travelOutdoor,
    priority: AlertPriority.medium,
    isFree: false,
  ),

  // ── Group 10: Environmental & Chemical ────────────────
  airQuality(
    label: 'Hazardous Air Quality',
    category: AlertCategory.environmentalChemical,
    priority: AlertPriority.high,
    isFree: false,
  ),
  biologicalHazard(
    label: 'Biological Hazard',
    category: AlertCategory.environmentalChemical,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  industrialExplosion(
    label: 'Industrial Explosion',
    category: AlertCategory.environmentalChemical,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  nuclearEvent(
    label: 'Nuclear Event',
    category: AlertCategory.environmentalChemical,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  oilSpill(
    label: 'Oil / Chemical Spill',
    category: AlertCategory.environmentalChemical,
    priority: AlertPriority.high,
    isFree: false,
  ),
  pandemic(
    label: 'Pandemic',
    category: AlertCategory.environmentalChemical,
    priority: AlertPriority.high,
    isFree: false,
  ),
  waterContamination(
    label: 'Water Contamination',
    category: AlertCategory.environmentalChemical,
    priority: AlertPriority.high,
    isFree: false,
  ),

  // ── Group 11: Digital & Cyber ─────────────────────────
  fakeEmergency(
    label: 'Fake Emergency Detection',
    category: AlertCategory.digitalCyber,
    priority: AlertPriority.medium,
    isFree: false,
  ),
  unknownTracking(
    label: 'Unknown Location Tracking',
    category: AlertCategory.digitalCyber,
    priority: AlertPriority.high,
    isFree: false,
  ),
  batteryCritical(
    label: 'Battery Critical',
    category: AlertCategory.digitalCyber,
    priority: AlertPriority.high,
    isFree: true,
  ),
  simRemoval(
    label: 'SIM Removal / Tamper',
    category: AlertCategory.digitalCyber,
    priority: AlertPriority.high,
    isFree: false,
  ),
  unknownAirTag(
    label: 'Unknown AirTag',
    category: AlertCategory.digitalCyber,
    priority: AlertPriority.critical,
    isFree: false,
  ),

  // ── Group 12: Child & Elder ───────────────────────────
  childInHotCar(
    label: 'Child in Hot Car',
    category: AlertCategory.childElder,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  geofenceExit(
    label: 'Geofence Exit',
    category: AlertCategory.childElder,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  elderlyFall(
    label: 'Elderly Fall',
    category: AlertCategory.childElder,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  elderlyInactivity(
    label: 'Elderly Inactivity',
    category: AlertCategory.childElder,
    priority: AlertPriority.high,
    isFree: false,
  ),
  medicineReminder(
    label: 'Medicine Reminder',
    category: AlertCategory.childElder,
    priority: AlertPriority.medium,
    isFree: true,
  ),
  schoolEmergency(
    label: 'School Emergency',
    category: AlertCategory.childElder,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  sugarBpReminder(
    label: 'Sugar/BP Check',
    category: AlertCategory.childElder,
    priority: AlertPriority.medium,
    isFree: true,
  ),

  // ── Group 13: Military & Conflict (Regional) ──────────
  airRaid(
    label: 'Air Raid',
    category: AlertCategory.personalSafety,
    priority: AlertPriority.critical,
    isFree: true,
  ),
  missileStrike(
    label: 'Missile Strike',
    category: AlertCategory.personalSafety,
    priority: AlertPriority.critical,
    isFree: true,
  ),
  droneAttack(
    label: 'Drone Attack',
    category: AlertCategory.personalSafety,
    priority: AlertPriority.critical,
    isFree: true,
  ),

  // ── SOS (Core) ────────────────────────────────────────
  manualSos(
    label: 'Manual SOS',
    category: AlertCategory.personalSafety,
    priority: AlertPriority.critical,
    isFree: true,
  ),
  shakeSos(
    label: 'Shake SOS',
    category: AlertCategory.personalSafety,
    priority: AlertPriority.critical,
    isFree: true,
  );

  const AlertType({
    required this.label,
    required this.category,
    required this.priority,
    required this.isFree,
  });

  final String label;
  final AlertCategory category;
  final AlertPriority priority;
  final bool isFree;
}
