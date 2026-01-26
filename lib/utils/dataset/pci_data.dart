//  pci_data.dart
//  Created by JeoJay127
//
class PciData {
  static final Map<String, Map<String, String>> gpuInfoMap = {
    // AMD Radeon HD 3870 X2
    "1002-950F": {"spoofId": "1002-9505", "name": "AMD Radeon HD 3870 X2"},
    // AMD Radeon HD 4830
    "1002-944C": {"spoofId": "1002-9442", "name": "AMD Radeon HD 4830"},
    // AMD Radeon HD 4650
    "1002-9498": {"spoofId": "1002-9553", "name": "AMD Radeon HD 4650"},
    // AMD Radeon HD 7670
    "1002-675B": {"spoofId": "1002-6758", "name": "AMD Radeon HD 7670"},
    // AMD Radeon HD 5750
    "1002-68BE": {"spoofId": "1002-68B8", "name": "AMD Radeon HD 5750"},
    // AMD Radeon HD 6750
    "1002-68BF": {"spoofId": "1002-68B8", "name": "AMD Radeon HD 6750"},
    // AMD Radeon HD 5450 / HD 6350
    "1002-68F9": {"spoofId": "1002-68E0", "name": "AMD Radeon HD 5450"},
    // AMD Radeon HD 8350
    "1002-68FA": {"spoofId": "1002-68E0", "name": "AMD Radeon HD 8350"},
    // AMD Radeon HD 8470 / HD 6450
    "1002-6778": {"spoofId": "1002-6779", "name": "AMD Radeon HD 8470"},
    // Oland XT [Radeon HD 8670 / R5 340X OEM / R7 250/350/350X OEM]
    "1002-6610": {"spoofId": "1002-672B", "name": "AMD Radeon R7 250"},
    // AMD Radeon HD 8570 / R5 430 / R7 240/340 / Radeon 520
    "1002-6611": {"spoofId": "1002-6798", "name": "AMD Radeon HD 8570"},
    // AMD FirePro V5900
    "1002-6707": {"spoofId": "1002-6704", "name": "AMD FirePro V5900"},
    // AMD Radeon R7 240/340 / Radeon 520
    "1002-6613": {"spoofId": "1002-6798", "name": "AMD Radeon R7 240"},
    // AMD Radeon R7 240   FakeID: [6798,6798,679A,6820]
    "1002-6617": {"spoofId": "1002-6798", "name": "AMD Radeon R7 240"},
    // AMD FirePro W4100
    "1002-682C": {"spoofId": "1002-683F", "name": "AMD FirePro W4100"},
    // AMD FirePro W5000
    "1002-6809": {"spoofId": "1002-6808", "name": "AMD FirePro W5000"},
    // AMD FirePro W5100
    "1002-6649": {"spoofId": "1002-665C", "name": "AMD FirePro W5100"},
    // AMD FirePro W8100
    "1002-67A1": {"spoofId": "1002-67B0", "name": "AMD FirePro W8100"},
    // AMD Radeon HD 7790/8770 / R7 360 / R9 260/360
    "1002-6658": {"spoofId": "1002-665C", "name": "AMD Radeon R7 260X"},
    // AMD Radeon HD 7950/8950 / R9 280
    "1002-679A": {"spoofId": "1002-6798", "name": "AMD Radeon HD 7950"},
    // AMD Radeon R9 290/390
    "1002-67B1": {"spoofId": "1002-67B0", "name": "AMD Radeon R9 290/390"},
    // AMD Radeon R7 370 / R9 270/370
    "1002-6811": {"spoofId": "1002-6798", "name": "AMD Radeon R7 370"},
    // AMD Radeon HD 7850 / R7 265 / R9 270 1024SP
    "1002-6819": {"spoofId": "1002-6818", "name": "AMD Radeon HD R9 270"},
    // AMD Radeon HD 8830M / R7 250
    "1002-682B": {"spoofId": "1002-683D", "name": "AMD Radeon HD R7 250"},
    // AMD Radeon HD 7730
    "1002-6837": {"spoofId": "1002-683F", "name": "AMD Radeon HD 7730"},
    // AMD Radeon HD R9 360
    "1002-665F": {"spoofId": "1002-665C", "name": "AMD Radeon HD R9 360"},
    // AMD Radeon R9 380
    "1002-6930": {"spoofId": "1002-6938", "name": "AMD Radeon R9 380"},
    // AMD Radeon R9 285/380
    "1002-6939": {"spoofId": "1002-6938", "name": "AMD Radeon R9 285/380"},
    // AMD Radeon RX 640 (Lexa core)
    "1002-6987": {"spoofId": "1002-67FF", "name": "AMD Radeon RX 640"},
    // AMD Radeon RX 550 (Lexa core)
    "1002-699F": {"spoofId": "1002-67FF", "name": "AMD Radeon RX 550"},
    // AMD Radeon PRO WX 2100 (Lexa core)
    "1002-6995": {"spoofId": "1002-67FF", "name": "AMD Radeon PRO WX 2100"},
    // AMD Radeon PRO WX 3100 (Lexa core)
    "1002-6985": {"spoofId": "1002-67E3", "name": "AMD Radeon PRO WX 3100"},
    // AMD Radeon PRO WX 3200 (Lexa core)
    "1002-6981": {"spoofId": "1002-67FF", "name": "AMD Radeon PRO WX 3200"},
    // AMD Radeon RX 6800S / 6650 XT / 6650M / 6650M XT
    "1002-73EF": {"spoofId": "1002-73FF", "name": "AMD Radeon RX 6650 XT"},
    // AMD Radeon Pro W6600M
    "1002-73E1": {"spoofId": "1002-73E3", "name": "AMD Radeon Pro W6600M"},
    // AMD Radeon RX 6900 XT (XTX/XTXH variant)
    "1002-73AF": {"spoofId": "1002-73BF", "name": "AMD Radeon RX 6900 XT"},
    // AMD Radeon RX 6950 XT
    "1002-73A5": {"spoofId": "1002-73BF", "name": "AMD Radeon RX 6950 XT"},
  };

  static String? getspoofId(String originalId) =>
      gpuInfoMap[originalId]?["spoofId"];

  static String? getGpuNameWithOriginId(String originalId) =>
      gpuInfoMap[originalId]?["name"];

  static String? getDeviceOriginalId(String originalId) =>
      originalId.split('-').last;

  static String? getDevicespoofId(String originalId) =>
      getspoofId(originalId)?.split('-').last;
}
