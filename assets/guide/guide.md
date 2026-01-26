
详细补丁指南可以参考[SSDT-补丁指南](https://github.com/JeoJay127/RapidSSDT/blob/main/wiki/SSDT-补丁指南.md)

### 1.工具兼容性

- Windows: 仅支持 Windows 10及以上 (不支持 Windows 8、7及更早版本).建议彻底关闭360，腾讯电脑管家，火绒等安全软件,以免操作过程中被拦截.

- macOS: 仅支持 macOS 10.15及以上,且显卡需支持 Metal (不建议macOS提取ACPI,请使用Windows或者Linux提取)

- Linux: 支持Debian 10及以上, Ubuntu 20.04 LTS ~  24.04 LTS (不支持20.04及更老版本，以及24.10及以上版本)

### 2.提取ACPI

##### **注意事项:** 

如果更改了以下任何一项，您必须重新提取、重新补丁，因为这些更改可能会导致本机ACPI（特别是SystemMemory区域）发生重大更改：

- 更新BIOS

- 更改任何BIOS选项

- 更改硬件或内存配置

##### 2.1 使用Windows提取(推荐)

  - 确保使用原生Boot Manager 方式来启动Windows，如果你使用了三方引导，比如：OpenCore来引导进入Windows系统，那么提取的ACPI表几乎已经被OpenCore注入的ACPI补丁污染，并非原始ACPI表！

##### 2.2 使用Linux提取(可选)  

 - 已经安装好Linux的情况下,可以使用Linux来提取ACPI表.一般不建议专门安装Linux来提取ACPI表

##### 2.3 使用macOS提取(不推荐)  

 - 不建议在macOS上提取ACPI表,因为绝大多数启动场景下,macOS都已经被OpenCore等引导器注入了ACPI补丁,提取的ACPI表几乎已经被污染,并非原始ACPI表!

 - 如果已经安装了macOS，并且目前没有使用任何补丁的ACPI文件启动，那么可以在Mac系统提取ACPI,否则不建议在Mac系统提取ACPI.