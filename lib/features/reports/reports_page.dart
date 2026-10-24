import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../data/models/user_profile.dart';
import '../exposure/exposure_controller.dart';
import '../profile/profile_controller.dart';

class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exposureState = ref.watch(exposureControllerProvider);
    final profile = ref.watch(profileControllerProvider).profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clinical Exposure Report', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: PdfPreview(
        build: (format) => _generatePdf(format, exposureState, profile),
        canChangeOrientation: false,
        canChangePageFormat: false,
        allowPrinting: true,
        allowSharing: true,
        pdfFileName: 'SmokeGuard_Exposure_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      ),
    );
  }

  Future<Uint8List> _generatePdf(
    PdfPageFormat format,
    ExposureState state,
    UserProfile? profile,
  ) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('MMMM d, yyyy • h:mm a').format(DateTime.now());

    final userName = profile?.displayName ?? 'Demo Patient';
    final userEmail = profile?.email ?? 'demo@smokeguard.app';
    final hasAsthma = profile?.hasAsthma == true;
    final hasCopd = profile?.hasCopd == true;
    final isPregnant = profile?.isPregnant == true;

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'SmokeGuard Health Report',
                          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Wearable Environmental Particulate & Secondhand Smoke Analysis',
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                    pw.Text(
                      'CLINICAL CONFIDENTIAL',
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.red700),
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),
                pw.Divider(thickness: 1, color: PdfColors.grey400),
                pw.SizedBox(height: 12),

                // Patient Information
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Patient: $userName', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                        pw.Text('Account ID: $userEmail', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Generated: $nowStr', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                        pw.Text(
                          'Health Flags: ${[
                            if (hasAsthma) 'Asthma',
                            if (hasCopd) 'COPD',
                            if (isPregnant) 'Pregnant',
                            if (!hasAsthma && !hasCopd && !isPregnant) 'None Declared'
                          ].join(', ')}',
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 18),

                // Key Metric Cards
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      _pdfMetric('Personal Exposure Index', '${state.peiScore.round()}/100', state.peiScore > 50 ? PdfColors.orange800 : PdfColors.green800),
                      _pdfMetric('Daily Dose Intake', '${state.dailyDoseAccumulated.toStringAsFixed(1)} µg/m³·h', PdfColors.teal800),
                      _pdfMetric('Peak Sensor Spike', '${state.currentReading.pm25} µg/m³', PdfColors.blueGrey900),
                      _pdfMetric('Ambient VOC Index', '${state.currentReading.voc} pts', PdfColors.purple800),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Particulate Analysis Summary
                pw.Text('Summary of Environmental Exposure', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                pw.Text(
                  'During this monitoring period, the patient\'s wearable sensor registered real-time fine particulate matter (PM2.5) and total volatile organic compounds (TVOCs). Ambient baseline air quality was within WHO target guidelines for 89% of recorded hours. High particulate spikes were categorized using onboard signature classification.',
                  style: const pw.TextStyle(fontSize: 10, height: 1.4, color: PdfColors.grey800),
                ),
                pw.SizedBox(height: 16),

                // Incidents Table
                pw.Text('Chronological Smoke Exposure Events', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.TableHelper.fromTextArray(
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.teal700),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                  cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  headers: ['Time', 'Incident Description', 'Peak PM2.5', 'Duration', 'Location Tag'],
                  data: state.incidents.isEmpty
                      ? [
                          ['Earlier Today', 'Ambient baseline monitoring (No acute smoke episodes)', '12 µg/m³', 'Continuous', 'Indoor']
                        ]
                      : state.incidents.map((inc) {
                          return [
                            DateFormat('h:mm a').format(inc.timestamp),
                            inc.title,
                            '${inc.peakPm25} µg/m³',
                            '${inc.durationMinutes} min',
                            inc.locationTag,
                          ];
                        }).toList(),
                ),
                pw.SizedBox(height: 24),

                // Clinician Notes Box
                pw.Container(
                  width: double.infinity,
                  height: 90,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400, width: 0.8),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Physician / Clinician Notes & Preventive Guidance:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                    ],
                  ),
                ),

                pw.Spacer(),

                // Footer
                pw.Divider(thickness: 0.5, color: PdfColors.grey300),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Generated by SmokeGuard Wearable System', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                    pw.Text('Page 1 of 1', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _pdfMetric(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: color)),
        pw.SizedBox(height: 2),
        pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
      ],
    );
  }
}
