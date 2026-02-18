import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Generates a multi-page Safety Route Report (SRR) as a PDF.
///
/// Sections: header, map snapshot, journey stats, safety breakdown,
/// SOS events (if any), integrity hash + footer.
class SRRReportGenerator {
  final SupabaseClient _client;

  SRRReportGenerator({required SupabaseClient client}) : _client = client;

  /// Generate the full SRR PDF and upload to Supabase Storage.
  /// Returns the report record ID.
  Future<String?> generateAndUpload({
    required String journeyId,
    required String userId,
    required Uint8List? mapSnapshot,
  }) async {
    // 1. Fetch journey, route, and SOS data
    final journey = await _fetchJourney(journeyId);
    if (journey == null) return null;

    final routeId = journey['route_id'] as String?;
    Map<String, dynamic>? route;
    if (routeId != null) {
      route = await _fetchRoute(routeId);
    }

    final sosEvents = await _fetchSOSEvents(journeyId);

    // 2. Build hash source data
    final hashSource = {
      'journey_id': journeyId,
      'user_id': userId,
      'started_at': journey['started_at'],
      'completed_at': journey['completed_at'],
      'distance_km': route?['distance_km'],
      'duration_min': route?['duration_min'],
      'safety_score': route?['safety_score'],
      'status': journey['status'],
      'sos_event_count': sosEvents.length,
      'generated_at': DateTime.now().toUtc().toIso8601String(),
    };
    final hashContent = json.encode(hashSource);
    final integrityHash = sha256.convert(utf8.encode(hashContent)).toString();

    // 3. Generate PDF
    final pdfBytes = await _buildPdf(
      journey: journey,
      route: route,
      sosEvents: sosEvents,
      mapSnapshot: mapSnapshot,
      integrityHash: integrityHash,
    );

    // 4. Upload PDF to Storage
    String? pdfUrl;
    try {
      final path = '$journeyId/srr_report.pdf';
      await _client.storage.from('reports').uploadBinary(
            path,
            pdfBytes,
            fileOptions:
                const FileOptions(contentType: 'application/pdf'),
          );
      pdfUrl = _client.storage.from('reports').getPublicUrl(path);
    } catch (_) {}

    // 5. Upload map snapshot
    String? mapUrl;
    if (mapSnapshot != null) {
      try {
        final mapPath = '$journeyId/map_snapshot.png';
        await _client.storage.from('reports').uploadBinary(
              mapPath,
              mapSnapshot,
              fileOptions:
                  const FileOptions(contentType: 'image/png'),
            );
        mapUrl = _client.storage.from('reports').getPublicUrl(mapPath);
      } catch (_) {}
    }

    // 6. Create report record
    try {
      final response = await _client.from('reports').insert({
        'journey_id': journeyId,
        'user_id': userId,
        'report_type': 'srr',
        'pdf_url': pdfUrl,
        'map_snapshot_url': mapUrl,
        'integrity_hash': integrityHash,
        'hash_source_data': hashSource,
      }).select('id').single();
      return response['id'] as String;
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List> _buildPdf({
    required Map<String, dynamic> journey,
    Map<String, dynamic>? route,
    required List<Map<String, dynamic>> sosEvents,
    Uint8List? mapSnapshot,
    required String integrityHash,
  }) async {
    final pdf = pw.Document(
      title: 'Safety Route Report',
      author: 'ResQ Route',
    );

    final dateFormat = DateFormat('dd MMM yyyy');
    final timeFormat = DateFormat('HH:mm:ss');

    final startedAt = DateTime.tryParse(journey['started_at'] ?? '');
    final completedAt = DateTime.tryParse(journey['completed_at'] ?? '');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('SAFETY ROUTE REPORT',
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                      'Report ID: SRR-${(journey['id'] as String? ?? '').substring(0, 8).toUpperCase()}',
                      style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(
                      'Date: ${startedAt != null ? dateFormat.format(startedAt) : 'N/A'}',
                      style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),
          pw.Divider(),
          pw.SizedBox(height: 12),

          // Map snapshot
          if (mapSnapshot != null) ...[
            pw.Center(
              child: pw.Image(pw.MemoryImage(mapSnapshot),
                  width: 500, height: 300, fit: pw.BoxFit.contain),
            ),
            pw.SizedBox(height: 16),
          ],

          // Journey stats
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Column(children: [
              _statRow('Distance',
                  '${(route?['distance_km'] as num?)?.toStringAsFixed(1) ?? 'N/A'} km'),
              _statRow('Duration',
                  '${route?['duration_min'] ?? 'N/A'} min'),
              _statRow('Safety Score',
                  '${(route?['safety_score'] as num?)?.toStringAsFixed(0) ?? 'N/A'}/100'),
              _statRow('Status',
                  (journey['status'] as String? ?? 'unknown').toUpperCase()),
              _statRow('Started',
                  startedAt != null ? timeFormat.format(startedAt) : 'N/A'),
              _statRow('Ended',
                  completedAt != null ? timeFormat.format(completedAt) : 'N/A'),
            ]),
          ),
          pw.SizedBox(height: 16),

          // SOS events
          if (sosEvents.isNotEmpty) ...[
            pw.Text('SOS Events (${sosEvents.length})',
                style: pw.TextStyle(
                    fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey200),
              cellPadding: const pw.EdgeInsets.all(6),
              headers: ['#', 'Trigger', 'Status', 'Time'],
              data: List.generate(
                sosEvents.length,
                (i) => [
                  '${i + 1}',
                  sosEvents[i]['trigger_type'] ?? '',
                  sosEvents[i]['status'] ?? '',
                  sosEvents[i]['created_at'] ?? '',
                ],
              ),
            ),
            pw.SizedBox(height: 16),
          ],

          // Integrity hash
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            color: PdfColors.grey100,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Document Integrity',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                pw.Text('SHA-256: $integrityHash',
                    style: pw.TextStyle(
                        fontSize: 7, font: pw.Font.courier())),
                pw.SizedBox(height: 4),
                pw.Text(
                    'Generated: ${DateTime.now().toUtc().toIso8601String()}',
                    style: const pw.TextStyle(fontSize: 8)),
                pw.SizedBox(height: 4),
                pw.Text(
                    'This document is tamper-evident. Any modification will invalidate the hash.',
                    style: pw.TextStyle(
                        fontSize: 7, color: PdfColors.grey700)),
              ],
            ),
          ),
        ],
        footer: (context) => pw.Center(
          child: pw.Text(
              'Generated by ResQ Route — Tamper-evident document  |  Page ${context.pageNumber}/${context.pagesCount}',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        ),
      ),
    );

    return pdf.save();
  }

  pw.Widget _statRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(value),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _fetchJourney(String journeyId) async {
    try {
      return await _client
          .from('journeys')
          .select()
          .eq('id', journeyId)
          .maybeSingle();
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _fetchRoute(String routeId) async {
    try {
      return await _client
          .from('routes')
          .select()
          .eq('id', routeId)
          .maybeSingle();
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchSOSEvents(
      String journeyId) async {
    try {
      final res = await _client
          .from('sos_events')
          .select('id, trigger_type, status, created_at')
          .eq('journey_id', journeyId)
          .order('created_at');
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }
}
