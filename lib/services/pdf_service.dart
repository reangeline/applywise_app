import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import '../models/resume.dart';

class PdfService {
  /// Constrói o conteúdo do PDF
  Future<List<pw.Widget>> _buildPdfContent(Resume resume, pw.Font bold, pw.Font regular, pw.Font italic) async {
    return [
      _buildHeader(resume, bold, regular),
      pw.SizedBox(height: 20),
      
      if (resume.personal?.summary?.isNotEmpty == true) ...[
        _buildSection('PROFESSIONAL SUMMARY', bold),
        pw.SizedBox(height: 8),
        pw.Text(
          resume.personal!.summary!,
          style: pw.TextStyle(font: regular, fontSize: 10, lineSpacing: 1.4),
          textAlign: pw.TextAlign.justify,
        ),
        pw.SizedBox(height: 16),
      ],
      
      if (resume.experiences?.isNotEmpty == true) ...[
        _buildSection('WORK EXPERIENCE', bold),
        pw.SizedBox(height: 8),
        ...resume.experiences!.map((exp) => _buildExperience(exp, bold, regular, italic)),
        pw.SizedBox(height: 16),
      ],
      
      // Education e Languages lado a lado
      if (resume.education?.isNotEmpty == true || resume.languages?.isNotEmpty == true) ...[
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Coluna Education
            if (resume.education?.isNotEmpty == true)
              pw.Expanded(
                flex: 2,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildSection('EDUCATION', bold),
                    pw.SizedBox(height: 8),
                    ...resume.education!.map((edu) => _buildEducation(edu, bold, regular, italic)),
                  ],
                ),
              ),
            
            if (resume.education?.isNotEmpty == true && resume.languages?.isNotEmpty == true)
              pw.SizedBox(width: 20),
            
            // Coluna Languages
            if (resume.languages?.isNotEmpty == true)
              pw.Expanded(
                flex: 1,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildSection('LANGUAGES', bold),
                    pw.SizedBox(height: 8),
                    _buildLanguages(resume.languages!, bold, regular),
                  ],
                ),
              ),
          ],
        ),
        pw.SizedBox(height: 16),
      ],
      
      if (resume.projects?.isNotEmpty == true) ...[
        _buildSection('PROJECTS', bold),
        pw.SizedBox(height: 8),
        ...resume.projects!.map((proj) => _buildProject(proj, bold, regular)),
      ],
    ];
  }

  /// Gera um PDF a partir de um currículo
  Future<File> generateResumePdf(Resume resume) async {
    // Garantir que o Flutter esteja inicializado
    WidgetsFlutterBinding.ensureInitialized();
    
    final pdf = pw.Document();

    // Carregar fontes (usando fontes do sistema via printing package)
    final bold = await PdfGoogleFonts.openSansBold();
    final regular = await PdfGoogleFonts.openSansRegular();
    final italic = await PdfGoogleFonts.openSansItalic();
    
    final content = await _buildPdfContent(resume, bold, regular, italic);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => content,
      ),
    );

    // Salvar o PDF
    final output = await getTemporaryDirectory();
    final fileName = _generateFileName(resume);
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }

  /// Gera nome do arquivo baseado no currículo
  String _generateFileName(Resume resume) {
    final name = resume.personal?.fullName ?? 'Resume';
    final sanitized = name.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '').replaceAll(' ', '_');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'Resume_${sanitized}_$timestamp.pdf';
  }

  /// Constrói o cabeçalho do PDF
  pw.Widget _buildHeader(Resume resume, pw.Font bold, pw.Font regular) {
    final personal = resume.personal;
    
    final contactItems = <pw.Widget>[];
    
    if (personal != null) {
      if (personal.email.isNotEmpty) {
        contactItems.add(_buildContactItem(personal.email, regular));
      }
      
      final phone = personal.phone;
      if (phone != null && phone.isNotEmpty) {
        contactItems.add(_buildContactItem(phone, regular));
      }
      
      final location = [personal.city, personal.country]
          .where((e) => e != null && e.isNotEmpty)
          .join(', ');
      if (location.isNotEmpty) {
        contactItems.add(_buildContactItem(location, regular));
      }
      
      final linkedinUrl = personal.linkedinUrl;
      if (linkedinUrl != null && linkedinUrl.isNotEmpty) {
        contactItems.add(_buildContactItem(
          linkedinUrl, 
          regular
        ));
      }
      
      final githubUrl = personal.githubUrl;
      if (githubUrl != null && githubUrl.isNotEmpty) {
        contactItems.add(_buildContactItem(
          githubUrl, 
          regular
        ));
      }
      
      final websiteUrl = personal.websiteUrl;
      if (websiteUrl != null && websiteUrl.isNotEmpty) {
        contactItems.add(_buildContactItem(
          websiteUrl, 
          regular
        ));
      }
    }
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Nome
        pw.Text(
          personal?.fullName.toUpperCase() ?? 'RESUME',
          style: pw.TextStyle(font: bold, fontSize: 24, letterSpacing: 1.2),
        ),
        
        if (personal != null && personal.currentRole != null && personal.currentRole!.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Text(
            personal.currentRole!,
            style: pw.TextStyle(font: regular, fontSize: 12, color: PdfColors.grey700),
          ),
        ],
        
        pw.SizedBox(height: 8),
        
        // Informações de contato
        pw.Wrap(
          spacing: 12,
          runSpacing: 4,
          children: contactItems,
        ),
      ],
    );
  }

  /// Extrai o domínio de uma URL
  String _extractUrlDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.isNotEmpty ? uri.host : url;
    } catch (e) {
      return url;
    }
  }

  /// Constrói um item de contato
  pw.Widget _buildContactItem(String text, pw.Font font) {
    return pw.Text(
      text,
      style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey800),
    );
  }

  /// Constrói uma seção (título)
  pw.Widget _buildSection(String title, pw.Font bold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(font: bold, fontSize: 14, letterSpacing: 0.8),
        ),
        pw.SizedBox(height: 4),
        pw.Container(
          width: double.infinity,
          height: 2,
          color: PdfColors.grey800,
        ),
      ],
    );
  }

  /// Constrói uma experiência profissional
  pw.Widget _buildExperience(WorkExperience exp, pw.Font bold, pw.Font regular, pw.Font italic) {
    // Dividir a descrição em tópicos (por linha, ou por ponto)
    final descriptionLines = exp.description
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();
    
    // Se tiver apenas uma linha sem quebras, tentar dividir por pontos
    final bullets = descriptionLines.length == 1
        ? exp.description
            .split('.')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList()
        : descriptionLines;
    
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      exp.role,
                      style: pw.TextStyle(font: bold, fontSize: 11),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      exp.company,
                      style: pw.TextStyle(font: italic, fontSize: 10, color: PdfColors.grey700),
                    ),
                  ],
                ),
              ),
              pw.Text(
                '${exp.startDate} - ${exp.isCurrent ? 'Present' : exp.endDate ?? 'N/A'}',
                style: pw.TextStyle(font: regular, fontSize: 9, color: PdfColors.grey600),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          // Exibir como bullet points
          ...bullets.map((bullet) => pw.Padding(
            padding: const pw.EdgeInsets.only(left: 12, bottom: 4),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '• ',
                  style: pw.TextStyle(font: bold, fontSize: 10),
                ),
                pw.Expanded(
                  child: pw.Text(
                    bullet,
                    style: pw.TextStyle(font: regular, fontSize: 10, lineSpacing: 1.3),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  /// Constrói uma educação
  pw.Widget _buildEducation(Education edu, pw.Font bold, pw.Font regular, pw.Font italic) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  edu.degree,
                  style: pw.TextStyle(font: bold, fontSize: 11),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  edu.institution,
                  style: pw.TextStyle(font: italic, fontSize: 10, color: PdfColors.grey700),
                ),
              ],
            ),
          ),
          pw.Text(
            '${edu.startDate} - ${edu.isCurrent ? 'Present' : edu.endDate ?? 'N/A'}',
            style: pw.TextStyle(font: regular, fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  /// Constrói um projeto
  pw.Widget _buildProject(Project proj, pw.Font bold, pw.Font regular) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Text(
                proj.name,
                style: pw.TextStyle(font: bold, fontSize: 11),
              ),
              if (proj.url?.isNotEmpty == true) ...[
                pw.SizedBox(width: 8),
                pw.Text(
                  '(${_extractUrlDomain(proj.url!)})',
                  style: pw.TextStyle(font: regular, fontSize: 9, color: PdfColors.blue700),
                ),
              ],
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            proj.description,
            style: pw.TextStyle(font: regular, fontSize: 10, lineSpacing: 1.3),
            textAlign: pw.TextAlign.justify,
          ),
        ],
      ),
    );
  }

  /// Constrói a seção de idiomas
  pw.Widget _buildLanguages(List<Language> languages, pw.Font bold, pw.Font regular) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: languages.map((lang) {
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Row(
            children: [
              pw.Container(
                width: 4,
                height: 4,
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey800,
                  shape: pw.BoxShape.circle,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Text(
                  '${lang.language} - ${lang.proficiency}',
                  style: pw.TextStyle(font: regular, fontSize: 10),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Abre o PDF gerado para visualização/compartilhamento
  Future<void> previewPdf(Resume resume) async {
    WidgetsFlutterBinding.ensureInitialized();

    final pdf = pw.Document();

    final bold = await PdfGoogleFonts.openSansBold();
    final regular = await PdfGoogleFonts.openSansRegular();
    final italic = await PdfGoogleFonts.openSansItalic();

    final content = await _buildPdfContent(resume, bold, regular, italic);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => content,
      ),
    );

    // Gera os bytes na thread principal antes de chamar o plugin
    final bytes = await pdf.save();

    await Printing.sharePdf(
      bytes: bytes,
      filename: _generateFileName(resume),
    );
  }
}
