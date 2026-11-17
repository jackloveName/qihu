import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'date_utils.dart';
import 'models.dart';

abstract final class ReportPdfService {
  static Future<void> share({
    required AppState state,
    required String reportType,
  }) async {
    final pet = state.pets.first;
    final regularData = await rootBundle.load(
      'assets/fonts/NotoSansSC-ReportSubset.ttf',
    );
    final regular = pw.Font.ttf(regularData);
    final serif = regular;
    final theme = pw.ThemeData.withFont(base: regular, bold: serif);
    final document = pw.Document(theme: theme);
    final now = DateTime.now();
    final petTasks = state.tasks.where((task) => task.petId == pet.id).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 40, 36, 36),
        header: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 10),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColor.fromInt(0xFFE2DFD3)),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                '栖护 · $reportType',
                style: pw.TextStyle(font: serif, fontSize: 16),
              ),
              pw.Text(
                PetDates.reportDate(now),
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColor.fromInt(0xFF75817A),
                ),
              ),
            ],
          ),
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              '仅供照护与沟通参考，不构成诊疗结论。',
              style: const pw.TextStyle(
                fontSize: 8,
                color: PdfColor.fromInt(0xFF75817A),
              ),
            ),
            pw.Text(
              '${context.pageNumber} / ${context.pagesCount}',
              style: const pw.TextStyle(
                fontSize: 8,
                color: PdfColor.fromInt(0xFFA6AEA8),
              ),
            ),
          ],
        ),
        build: (context) => [
          pw.SizedBox(height: 18),
          pw.Text(pet.name, style: pw.TextStyle(font: serif, fontSize: 27)),
          pw.SizedBox(height: 4),
          pw.Text(
            '${pet.species.label} · ${pet.age} · ${pet.environment}',
            style: const pw.TextStyle(
              fontSize: 11,
              color: PdfColor.fromInt(0xFF75817A),
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFF5F3EB),
              borderRadius: pw.BorderRadius.circular(10),
              border: pw.Border.all(color: const PdfColor.fromInt(0xFFE2DFD3)),
            ),
            child: pw.Row(
              children: [
                _metric('体重', pet.weight),
                _metric('温度', pet.temperature),
                _metric('湿度', pet.humidity),
                _metric('健康记录', '${pet.logs.length} 条'),
              ],
            ),
          ),
          pw.SizedBox(height: 24),
          _sectionTitle('健康时间线', serif),
          pw.SizedBox(height: 8),
          if (pet.logs.isEmpty)
            _bodyText('暂无健康记录。')
          else
            for (final log in pet.logs.take(8)) ...[
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 58,
                    child: pw.Text(
                      PetDates.relativeDateTime(log.occurredAt ?? now, now),
                      style: const pw.TextStyle(
                        fontSize: 8.5,
                        color: PdfColor.fromInt(0xFF75817A),
                      ),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          log.title,
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                        pw.SizedBox(height: 2),
                        _bodyText(log.description),
                        if (log.followUpAt != null) ...[
                          pw.SizedBox(height: 2),
                          pw.Text(
                            '复看：${PetDates.relativeDateTime(log.followUpAt!, now)} '
                            '${PetDates.clock(log.followUpAt!)}',
                            style: const pw.TextStyle(
                              fontSize: 8.5,
                              color: PdfColor.fromInt(0xFFB0762F),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
            ],
          pw.SizedBox(height: 12),
          _sectionTitle('养护任务与执行记录', serif),
          pw.SizedBox(height: 8),
          if (petTasks.isEmpty)
            _bodyText('暂无养护任务。')
          else
            for (final task in petTasks.take(12))
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 7),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: const PdfColor.fromInt(0xFFE2DFD3),
                  ),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            '${task.title} · ${task.time}',
                            style: const pw.TextStyle(fontSize: 10.5),
                          ),
                          pw.SizedBox(height: 2),
                          _bodyText(task.subtitle),
                          if (task.latestRun?.note.isNotEmpty ?? false) ...[
                            pw.SizedBox(height: 3),
                            pw.Text(
                              '执行备注：${task.latestRun!.note}',
                              style: const pw.TextStyle(
                                fontSize: 8.5,
                                color: PdfColor.fromInt(0xFF3A4A42),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Text(
                      _statusLabel(task.status),
                      style: pw.TextStyle(
                        fontSize: 8.5,
                        color: _statusColor(task.status),
                      ),
                    ),
                  ],
                ),
              ),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFF4EDDC),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: _bodyText(
              '报告包含本地保存的护理、环境和健康记录。导出前请确认接收对象；'
              '完整医疗资料可能涉及敏感信息。',
              color: const PdfColor.fromInt(0xFF7A5520),
            ),
          ),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await document.save(),
      filename:
          '栖护_${pet.name}_${PetDates.reportDate(now).replaceAll('.', '')}.pdf',
    );
  }

  static pw.Widget _metric(String label, String value) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColor.fromInt(0xFF75817A),
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(value, style: const pw.TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  static pw.Widget _sectionTitle(String value, pw.Font font) {
    return pw.Text(value, style: pw.TextStyle(font: font, fontSize: 15));
  }

  static pw.Widget _bodyText(
    String value, {
    PdfColor color = const PdfColor.fromInt(0xFF3A4A42),
  }) {
    return pw.Text(
      value,
      style: pw.TextStyle(fontSize: 9, lineSpacing: 3, color: color),
    );
  }

  static String _statusLabel(TaskStatus status) {
    return switch (status) {
      TaskStatus.pending => '待完成',
      TaskStatus.done => '已完成',
      TaskStatus.skipped => '已跳过',
    };
  }

  static PdfColor _statusColor(TaskStatus status) {
    return switch (status) {
      TaskStatus.pending => const PdfColor.fromInt(0xFFB0762F),
      TaskStatus.done => const PdfColor.fromInt(0xFF1D4A3D),
      TaskStatus.skipped => const PdfColor.fromInt(0xFF75817A),
    };
  }
}
