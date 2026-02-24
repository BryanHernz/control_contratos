import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/worker_model.dart';

class PdfContractService {
  static Future<void> generateBatchContracts(List<WorkerModel> workers) async {
    try {
      final pdf = pw.Document();
      var cambria = await rootBundle.load("lib/images/Cambria.ttf");
      var calibri = await rootBundle.load("lib/images/Calibri Regular.ttf");
      var calibriBold = await rootBundle.load("lib/images/Calibri Bold.ttf");

      var empresaParam = await FirebaseFirestore.instance
          .collection('Otros')
          .doc('empresadata')
          .get();

      double baselina = 4;
      double letterSize = 12;

      for (var worker in workers) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.letter,
            margin: const pw.EdgeInsets.symmetric(vertical: 40, horizontal: 60),
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        '${empresaParam['nombreempresa']}',
                        style: pw.TextStyle(
                          font: pw.Font.ttf(cambria),
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      pw.Text(
                        'AÑO ${DateTime.now().year}',
                        style: pw.TextStyle(
                          font: pw.Font.ttf(cambria),
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 20),
                    child: pw.Center(
                      child: pw.Text(
                        'CONTRATO DE TRABAJO PARA FAENA DETERMINADA',
                        style: pw.TextStyle(
                          decoration: pw.TextDecoration.underline,
                          font: pw.Font.ttf(calibriBold),
                          fontSize: letterSize,
                        ),
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 20),
                    child: pw.RichText(
                      textAlign: pw.TextAlign.justify,
                      text: pw.TextSpan(
                        baseline: baselina,
                        text: 'En Paine, a ',
                        style: pw.TextStyle(
                          font: pw.Font.ttf(calibri),
                          fontSize: letterSize,
                        ),
                        children: [
                          pw.TextSpan(
                            baseline: baselina,
                            text: worker.ingress!.toUpperCase(),
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibriBold),
                              fontSize: letterSize,
                            ),
                          ),
                          pw.TextSpan(
                            baseline: baselina,
                            text: ', entre ',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibri),
                              fontSize: letterSize,
                            ),
                          ),
                          pw.TextSpan(
                            baseline: baselina,
                            text: '${empresaParam['nombreempresa']}.,',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibriBold),
                              fontSize: letterSize,
                            ),
                          ),
                          pw.TextSpan(
                            baseline: baselina,
                            text: ' RUT N° ',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibri),
                              fontSize: letterSize,
                            ),
                          ),
                          pw.TextSpan(
                            baseline: baselina,
                            text: '${empresaParam['rut']}',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibriBold),
                              fontSize: letterSize,
                            ),
                          ),
                          pw.TextSpan(
                            baseline: baselina,
                            text: ', Representada por Don ',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibri),
                              fontSize: letterSize,
                            ),
                          ),
                          pw.TextSpan(
                            baseline: baselina,
                            text: 'OCTAVIO ORLANDO NUNEZ MENARES',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibriBold),
                              fontSize: letterSize,
                            ),
                          ),
                          pw.TextSpan(
                            baseline: baselina,
                            text: ' RUT N° ',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibri),
                              fontSize: letterSize,
                            ),
                          ),
                          pw.TextSpan(
                            baseline: baselina,
                            text: '11.171.021-K',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibriBold),
                              fontSize: letterSize,
                            ),
                          ),
                          pw.TextSpan(
                            baseline: baselina,
                            text: ' correo electrónico ',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibri),
                              fontSize: letterSize,
                            ),
                          ),
                          pw.TextSpan(
                            baseline: baselina,
                            text: 'MRL.ANDREA@LIVE.COM',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibriBold),
                              fontSize: letterSize,
                            ),
                          ),
                          pw.TextSpan(
                            baseline: baselina,
                            text:
                                ', ambos con domicilio en O’Higgins Pelay Lt 2 H Pc N° 2 A, Comuna San Francisco De Mostazal, en lo sucesivo ',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibri),
                              fontSize: letterSize,
                            ),
                          ),
                          pw.TextSpan(
                            baseline: baselina,
                            text: 'El “Empleador”',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibriBold),
                              decoration: pw.TextDecoration.underline,
                              fontSize: letterSize,
                            ),
                          ),
                          pw.TextSpan(
                            baseline: baselina,
                            text: ' y Don(a): ',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibriBold),
                              fontSize: letterSize,
                            ),
                          ),
                          pw.TextSpan(
                            baseline: baselina,
                            text:
                                '${worker.name!.toUpperCase()} ${worker.lastName!.toUpperCase()}',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibriBold),
                              fontSize: letterSize,
                            ),
                          ),
                          pw.TextSpan(
                            baseline: baselina,
                            text: ', RUT N° ',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibri),
                              fontSize: letterSize,
                            ),
                          ),
                          pw.TextSpan(
                            baseline: baselina,
                            text: worker.rut,
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibriBold),
                              fontSize: letterSize,
                            ),
                          ),
                          pw.TextSpan(
                            baseline: baselina,
                            text: ', nacido el ',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibri),
                              fontSize: letterSize,
                            ),
                          ),
                          pw.TextSpan(
                            baseline: baselina,
                            text: worker.birth!.toUpperCase(),
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibriBold),
                              fontSize: letterSize,
                            ),
                          ),
                          pw.TextSpan(
                            baseline: baselina,
                            text: ', de nacionalidad ',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibri),
                              fontSize: letterSize,
                            ),
                          ),
                          pw.TextSpan(
                            baseline: baselina,
                            text: worker.nacionality!.toUpperCase(),
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibriBold),
                              fontSize: letterSize,
                            ),
                          ),
                          pw.TextSpan(
                            baseline: baselina,
                            text: ', Estado Civil ',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibri),
                              fontSize: letterSize,
                            ),
                          ),
                          pw.TextSpan(
                            baseline: baselina,
                            text: worker.civilState!.toUpperCase(),
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibriBold),
                              fontSize: letterSize,
                            ),
                          ),
                          pw.TextSpan(
                            baseline: baselina,
                            text: ', domiciliado en ',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibri),
                              fontSize: letterSize,
                            ),
                          ),
                          pw.TextSpan(
                            baseline: baselina,
                            text: worker.adress!.toUpperCase(),
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibriBold),
                              fontSize: letterSize,
                            ),
                          ),
                          pw.TextSpan(
                            baseline: baselina,
                            text: ', comuna de ',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibri),
                              fontSize: letterSize,
                            ),
                          ),
                          pw.TextSpan(
                            baseline: baselina,
                            text: worker.commune!.toUpperCase(),
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibriBold),
                              fontSize: letterSize,
                            ),
                          ),
                          pw.TextSpan(
                            baseline: baselina,
                            text:
                                ', procede de igual caso, en adelante y para los efectos de este contrato ',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibri),
                              fontSize: letterSize,
                            ),
                          ),
                          pw.TextSpan(
                            baseline: baselina,
                            text: 'El “Trabajador” ',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibriBold),
                              decoration: pw.TextDecoration.underline,
                              fontSize: letterSize,
                            ),
                          ),
                          pw.TextSpan(
                            baseline: baselina,
                            text: ', correo electrónico ',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibri),
                              fontSize: letterSize,
                            ),
                          ),
                          pw.TextSpan(
                            baseline: baselina,
                            text: worker.email?.toUpperCase() ?? "",
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibriBold),
                              fontSize: letterSize,
                            ),
                          ),
                          pw.TextSpan(
                            baseline: baselina,
                            text:
                                ', han convenido en el siguiente contrato de trabajo.',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibri),
                              fontSize: letterSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 12),
                    child: pw.RichText(
                      textAlign: pw.TextAlign.justify,
                      text: pw.TextSpan(
                        baseline: baselina,
                        text: '1.- ',
                        style: pw.TextStyle(
                          font: pw.Font.ttf(calibriBold),
                          fontSize: letterSize,
                        ),
                        children: [
                          pw.TextSpan(
                            baseline: baselina,
                            text:
                                'El “Trabajador” se compromete y obliga ha prestar servicios de su especialidad como ',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibri),
                              fontSize: letterSize,
                            ),
                          ),
                          pw.TextSpan(
                            baseline: baselina,
                            text: worker.labor!.toUpperCase(),
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibriBold),
                              fontSize: letterSize,
                            ),
                          ),
                          pw.TextSpan(
                            baseline: baselina,
                            text: ' en FAENA ',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibri),
                              fontSize: letterSize,
                            ),
                          ),
                          pw.TextSpan(
                            baseline: baselina,
                            text: worker.place!.toUpperCase(),
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibriBold),
                              fontSize: letterSize,
                            ),
                          ),
                          pw.TextSpan(
                            baseline: baselina,
                            text:
                                ' ubicada en O\'Higgins Pelay Lt 2 H Pc N° 2 A, Comuna de San Francisco de Mostazal, debiendo someterse a las siguientes instrucciones impartidas por el “Empleador” y por sus Jefes Directos.',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibri),
                              fontSize: letterSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 12),
                    child: pw.RichText(
                      textAlign: pw.TextAlign.justify,
                      text: pw.TextSpan(
                        baseline: baselina,
                        text: '2.- ',
                        style: pw.TextStyle(
                          font: pw.Font.ttf(calibriBold),
                          fontSize: letterSize,
                        ),
                        children: [
                          pw.TextSpan(
                            baseline: baselina,
                            text:
                                'La jornada ordinaria de trabajo será de 44 Horas Semanales, pudiendo ser distribuida de la siguiente manera: a) Jornada De Lunes a Sábado, en horarios comprendido desde las 08:30 hasta las 18:30 con 1 hora de colación. b) En sistema de turnos de mañana o de tarde según sea requerido por él supervisor.',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibri),
                              fontSize: letterSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 12),
                    child: pw.RichText(
                      textAlign: pw.TextAlign.justify,
                      text: pw.TextSpan(
                        baseline: baselina,
                        text: '3.- ',
                        style: pw.TextStyle(
                          font: pw.Font.ttf(calibriBold),
                          fontSize: letterSize,
                        ),
                        children: [
                          pw.TextSpan(
                            baseline: baselina,
                            text:
                                'El “Empleador” pagara una remuneración a razón de \$500.000.- pesos mensuales (Sueldo base mínimo) como remuneración liquida y esta será cancelada mensualmente entre los días 1 y 5 del mes siguiente al vencimiento y los anticipos se les pagará los días 20 de cada mes o al hábil anterior. La remuneración total incluirá la asignación de movilización y movilización y estarán incluidos y detallados mes a mes en su liquidación de sueldo. Las partes convienen que la liquidación y pago de las remuneraciones se podrán realizar en dinero efectivo y/ en transferencia.',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibri),
                              fontSize: letterSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 12),
                    child: pw.RichText(
                      textAlign: pw.TextAlign.justify,
                      text: pw.TextSpan(
                        baseline: baselina,
                        text: '4.- ',
                        style: pw.TextStyle(
                          font: pw.Font.ttf(calibriBold),
                          fontSize: letterSize,
                        ),
                        children: [
                          pw.TextSpan(
                            baseline: baselina,
                            text:
                                'De la remuneración estipulada se impondrá en las siguientes instituciones: \n',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibri),
                              fontSize: letterSize,
                            ),
                          ),
                          pw.TextSpan(
                            baseline: baselina,
                            text:
                                'AFP: ${worker.afp!.toUpperCase()} | PREVISIÓN S: ${worker.prevision!.toUpperCase()}',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibri),
                              fontSize: letterSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.letter,
            margin: const pw.EdgeInsets.symmetric(vertical: 40, horizontal: 60),
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 12),
                    child: pw.RichText(
                      textAlign: pw.TextAlign.justify,
                      text: pw.TextSpan(
                        baseline: baselina,
                        text: '5.- ',
                        style: pw.TextStyle(
                          font: pw.Font.ttf(calibriBold),
                          fontSize: letterSize,
                        ),
                        children: [
                          pw.TextSpan(
                            baseline: baselina,
                            text:
                                'Se prohíbe en forma estricta fumar en lugares de trabajo o encender fogatas con el objeto de preparase alimentos u otras especies (Solo lo pueden hacer en lugar habilitado). El presentarse a su lugar de trabajo en manifiesto estado de intemperancia bajo la influencia de narcóticos o de drogas enervantes o introducirlas en el predio dará causa de termino de inmediato a sus servicios. Mantener un respetuoso trato y lealtad para con el “Empleador”.',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibri),
                              fontSize: letterSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 12),
                    child: pw.RichText(
                      textAlign: pw.TextAlign.justify,
                      text: pw.TextSpan(
                        baseline: baselina,
                        text: '6.- ',
                        style: pw.TextStyle(
                          font: pw.Font.ttf(calibriBold),
                          fontSize: letterSize,
                        ),
                        children: [
                          pw.TextSpan(
                            baseline: baselina,
                            text:
                                'El presente contrato terminará a la conclusión de la FAENA O CONCLUCION DEL SERVICIO por el  cual  fue contratado y que se indican en la Cláusula  Nº  (1), de este contrato, sin perjuicio de terminarse  antes por cualquiera de las causales  establecidas  en los Artículo  159 al 160 del Código del Trabajo, por no mediar incumplimiento  alguna por parte del “Trabajador”.',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibri),
                              fontSize: letterSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 12),
                    child: pw.RichText(
                      textAlign: pw.TextAlign.justify,
                      text: pw.TextSpan(
                        baseline: baselina,
                        text: '7.- ',
                        style: pw.TextStyle(
                          font: pw.Font.ttf(calibriBold),
                          fontSize: letterSize,
                        ),
                        children: [
                          pw.TextSpan(
                            baseline: baselina,
                            text:
                                'El “Trabajador“ autoriza  para que el “Empleador“ deduzca mes a mes el valor diario del tiempo que haya faltado al no justificado, dentro de su periodo de la semana. Así  como también cualquier suma que  se  adeuda , sea por concepto de prestamos entregados, prestamos  médicos, leyes sociales, por daño materiales a  muebles u/o destrozos que realice en el lugar y recinto que vive que sean  ajenos a su uso habitacional .',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibri),
                              fontSize: letterSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 12),
                    child: pw.RichText(
                      textAlign: pw.TextAlign.justify,
                      text: pw.TextSpan(
                        baseline: baselina,
                        text: '8.- ',
                        style: pw.TextStyle(
                          font: pw.Font.ttf(calibriBold),
                          fontSize: letterSize,
                        ),
                        children: [
                          pw.TextSpan(
                            baseline: baselina,
                            text:
                                'Para todos los efectos derivados de este contrato de trabajo, las partes fijan  domicilio en la ciudad y comuna de SAN FCO DE MOSTAZAL.',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibri),
                              fontSize: letterSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 12),
                    child: pw.RichText(
                      textAlign: pw.TextAlign.justify,
                      text: pw.TextSpan(
                        baseline: baselina,
                        text: '9.- ',
                        style: pw.TextStyle(
                          font: pw.Font.ttf(calibriBold),
                          fontSize: letterSize,
                        ),
                        children: [
                          pw.TextSpan(
                            baseline: baselina,
                            text:
                                'El Presente Contrato se firma en dos ejemplares de mismo orden u de igual fecha, declarando recibir el “Trabajador“ en  este  el ejemplar suyo e informar al “Empleador“ sobre sus  antecedentes y mantenerlos  al  día para poder presentarlos a su AFP. u PREVISION de SALUD. ',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibri),
                              fontSize: letterSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 12),
                    child: pw.RichText(
                      textAlign: pw.TextAlign.justify,
                      text: pw.TextSpan(
                        baseline: baselina,
                        text: '10.- ',
                        style: pw.TextStyle(
                          font: pw.Font.ttf(calibriBold),
                          fontSize: letterSize,
                        ),
                        children: [
                          pw.TextSpan(
                            baseline: baselina,
                            text:
                                'Se deja constancia que Don(a) ingresó al servicio de la empresa con fecha ',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibri),
                              fontSize: letterSize,
                            ),
                          ),
                          pw.TextSpan(
                            baseline: baselina,
                            text: worker.ingress!.toUpperCase(),
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibriBold),
                              fontSize: letterSize,
                            ),
                          ),
                          pw.TextSpan(
                            baseline: baselina,
                            text: '.',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibri),
                              fontSize: letterSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 100),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        mainAxisAlignment: pw.MainAxisAlignment.start,
                        children: [
                          pw.Text(
                            '_______________________________',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibriBold),
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          pw.Text(
                            '${empresaParam['nombreempresa']}',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibriBold),
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          pw.Text(
                            'RUT N°: ${empresaParam['rut']}',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibriBold),
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          pw.Text(
                            'EMPLEADOR',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibriBold),
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        mainAxisAlignment: pw.MainAxisAlignment.start,
                        children: [
                          pw.Text(
                            '_______________________________',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibriBold),
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          pw.Text(
                            '${worker.name!.toUpperCase()} ${worker.lastName!.toUpperCase()}',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibriBold),
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          pw.Text(
                            'RUT N°: ${worker.rut}',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibriBold),
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          pw.Text(
                            'TRABAJADOR',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibriBold),
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 15),
                  pw.Center(
                    child: pw.Text(
                      "O’Higgins Pelay Lt 2 H Pc N° 2 A, Comuna San Francisco De Mostazal",
                      style: pw.TextStyle(
                          font: pw.Font.ttf(calibriBold),
                          fontSize: 10,
                          color: PdfColor.fromHex('#9B9B9B')),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }

      await Printing.layoutPdf(
          onLayout: (format) async => pdf.save(), format: PdfPageFormat.letter);
    } catch (e) {
      if (kDebugMode) {
        print('Error generating batch contracts: \$e');
      }
    }
  }
}
