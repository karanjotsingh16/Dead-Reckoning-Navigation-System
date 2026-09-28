/// Yeh file offline "decision tree" data store karti hai - koi AI API call
/// nahi, sab kuch phone ke andar hi hai isliye bina internet ke kaam karega.
class VehicleIssue {
  final String symptom;
  final String icon; // Emoji icon - simple aur effective
  final List<String> possibleCauses;
  final List<String> steps;
  final String severity; // "Low", "Medium", "High"

  VehicleIssue({
    required this.symptom,
    required this.icon,
    required this.possibleCauses,
    required this.steps,
    required this.severity,
  });
}

/// Common vehicle issues ka database - offline decision tree.
/// Real project mein isko aur detailed/bada kar sakte ho.
final List<VehicleIssue> vehicleIssuesDatabase = [
  VehicleIssue(
    symptom: 'Gaadi Start Nahi Ho Rahi',
    icon: '🔋',
    severity: 'Medium',
    possibleCauses: [
      'Battery down ho sakti hai',
      'Fuel khatam ho sakta hai',
      'Starter motor mein problem',
    ],
    steps: [
      'Pehle check karo ki fuel gauge kya dikha raha hai - fuel to nahi khatam?',
      'Headlights on karke dekho - agar dim hain to battery weak hai',
      'Battery terminals check karo - loose ya corroded to nahi hain',
      'Agar battery down hai, jump-start karne ki koshish karo (dusri gaadi se cables se)',
      'Agar phir bhi start na ho, nearest mechanic/garage ko contact karo',
    ],
  ),
  VehicleIssue(
    symptom: 'Engine Se Ajeeb Aawaz Aa Rahi',
    icon: '⚙️',
    severity: 'High',
    possibleCauses: [
      'Loose belt ya pulley',
      'Low engine oil',
      'Exhaust system mein leak',
    ],
    steps: [
      'Gaadi ko safe jagah rok do, engine band kar do',
      'Engine oil level check karo (dipstick se) - agar kam hai to top-up karo',
      'Hood khol ke dekho koi belt loose ya damaged to nahi dikh raha',
      'Agar knocking/grinding sound aa rahi hai, gaadi mat chalao - towing ki zaroorat ho sakti hai',
      'Halki si rattling sound hai to dheere chala ke nearest garage tak pahunch sakte ho',
    ],
  ),
  VehicleIssue(
    symptom: 'Engine Overheat Ho Raha Hai',
    icon: '🌡️',
    severity: 'High',
    possibleCauses: [
      'Coolant level low',
      'Radiator mein blockage',
      'Cooling fan kharab',
    ],
    steps: [
      'TURANT gaadi safe jagah rok do aur engine band kar do',
      'Hood mat kholo turant - garam steam se jal sakte ho, 10-15 min wait karo',
      'Thande hone ke baad hood kholo aur coolant reservoir check karo',
      'Agar coolant kam hai, thoda paani daal sakte ho temporarily (sirf emergency mein)',
      'Gaadi ko tow karwao ya mechanic ko bulao - overheated engine se aage chalana risky hai',
    ],
  ),
  VehicleIssue(
    symptom: 'Tyre Punchar / Flat Ho Gaya',
    icon: '🛞',
    severity: 'Medium',
    possibleCauses: [
      'Nail ya sharp object se punchar',
      'Air pressure bahut kam',
    ],
    steps: [
      'Gaadi ko safe, flat jagah rok do (road ke side mein, traffic se door)',
      'Hazard lights on karo',
      'Spare tyre aur jack nikaalo (usually boot/dickie mein hota hai)',
      'Gaadi ko jack se uthao, nut wrench se wheel nuts khol ke tyre change karo',
      'Agar spare tyre nahi hai ya tools nahi hain, roadside assistance ya nearby garage ko call karo',
    ],
  ),
  VehicleIssue(
    symptom: 'Brake Soft Lag Rahe / Kaam Nahi Kar Rahe',
    icon: '🛑',
    severity: 'High',
    possibleCauses: [
      'Brake fluid low',
      'Brake pads worn out',
      'Air brake line mein',
    ],
    steps: [
      'YEH SERIOUS HAI - gaadi ko turant dheere karke safe jagah rok do',
      'Engine brake use karo (gear down karo) agar normal brake weak lag rahe hain',
      'Brake fluid reservoir check karo agar accessible hai',
      'Gaadi ko bilkul mat chalao jab tak brake fix na ho jaaye',
      'TURANT roadside assistance ya towing service ko call karo - yeh safety issue hai',
    ],
  ),
  VehicleIssue(
    symptom: 'Fuel Khatam Ho Gaya',
    icon: '⛽',
    severity: 'Low',
    possibleCauses: [
      'Fuel gauge sahi track nahi kiya',
    ],
    steps: [
      'Gaadi ko safe jagah rok do, hazard lights on karo',
      'Nearest fuel station dhundo (app mein "nearest garage" feature use karo)',
      'Agar fuel station door hai, kisi se fuel can mein fuel laane ko bolo',
      'Roadside fuel-delivery service bhi try kar sakte ho agar available ho',
    ],
  ),
];