//  dsdt.dart
//  Created by JeoJay127
//
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:rapidssdt/utils/log/log.dart';
import 'package:rapidssdt/utils/ssdttool/tool.dart';
import 'package:rapidssdt/utils/ssdttool/util.dart';
import 'package:path/path.dart' as path;
import 'run.dart';

class DSDT {
  final ACPITool acpiTool;
  final Run r = Run();
  final Util util = Util();

  /// 是否使用本地工具
  bool useLocaliAsl;

  /// 是否使用本地工具
  bool useLeagcyiAsl;

  /// 允许的签名列表
  final List<String> allowedSignatures = [
    "APIC",
    "DMAR",
    "FACP",
    "DSDT",
    "SSDT",
  ];

  /// 混合列表
  final List<String> mixedListing = ["DSDT", "SSDT"];

  /// ACPI 表映射
  Map<String, dynamic> acpiTables = {};

  /// 十六进制匹配正则表达式
  final RegExp hexMatch = RegExp(
    r"^\s*[0-9A-F]{4,}:(\s[0-9A-F]{2})+(\s+\/\/.*)?$",
  );

  /// 类型匹配正则表达式
  final RegExp typeMatch = RegExp(
    r".*(Processor|Scope|Device|Method|Name) \(([^,\)]+).*",
  );

  DSDT({required this.useLocaliAsl, this.useLeagcyiAsl = false})
    : acpiTool = ACPITool(
        useLocaliAsl: useLocaliAsl,
        useLegacyAsl: useLeagcyiAsl,
      );

  /// 获取表签名
  /// [tablePath]: 表路径
  /// [tableName]: 表名（可选）
  /// [data]: 数据（可选）
  /// 如果表存在，返回前4个字节的签名；如果表不存在或发生错误，返回 null。
  String? tableSignature(
    String tablePath, {
    String? tableName,
    Uint8List? data,
  }) {
    // 构建表完整路径
    final filePath = tableName != null && tableName.isNotEmpty
        ? path.join(tablePath, tableName)
        : tablePath;

    // 检查表是否存在
    final file = File(filePath);
    if (!file.existsSync()) {
      Log('表不存在: $filePath');
      return null;
    }
    if (data != null) {
      // 已传入数据, 确保数据长度足够用于签名（至少 4 字节）
      if (data.length >= 4) {
        return String.fromCharCodes(data.sublist(0, 4));
      } else {
        Log('传入数据长度不足 4 字节: $filePath');
        return null;
      }
    }
    RandomAccessFile? openedFile;
    try {
      // 打开文件
      openedFile = file.openSync(mode: FileMode.read);

      // 读取前4个字节
      final bytes = openedFile.readSync(4);
      if (bytes.length < 4) {
        Log('文件内容不足 4 字节: $filePath');
        return null;
      }

      // 检查是否可以转换为字符串
      return String.fromCharCodes(bytes);
    } catch (e) {
      // 捕获任何异常并返回 null
      Log.error('读取签名发生错误: $e, 文件路径: $filePath');
      return null;
    } finally {
      // 确保文件关闭
      openedFile?.closeSync();
    }
  }

  /// 统计非 ASCII 字符数量
  /// [data]: 数据
  /// 返回非 ASCII 字符数量
  int nonAsciiCountFunc(Uint8List data) {
    int nonAscii = 0;
    for (final byte in data) {
      if (byte >= 0x80) {
        nonAscii++;
      }
    }
    return nonAscii;
  }

  /// 判断表是否有效
  /// [tablePath]: 表路径
  /// [tableName]: 表名（可选）
  /// 如果表的签名在允许的签名列表中，则返回 true，否则返回 false。
  /// 如果 [checkSignature] 为 true，则会检查表的签名；否则不会检查签名。

  bool tableIsValid(
    String tablePath, {
    String? tableName,
    bool? ensureBinary = true,
    bool checkSignature = true,
  }) {
    // 构建表完整路径
    final filePath = tableName != null && tableName.isNotEmpty
        ? path.join(tablePath, tableName)
        : tablePath;
    // 检查文件是否存在
    final file = File(filePath);

    if (!file.existsSync()) {
      return false;
    }
    // 设置一个用于存放数据的占位变量
    Uint8List? data;
    if (ensureBinary != null) {
      // 确保该表是正确的类型 - 读取它的数据
      try {
        data = file.readAsBytesSync();
      } catch (_) {
        return false;
      }
      // 确保确实读取到数据
      if (data.isEmpty) {
        return false;
      }
      // 统计非 ASCII 字符数量
      int nonAsciiCountResult = nonAsciiCountFunc(data);
      if (ensureBinary && nonAsciiCountResult == 0) {
        // 期望是二进制文件，但它全部是 ASCII
        return false;
      } else if (!ensureBinary && nonAsciiCountResult > 0) {
        // 期望是 ASCII，但它是二进制
        return false;
      }
    }

    if (checkSignature) {
      // 检查签名 - 如果之前没加载数据，现在加载
      if (!allowedSignatures.contains(tableSignature(filePath, data: data))) {
        return false;
      }
    }
    // 表通过所有检查
    return true;
  }

  /// 根据 ID 获取表
  /// [tableId] : 表ID
  Map<String, dynamic>? getTableWithId(String tableId) {
    try {
      return acpiTables.values.firstWhere(
        (v) => v['id'] == tableId,
        orElse: () => null,
      );
    } catch (e) {
      return null;
    }
  }

  /// 根据签名获取表
  /// [tableSig] : 签名
  Map<String, dynamic>? getTableWithSignature(String tableSig) {
    try {
      return acpiTables.values.firstWhere(
        (v) => v['signature'] == tableSig,
        orElse: () => null,
      );
    } catch (e) {
      return null;
    }
  }

  /// 根据 ID 或签名获取表
  /// [tableIdOrSig] : ID 或签名
  Map<String, dynamic>? getTable(String tableIdOrSig) {
    try {
      return acpiTables.values.firstWhere(
        (v) => v['id'] == tableIdOrSig || v['signature'] == tableIdOrSig,
        orElse: () => null,
      );
    } catch (e) {
      return null;
    }
  }

  /// 获取 DSDT 表
  Map<String, dynamic>? getDsdt() {
    return getTableWithSignature("DSDT");
  }

  /// 查找位于传入 index 之前的上一组十六进制数字
  /// 并返回这组十六进制数字的文本内容、起始索引和结束索引 (文本, 起始索引, 结束索引)
  /// [index] : 起始索引
  /// [table] : 提供的 ACPI 表，可选
  (String, int, int) findPreviousHex({
    int index = 0,
    Map<String, dynamic>? table,
  }) {
    table ??= getDsdt();
    if (table == null) return ("", -1, -1);

    final lines = table['lines'];
    if (lines is! List || lines.isEmpty || index < 0 || index >= lines.length) {
      return ("", -1, -1);
    }

    final reversedLines = lines.sublist(0, index + 1).reversed.toList();

    bool seenNonHex = false;

    for (int i = 0; i < reversedLines.length; i++) {
      final line = reversedLines[i];

      if (!seenNonHex) {
        if (!isHex(line)) {
          seenNonHex = true;
        }
        continue;
      }

      if (isHex(line)) {
        final endIndex = index - i;
        final (hexText, startIndex) = getHexEndingAt(endIndex, table: table);
        return (hexText, startIndex, endIndex);
      }
    }

    return ("", -1, -1);
  }

  /// 查找位于传入 index 之后的下一组十六进制数字
  /// 并返回这组十六进制数字的文本内容、起始索引和结束索引 (文本, 起始索引, 结束索引)
  /// [index] : 起始索引
  /// [table] : 提供的 ACPI 表，可选
  (String, int, int) findNextHex({int index = 0, Map<String, dynamic>? table}) {
    // 如果未提供table，则获取 DSDT 或唯一表
    table ??= getDsdt();
    if (table == null) return ("", -1, -1);

    int startIndex = -1;
    int endIndex = -1;
    bool oldHex = true;

    var lines = table['lines'] ?? [];
    for (int i = index; i < lines.length; i++) {
      String line = lines[i];

      if (oldHex) {
        if (!isHex(line)) {
          oldHex = false;
        }
        continue;
      }

      if (isHex(line)) {
        startIndex = i;
        final result = getHexStartingAt(startIndex, table: table);
        final hexText = result.$1;
        endIndex = result.$2;
        return (hexText, startIndex, endIndex);
      }
    }
    return ("", startIndex, endIndex);
  }

  /// 检查是否是十六进制数据
  bool isHex(String line) {
    return hexMatch.hasMatch(line.trim());
  }

  /// 从指定索引开始获取十六进制字符串，并返回结束索引
  /// [startIndex] : 起始索引
  /// [table] : 提供的 ACPI 表，可选
  (String, int) getHexStartingAt(
    int startIndex, {
    Map<String, dynamic>? table,
  }) {
    // 如果未提供table，则获取 DSDT 或唯一表
    table ??= getDsdt();
    if (table == null) {
      return ("", -1);
    }

    String hexText = "";
    int index = -1;

    List<String> lines = List<String>.from(table["lines"] ?? []);
    for (int i = 0; i < lines.length; i++) {
      String x = lines[startIndex + i];
      if (!isHex(x)) {
        break;
      }
      hexText += util.getHex(x);
      index = startIndex + i;
    }

    return (hexText, index);
  }

  /// 从指定索引结束获取十六进制字符串，并返回开始索引
  /// [startIndex] : 结束索引
  /// [table] : 提供的 ACPI 表，可选
  (String, int) getHexEndingAt(int startIndex, {Map<String, dynamic>? table}) {
    // 如果未提供table，则获取 DSDT 或唯一表
    table ??= getDsdt();
    if (table == null) {
      return ("", -1);
    }

    String hexText = "";
    int index = -1;

    // 遍历 lines 列表，按逆序索引查找十六进制字符串
    List<String> lines = List<String>.from(table["lines"]);
    for (int i = 0; i < lines.length; i++) {
      String x = lines[startIndex - i];
      if (!isHex(x)) {
        break;
      }
      hexText = util.getHex(x) + hexText;
      index = startIndex - i;
    }

    return (hexText, index);
  }

  /// 检查某个特定文件是否存在，并且文件大小是否大于 0（非空文件）
  /// [folderPath] : 文件夹路径
  /// [fileName] : 文件名
  bool exists(String folderPath, String fileName) {
    //如果folderPath不是目录
    if (!Directory(folderPath).existsSync()) {
      folderPath = Directory(folderPath).parent.path;
    }
    // 拼接路径
    final checkPath = path.join(folderPath, fileName);
    // 检查文件是否存在且非空
    final file = File(checkPath);
    if (file.existsSync() && file.lengthSync() > 0) {
      return true;
    }

    return false;
  }

  /// 加载ACPI表
  /// [tablePath] : 表路径
  /// [exclude] : 排除的表名
  Future<(Map, List)> loadTable(
    String tablePath, {
    List<String> exclude = const [],
    List<String> externalTables = const [],
    bool logProgress = true,
  }) async {
    String cwd = Directory.current.path;
    Directory? temp;
    Map<String, Map<String, dynamic>> targetFiles = {};
    final excludeSet = exclude.map((e) => e.toLowerCase()).toSet();
    List<String> failed = [];
    void progress(String message) {
      if (logProgress) Log(message);
    }

    try {
      List<String> validFiles = [];

      // 检查路径是文件还是目录
      if (Directory(tablePath).existsSync()) {
        // 如果是目录，获取所有有效的文件
        var files = Directory(tablePath).listSync().toList();
        validFiles = files
            .where((item) {
              final name = path.basename(item.path);
              if (excludeSet.contains(name.toLowerCase())) {
                progress("跳过: $name ,先前已经正确反编译!");
                return false;
              }
              return tableIsValid(tablePath, tableName: name);
            })
            .map((item) => item.path)
            .toList();
      } else if (File(tablePath).existsSync()) {
        final name = path.basename(tablePath);
        if (excludeSet.contains(name.toLowerCase())) {
          Log.warning("目标文件在排除列表中: $name");
        } else if (tableIsValid(tablePath, checkSignature: false)) {
          validFiles = [tablePath];
        }
      } else {
        Log.warning("无效路径: $tablePath");
        throw FileSystemException("无效路径", tablePath);
      }

      if (validFiles.isEmpty && exclude.isEmpty) {
        Log.warning("在$tablePath 没有找到有效的.aml 或.dat 文件!");
        return ({}, failed);
      }

      // 创建临时目录,存放要反编译的文件
      temp = Directory.systemTemp.createTempSync();
      // 判断目录是否存在
      if (!temp.existsSync()) {
        // 创建目录
        temp.createSync(recursive: true);
        debugPrint('临时目录已创建于：${temp.path}');
      } else {
        debugPrint('临时目录已存在于：${temp.path}');
      }

      for (var file in validFiles) {
        await File(file).copy(path.join(temp.path, path.basename(file)));
      }
      final externalFileNames = <String>[];
      for (final externalTable in externalTables) {
        final externalFile = File(externalTable);
        if (!externalFile.existsSync()) {
          Log.warning("外部 ACPI 表不存在，已跳过: $externalTable");
          continue;
        }
        final externalName = path.basename(externalTable);
        final externalTarget = path.join(temp.path, externalName);
        if (!File(externalTarget).existsSync()) {
          await externalFile.copy(externalTarget);
        }
        externalFileNames.add(externalName);
      }

      // 处理有效文件
      var tempDir = Directory(temp.path);
      var listDir = tempDir.listSync().toList();
      //如果是文件，过滤其他
      if (File(tablePath).existsSync()) {
        listDir = listDir
            .where((e) => path.basename(e.path) == path.basename(tablePath))
            .toList();
      }

      for (var file in listDir) {
        String fileName = file.uri.pathSegments.last;
        if (listDir.length > 1 &&
            !tableIsValid(temp.path, tableName: fileName)) {
          continue; // 如果是多个文件，跳过无效文件
        }
        var nameExt = fileName.split('.');
        if (nameExt.isNotEmpty &&
            (nameExt.last.toLowerCase() == 'asl' ||
                nameExt.last.toLowerCase() == 'dsl')) {
          continue; // 跳过已反编译的文件
        }

        targetFiles[fileName] = {
          'assembledName': fileName,
          'disassembledName':
              '${fileName.split('.').sublist(0, fileName.split('.').length - 1).join('.')}.dsl',
        };
      }

      if (targetFiles.isEmpty && exclude.isEmpty) {
        throw FileSystemException("没有找到有效的 .aml 或 .dat 文件", tablePath);
      }

      /// 切换到临时目录,减少目录太深的问题
      Directory.current = temp;
      List<String> dsdtOrSsdt = targetFiles.keys
          .where(
            (x) => mixedListing.contains(
              tableSignature(temp?.path ?? '', tableName: x),
            ),
          )
          .map((e) => e)
          .toList();
      List<String> otherTables = targetFiles.keys
          .where((x) => !dsdtOrSsdt.any((path) => path.endsWith(x)))
          .map((e) => e)
          .toList();

      // 反编译 DSDT 和 SSDT 表
      if (dsdtOrSsdt.isNotEmpty) {
        if (externalFileNames.isNotEmpty) {
          progress(
            '正在使用 ${externalFileNames.join(', ')} 作为外部命名空间联合反编译 '
            '${dsdtOrSsdt.map(path.basename).join(', ')} ...',
          );
        } else if (dsdtOrSsdt.length == 1) {
          progress('正在反编译 ${dsdtOrSsdt.first} 文件...');
        } else {
          if (excludeSet.contains('dsdt.aml')) {
            progress('正在批量反编译 SSDT.aml 文件...');
          } else {
            progress('正在批量反编译 DSDT.aml 和 SSDT.aml 文件...');
          }
        }
        List<String> failedTemp = [];
        List<String> args = externalFileNames.isNotEmpty
            ? [
                acpiTool.iasl,
                "-e",
                ...externalFileNames,
                "-dl",
                "-l",
                ...dsdtOrSsdt,
              ]
            : [acpiTool.iasl, "-da", "-dl", "-l", ...dsdtOrSsdt];
        var result = await r.run([
          {"args": args},
        ]);

        if (result.isNotEmpty &&
            result.last != '0' &&
            externalFileNames.isNotEmpty) {
          for (final table in dsdtOrSsdt) {
            final output = File(
              path.join(
                temp.path,
                targetFiles[path.basename(table)]!['disassembledName'],
              ),
            );
            if (output.existsSync()) output.deleteSync();
            if (logProgress) {
              Log.warning('=> ${path.basename(table)} 与外部 ACPI 表联合反编译失败！');
            }
          }
        } else if (result.isNotEmpty && result.last != '0') {
          // 如果第一次反编译失败，重试一次，不带 -da 参数
          args = [acpiTool.iasl, "-dl", "-l", ...dsdtOrSsdt];
          final res = await r.run([
            {"args": args},
          ]);
          if (res.isNotEmpty && res.last != '0') {
            // 如果第二次反编译仍然失败，则打印错误信息
            for (var e in dsdtOrSsdt) {
              if (!exists(
                temp.path,
                targetFiles[path.basename(e)]!['disassembledName'],
              )) {
                Log.warning('=> ${path.basename(e)} 反编译失败！');
              } else {
                progress('=> ${path.basename(e)} 反编译成功！');
              }
            }
            progress('');
          } else {
            for (var e in dsdtOrSsdt) {
              progress('=> ${path.basename(e)} 反编译成功！');
            }
            progress('');
          }
        } else {
          for (var e in dsdtOrSsdt) {
            progress('=> ${path.basename(e)} 反编译成功！');
          }
        }

        // 获取反编译名称失败的列表
        for (var e in dsdtOrSsdt) {
          if (!exists(
            temp.path,
            targetFiles[path.basename(e)]!['disassembledName'],
          )) {
            failedTemp.add(e);
          }
        }

        // 单独反编译失败的.aml 文件
        if (failedTemp.isNotEmpty) {
          if (externalFileNames.isNotEmpty) {
            // SSDT 独立反编译会把 DSDT 中的 FieldUnit 等对象误判为 MethodObj，
            // 产生能够反编译、但无法重新编译的损坏 DSL，因此不能降级重试。
            failed.addAll(failedTemp);
          } else {
            progress('正在单独反编译失败的.aml 文件...');
            for (var e in failedTemp) {
              args = [acpiTool.iasl, "-dl", "-l", e];
              final res = await r.run([
                {"args": args},
              ]);
              if (res.isNotEmpty && res.last == '0') {
                progress('=> $e 反编译成功！');
              } else {
                Log.error('=> $e 反编译失败！');
              }
              if (!exists(
                temp.path,
                targetFiles[path.basename(e)]!['disassembledName'],
              )) {
                failed.add(e);
              }
            }
            progress('');
          }
        }
      }

      // 反编译其他.aml文件 (例如 DMAR, APIC)
      if (otherTables.isNotEmpty) {
        progress('正在反编译其他.aml文件...');
        List<String> args = [acpiTool.iasl, "-dl", "-l", ...otherTables];
        final res = await r.run([
          {"args": args},
        ]);

        if (res.last == '0') {
          for (var e in otherTables) {
            progress('=>  ${path.basename(e)} 反编译成功！');
          }
        }
        // 获取反编译名称失败的列表
        for (var e in otherTables) {
          if (!exists(
            temp.path,
            targetFiles[path.basename(e)]!['disassembledName'],
          )) {
            failed.add(e);
          }
        }
      }

      if (logProgress &&
          failed.length == targetFiles.length &&
          exclude.isEmpty) {
        Log.error("反编译失败: ${failed.toList()}");
      }

      List<String> toRemove = [];
      // 处理反编译后的文件
      for (var file in targetFiles.keys) {
        file = path.basename(file);
        String disassembledPath = path.join(
          temp.path,
          targetFiles[file]!['disassembledName'],
        );

        if (!exists(temp.path, disassembledPath)) {
          toRemove.add(file);
          continue;
        }

        String tableContent = await File(disassembledPath).readAsString();
        targetFiles[file]!['table'] = tableContent;
        // 删除文件开头的编译器信息
        if (targetFiles[file]!["table"]!.startsWith("/*")) {
          final contentParts = targetFiles[file]!["table"]!.split("*/");
          targetFiles[file]!["table"] = contentParts
              .sublist(1)
              .join("*/")
              .trim();
        }

        // 检查 "Table Header:" 或 "Raw Table Data: Length"，并去除这些部分后的内容
        for (final header in ["\nTable Header:", "\nRaw Table Data: Length"]) {
          if (targetFiles[file]!["table"]!.contains(header)) {
            final contentParts = targetFiles[file]!["table"]!.split(header);
            targetFiles[file]!["table"] = contentParts
                .sublist(0, contentParts.length - 1)
                .join(header)
                .trim();
            break; // 找到匹配项后立即退出循环
          }
        }

        // 按行分割表数据
        targetFiles[file]!["lines"] = targetFiles[file]!["table"]!.split('\n');

        // 调用自定义方法处理作用域和路径
        targetFiles[file]!["scopes"] = getScopes(table: targetFiles[file]!);
        targetFiles[file]!["paths"] = getPaths(table: targetFiles[file]!);

        String filePath = path.join(temp.path, file);
        final tableBytes = await File(filePath).readAsBytes();
        targetFiles[file]!["raw"] = tableBytes;
        // 解析表头并提取信息
        targetFiles[file]!["signature"] = utf8.decode(tableBytes.sublist(0, 4));
        targetFiles[file]!["revision"] = tableBytes[8];
        targetFiles[file]!["oem"] = utf8.decode(
          tableBytes.sublist(10, 16).where((byte) => byte != 0).toList(),
        );
        targetFiles[file]!["id"] = utf8.decode(
          tableBytes.sublist(16, 24).where((byte) => byte != 0).toList(),
        );
        targetFiles[file]!["oem_revision"] = util.littleEndianToInt(
          tableBytes.sublist(24, 28),
        );
        targetFiles[file]!["length"] = tableBytes.length;

        /// 如果是 DSDT 或 SSDT 表，处理十六进制数据
        if (mixedListing.contains(targetFiles[file]!["signature"])) {
          // 构造十六进制数据的最后一部分
          final lines = targetFiles[file]!["lines"] as List<String>;
          final lastHex = lines.reversed.firstWhere(
            (line) => isHex(line),
            orElse: () => '',
          );

          int nextAddr = 0;
          Uint8List remaining = Uint8List(0);
          if (lastHex.isNotEmpty) {
            // 获取地址和十六进制字节
            final addr = int.parse(lastHex.split(":")[0].trim(), radix: 16);
            final hexs = lastHex.split(":")[1].split("//")[0].trim();
            nextAddr = addr + hexs.split(" ").length;

            // 获取末尾的原始数据
            final hexb = util.getHexBytes(hexs.replaceAll(" ", ""));
            final raw = targetFiles[file]!["raw"];
            // 取最后一段数据
            int lastIndex = util.indexOfSubBytes(raw, hexb, reverse: true);
            if (lastIndex != -1 && lastIndex + hexb.length < raw.length) {
              remaining = Uint8List.fromList(
                raw.sublist(lastIndex + hexb.length),
              );
            } else {
              remaining = Uint8List(0);
            }
          }
          // 分块处理剩余数据
          for (var i = 0; i < remaining.length; i += 16) {
            final chunk = remaining.sublist(
              i,
              i + 16 > remaining.length ? remaining.length : i + 16,
            );
            final hexString = chunk
                .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
                .join(" ");

            final line =
                "   ${nextAddr.toRadixString(16).toUpperCase().padLeft(4, '0')}: $hexString";
            nextAddr += chunk.length;

            // 添加到目标文件的数据中
            lines.add(line);
            targetFiles[file]!["table"] += "\n$line";
          }
        }
      }
      // 将新的表数据添加或更新到 acpiTables 中
      for (var table in targetFiles.keys) {
        acpiTables[table] = targetFiles[table]!;
      }
      // 移除没有反编译的文件
      for (var file in toRemove) {
        targetFiles.remove(file);
      }
      // 返回已加载的表数据
      return (targetFiles, failed);
    } catch (e) {
      if (e.toString().contains('Failed to decode data using encoding')) {
        Log.warning('注意：路径或文件名尽量不要包含中文或特殊字符,否则可能带来意外问题！');
      } else {
        Log.error('发生错误 : ${e.toString()}');
      }

      return ({}, failed);
    } finally {
      Directory.current = cwd;
      // 清理临时文件夹
      if (temp != null) {
        Directory(temp.path).deleteSync(recursive: true);
      }
    }
  }

  Future<String?> _getDumpToolPath({bool useLocaliAsl = false}) async {
    final String dir = await acpiTool.getExecutableDir(local: useLocaliAsl);
    final fileName = Platform.isWindows
        ? 'acpidump.exe'
        : Platform.isLinux
        ? 'acpidump'
        : Platform.isMacOS
        ? 'patchmatic'
        : null;

    if (fileName == null) return null;
    return path.join(dir, fileName);
  }

  Future<bool> checkDumpTool({bool useLocaliAsl = false}) async {
    final exePath = await _getDumpToolPath(useLocaliAsl: useLocaliAsl);
    return exePath != null && File(exePath).existsSync();
  }

  /// 导出 ACPI 表
  /// [filePath] : 路径
  /// [disassemble] : 是否反编译
  /// [onRequestSudoPassword]
  Future<String?> dumpTables(
    String filePath, {
    bool disassemble = false,
    Future<String?> Function()? onRequestSudoPassword,
  }) async {
    final exePath = await _getDumpToolPath(useLocaliAsl: useLocaliAsl);
    if (exePath == null || !File(exePath).existsSync()) {
      Log.warning("acpidump 工具未准备就绪！已终止操作！");
      return null;
    }

    Log("正在导出 ACPI 表...");
    String outputPath = await util.checkPath(
      filePath: filePath,
      onError: (error) => Log.error(error),
    );

    if (!(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      Log.error("当前平台不支持!");
      return null;
    }

    Future<ProcessResult> runDump({String? sudoPassword}) async {
      if (Platform.isMacOS) {
        return await Process.run(exePath, [
          '-extractall',
          '-raw',
        ], workingDirectory: outputPath);
      } else if (Platform.isLinux && sudoPassword != null) {
        final process = await Process.start(
          'sudo',
          ['-S', exePath, '-b'],
          workingDirectory: outputPath,
          runInShell: true,
        );
        process.stdin.writeln(sudoPassword);
        await process.stdin.flush();
        await process.stdin.close();

        final stdoutData = await process.stdout
            .transform(SystemEncoding().decoder)
            .join();
        final stderrData = await process.stderr
            .transform(SystemEncoding().decoder)
            .join();
        final exitCode = await process.exitCode;

        return ProcessResult(process.pid, exitCode, stdoutData, stderrData);
      } else {
        return await Process.run(exePath, ['-b'], workingDirectory: outputPath);
      }
    }

    String? sudoPassword;
    if (Platform.isLinux && onRequestSudoPassword != null) {
      Log("等待输入 sudo 密码授权...");
      sudoPassword = await onRequestSudoPassword();
      if (sudoPassword == null || sudoPassword.isEmpty) {
        Log.warning("用户取消授权");
        return null;
      }
    }
    final result = await runDump(sudoPassword: sudoPassword);

    if (result.exitCode != 0) {
      Log.error("发生错误: ${result.stderr}");
      return null;
    }

    bool hasTable = Directory(outputPath).listSync().any(
      (file) =>
          file.path.toLowerCase().endsWith(".aml") ||
          file.path.toLowerCase().endsWith(".dat"),
    );
    if (!hasTable) {
      Log.warning("当前平台提取 ACPI 表为空或不支持导出 ACPI 表！");
      return null;
    }

    if (!Directory(
      outputPath,
    ).listSync().any((file) => file.path.toLowerCase().contains("dsdt."))) {
      Log.warning("=> 未找到 DSDT，正在按签名导出…");
      final dsdtResult = await Process.run(exePath, [
        '-b',
        '-n',
        'DSDT',
      ], workingDirectory: outputPath);
      if (dsdtResult.exitCode != 0) {
        Log.error("发生错误: ${dsdtResult.stderr}");
        return null;
      }
    }

    Log("正在更新表名…");
    for (var entity in Directory(outputPath).listSync()) {
      if (entity is File) {
        String newName = entity.uri.pathSegments.last
            .toUpperCase()
            .replaceAll(".DAT", ".aml")
            .replaceAll(".AML", ".aml");
        if (newName != entity.uri.pathSegments.last) {
          try {
            entity.renameSync(path.join(outputPath, newName));
          } catch (e) {
            Log.error("=> 重命名失败: $e");
          }
        }
      }
    }

    Log("导出 ACPI 表成功!");
    if (disassemble) {
      await loadTable(outputPath);
    }

    return outputPath;
  }

  /// 获取唯一的填充字符串
  /// [currentHex] : 当前的十六进制数据行内容
  /// [index] : 当前所在行的索引
  /// [direction] : 搜索方向（true 表示向前，false 表示向后, null 表示双向）
  /// [instance] : 当前是该对象的第几个实例（可选）
  /// [table] : 提供的 ACPI 表，可选
  (String, String) getUniquePad({
    required String currentHex,
    required int index,
    bool? direction,
    int instance = 0,
    Map<String, dynamic>? table,
  }) {
    // 如果未提供table，则获取 DSDT 或唯一表
    table ??= getDsdt();
    if (table == null) {
      throw Exception("未提供有效 ACPI 表!");
    }

    int startIndex = index;
    var result = getHexStartingAt(index, table: table);
    String line = result.$1;
    int lastIndex = result.$2;

    if (lastIndex == -1) {
      throw Exception("未找到从 $index 这个位置开始的十六进制数据!");
    }
    String firstLine = line;

    /// 假设 currentHex 至少有 1 字节的数据存在于 index 位置，如果还未找到完整数据
    /// 则至少需要加载 len(current_hex) - 2 长度的数据。
    while (true) {
      if (line.contains(currentHex) ||
          line.length >= firstLine.length + currentHex.length) {
        break; // 已达到上限
      }
      var newResult = findNextHex(index: lastIndex, table: table);
      String newLine = newResult.$1;
      lastIndex = newResult.$2;
      if (lastIndex == -1) {
        throw Exception("未没找到要定位的十六进制数据!");
      }
      line += newLine;
    }

    if (!line.contains(currentHex)) {
      throw Exception("未在索引 $startIndex-$lastIndex 范围内找到 $currentHex !");
    }

    String padl = "";
    String padr = "";
    List<String> parts = line.split(currentHex);
    if (instance >= parts.length - 1) {
      throw Exception("实例 $instance 超出范围!");
    }

    String linel = parts.sublist(0, instance + 1).join(currentHex);
    String liner = parts.sublist(instance + 1).join(currentHex);

    while (true) {
      // 检查十六进制字符串是否唯一
      var checkBytes = util.getHexBytes(padl + currentHex + padr);
      if (util.containsSublist(table["raw"], checkBytes, 1)) {
        break;
      }

      if (direction == true ||
          (direction == null && padr.length <= padl.length)) {
        // 检查前向字节
        if (liner.isEmpty) {
          // 需要更多数据
          var nextResult = findNextHex(index: lastIndex, table: table);
          liner = nextResult.$1;
          lastIndex = nextResult.$3;
          if (lastIndex == -1) {
            throw Exception("未没找到要定位的十六进制数据!");
          }
        }
        padr += liner.substring(0, 2);
        liner = liner.substring(2);
        continue;
      }

      if (direction == false ||
          (direction == null && padl.length <= padr.length)) {
        // 检查后向字节
        if (linel.isEmpty) {
          // 需要更多数据
          var prevResult = findPreviousHex(index: startIndex, table: table);
          linel = prevResult.$1;
          startIndex = prevResult.$2;
          var endIndex = prevResult.$3;
          if (endIndex == -1) {
            throw Exception("未没找到要定位的十六进制数据!");
          }
        }
        padl = linel.substring(linel.length - 2) + padl;
        linel = linel.substring(0, linel.length - 2);
        continue;
      }
      break;
    }

    return (padl, padr);
  }

  /// 获取最短的唯一填充标识（Pad），用于在 ACPI 表中唯一标识某个对象的位置
  /// [currentHex] : 当前的十六进制数据行内容
  /// [index] : 当前所在行的索引
  /// [instance] : 当前是该对象的第几个实例（可选）
  /// [table] : 提供的 ACPI 表，可选
  (String, String) getShortestUniquePad({
    required String currentHex,
    required int index,
    int instance = 0,
    Map<String, dynamic>? table,
  }) {
    // 如果未提供table，则获取 DSDT 或唯一表
    table ??= getDsdt();
    // 没有有效的 table，返回 null
    if (table == null) {
      return ("", "");
    }

    (String, String)? leftPad;
    (String, String)? rightPad;
    (String, String)? midPad;

    try {
      // 尝试获取从左侧扫描得到的唯一 Pad
      leftPad = getUniquePad(
        currentHex: currentHex,
        index: index,
        direction: false,
        instance: instance,
        table: table,
      );
    } catch (e) {
      leftPad = null;
    }
    try {
      // 尝试获取从右侧扫描得到的唯一 Pad
      rightPad = getUniquePad(
        currentHex: currentHex,
        index: index,
        direction: true,
        instance: instance,
        table: table,
      );
    } catch (e) {
      rightPad = null;
    }
    try {
      // 尝试获取从当前位置中间范围扫描得到的唯一 Pad
      midPad = getUniquePad(
        currentHex: currentHex,
        index: index,
        direction: null,
        instance: instance,
        table: table,
      );
    } catch (e) {
      midPad = null;
    }
    // 三个方向都无法获取唯一 Pad，则抛出异常
    if (leftPad == null && rightPad == null && midPad == null) {
      throw Exception("未找到唯一的填充标识!");
    }

    // 三个方向中至少有一个成功获取的 Pad
    // 比较长度，选出最短的唯一 Pad（以两个字符串拼接后的长度为准）
    (String, String)? minPad;
    for (var x in [leftPad, rightPad, midPad]) {
      if (x == null) continue; // 跳过无效项
      if (minPad == null ||
          (x.$1 + x.$2).length < (minPad.$1 + minPad.$2).length) {
        minPad = x;
      }
    }

    return minPad ?? ("", "");
  }

  /// 搜集所有可能的包含Notify BATx方法
  /// [batteryNames] 电池名称列表，例如 ["BAT0", "BAT1"]
  Map<String, Map<String, dynamic>> collectBatteryNotifyMethods({
    required List<String> batteryNames,
    required Map<String, dynamic>? table,
    bool stripComments = true,
  }) {
    table ??= getDsdt();
    if (table?["lines"] == null) {
      Log("=> $table: 无效的 table 参数");
      return {};
    }

    final List<String> lines = (table?["lines"] as List).cast<String>();
    final Map<String, Map<String, dynamic>> notifyMethods = {};

    /// Method 定义匹配
    final methodRegex = RegExp(
      r'^\s*Method\s*\(\s*([A-Za-z0-9_]+)\s*,\s*(\d+)\s*,\s*([A-Za-z]+)',
      caseSensitive: false,
    );

    /// 生成 Notify 正则列表
    final notifyRegexList = batteryNames.map((batteryName) {
      return RegExp(
        r'Notify\s*\(\s*(?:[\\^A-Z0-9_\.]+\.)?' +
            RegExp.escape(batteryName) +
            r'\s*,',
        caseSensitive: false,
      );
    }).toList();

    for (int i = 0; i < lines.length; i++) {
      final match = methodRegex.firstMatch(lines[i]);
      if (match == null) continue;

      try {
        /// 提取完整 Method block
        final methodLines = getScope(
          startingIndex: i,
          stripComments: stripComments,
          table: table,
        );

        if (methodLines.isEmpty) continue;

        final methodText = methodLines.join('\n');

        /// 检测是否包含 Notify BATx
        bool hasNotify = false;
        for (final reg in notifyRegexList) {
          if (reg.hasMatch(methodText)) {
            hasNotify = true;
            break;
          }
        }

        if (!hasNotify) continue;

        ///
        final methodName = match.group(1) ?? "";
        String methodPath = "";
        final methodPaths = getMethodPaths(obj: methodName);
        if (methodPaths.isNotEmpty && methodPaths.first.isNotEmpty) {
          methodPath = _getParentScope(methodPaths[0][0]);
        }

        final methodInfo = {
          "text": methodText,
          "type": "MethodObj",
          "name": match.group(1) ?? "",
          "argCount": int.tryParse(match.group(2) ?? "0") ?? 0,
          "flags": match.group(3) ?? "NotSerialized",
          "scope": methodPath,
          "table": table,
        };

        notifyMethods[methodInfo["name"] as String] = methodInfo;
      } catch (e) {
        Log.warning("collectBatteryNotifyMethods: 解析 Method 失败: $e");
      }
    }

    return notifyMethods;
  }

  String _getParentScope(String path) {
    final idx = path.lastIndexOf('.');
    if (idx == -1) return path; // 没有父级
    return path.substring(0, idx);
  }

  /// 获取指定 Scope 路径的所有 Scope 块
  /// [scopePath] 例如 "_SB.PCI0" 或 "PCI0"
  /// [table] ACPI 表
  /// [stripComments] 是否去掉注释
  List<List<String>> getScopesOfPath({
    required String scopePath,
    required Map<String, dynamic>? table,
    bool stripComments = true,
  }) {
    table ??= getDsdt();
    if (table?["lines"] == null) {
      Log("=> $table getScopesOfPath: 无效的 table 参数");
      return <List<String>>[];
    }

    final List<String> lines = (table?["lines"] as List).cast<String>();
    final List<List<String>> results = [];

    final scopeName = scopePath.split('.').last;

    final RegExp scopeRegex = RegExp(
      r'^\s*Scope\s*\(\s*([^\)]+)\s*\)',
      caseSensitive: false,
    );

    for (int i = 0; i < lines.length; i++) {
      final match = scopeRegex.firstMatch(lines[i]);
      if (match == null) continue;

      final foundPath = match.group(1)!.trim();

      bool isMatch = false;

      final target = scopePath.trim();
      final targetWithSlash = target.startsWith(r'\') ? target : r'\' + target;
      final targetWithoutSlash = target.startsWith(r'\')
          ? target.substring(1)
          : target;

      // 完整路径匹配（兼容 \）
      if (foundPath.toLowerCase() == targetWithSlash.toLowerCase() ||
          foundPath.toLowerCase() == targetWithoutSlash.toLowerCase()) {
        isMatch = true;
      }

      // 节点匹配
      if (!scopePath.contains('.')) {
        final last = foundPath.replaceFirst(RegExp(r'^\\'), '').split('.').last;
        if (last.toLowerCase() == scopeName.toLowerCase()) {
          isMatch = true;
        }
      }

      if (!isMatch) continue;

      try {
        final scopeLines = getScope(
          startingIndex: i,
          stripComments: stripComments,
          table: table,
        );

        if (scopeLines.isNotEmpty) {
          results.add(scopeLines);
        }
      } catch (e) {
        Log.warning("getScopesOfPath: 提取 Scope 时发生错误: $e");
      }
    }

    return results;
  }

  /// 获取某个设备的完整 Scope（设备体内的所有行）
  /// [devicePath] 设备路径，如 "_SB.PC00.XHCI" 或简单设备名 "XHCI"
  /// [table] ACPI 表,可选
  /// [stripComments] 是否去掉注释（默认 true）
  List<String> getScopeOfDevice({
    required String devicePath,
    required Map<String, dynamic>? table,
    bool stripComments = true,
  }) {
    table ??= getDsdt();
    if (table?["lines"] == null) {
      Log("=> getScopeOfDevice: 无效的 table 参数");
      return <String>[];
    }

    final List<String> lines = (table?["lines"] as List).cast<String>();
    final String deviceName = devicePath.split('.').last;
    final RegExp deviceLineRegex = RegExp(
      r'^\s*Device\s*\(\s*' + RegExp.escape(deviceName) + r'\s*\)',
      caseSensitive: false,
    );

    // 1) 尝试通过 getPaths 获取设备的精确位置
    int? foundIndex;
    try {
      final paths = getPaths(table: table);
      for (final path in paths) {
        final pathStr = path[0] as String;
        final pathType = path[2] as String;

        // 检查是否是设备路径，并且路径匹配
        if (pathType == "Device") {
          // 检查完整路径匹配
          if (pathStr.toLowerCase() == devicePath.toLowerCase()) {
            foundIndex = path[1] as int;
            break;
          }

          // 检查设备名匹配（当传入的是简单设备名时）
          if (!devicePath.contains('.') &&
              pathStr.split('.').last.toLowerCase() ==
                  deviceName.toLowerCase()) {
            foundIndex = path[1] as int;
            break;
          }
        }
      }
    } catch (e) {
      Log.warning("getScopeOfDevice: 通过路径查找设备时发生错误: $e");
    }

    // 2) 如果上面没有定位到，使用简单的 Device (<NAME>) 全表查找
    if (foundIndex == null) {
      for (int i = 0; i < lines.length; i++) {
        if (deviceLineRegex.hasMatch(lines[i])) {
          // 验证这是否是我们要找的设备
          try {
            final scopeLines = getScope(
              startingIndex: i,
              stripComments: stripComments,
              table: table,
            );

            // 验证提取的 Scope 是否包含设备相关信息
            bool isValidScope = false;
            final scopeText = scopeLines.join("\n").toLowerCase();

            // 检查是否包含设备名或常见标识符
            if (scopeText.contains(deviceName.toLowerCase()) ||
                scopeText.contains("_adr") ||
                scopeText.contains("_hid") ||
                scopeText.contains("_uid")) {
              isValidScope = true;
            }

            // 如果是完整路径，还需要进一步验证
            if (devicePath.contains('.') && isValidScope) {
              // 尝试通过路径层次结构验证
              final pathParts = devicePath.split('.');
              bool pathMatch = true;

              // 检查 Scope 中是否包含路径中的关键部分
              for (final part in pathParts) {
                if (!scopeText.contains(part.toLowerCase())) {
                  pathMatch = false;
                  break;
                }
              }

              isValidScope = pathMatch;
            }

            if (isValidScope || !devicePath.contains('.')) {
              foundIndex = i;
              break;
            }
          } catch (e) {
            // 出错时仍接受此行作为候选
            Log.warning("getScopeOfDevice: 验证 Scope 时发生错误: $e");
            foundIndex = i;
            break;
          }
        }
      }
    }

    if (foundIndex == null) {
      Log("=> 未在表中找到 Device ($deviceName) 的定义（devicePath=$devicePath）");
      return <String>[];
    }

    // 3) 调用改进的 getScope 提取完整 Scope
    try {
      final scopeLines = getScope(
        startingIndex: foundIndex,
        stripComments: stripComments,
        table: table,
      );

      if (scopeLines.isEmpty) {
        Log("=> 找到 Device ($deviceName) 行 (index=$foundIndex)，但无法提取 Scope");
        return <String>[];
      }

      // 确保返回的 scope 属于期望的 device
      if (devicePath.contains('.')) {
        final joined = scopeLines.join("\n").toLowerCase();
        if (!joined.contains(deviceName.toLowerCase())) {
          Log.warning(
            "=> 提取的 Scope 似乎不包含设备名 $deviceName（devicePath=$devicePath），但仍返回内容。",
          );
        }
      }

      return scopeLines;
    } catch (e) {
      Log.error("getScopeOfDevice: 在提取 scope 时发生错误: $e");
      return <String>[];
    }
  }

  /// 获取所有设备列表
  /// [search] 搜索字符串
  /// [types] 设备类型列表
  /// [stripComments] 是否去掉注释
  /// [table] ACPI 表 （可选）
  List<List<dynamic>> getDevices({
    String? search,
    List<String> types = const ["Device (", "Scope ("],
    bool stripComments = false,
    Map<String, dynamic>? table,
  }) {
    // 如果未提供table，则获取 DSDT 或唯一表
    table ??= getDsdt();
    // 如果 table 或 search 为空，返回空列表
    if (table == null || search == null) return [];

    List<List<dynamic>> devices = [];
    String? lastDevice;
    int deviceIndex = 0;

    // 从 table 中获取 lines
    List<String> lines = List<String>.from(table["lines"] ?? []);

    for (int index = 0; index < lines.length; index++) {
      String line = lines[index];

      // 如果是十六进制字符串，跳过
      if (isHex(line)) {
        continue;
      }

      // 如果需要去掉注释，调用 getLine 方法
      if (stripComments) {
        line = util.getLine(line);
      }

      // 如果行包含任何指定的类型，更新 lastDevice 和 deviceIndex
      if (types.any((type) => line.contains(type))) {
        lastDevice = line;
        deviceIndex = index;
      }

      // 如果行包含 search 字符串，添加到 devices 列表
      if (line.contains(search)) {
        devices.add([lastDevice, deviceIndex, index]);
      }
    }

    return devices;
  }

  /// 获取指定索引开始的作用域
  /// [startingIndex] 起始索引
  /// [addHex] 是否添加十六进制字符串
  /// [stripComments] 是否去掉注释
  /// [table] ACPI 表 （可选）
  List<String> getScope({
    int startingIndex = 0,
    bool addHex = false,
    bool stripComments = false,
    Map<String, dynamic>? table,
  }) {
    // 如果未提供table，则获取 DSDT 或唯一表
    table ??= getDsdt();
    // 如果 table 为空，返回空列表
    if (table == null) return [];

    List<String> scope = [];
    List<String> lines = List<String>.from(
      table["lines"] ?? [],
    ); // 从 table 中获取 lines
    int? brackets;

    for (int i = startingIndex; i < lines.length; i++) {
      String line = lines[i];

      // 如果是十六进制字符串
      if (isHex(line)) {
        if (addHex) {
          scope.add(line);
        }
        continue;
      }

      // 如果需要去掉注释
      if (stripComments) {
        line = util.getLine(line);
      }

      // 添加当前行到 scope 中
      scope.add(line);

      // 计算括号数量，标识当前作用域
      if (brackets == null) {
        if (line.contains("{")) {
          brackets = line.split("{").length - 1;
        }
        continue;
      }

      brackets =
          brackets + line.split("{").length - 1 - line.split("}").length + 1;

      // 如果括号数量小于等于0，表示已经退出了作用域
      if (brackets <= 0) {
        return scope;
      }
    }

    return scope;
  }

  /// 获取所有作用域列表
  /// [table] ACPI 表 （可选）
  List<List<dynamic>> getScopes({Map<String, dynamic>? table}) {
    // 如果未提供table，则获取 DSDT 或唯一表
    table ??= getDsdt();
    if (table == null) return [];

    List<List<dynamic>> scopes = [];
    // 从 table 中获取 lines
    List<String> lines = List<String>.from(table["lines"] ?? []);

    for (int index = 0; index < lines.length; index++) {
      String line = lines[index];

      // 如果是十六进制字符串，跳过
      if (isHex(line)) continue;

      // 检查是否包含特定字符串
      if (line.contains("Processor (") ||
          line.contains("Scope (") ||
          line.contains("Device (") ||
          line.contains("Method (") ||
          line.contains("Name (")) {
        // 添加包含匹配项的行和其索引
        scopes.add([line, index]);
      }
    }

    return scopes;
  }

  /// 获取 ACPI 表中的所有路径信息（如 Device、Processor、Method 等定义的位置和类型）
  /// group("name") = match.group(2)
  /// group("type") = match.group(1)
  /// [table] ACPI 表 （可选）
  List<List<dynamic>> getPaths({Map<String, dynamic>? table}) {
    // 如果未提供table，则获取 DSDT 或唯一表
    table ??= getDsdt();
    if (table == null) return [];

    List<List<dynamic>> pathList = []; // 最终返回的路径列表
    List<List<dynamic>> path0 = []; // 当前正在处理的路径列表
    int brackets = 0; // 用于追踪大括号层级

    var lines = table['lines'] ?? [];
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];

      if (isHex(line)) {
        // 跳过十六进制内容
        continue;
      }

      line = util.getLine(line);
      // 更新当前括号嵌套层级（{ +1，} -1）
      brackets += line.split("{").length - line.split("}").length;

      while (path0.isNotEmpty) {
        // 如果当前路径嵌套层级高于或等于新的层级，则移除这些路径
        if (path0.last.last >= brackets) {
          path0.removeLast();
        } else {
          break;
        }
      }

      var match = typeMatch.firstMatch(line);
      if (match != null) {
        // 添加新的路径条目，并按需保存完整路径
        path0.add([match.group(2), brackets]);

        if (match.group(1) == "Scope") {
          // Scope 类型仅表示作用域，不计入路径列表
          continue;
        }

        // 构建完整路径，仅包含非 Scope 且不是完全限定名（如以 \ 开头） 的路径
        List<String> path = [];
        for (var p in path0.reversed) {
          path.add(p[0]);
          if (p[0] == "_SB" ||
              p[0] == "_SB_" ||
              p[0] == "_PR" ||
              p[0] == "_PR_" ||
              p[0].startsWith("\\") ||
              p[0].startsWith("_SB.") ||
              p[0].startsWith("_SB_.") ||
              p[0].startsWith("_PR.") ||
              p[0].startsWith("_PR_.")) {
            // 如果路径已是全限定路径，则停止向上拼接
            break;
          }
        }

        path = path.reversed.toList();
        // 标准化路径格式，如果以 "\" 开头重复了就去掉
        if (path.isNotEmpty && path[0] == "\\") path.removeAt(0);

        // 处理 ACPI 中的 ^（caret）向上跳级表示法
        if (path.any((x) => x.contains("^"))) {
          List<String> newPath = [];
          for (var x in path) {
            int caretCount = x.split("^").length - 1;
            if (caretCount > 0) {
              // 从路径中移除对应级数的上层路径
              final start = (newPath.length - caretCount).clamp(
                0,
                newPath.length,
              );
              newPath.removeRange(start, newPath.length);
            }
            // 添加去掉 ^ 后的路径元素
            newPath.add(x.replaceAll("^", ""));
          }
          path = newPath;
        }

        if (path.isEmpty) continue;
        // 构造最终路径字符串
        String pathStr = path.join(".");
        pathStr = pathStr[0] != "\\" ? "\\$pathStr" : pathStr;
        // 添加到最终结果中：[路径字符串, 行号, 类型]
        pathList.add([pathStr, i, match.group(1)]);
      }
    }

    // 按路径字符串排序后返回
    pathList.sort((a, b) => a[0].compareTo(b[0]));
    return pathList;
  }

  /// 获取 Device 类型的路径
  /// [obj] Device 名称
  /// [table] ACPI 表 （可选）
  List<List<dynamic>> getDevicePaths({
    String obj = "HPET",
    Map<String, dynamic>? table,
  }) {
    return getPathOfType(objType: "Device", obj: obj, table: table);
  }

  /// 获取 Method 类型的路径
  /// [obj] Method 名称
  /// [table] ACPI 表 （可选）
  List<List<dynamic>> getMethodPaths({
    String obj = "_STA",
    Map<String, dynamic>? table,
  }) {
    return getPathOfType(objType: "Method", obj: obj, table: table);
  }

  /// 获取 Name 类型的路径
  /// [obj] Name 名称
  /// [table] ACPI 表 （可选）
  List<List<dynamic>> getNamePaths({
    String obj = "CPU0",
    Map<String, dynamic>? table,
  }) {
    return getPathOfType(objType: "Name", obj: obj, table: table);
  }

  /// 获取 Processor 类型的路径
  /// [objType] 对象类型
  /// [table] ACPI 表 （可选）
  List<List<dynamic>> getProcessorPaths({
    String objType = "Processor",
    Map<String, dynamic>? table,
  }) {
    return getPathOfType(objType: objType, obj: "", table: table);
  }

  /// 获取 Method 类型信息
  /// [obj] Method 名称
  /// [table] ACPI 表 （可选）
  List<dynamic> getMethodInfo({
    String obj = "_STA",
    String objType = "Method",
    Map<String, dynamic>? table,
  }) {
    table ??= getDsdt();
    if (table == null) return [];

    List<dynamic> infos = [];

    // 标准化方法名
    obj = obj
        .split(".")
        .map((x) => x.replaceAll(RegExp(r"_$"), "").toUpperCase())
        .join(".");

    objType = objType.toLowerCase();

    // 遍历所有 scope 行
    for (var scope in table['scopes'] ?? []) {
      if (scope.length < 2) continue;

      String rawLine = scope[0].toString().trim();
      final lineNum = scope[1];

      // “Method” 开头才处理
      if (!rawLine.startsWith("Method")) continue;

      // 去掉注释： 双斜线 // ... 之后全部删除
      rawLine = rawLine.replaceAll(RegExp(r'//.*$'), "").trim();

      // 匹配方法定义
      final match = RegExp(
        r'Method\s*\(\s*([A-Za-z0-9_\.\\]+)\s*,\s*(\d+)\s*,\s*([A-Za-z]+)\s*\)',
        caseSensitive: false,
      ).firstMatch(rawLine);

      if (match == null) continue;

      String fullName = match.group(1)!.trim(); // \_SB.PCI0._PTS
      int argCount = int.parse(match.group(2)!);
      String flag = match.group(3)!.trim();

      // 最后一级方法名，例如 _PTS
      String methodName = fullName
          .split(".")
          .last
          .replaceAll("\\", "")
          .toUpperCase();

      // 不匹配跳过
      if (methodName != obj) continue;

      // 最终方法定义（去注释、去前后空格）
      final cleanDefinition = "Method ($fullName, $argCount, $flag)";

      // 返回结构: [定义, 行号, 方法名, 参数数量, 属性]
      infos.addAll([cleanDefinition, lineNum, methodName, argCount, flag]);
    }

    return infos;
  }

  /// 获取指定类型和名称的路径（如查找某个 Device 类型下名为 HPET 的路径）
  /// [objType] 对象类型
  /// [obj] 对象名称
  /// [table] ACPI 表 （可选）
  List<List<dynamic>> getPathOfType({
    String objType = "Device",
    String obj = "HPET",
    Map<String, dynamic>? table,
  }) {
    // 如果未传入表，则尝试获取 DSDT 或唯一表
    table ??= getDsdt();
    if (table == null) return [];

    List<List<dynamic>> paths = [];

    // 移除末尾下划线并统一大小写（将对象名标准化）
    obj = obj
        .split(".")
        .map((x) => x.replaceAll(RegExp(r"_$"), "").toUpperCase())
        .join(".");

    objType = objType.isNotEmpty ? objType.toLowerCase() : objType;

    // 遍历所有路径
    for (var path in table['paths'] ?? []) {
      // 对路径中的设备名做同样的标准化处理：去除末尾下划线并转大写
      String pathCheck = path[0]
          .split(".")
          .map((x) => x.replaceAll(RegExp(r"_$"), "").toUpperCase())
          .join(".");

      // 类型不匹配或设备名不匹配则跳过
      if ((objType.isNotEmpty && objType != path[2].toLowerCase()) ||
          !pathCheck.endsWith(obj)) {
        // 不匹配则跳过
        continue;
      }
      // 匹配成功，添加到结果列表
      paths.add(path);
    }

    // 对路径进行排序后返回
    paths.sort((a, b) => a.toString().compareTo(b.toString()));
    return paths;
  }

  /// 提取 idTypes 中的字符串类型并返回
  /// [idTypes] ID 类型列表
  List<String> _extractIdTypes(Object? idTypes) {
    final result = <String>[];

    if (idTypes is List) {
      result.addAll(idTypes.whereType<String>().map((e) => e.toUpperCase()));
    } else if (idTypes is String) {
      result.add(idTypes.toUpperCase());
    } else if (idTypes is Record) {
      final fields = idTypes
          .toString()
          .replaceAll('(', '')
          .replaceAll(')', '')
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      result.addAll(fields.map((e) => e.toUpperCase()));
    }

    return result;
  }

  /// 获取包含指定 ID 的设备路径列表
  /// [id] ID 字符串
  /// [idTypes] ID 类型列表
  /// [table] ACPI 表 （可选）
  List<List<dynamic>> getDevicePathsWithId({
    String id = "PNP0A03",
    Object? idTypes = const ("_HID", "_CID"),
    Map<String, dynamic>? table,
  }) {
    table ??= getDsdt();
    if (table == null || table.isEmpty) return [];

    final idTypeList = _extractIdTypes(idTypes);
    if (idTypeList.isEmpty) return [];

    final idUpper = id.toUpperCase();
    final devs = <String>[];
    final paths = table['paths'] ?? [];
    final lines = table['lines'] ?? {};

    for (final p in paths) {
      try {
        for (final typeCheck in idTypeList) {
          if (p[0].endsWith(typeCheck) &&
              lines[p[1]]?.contains(idUpper) == true) {
            final trimmed = p[0]
                .substring(0, p[0].length - typeCheck.length)
                .replaceAll(RegExp(r"\.+$"), "");
            devs.add(trimmed);
            break;
          }
        }
      } catch (e) {
        Log.error('getDevicePathsWithId方法处理路径发生错误 $p: $e');
        continue;
      }
    }

    List<List<dynamic>> devices = [];
    for (final p in paths) {
      if (devs.contains(p[0]) && p[2] == "Device") {
        devices.add(p as List);
      }
    }
    return devices;
  }

  /// 获取DSDT根作用域下的所有Field变量
  /// 整理成一个List列表，每个列表是一个字典元素
  /// 该字典包含该变量所属Field名，字节长度，位长度，偏移
  List<Map<String, dynamic>> getRootFieldVariables({
    Map<String, dynamic>? table,
  }) {
    table ??= getDsdt();
    final List<Map<String, dynamic>> fieldVariables = [];
    if (!table!.containsKey('lines')) {
      return fieldVariables;
    }

    final lines = table['lines'] as List<String>;
    bool inField = false;
    String currentFieldName = "";
    int currentOffset = 0;

    for (final line in lines) {
      final trimmedLine = line.trim();

      // 检查是否进入Field区域
      if (trimmedLine.startsWith('Field (')) {
        inField = true;
        // 提取Field名称（如果有）
        final fieldMatch = RegExp(
          r'Field\s*\(\s*\S+\s*,\s*(\S+)',
        ).firstMatch(trimmedLine);
        if (fieldMatch != null) {
          currentFieldName = fieldMatch.group(1)!;
        }
        currentOffset = 0;
      }
      // 检查是否退出Field区域
      else if (inField && trimmedLine == '}') {
        inField = false;
        currentFieldName = "";
      }
      // 在Field区域内，检查字段定义
      else if (inField) {
        // 匹配字段定义，如 "OSYS,   16,"
        final fieldMatch = RegExp(
          r'^\s*([A-Z0-9_]+)\s*,\s*(\d+)\s*,?',
        ).firstMatch(trimmedLine);
        if (fieldMatch != null) {
          final fieldName = fieldMatch.group(1)!;
          final bitLength = int.parse(fieldMatch.group(2)!);
          final byteLength = (bitLength + 7) ~/ 8;

          fieldVariables.add({
            "fieldName": currentFieldName,
            "name": fieldName,
            "byteLength": byteLength,
            "bitLength": bitLength,
            "offset": currentOffset,
          });

          // 更新偏移量（按位计算）
          currentOffset += (bitLength + 7) ~/ 8;
        }
      }
    }

    return fieldVariables;
  }

  /// 检测 Name 对象类型
  /// [nameText] Name 对象文本（完整 Name(...) 语句，允许多行）
  String detectNameType(String nameText) {
    final upper = nameText.toUpperCase();

    // 取逗号后内容
    final commaIndex = upper.indexOf(',');
    if (commaIndex == -1) return "UnknownObj";

    final valuePart = upper.substring(commaIndex + 1);

    if (valuePart.contains("PACKAGE")) {
      return "PkgObj";
    }

    if (valuePart.contains("BUFFER")) {
      return "BuffObj";
    }

    if (valuePart.contains("EISAID")) {
      return "IntObj";
    }

    if (RegExp(r'\b(ZERO|ONE|ONES)\b').hasMatch(valuePart)) {
      return "IntObj";
    }

    if (RegExp(r'0X[0-9A-F]+|\b\d+\b').hasMatch(valuePart)) {
      return "IntObj";
    }

    return "UnknownObj";
  }

  /// 获取 ACPI 根作用域下的所有 Name 变量及其类型
  List<Map<String, dynamic>> getRootNameTypeByName({
    Map<String, dynamic>? table,
  }) {
    table ??= getDsdt();
    final List<Map<String, dynamic>> nameVariables = [];
    if (table == null || !table.containsKey('lines')) {
      return nameVariables;
    }

    final lines = table['lines'] as List<String>;

    for (int i = 0; i < lines.length; i++) {
      final trimmedLine = lines[i].trim();

      // 完全按 getRootFieldVariables 扫描方式：只要遇到 Name( 开头就采集。
      if (!trimmedLine.startsWith('Name (')) continue;

      final buffer = StringBuffer();
      int paren = 0;
      bool started = false;
      int t = i;

      for (; t < lines.length; t++) {
        final current = lines[t];
        buffer.writeln(current);
        for (final ch in current.split('')) {
          if (ch == '(') {
            paren++;
            started = true;
          } else if (ch == ')') {
            paren--;
          }
        }
        if (started && paren == 0) break;
      }

      final text = buffer.toString().trim();
      final match = RegExp(
        r'^\s*Name\s*\(\s*([A-Za-z0-9_]+)\s*,',
        caseSensitive: false,
      ).firstMatch(text);
      final varName = (match?.group(1) ?? "").trim().toUpperCase();
      if (varName.isEmpty) {
        i = t;
        continue;
      }

      nameVariables.add({
        "name": varName,
        "type": detectNameType(text),
        "text": text,
      });

      i = t;
    }

    return nameVariables;
  }

  /// 获取包含指定 CID 的设备路径
  /// [cid] CID 字符串
  /// [table] ACPI 表 （可选）
  List<List<dynamic>> getDevicePathsWithCid({
    String cid = "PNP0A03",
    Map<String, dynamic>? table,
  }) {
    return getDevicePathsWithId(id: cid, idTypes: ("_CID",), table: table);
  }

  /// 获取包含指定 HID 的设备路径列表
  /// [hid] HID 字符串
  /// [table] ACPI 表 （可选）
  List<List<dynamic>> getDevicePathsWithHid({
    String hid = "ACPI000E",
    Map<String, dynamic>? table,
  }) {
    return getDevicePathsWithId(id: hid, idTypes: ("_HID",), table: table);
  }
}
