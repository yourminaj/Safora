/// 5-tier alert priority system.
///
/// Maps to user-visible severity: Info → Advisory → Warning → Danger → Critical
enum AlertPriority {
  critical, // Life-threatening — auto-trigger SOS, 30-sec siren
  danger,   // Dangerous — urgent alarm, notify contacts
  warning,  // Warning — notification + vibration
  advisory, // Advisory — standard notification
  info,     // Informational — silent notification + badge
}

/// Alert categories grouping all risk types.
enum AlertCategory {
  healthMedical('Health & Medical'),
  vehicleTransport('Vehicle & Transport'),
  naturalDisaster('Natural Disasters'),
  weatherEmergency('Weather Emergencies'),
  personalSafety('Personal Safety & Crime'),
  homeDomestic('Home & Domestic'),
  workplace('Workplace Hazards'),
  waterMarine('Water & Marine'),
  travelOutdoor('Travel & Outdoor'),
  environmentalChemical('Environmental & Chemical'),
  digitalCyber('Digital & Cyber'),
  childElder('Child & Elder Safety'),
  militaryDefense('Military & Defense'),
  infrastructure('Infrastructure'),
  spaceAstronomical('Space & Astronomical'),
  maritimeAviation('Maritime & Aviation');

  const AlertCategory(this.label);

  final String label;
}

/// All 127 risk types the app can detect and alert for.
///
/// Each type has a category, priority, and detection method.
enum AlertType {
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
    priority: AlertPriority.danger,
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
    priority: AlertPriority.warning,
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
    priority: AlertPriority.danger,
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
    priority: AlertPriority.danger,
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
    priority: AlertPriority.danger,
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
    priority: AlertPriority.danger,
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
    priority: AlertPriority.advisory,
    isFree: true,
  ),
  speedWarning(
    label: 'Speed Limit Warning',
    category: AlertCategory.vehicleTransport,
    priority: AlertPriority.warning,
    isFree: true,
  ),
  vehicleBreakdown(
    label: 'Vehicle Breakdown',
    category: AlertCategory.vehicleTransport,
    priority: AlertPriority.danger,
    isFree: false,
  ),
  wrongWayDriving(
    label: 'Wrong-Way Driving',
    category: AlertCategory.vehicleTransport,
    priority: AlertPriority.critical,
    isFree: false,
  ),

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
    priority: AlertPriority.warning,
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
    priority: AlertPriority.danger,
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

  blizzard(
    label: 'Blizzard',
    category: AlertCategory.weatherEmergency,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  denseFog(
    label: 'Dense Fog',
    category: AlertCategory.weatherEmergency,
    priority: AlertPriority.danger,
    isFree: false,
  ),
  dustStorm(
    label: 'Dust Storm',
    category: AlertCategory.weatherEmergency,
    priority: AlertPriority.danger,
    isFree: false,
  ),
  extremeCold(
    label: 'Extreme Cold',
    category: AlertCategory.weatherEmergency,
    priority: AlertPriority.danger,
    isFree: true,
  ),
  extremeHeat(
    label: 'Extreme Heat',
    category: AlertCategory.weatherEmergency,
    priority: AlertPriority.danger,
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
    priority: AlertPriority.danger,
    isFree: true,
  ),
  strongWind(
    label: 'Strong Wind',
    category: AlertCategory.weatherEmergency,
    priority: AlertPriority.warning,
    isFree: false,
  ),
  uvRadiation(
    label: 'UV Radiation',
    category: AlertCategory.weatherEmergency,
    priority: AlertPriority.warning,
    isFree: false,
  ),

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
    priority: AlertPriority.danger,
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
    priority: AlertPriority.warning,
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
    priority: AlertPriority.danger,
    isFree: false,
  ),
  protest(
    label: 'Protest / Riot',
    category: AlertCategory.personalSafety,
    priority: AlertPriority.danger,
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
    priority: AlertPriority.danger,
    isFree: false,
  ),
  suspiciousActivity(
    label: 'Suspicious Activity',
    category: AlertCategory.personalSafety,
    priority: AlertPriority.warning,
    isFree: true,
  ),
  terrorism(
    label: 'Terrorism',
    category: AlertCategory.personalSafety,
    priority: AlertPriority.critical,
    isFree: false,
  ),

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
    priority: AlertPriority.danger,
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
    priority: AlertPriority.danger,
    isFree: false,
  ),

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
    priority: AlertPriority.danger,
    isFree: false,
  ),
  loneWorker(
    label: 'Lone Worker Check-In',
    category: AlertCategory.workplace,
    priority: AlertPriority.warning,
    isFree: false,
  ),
  radiationExposure(
    label: 'Radiation Exposure',
    category: AlertCategory.workplace,
    priority: AlertPriority.critical,
    isFree: false,
  ),

  drowning(
    label: 'Drowning',
    category: AlertCategory.waterMarine,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  ripCurrent(
    label: 'Rip Current',
    category: AlertCategory.waterMarine,
    priority: AlertPriority.danger,
    isFree: false,
  ),
  dangerousMarineLife(
    label: 'Dangerous Marine Life',
    category: AlertCategory.waterMarine,
    priority: AlertPriority.danger,
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

  altitudeSickness(
    label: 'Altitude Sickness',
    category: AlertCategory.travelOutdoor,
    priority: AlertPriority.danger,
    isFree: false,
  ),
  animalAttack(
    label: 'Animal Attack',
    category: AlertCategory.travelOutdoor,
    priority: AlertPriority.danger,
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
    priority: AlertPriority.warning,
    isFree: false,
  ),
  gettingLost(
    label: 'Getting Lost',
    category: AlertCategory.travelOutdoor,
    priority: AlertPriority.danger,
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
    priority: AlertPriority.danger,
    isFree: false,
  ),
  touristScam(
    label: 'Tourist Scam',
    category: AlertCategory.travelOutdoor,
    priority: AlertPriority.warning,
    isFree: false,
  ),

  airQuality(
    label: 'Hazardous Air Quality',
    category: AlertCategory.environmentalChemical,
    priority: AlertPriority.danger,
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
    priority: AlertPriority.danger,
    isFree: false,
  ),
  pandemic(
    label: 'Pandemic',
    category: AlertCategory.environmentalChemical,
    priority: AlertPriority.danger,
    isFree: false,
  ),
  waterContamination(
    label: 'Water Contamination',
    category: AlertCategory.environmentalChemical,
    priority: AlertPriority.danger,
    isFree: false,
  ),

  fakeEmergency(
    label: 'Fake Emergency Detection',
    category: AlertCategory.digitalCyber,
    priority: AlertPriority.warning,
    isFree: false,
  ),
  unknownTracking(
    label: 'Unknown Location Tracking',
    category: AlertCategory.digitalCyber,
    priority: AlertPriority.danger,
    isFree: false,
  ),
  batteryCritical(
    label: 'Battery Critical',
    category: AlertCategory.digitalCyber,
    priority: AlertPriority.danger,
    isFree: true,
  ),
  simRemoval(
    label: 'SIM Removal / Tamper',
    category: AlertCategory.digitalCyber,
    priority: AlertPriority.danger,
    isFree: false,
  ),
  unknownAirTag(
    label: 'Unknown AirTag',
    category: AlertCategory.digitalCyber,
    priority: AlertPriority.critical,
    isFree: false,
  ),

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
    priority: AlertPriority.danger,
    isFree: false,
  ),
  medicineReminder(
    label: 'Medicine Reminder',
    category: AlertCategory.childElder,
    priority: AlertPriority.warning,
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
    priority: AlertPriority.warning,
    isFree: true,
  ),

  airRaid(
    label: 'Air Raid',
    category: AlertCategory.militaryDefense,
    priority: AlertPriority.critical,
    isFree: true,
  ),
  missileStrike(
    label: 'Missile Strike',
    category: AlertCategory.militaryDefense,
    priority: AlertPriority.critical,
    isFree: true,
  ),
  droneAttack(
    label: 'Drone Attack',
    category: AlertCategory.militaryDefense,
    priority: AlertPriority.critical,
    isFree: true,
  ),
  militaryOperation(
    label: 'Military Operation',
    category: AlertCategory.militaryDefense,
    priority: AlertPriority.critical,
    isFree: true,
  ),
  curfew(
    label: 'Curfew',
    category: AlertCategory.militaryDefense,
    priority: AlertPriority.danger,
    isFree: true,
  ),
  evacuation(
    label: 'Evacuation Order',
    category: AlertCategory.militaryDefense,
    priority: AlertPriority.critical,
    isFree: true,
  ),

  powerOutage(
    label: 'Power Outage',
    category: AlertCategory.infrastructure,
    priority: AlertPriority.warning,
    isFree: true,
  ),
  damFailure(
    label: 'Dam Failure',
    category: AlertCategory.infrastructure,
    priority: AlertPriority.critical,
    isFree: true,
  ),
  bridgeCollapse(
    label: 'Bridge Collapse',
    category: AlertCategory.infrastructure,
    priority: AlertPriority.critical,
    isFree: true,
  ),
  gasLeakInfra(
    label: 'Gas Leak (Infrastructure)',
    category: AlertCategory.infrastructure,
    priority: AlertPriority.danger,
    isFree: true,
  ),
  buildingCollapse(
    label: 'Building Collapse',
    category: AlertCategory.infrastructure,
    priority: AlertPriority.critical,
    isFree: true,
  ),

  solarFlare(
    label: 'Solar Flare',
    category: AlertCategory.spaceAstronomical,
    priority: AlertPriority.advisory,
    isFree: true,
  ),
  asteroidProximity(
    label: 'Asteroid Proximity',
    category: AlertCategory.spaceAstronomical,
    priority: AlertPriority.info,
    isFree: true,
  ),
  satelliteDebris(
    label: 'Satellite Re-entry Debris',
    category: AlertCategory.spaceAstronomical,
    priority: AlertPriority.advisory,
    isFree: true,
  ),

  aviationIncident(
    label: 'Aviation Incident',
    category: AlertCategory.maritimeAviation,
    priority: AlertPriority.critical,
    isFree: true,
  ),
  noFlyZoneViolation(
    label: 'No-Fly Zone Violation',
    category: AlertCategory.maritimeAviation,
    priority: AlertPriority.danger,
    isFree: true,
  ),
  shipDistress(
    label: 'Ship Distress Signal',
    category: AlertCategory.maritimeAviation,
    priority: AlertPriority.critical,
    isFree: true,
  ),

  roadClosure(
    label: 'Road Closure',
    category: AlertCategory.vehicleTransport,
    priority: AlertPriority.advisory,
    isFree: true,
  ),
  transitEmergency(
    label: 'Transit Emergency',
    category: AlertCategory.vehicleTransport,
    priority: AlertPriority.danger,
    isFree: true,
  ),

  dataBreach(
    label: 'Data Breach',
    category: AlertCategory.digitalCyber,
    priority: AlertPriority.warning,
    isFree: false,
  ),
  criticalInfraAttack(
    label: 'Critical Infrastructure Attack',
    category: AlertCategory.digitalCyber,
    priority: AlertPriority.danger,
    isFree: false,
  ),

  amberAlert(
    label: 'Amber Alert (Missing Child)',
    category: AlertCategory.personalSafety,
    priority: AlertPriority.critical,
    isFree: true,
  ),
  silverAlert(
    label: 'Silver Alert (Missing Elder)',
    category: AlertCategory.personalSafety,
    priority: AlertPriority.danger,
    isFree: true,
  ),

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
  ),

  voiceDistressSos(
    label: 'Voice Distress Detected',
    category: AlertCategory.personalSafety,
    priority: AlertPriority.critical,
    isFree: false,
  ),
  suspiciousMovementSos(
    label: 'Suspicious Movement Detected',
    category: AlertCategory.personalSafety,
    priority: AlertPriority.danger,
    isFree: false,
  ),
  roadHazardAlert(
    label: 'Road Hazard Detected',
    category: AlertCategory.naturalDisaster,
    priority: AlertPriority.warning,
    isFree: false,
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
