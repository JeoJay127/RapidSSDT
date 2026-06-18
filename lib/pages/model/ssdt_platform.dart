//  ssdt_platform.dart
//  Created by JeoJay127
//
// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'package:rapidssdt/utils/ssdttool/table.dart';

class SsdtPlatform {
  static Map<String, Map<String, dynamic>> platform_intel_desktop = {
    '0代-Penryn-775平台': {
      'basic': [ACPITable.ssdtECDesktop],
      'recommend': [ACPITable.ssdtHPET],
      'optional': optional_sstds_intel_desktop,
    },
    '1代-Lynnfield-1156平台': {
      'basic': [ACPITable.ssdtECDesktop],
      'recommend': [ACPITable.ssdtHPET],
      'optional': optional_sstds_intel_desktop,
    },
    '2代-Sandy Bridge-1155平台': {
      'basic': [ACPITable.ssdtECDesktop],
      'recommend': [
        ACPITable.ssdtHPET,
        {...ACPITable.ssdtIMEI, 'extra': '3A1C'},
      ],
      'optional': optional_sstds_intel_desktop,
    },
    '3代-Ivy Bridge-1155平台': {
      'basic': [ACPITable.ssdtECDesktop],
      'recommend': [
        ACPITable.ssdtHPET,
        {...ACPITable.ssdtIMEI, 'extra': '3A1E'},
        ACPITable.ssdtDMAR,
      ],
      'optional': optional_sstds_intel_desktop,
    },
    '4代-Haswell-1150平台': {
      'basic': [ACPITable.ssdtECDesktop, ACPITable.ssdtPLUG],
      'recommend': [ACPITable.ssdtHPET, ACPITable.ssdtDMAR],
      'optional': [...optional_sstds_intel_desktop, ACPITable.ssdtMEM2],
    },
    '5代-Broadwell-1150平台': {
      'basic': [ACPITable.ssdtECDesktop, ACPITable.ssdtPLUG],
      'recommend': [ACPITable.ssdtHPET, ACPITable.ssdtDMAR],
      'optional': [...optional_sstds_intel_desktop, ACPITable.ssdtMEM2],
    },
    '6代-Skylake-1151平台': {
      'basic': [ACPITable.ssdtECUSBXDesktop, ACPITable.ssdtPLUG],
      'recommend': [ACPITable.ssdtHPET, ACPITable.ssdtDMAR],
      'optional': [...optional_sstds_intel_desktop, ACPITable.ssdtMEM2],
    },
    '7代-Kaby Lake-1151平台': {
      'basic': [ACPITable.ssdtECUSBXDesktop, ACPITable.ssdtPLUG],
      'recommend': [ACPITable.ssdtHPET, ACPITable.ssdtDMAR],
      'optional': [...optional_sstds_intel_desktop, ACPITable.ssdtMEM2],
    },
    '8代-Coffee Lake-1151平台': {
      'basic': [
        ACPITable.ssdtECUSBXDesktop,
        ACPITable.ssdtPLUG,
        ACPITable.ssdtAWAC,
        ACPITable.ssdtPMC,
      ],
      'recommend': [ACPITable.ssdtHPET, ACPITable.ssdtDMAR],
      'optional': optional_sstds_intel_desktop,
    },
    '9代-Coffee Lake-1151平台': {
      'basic': [
        ACPITable.ssdtECUSBXDesktop,
        ACPITable.ssdtPLUG,
        ACPITable.ssdtAWAC,
        ACPITable.ssdtPMC,
      ],
      'recommend': [ACPITable.ssdtHPET, ACPITable.ssdtDMAR],
      'optional': optional_sstds_intel_desktop,
    },
    '10代-Comet Lake-1200平台': {
      'basic': [
        ACPITable.ssdtECUSBXDesktop,
        ACPITable.ssdtPLUG,
        ACPITable.ssdtAWAC,
        ACPITable.ssdtRHUB,
      ],
      'recommend': [ACPITable.ssdtHPET, ACPITable.ssdtDMAR],
      'optional': optional_sstds_intel_desktop,
    },
    '11代-Rocket Lake-1200平台': {
      'basic': [
        ACPITable.ssdtECUSBXDesktop,
        ACPITable.ssdtPLUG,
        ACPITable.ssdtAWAC,
        ACPITable.ssdtRHUB,
      ],
      'recommend': [ACPITable.ssdtHPET, ACPITable.ssdtDMAR],
      'optional': optional_sstds_intel_desktop,
    },
    '12代-Alder Lake-1700平台': {
      'basic': [
        ACPITable.ssdtECUSBXDesktop,
        ACPITable.ssdtPLUGALT,
        ACPITable.ssdtAWAC,
      ],
      'recommend': [
        ACPITable.ssdtRHUB,
        ACPITable.ssdtHPET,
        ACPITable.ssdtPMC,
        ACPITable.ssdtDMAR,
      ],
      'optional': optional_sstds_intel_desktop,
    },
    '13代-Raptor Lake-1700平台': {
      'basic': [
        ACPITable.ssdtECUSBXDesktop,
        ACPITable.ssdtPLUGALT,
        ACPITable.ssdtAWAC,
        ACPITable.ssdtRHUB,
        ACPITable.ssdtDMAR,
      ],
      'recommend': [ACPITable.ssdtHPET, ACPITable.ssdtPMC],
      'optional': optional_sstds_intel_desktop,
    },
    '14代-Raptor Lake-1700平台': {
      'basic': [
        ACPITable.ssdtECUSBXDesktop,
        ACPITable.ssdtPLUGALT,
        ACPITable.ssdtAWAC,
        ACPITable.ssdtRHUB,
        ACPITable.ssdtDMAR,
      ],
      'recommend': [ACPITable.ssdtHPET, ACPITable.ssdtPMC],
      'optional': optional_sstds_intel_desktop,
    },
    '15代-Arrow Lake-1851平台': {
      'basic': [
        ACPITable.ssdtECUSBXDesktop,
        ACPITable.ssdtPLUGALT,
        ACPITable.ssdtAWAC,
        ACPITable.ssdtRHUB,
        ACPITable.ssdtDMAR,
      ],
      'recommend': [ACPITable.ssdtHPET, ACPITable.ssdtPMC],
      'optional': optional_sstds_intel_desktop,
    },
  };

  static Map<String, Map<String, dynamic>> platform_intel_laptop = {
    '0代-Penryn-笔记本': {
      'basic': [
        ACPITable.ssdtECLaptop,
        {...ACPITable.ssdtPNLF, 'extra': 14},
      ],
      'recommend': [ACPITable.ssdtHPET],
      'optional': optional_sstds_intel_laptop,
    },
    '1代-Arrandale-笔记本': {
      'basic': [
        ACPITable.ssdtECLaptop,
        {...ACPITable.ssdtPNLF, 'extra': 14},
      ],
      'recommend': [ACPITable.ssdtHPET],
      'optional': optional_sstds_intel_laptop,
    },
    '2代-Sandy Bridge-笔记本': {
      'basic': [
        ACPITable.ssdtECLaptop,
        {...ACPITable.ssdtPNLF, 'extra': 14},
      ],
      'recommend': [
        ACPITable.ssdtHPET,
        {...ACPITable.ssdtIMEI, 'extra': '3A1C'},
      ],
      'optional': optional_sstds_intel_laptop,
    },
    '3代-Ivy Bridge-笔记本': {
      'basic': [
        ACPITable.ssdtECLaptop,
        {...ACPITable.ssdtPNLF, 'extra': 14},
      ],
      'recommend': [
        ACPITable.ssdtHPET,
        {...ACPITable.ssdtIMEI, 'extra': '3A1E'},
        ACPITable.ssdtALS0,
        ACPITable.ssdtDMAR,
      ],
      'optional': optional_sstds_intel_laptop,
    },
    '4代-Haswell-笔记本': {
      'basic': [
        ACPITable.ssdtECLaptop,
        ACPITable.ssdtPLUG,
        {...ACPITable.ssdtPNLF, 'extra': 15},
        ACPITable.ssdtXOSI,
      ],
      'recommend': [ACPITable.ssdtHPET, ACPITable.ssdtALS0, ACPITable.ssdtDMAR],
      'optional': [
        ACPITable.ssdtGPI0,
        ...optional_sstds_intel_laptop,
        ACPITable.ssdtMEM2,
      ],
    },
    '5代-Broadwell-笔记本': {
      'basic': [
        ACPITable.ssdtECLaptop,
        ACPITable.ssdtPLUG,
        {...ACPITable.ssdtPNLF, 'extra': 15},
        ACPITable.ssdtXOSI,
      ],
      'recommend': [ACPITable.ssdtHPET, ACPITable.ssdtALS0, ACPITable.ssdtDMAR],
      'optional': [
        ACPITable.ssdtGPI0,
        ...optional_sstds_intel_laptop,
        ACPITable.ssdtMEM2,
      ],
    },
    '6代-Skylake-笔记本': {
      'basic': [
        ACPITable.ssdtECUSBXLaptop,
        ACPITable.ssdtPLUG,
        {...ACPITable.ssdtPNLF, 'extra': 16},
        ACPITable.ssdtXOSI,
      ],
      'recommend': [ACPITable.ssdtHPET, ACPITable.ssdtALS0, ACPITable.ssdtDMAR],
      'optional': [
        ACPITable.ssdtGPI0,
        ...optional_sstds_intel_laptop,
        ACPITable.ssdtMEM2,
      ],
    },
    '7代-Kaby Lake-笔记本': {
      'basic': [
        ACPITable.ssdtECUSBXLaptop,
        ACPITable.ssdtPLUG,
        {...ACPITable.ssdtPNLF, 'extra': 16},
        ACPITable.ssdtXOSI,
      ],
      'recommend': [ACPITable.ssdtHPET, ACPITable.ssdtALS0, ACPITable.ssdtDMAR],
      'optional': [
        ACPITable.ssdtGPI0,
        ...optional_sstds_intel_laptop,
        ACPITable.ssdtMEM2,
      ],
    },
    '8代-Coffee Lake-笔记本': {
      'basic': [
        ACPITable.ssdtECUSBXLaptop,
        ACPITable.ssdtPLUG,
        {...ACPITable.ssdtPNLF, 'extra': 19},
        ACPITable.ssdtAWAC,
        ACPITable.ssdtXOSI,
      ],
      'recommend': [
        ACPITable.ssdtHPET,
        ACPITable.ssdtPMC,
        ACPITable.ssdtALS0,
        ACPITable.ssdtDMAR,
      ],
      'optional': [ACPITable.ssdtGPI0, ...optional_sstds_intel_laptop],
    },
    '9代-Coffee Lake-笔记本': {
      'basic': [
        ACPITable.ssdtECUSBXLaptop,
        ACPITable.ssdtPLUG,
        {...ACPITable.ssdtPNLF, 'extra': 19},
        ACPITable.ssdtAWAC,
        ACPITable.ssdtPMC,
        ACPITable.ssdtXOSI,
      ],
      'recommend': [ACPITable.ssdtHPET, ACPITable.ssdtALS0, ACPITable.ssdtDMAR],
      'optional': [ACPITable.ssdtGPI0, ...optional_sstds_intel_laptop],
    },
    '10代-Comet Lake-笔记本': {
      'basic': [
        ACPITable.ssdtECUSBXLaptop,
        ACPITable.ssdtPLUG,
        {...ACPITable.ssdtPNLF, 'extra': 19},
        ACPITable.ssdtAWAC,
        ACPITable.ssdtXOSI,
      ],
      'recommend': [
        ACPITable.ssdtHPET,
        ACPITable.ssdtPMC,
        ACPITable.ssdtALS0,
        ACPITable.ssdtDMAR,
      ],
      'optional': [ACPITable.ssdtGPI0, ...optional_sstds_intel_laptop],
    },
    '10代-Ice Lake-笔记本': {
      'basic': [
        ACPITable.ssdtECUSBXLaptop,
        ACPITable.ssdtPLUG,
        {...ACPITable.ssdtPNLF, 'extra': 19},
        ACPITable.ssdtAWAC,
        ACPITable.ssdtXOSI,
        ACPITable.ssdtRHUB,
      ],
      'recommend': [
        ACPITable.ssdtHPET,
        ACPITable.ssdtPMC,
        ACPITable.ssdtALS0,
        ACPITable.ssdtDMAR,
      ],
      'optional': [ACPITable.ssdtGPI0, ...optional_sstds_intel_laptop],
    },
    '11代-Rocket Lake-笔记本': {
      'basic': [
        ACPITable.ssdtECUSBXLaptop,
        ACPITable.ssdtPLUG,
        ACPITable.ssdtPNLF,
        ACPITable.ssdtAWAC,
        ACPITable.ssdtXOSI,
      ],
      'recommend': [
        ACPITable.ssdtHPET,
        ACPITable.ssdtPMC,
        ACPITable.ssdtALS0,
        ACPITable.ssdtRHUB,
        ACPITable.ssdtDMAR,
      ],
      'optional': [ACPITable.ssdtGPI0, ...optional_sstds_intel_laptop],
    },
    '12代-Alder Lake-笔记本': {
      'basic': [
        ACPITable.ssdtECUSBXLaptop,
        ACPITable.ssdtPLUGALT,
        ACPITable.ssdtPNLF,
        ACPITable.ssdtAWAC,
        ACPITable.ssdtXOSI,
      ],
      'recommend': [
        ACPITable.ssdtHPET,
        ACPITable.ssdtPMC,
        ACPITable.ssdtALS0,
        ACPITable.ssdtRHUB,
        ACPITable.ssdtDMAR,
      ],
      'optional': [ACPITable.ssdtGPI0, ...optional_sstds_intel_laptop],
    },
    '13代-Raptor Lake-笔记本': {
      'basic': [
        ACPITable.ssdtECUSBXLaptop,
        ACPITable.ssdtPLUGALT,
        ACPITable.ssdtPNLF,
        ACPITable.ssdtAWAC,
        ACPITable.ssdtXOSI,
      ],
      'recommend': [
        ACPITable.ssdtHPET,
        ACPITable.ssdtPMC,
        ACPITable.ssdtALS0,
        ACPITable.ssdtRHUB,
        ACPITable.ssdtDMAR,
      ],
      'optional': [ACPITable.ssdtGPI0, ...optional_sstds_intel_laptop],
    },
    '14代-Raptor Lake-笔记本': {
      'basic': [
        ACPITable.ssdtECUSBXLaptop,
        ACPITable.ssdtPLUGALT,
        ACPITable.ssdtPNLF,
        ACPITable.ssdtAWAC,
        ACPITable.ssdtXOSI,
      ],
      'recommend': [
        ACPITable.ssdtHPET,
        ACPITable.ssdtPMC,
        ACPITable.ssdtALS0,
        ACPITable.ssdtRHUB,
        ACPITable.ssdtDMAR,
      ],
      'optional': [ACPITable.ssdtGPI0, ...optional_sstds_intel_laptop],
    },
    '15代-Arrow Lake-笔记本': {
      'basic': [
        ACPITable.ssdtECUSBXLaptop,
        ACPITable.ssdtPLUGALT,
        ACPITable.ssdtPNLF,
        ACPITable.ssdtAWAC,
        ACPITable.ssdtXOSI,
      ],
      'recommend': [
        ACPITable.ssdtHPET,
        ACPITable.ssdtPMC,
        ACPITable.ssdtALS0,
        ACPITable.ssdtRHUB,
        ACPITable.ssdtDMAR,
      ],
      'optional': [ACPITable.ssdtGPI0, ...optional_sstds_intel_laptop],
    },
  };

  static Map<String, Map<String, dynamic>> platform_intel_nuc = {
    '0代-Penryn-迷你主机': {
      'basic': [ACPITable.ssdtECDesktop],
      'recommend': [ACPITable.ssdtHPET],
      'optional': optional_sstds_intel_nuc,
    },
    '1代-Arrandale-迷你主机': {
      'basic': [ACPITable.ssdtECDesktop],
      'recommend': [ACPITable.ssdtHPET],
      'optional': optional_sstds_intel_nuc,
    },
    '2代-Sandy Bridge-迷你主机': {
      'basic': [ACPITable.ssdtECDesktop],
      'recommend': [
        ACPITable.ssdtHPET,
        {...ACPITable.ssdtIMEI, 'extra': '3A1C'},
      ],
      'optional': optional_sstds_intel_nuc,
    },
    '3代-Ivy Bridge-迷你主机': {
      'basic': [ACPITable.ssdtECDesktop],
      'recommend': [
        ACPITable.ssdtHPET,
        {...ACPITable.ssdtIMEI, 'extra': '3A1E'},
        ACPITable.ssdtDMAR,
      ],
      'optional': optional_sstds_intel_nuc,
    },
    '4代-Haswell-迷你主机': {
      'basic': [ACPITable.ssdtECDesktop, ACPITable.ssdtPLUG],
      'recommend': [ACPITable.ssdtHPET, ACPITable.ssdtDMAR],
      'optional': [...optional_sstds_intel_nuc, ACPITable.ssdtMEM2],
    },
    '5代-Broadwell-迷你主机': {
      'basic': [ACPITable.ssdtECDesktop, ACPITable.ssdtPLUG],
      'recommend': [ACPITable.ssdtHPET, ACPITable.ssdtDMAR],
      'optional': [...optional_sstds_intel_nuc, ACPITable.ssdtMEM2],
    },
    '6代-Skylake-迷你主机': {
      'basic': [ACPITable.ssdtECUSBXDesktop, ACPITable.ssdtPLUG],
      'recommend': [ACPITable.ssdtHPET, ACPITable.ssdtDMAR],
      'optional': [...optional_sstds_intel_nuc, ACPITable.ssdtMEM2],
    },
    '7代-Kaby Lake-迷你主机': {
      'basic': [ACPITable.ssdtECUSBXDesktop, ACPITable.ssdtPLUG],
      'recommend': [ACPITable.ssdtHPET, ACPITable.ssdtDMAR],
      'optional': [...optional_sstds_intel_nuc, ACPITable.ssdtMEM2],
    },
    '8代-Coffee Lake-迷你主机': {
      'basic': [
        ACPITable.ssdtECUSBXDesktop,
        ACPITable.ssdtPLUG,
        ACPITable.ssdtPNLF,
        ACPITable.ssdtAWAC,
        ACPITable.ssdtPMC,
      ],
      'recommend': [ACPITable.ssdtHPET, ACPITable.ssdtDMAR],
      'optional': optional_sstds_intel_nuc,
    },
    '9代-Coffee Lake-迷你主机': {
      'basic': [
        ACPITable.ssdtECUSBXDesktop,
        ACPITable.ssdtPLUG,
        ACPITable.ssdtPNLF,
        ACPITable.ssdtAWAC,
        ACPITable.ssdtPMC,
      ],
      'recommend': [ACPITable.ssdtHPET, ACPITable.ssdtDMAR],
      'optional': optional_sstds_intel_nuc,
    },
    '10代-Comet Lake-迷你主机': {
      'basic': [
        ACPITable.ssdtECUSBXDesktop,
        ACPITable.ssdtPLUG,
        ACPITable.ssdtAWAC,
        ACPITable.ssdtRHUB,
      ],
      'recommend': [ACPITable.ssdtHPET, ACPITable.ssdtDMAR],
      'optional': optional_sstds_intel_nuc,
    },
    '10代-Ice Lake-迷你主机': {
      'basic': [
        ACPITable.ssdtECUSBXLaptop,
        ACPITable.ssdtPLUG,
        ACPITable.ssdtAWAC,
        ACPITable.ssdtRHUB,
      ],
      'recommend': [ACPITable.ssdtHPET, ACPITable.ssdtDMAR],
      'optional': optional_sstds_intel_nuc,
    },
    '11代-Tiger Lake-迷你主机': {
      'basic': [
        ACPITable.ssdtECUSBXDesktop,
        ACPITable.ssdtPLUG,
        ACPITable.ssdtAWAC,
      ],
      'recommend': [ACPITable.ssdtHPET, ACPITable.ssdtRHUB, ACPITable.ssdtDMAR],
      'optional': optional_sstds_intel_nuc,
    },
    '12代-Alder Lake-迷你主机': {
      'basic': [
        ACPITable.ssdtECUSBXDesktop,
        ACPITable.ssdtPLUGALT,
        ACPITable.ssdtAWAC,
      ],
      'recommend': [ACPITable.ssdtHPET, ACPITable.ssdtRHUB, ACPITable.ssdtDMAR],
      'optional': optional_sstds_intel_nuc,
    },
    '13代-Raptor Lake-迷你主机': {
      'basic': [
        ACPITable.ssdtECUSBXDesktop,
        ACPITable.ssdtPLUGALT,
        ACPITable.ssdtAWAC,
      ],
      'recommend': [ACPITable.ssdtHPET, ACPITable.ssdtRHUB, ACPITable.ssdtDMAR],
      'optional': optional_sstds_intel_nuc,
    },
    '14代-Raptor Lake-迷你主机': {
      'basic': [
        ACPITable.ssdtECUSBXDesktop,
        ACPITable.ssdtPLUGALT,
        ACPITable.ssdtAWAC,
      ],
      'recommend': [ACPITable.ssdtHPET, ACPITable.ssdtRHUB, ACPITable.ssdtDMAR],
      'optional': optional_sstds_intel_nuc,
    },
    '15代-Arrow Lake-迷你主机': {
      'basic': [
        ACPITable.ssdtECUSBXDesktop,
        ACPITable.ssdtPLUGALT,
        ACPITable.ssdtAWAC,
      ],
      'recommend': [ACPITable.ssdtHPET, ACPITable.ssdtRHUB, ACPITable.ssdtDMAR],
      'optional': optional_sstds_intel_nuc,
    },
  };

  static Map<String, Map<String, dynamic>> platform_intel_hedt = {
    '1代-Nehalem&Westmere-X58平台': {
      'basic': [ACPITable.ssdtECDesktop],
      'recommend': [ACPITable.ssdtHPET, ACPITable.ssdtAPIC],
      'optional': optional_sstds_intel_hedt,
    },
    '2代-Sandy Bridge-E-X79平台': {
      'basic': [ACPITable.ssdtECDesktop, ACPITable.ssdtUNC],
      'recommend': [ACPITable.ssdtHPET, ACPITable.ssdtAPIC, ACPITable.ssdtDMAR],
      'optional': optional_sstds_intel_hedt,
    },
    '3代-Ivy Bridge-E-X79平台': {
      'basic': [ACPITable.ssdtECDesktop, ACPITable.ssdtUNC],
      'recommend': [ACPITable.ssdtHPET, ACPITable.ssdtAPIC, ACPITable.ssdtDMAR],
      'optional': optional_sstds_intel_hedt,
    },
    '4代-Haswell-E-X99平台': {
      'basic': [
        ACPITable.ssdtECUSBXDesktop,
        ACPITable.ssdtPLUG,
        ACPITable.ssdtRTC0RANGE,
        ACPITable.ssdtUNC,
      ],
      'recommend': [ACPITable.ssdtHPET, ACPITable.ssdtAPIC, ACPITable.ssdtDMAR],
      'optional': optional_sstds_intel_hedt,
    },
    '5代-Broadwell-E-X99平台': {
      'basic': [
        ACPITable.ssdtECUSBXDesktop,
        ACPITable.ssdtPLUG,
        ACPITable.ssdtRTC0RANGE,
        ACPITable.ssdtUNC,
      ],
      'recommend': [ACPITable.ssdtHPET, ACPITable.ssdtAPIC, ACPITable.ssdtDMAR],
      'optional': optional_sstds_intel_hedt,
    },
    '6代-Skylake-X&W-X299平台': {
      'basic': [
        ACPITable.ssdtECUSBXDesktop,
        ACPITable.ssdtPLUG,
        ACPITable.ssdtRTC0RANGE,
      ],
      'recommend': [ACPITable.ssdtHPET, ACPITable.ssdtAPIC, ACPITable.ssdtDMAR],
      'optional': optional_sstds_intel_hedt,
    },
    '10代-Cascade Lake-X&W-X599平台': {
      'basic': [
        ACPITable.ssdtECUSBXDesktop,
        ACPITable.ssdtPLUG,
        ACPITable.ssdtRTC0RANGE,
      ],
      'recommend': [ACPITable.ssdtHPET, ACPITable.ssdtAPIC, ACPITable.ssdtDMAR],
      'optional': optional_sstds_intel_hedt,
    },
  };

  static Map<String, Map<String, dynamic>> platform_amd_desktop = {
    'Bulldozer(15h) and Jaguar(16h)': {
      'basic': [ACPITable.ssdtECUSBXDesktop],
      'recommend': [ACPITable.ssdtHPET, ACPITable.ssdtDMAR],
      'optional': optional_sstds_amd_desktop,
    },
    'Ryzen and Threadripper(17h and 19h)': {
      'basic': [ACPITable.ssdtECUSBXDesktop, ACPITable.ssdtPLUG],
      'recommend': [ACPITable.ssdtCPUR, ACPITable.ssdtHPET, ACPITable.ssdtDMAR],
      'optional': optional_sstds_amd_desktop,
    },
  };

  static Map<String, Map<String, dynamic>> platform_amd_laptop = {
    'Bulldozer(15h) and Jaguar(16h)-笔记本': {
      'basic': [ACPITable.ssdtECUSBXLaptop],
      'recommend': [ACPITable.ssdtHPET, ACPITable.ssdtDMAR],
      'optional': optional_sstds_amd_laptop,
    },
    'Ryzen-笔记本': {
      'basic': [
        ACPITable.ssdtECUSBXLaptop,
        ACPITable.ssdtPLUG,
        {...ACPITable.ssdtPNLF, 'extra': 19},
        ACPITable.ssdtXOSI,
      ],
      'recommend': [ACPITable.ssdtCPUR, ACPITable.ssdtHPET, ACPITable.ssdtDMAR],
      'optional': optional_sstds_amd_laptop,
    },
  };

  static Map<String, Map<String, dynamic>> platform_amd_nuc = {
    'Bulldozer(15h) and Jaguar(16h)-迷你主机': {
      'basic': [ACPITable.ssdtECUSBXDesktop],
      'recommend': [ACPITable.ssdtHPET, ACPITable.ssdtDMAR],
      'optional': optional_sstds_amd_nuc,
    },
    'Ryzen-迷你主机': {
      'basic': [ACPITable.ssdtECUSBXDesktop, ACPITable.ssdtPLUG],
      'recommend': [ACPITable.ssdtCPUR, ACPITable.ssdtHPET, ACPITable.ssdtDMAR],
      'optional': optional_sstds_amd_nuc,
    },
  };

  static Map<String, Map<String, dynamic>> platform_amd_hedt = {
    'Ryzen and Threadripper(17h and 19h)-高端服务器': {
      'basic': [ACPITable.ssdtECUSBXDesktop, ACPITable.ssdtPLUG],
      'recommend': [ACPITable.ssdtHPET, ACPITable.ssdtDMAR, ACPITable.ssdtCPUR],
      'optional': optional_sstds_amd_hedt,
    },
  };

  static Map<String, Map<String, Map<String, dynamic>>> platform_mapping = {
    'Intel': {
      '台式机': {'platform': platform_intel_desktop, 'index': 4},
      '笔记本': {'platform': platform_intel_laptop, 'index': 4},
      '迷你主机': {'platform': platform_intel_nuc, 'index': 4},
      '服务器': {'platform': platform_intel_hedt, 'index': 3},
    },
    'AMD': {
      '台式机': {'platform': platform_amd_desktop, 'index': 1},
      '笔记本': {'platform': platform_amd_laptop, 'index': 1},
      '迷你主机': {'platform': platform_amd_nuc, 'index': 1},
      '服务器': {'platform': platform_amd_hedt, 'index': 0},
    },
  };

  /// ======= 可选的SSDT表-Intel台式机 =======
  static const optional_sstds_intel_desktop = [
    ACPITable.ssdtSBUSMCHC,
    ACPITable.ssdtGPRW,
    ACPITable.ssdtFixShutdown,
    ACPITable.ssdtFACP,
    ACPITable.ssdtDMAC,
    ACPITable.ssdtPWRB,
    ACPITable.ssdtSLPB,
  ];

  /// ======= 可选的SSDT表-Intel笔记本 =======
  static const optional_sstds_intel_laptop = [
    ACPITable.ssdtSBUSMCHC,
    ACPITable.ssdtGPRW,
    ACPITable.ssdtFixShutdown,
    ACPITable.ssdtFACP,
    ACPITable.ssdtRMNE,
    ACPITable.ssdtDMAC,
    ACPITable.ssdtSLPB,
    ACPITable.ssdtPWRB,
  ];

  /// ======= 可选的SSDT表-Intel迷你主机 =======
  static const optional_sstds_intel_nuc = [
    ACPITable.ssdtSBUSMCHC,
    ACPITable.ssdtGPRW,
    ACPITable.ssdtFixShutdown,
    ACPITable.ssdtFACP,
    ACPITable.ssdtDMAC,
    ACPITable.ssdtPWRB,
    ACPITable.ssdtSLPB,
  ];

  /// ======= 可选的SSDT表-Intel服务器 =======
  static const optional_sstds_intel_hedt = [
    ACPITable.ssdtSBUSMCHC,
    ACPITable.ssdtGPRW,
    ACPITable.ssdtFixShutdown,
    ACPITable.ssdtFACP,
    ACPITable.ssdtDMAC,
    ACPITable.ssdtPWRB,
    ACPITable.ssdtSLPB,
  ];

  /// ======= 可选的SSDT表-AMD台式机 =======
  static const optional_sstds_amd_desktop = [
    ACPITable.ssdtSBUSMCHC,
    ACPITable.ssdtGPRW,
    ACPITable.ssdtFixShutdown,
    ACPITable.ssdtFACP,
    ACPITable.ssdtDMAC,
    ACPITable.ssdtPWRB,
    ACPITable.ssdtSLPB,
  ];

  /// ======= 可选的SSDT表-AMD笔记本 =======
  static const optional_sstds_amd_laptop = [
    ACPITable.ssdtSBUSMCHC,
    ACPITable.ssdtGPRW,
    ACPITable.ssdtFixShutdown,
    ACPITable.ssdtFACP,
    ACPITable.ssdtRMNE,
    ACPITable.ssdtDMAC,
    ACPITable.ssdtSLPB,
    ACPITable.ssdtPWRB,
  ];

  /// ======= 可选的SSDT表-AMD迷你主机 =======
  static const optional_sstds_amd_nuc = [
    ACPITable.ssdtSBUSMCHC,
    ACPITable.ssdtGPRW,
    ACPITable.ssdtFixShutdown,
    ACPITable.ssdtFACP,
    ACPITable.ssdtDMAC,
    ACPITable.ssdtPWRB,
    ACPITable.ssdtSLPB,
  ];

  /// ======= 可选的SSDT表-AMD服务器 =======
  static const optional_sstds_amd_hedt = [
    ACPITable.ssdtSBUSMCHC,
    ACPITable.ssdtGPRW,
    ACPITable.ssdtFixShutdown,
    ACPITable.ssdtFACP,
    ACPITable.ssdtDMAC,
    ACPITable.ssdtPWRB,
    ACPITable.ssdtSLPB,
  ];
}
