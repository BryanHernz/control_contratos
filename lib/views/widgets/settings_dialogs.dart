import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:animated_snack_bar/animated_snack_bar.dart';
import '../../customs/widgets_custom.dart';
import '../../services/firestore_db.dart';

// --- Shared Helper Methods ---

Future<void> _selectTime(BuildContext context, TimeOfDay? initialTime,
    Function(TimeOfDay) onTimeSelected) async {
  final TimeOfDay? picked = await showTimePicker(
    context: context,
    initialTime: initialTime ?? TimeOfDay.now(),
  );
  if (picked != null) {
    onTimeSelected(picked);
  }
}

String _formatTime(TimeOfDay? time) {
  if (time == null) return '00:00';
  final String hour = time.hour.toString().padLeft(2, '0');
  final String minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _formatOrFallback(TimeOfDay? start, TimeOfDay? end, String fallbackStart,
    String fallbackEnd) {
  if (start != null && end != null) {
    return '${_formatTime(start)}/${_formatTime(end)}';
  }
  return '$fallbackStart/$fallbackEnd';
}

// --- Workplace Widgets (Lugares) ---

class NewPlace extends StatefulWidget {
  const NewPlace({super.key});

  @override
  State<NewPlace> createState() => _NewPlaceState();
}

class _NewPlaceState extends State<NewPlace> {
  final TextEditingController _tipoController = TextEditingController();
  final TextEditingController _horasController =
      TextEditingController(text: "44");
  final TextEditingController _colacionController =
      TextEditingController(text: "60");

  TimeOfDay? _ljDesde = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay? _ljHasta = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay? _vDesde = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay? _vHasta = const TimeOfDay(hour: 17, minute: 0);
  TimeOfDay? _sDesde = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay? _sHasta = const TimeOfDay(hour: 13, minute: 0);

  bool _trabajaSabado = false;
  bool _mismoHorarioLunesViernes = false;
  final _formKey = GlobalKey<FormState>();

  void saveNewPlace() async {
    try {
      String nuevoLugar = _tipoController.text.trim();
      String horasLugar = _horasController.text.trim();

      String lunesJueves =
          _formatOrFallback(_ljDesde, _ljHasta, '08:00', '18:00');
      String viernes = _mismoHorarioLunesViernes
          ? lunesJueves
          : _formatOrFallback(_vDesde, _vHasta, '08:00', '17:00');

      if (horasLugar.isEmpty) horasLugar = "44";
      await db.runTransaction((transaction) async {
        DocumentReference lugaresRef = db.collection('Otros').doc('lugares');
        DocumentReference horasRef =
            db.collection('Otros').doc('lugares_horas');

        DocumentSnapshot lugaresSnapshot = await transaction.get(lugaresRef);
        DocumentSnapshot horasSnapshot = await transaction.get(horasRef);

        List<dynamic> tipos =
            lugaresSnapshot.exists && lugaresSnapshot.data() != null
                ? List.from((lugaresSnapshot.data() as Map)['tipos'] ?? [])
                : [];
        List<dynamic> pruebaHoras =
            horasSnapshot.exists && horasSnapshot.data() != null
                ? List.from((horasSnapshot.data() as Map)['prueba_horas'] ?? [])
                : [];
        List<dynamic> lunesJuevesList =
            horasSnapshot.exists && horasSnapshot.data() != null
                ? List.from((horasSnapshot.data() as Map)['lunes_jueves'] ?? [])
                : [];
        List<dynamic> viernesList =
            horasSnapshot.exists && horasSnapshot.data() != null
                ? List.from((horasSnapshot.data() as Map)['viernes'] ?? [])
                : [];
        List<dynamic> sabadosList =
            horasSnapshot.exists && horasSnapshot.data() != null
                ? List.from((horasSnapshot.data() as Map)['sabados'] ?? [])
                : [];
        List<dynamic> colacionList =
            horasSnapshot.exists && horasSnapshot.data() != null
                ? List.from((horasSnapshot.data() as Map)['colacion'] ?? [])
                : [];

        // Asegurar consistencia de longitudes
        while (pruebaHoras.length < tipos.length) {
          pruebaHoras.add("44");
        }
        while (lunesJuevesList.length < tipos.length) {
          lunesJuevesList.add("08:00/18:00");
        }
        while (viernesList.length < tipos.length) {
          viernesList.add("08:00/17:00");
        }
        while (sabadosList.length < tipos.length) {
          sabadosList.add("N/A");
        }
        while (colacionList.length < tipos.length) {
          colacionList.add("60");
        }

        String sabadoValue = _trabajaSabado
            ? _formatOrFallback(_sDesde, _sHasta, '08:00', '12:00')
            : "N/A";
        String colacionValue = _colacionController.text.trim();
        if (colacionValue.isEmpty) colacionValue = "60";

        tipos.add(nuevoLugar);
        pruebaHoras.add(horasLugar);
        lunesJuevesList.add(lunesJueves);
        viernesList.add(viernes);
        sabadosList.add(sabadoValue);
        colacionList.add(colacionValue);

        transaction.update(lugaresRef, {'tipos': tipos});
        transaction.set(
            horasRef,
            {
              'prueba_horas': pruebaHoras,
              'lunes_jueves': lunesJuevesList,
              'viernes': viernesList,
              'sabados': sabadosList,
              'colacion': colacionList,
            },
            SetOptions(merge: true));
      });

      if (!mounted) return;
      Get.back();
      AnimatedSnackBar.material(
        'Establecimiento registrado con éxito',
        mobileSnackBarPosition: MobileSnackBarPosition.top,
        desktopSnackBarPosition: DesktopSnackBarPosition.bottomRight,
        type: AnimatedSnackBarType.success,
      ).show(context);
    } catch (e) {
      debugPrint("Error saving new place: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InputTextField(
                textController: _tipoController,
                hint: 'Establecimiento',
                onFieldSubmitted: (_) {
                  if (_formKey.currentState!.validate()) saveNewPlace();
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese un establecimiento';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InputTextField(
                teclado: TextInputType.number,
                textController: _horasController,
                hint: 'Horas Semanales (Ej: 40 o 44)',
                onFieldSubmitted: (_) {
                  if (_formKey.currentState!.validate()) saveNewPlace();
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese las horas semanales';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Debe ser un número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InputTextField(
                teclado: const TextInputType.numberWithOptions(decimal: true),
                textController: _colacionController,
                hint: 'Minutos de Colación (Ej: 60 o 45)',
                onFieldSubmitted: (_) {
                  if (_formKey.currentState!.validate()) saveNewPlace();
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese los minutos de colación';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Debe ser un número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text('Horario Lunes a Jueves',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context, _ljDesde,
                          (time) => setState(() => _ljDesde = time)),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                            labelText: 'Desde', border: OutlineInputBorder()),
                        child: Text(_formatTime(_ljDesde)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context, _ljHasta,
                          (time) => setState(() => _ljHasta = time)),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                            labelText: 'Hasta', border: OutlineInputBorder()),
                        child: Text(_formatTime(_ljHasta)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Mismo horario Lunes a Viernes'),
                subtitle: const Text(
                    'El viernes tiene el mismo horario que Lunes a Jueves'),
                value: _mismoHorarioLunesViernes,
                onChanged: (bool? value) {
                  setState(() {
                    _mismoHorarioLunesViernes = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
              if (!_mismoHorarioLunesViernes) ...[
                const Text('Horario Viernes',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectTime(context, _vDesde,
                            (time) => setState(() => _vDesde = time)),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                              labelText: 'Desde', border: OutlineInputBorder()),
                          child: Text(_formatTime(_vDesde)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectTime(context, _vHasta,
                            (time) => setState(() => _vHasta = time)),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                              labelText: 'Hasta', border: OutlineInputBorder()),
                          child: Text(_formatTime(_vHasta)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              CheckboxListTile(
                title: const Text('Trabaja los Sábados'),
                value: _trabajaSabado,
                onChanged: (bool? value) {
                  setState(() {
                    _trabajaSabado = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
              if (_trabajaSabado) ...[
                const Text('Horario Sábado',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectTime(context, _sDesde,
                            (time) => setState(() => _sDesde = time)),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                              labelText: 'Desde', border: OutlineInputBorder()),
                          child: Text(_formatTime(_sDesde)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectTime(context, _sHasta,
                            (time) => setState(() => _sHasta = time)),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                              labelText: 'Hasta', border: OutlineInputBorder()),
                          child: Text(_formatTime(_sHasta)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      funcion: () {
                        Get.back();
                      },
                      texto: 'Cancelar',
                      cancelar: true,
                      icon: Icons.close_rounded,
                      width: double.infinity,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                        funcion: () {
                          if (_formKey.currentState!.validate()) {
                            _formKey.currentState!.save();
                            saveNewPlace();
                          }
                        },
                        texto: 'Agregar',
                        cancelar: false,
                        icon: Icons.add_rounded,
                        width: double.infinity),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditPlace extends StatefulWidget {
  final String existingPlace;
  const EditPlace({super.key, required this.existingPlace});

  @override
  State<EditPlace> createState() => _EditPlaceState();
}

class _EditPlaceState extends State<EditPlace> {
  final TextEditingController _horasController = TextEditingController();
  final TextEditingController _colacionController = TextEditingController();
  TimeOfDay? _ljDesde;
  TimeOfDay? _ljHasta;
  TimeOfDay? _vDesde;
  TimeOfDay? _vHasta;
  TimeOfDay? _sDesde;
  TimeOfDay? _sHasta;
  bool _trabajaSabado = false;
  bool _mismoHorarioLunesViernes = false;
  bool _isLoading = true;
  int placeIndex = -1;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadPlaceData();
  }

  void _loadPlaceData() async {
    try {
      DocumentSnapshot snapshot =
          await db.collection('Otros').doc('lugares_horas').get();

      DocumentSnapshot snapshotNombres =
          await db.collection('Otros').doc('lugares').get();

      if (snapshot.exists && snapshotNombres.exists) {
        List<dynamic> nombres = snapshotNombres['tipos'];
        placeIndex = nombres.indexOf(widget.existingPlace);

        if (placeIndex != -1) {
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

          _horasController.text = data['prueba_horas'][placeIndex].toString();

          if (data.containsKey('colacion')) {
            _colacionController.text = data['colacion'][placeIndex].toString();
          } else {
            _colacionController.text = "60";
          }

          TimeOfDay parse(String val, TimeOfDay def) {
            try {
              if (val.contains('/')) {
                final parts = val.split('/');
                final timeParts = parts[0].split(':');
                return TimeOfDay(
                    hour: int.parse(timeParts[0]),
                    minute: int.parse(timeParts[1]));
              }
            } catch (_) {}
            return def;
          }

          TimeOfDay parseEnd(String val, TimeOfDay def) {
            try {
              if (val.contains('/')) {
                final parts = val.split('/');
                final timeParts = parts[1].split(':');
                return TimeOfDay(
                    hour: int.parse(timeParts[0]),
                    minute: int.parse(timeParts[1]));
              }
            } catch (_) {}
            return def;
          }

          if (data.containsKey('lunes_jueves')) {
            _ljDesde = parse(data['lunes_jueves'][placeIndex],
                const TimeOfDay(hour: 8, minute: 0));
            _ljHasta = parseEnd(data['lunes_jueves'][placeIndex],
                const TimeOfDay(hour: 18, minute: 0));
          }

          if (data.containsKey('viernes')) {
            final viernesVal = data['viernes'][placeIndex].toString();
            final ljVal = data.containsKey('lunes_jueves')
                ? data['lunes_jueves'][placeIndex].toString()
                : '';
            // Si el viernes es igual al lunes_jueves, activar el checkbox
            if (viernesVal == ljVal && viernesVal.isNotEmpty) {
              _mismoHorarioLunesViernes = true;
            } else {
              _vDesde = parse(viernesVal, const TimeOfDay(hour: 8, minute: 0));
              _vHasta =
                  parseEnd(viernesVal, const TimeOfDay(hour: 17, minute: 0));
            }
          }

          if (data.containsKey('sabados') &&
              data['sabados'][placeIndex] != "N/A") {
            _trabajaSabado = true;
            _sDesde = parse(data['sabados'][placeIndex],
                const TimeOfDay(hour: 8, minute: 0));
            _sHasta = parseEnd(data['sabados'][placeIndex],
                const TimeOfDay(hour: 13, minute: 0));
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading place data: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void saveEditPlace() async {
    if (placeIndex == -1) return;
    try {
      String horasStr = _horasController.text.trim();
      String colacionStr = _colacionController.text.trim();
      String ljStr = _formatOrFallback(_ljDesde, _ljHasta, '08:00', '18:00');
      String vStr = _mismoHorarioLunesViernes
          ? ljStr
          : _formatOrFallback(_vDesde, _vHasta, '08:00', '17:00');
      String sStr = _trabajaSabado
          ? _formatOrFallback(_sDesde, _sHasta, '08:00', '12:00')
          : "N/A";

      await db.runTransaction((transaction) async {
        DocumentReference ref = db.collection('Otros').doc('lugares_horas');
        DocumentSnapshot snapshot = await transaction.get(ref);

        if (snapshot.exists) {
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          List<dynamic> ph = List.from(data['prueba_horas']);
          List<dynamic> col = data.containsKey('colacion')
              ? List.from(data['colacion'])
              : List.filled(ph.length, "60");
          List<dynamic> lj = data.containsKey('lunes_jueves')
              ? List.from(data['lunes_jueves'])
              : List.filled(ph.length, "08:00/18:00");
          List<dynamic> v = data.containsKey('viernes')
              ? List.from(data['viernes'])
              : List.filled(ph.length, "08:00/17:00");
          List<dynamic> s = data.containsKey('sabados')
              ? List.from(data['sabados'])
              : List.filled(ph.length, "N/A");

          ph[placeIndex] = horasStr;
          col[placeIndex] = colacionStr;
          lj[placeIndex] = ljStr;
          v[placeIndex] = vStr;
          s[placeIndex] = sStr;

          transaction.update(ref, {
            'prueba_horas': ph,
            'colacion': col,
            'lunes_jueves': lj,
            'viernes': v,
            'sabados': s,
          });
        }
      });

      if (!mounted) return;
      Get.back();
      AnimatedSnackBar.material(
        'Cambios guardados con éxito',
        mobileSnackBarPosition: MobileSnackBarPosition.top,
        desktopSnackBarPosition: DesktopSnackBarPosition.bottomRight,
        type: AnimatedSnackBarType.success,
      ).show(context);
    } catch (e) {
      debugPrint("Error saving edit place: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InputTextField(
                teclado: TextInputType.number,
                textController: _horasController,
                hint: 'Horas Semanales',
                onFieldSubmitted: (_) {
                  if (_formKey.currentState!.validate()) saveEditPlace();
                },
                validator: (val) =>
                    val == null || val.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              InputTextField(
                teclado: TextInputType.number,
                textController: _colacionController,
                hint: 'Minutos de Colación',
                onFieldSubmitted: (_) {
                  if (_formKey.currentState!.validate()) saveEditPlace();
                },
                validator: (val) =>
                    val == null || val.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              const Text('Horario Lunes a Jueves',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context, _ljDesde,
                          (t) => setState(() => _ljDesde = t)),
                      child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Desde'),
                          child: Text(_formatTime(_ljDesde))),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context, _ljHasta,
                          (t) => setState(() => _ljHasta = t)),
                      child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Hasta'),
                          child: Text(_formatTime(_ljHasta))),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Mismo horario Lunes a Viernes'),
                subtitle: const Text(
                    'El viernes tiene el mismo horario que Lunes a Jueves'),
                value: _mismoHorarioLunesViernes,
                onChanged: (v) =>
                    setState(() => _mismoHorarioLunesViernes = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              if (!_mismoHorarioLunesViernes) ...[
                const Text('Horario Viernes',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectTime(context, _vDesde,
                            (t) => setState(() => _vDesde = t)),
                        child: InputDecorator(
                            decoration:
                                const InputDecoration(labelText: 'Desde'),
                            child: Text(_formatTime(_vDesde))),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectTime(context, _vHasta,
                            (t) => setState(() => _vHasta = t)),
                        child: InputDecorator(
                            decoration:
                                const InputDecoration(labelText: 'Hasta'),
                            child: Text(_formatTime(_vHasta))),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              CheckboxListTile(
                title: const Text('Trabaja Sábados'),
                value: _trabajaSabado,
                onChanged: (v) => setState(() => _trabajaSabado = v ?? false),
              ),
              if (_trabajaSabado) ...[
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectTime(context, _sDesde,
                            (t) => setState(() => _sDesde = t)),
                        child: InputDecorator(
                            decoration:
                                const InputDecoration(labelText: 'Desde'),
                            child: Text(_formatTime(_sDesde))),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectTime(context, _sHasta,
                            (t) => setState(() => _sHasta = t)),
                        child: InputDecorator(
                            decoration:
                                const InputDecoration(labelText: 'Hasta'),
                            child: Text(_formatTime(_sHasta))),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                        funcion: () => Get.back(),
                        texto: 'Cancelar',
                        cancelar: true,
                        icon: Icons.close_rounded,
                        width: double.infinity),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      funcion: () {
                        if (_formKey.currentState!.validate()) {
                          saveEditPlace();
                        }
                      },
                      texto: 'Guardar',
                      cancelar: false,
                      icon: Icons.check_rounded,
                      width: double.infinity,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Generic Settings Widgets ---

class NewAfp extends StatefulWidget {
  const NewAfp({super.key});
  @override
  State<NewAfp> createState() => _NewAfpState();
}

class _NewAfpState extends State<NewAfp> {
  final TextEditingController _cont = TextEditingController();
  final _key = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return _buildNewGeneric('Nueva AFP', 'Nombre AFP', _cont, _key, 'afps',
        'AFP registrada con éxito');
  }
}

class NewPrevision extends StatefulWidget {
  const NewPrevision({super.key});
  @override
  State<NewPrevision> createState() => _NewPrevisionState();
}

class _NewPrevisionState extends State<NewPrevision> {
  final TextEditingController _cont = TextEditingController();
  final _key = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return _buildNewGeneric('Nueva Previsión', 'Nombre Previsión', _cont, _key,
        'previsiones', 'Previsión registrada con éxito');
  }
}

class NewCommune extends StatefulWidget {
  const NewCommune({super.key});
  @override
  State<NewCommune> createState() => _NewCommuneState();
}

class _NewCommuneState extends State<NewCommune> {
  final TextEditingController _cont = TextEditingController();
  final _key = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return _buildNewGeneric('Nueva Comuna', 'Nombre Comuna', _cont, _key,
        'comunas', 'Comuna registrada con éxito');
  }
}

class NewCivilState extends StatefulWidget {
  const NewCivilState({super.key});
  @override
  State<NewCivilState> createState() => _NewCivilStateState();
}

class _NewCivilStateState extends State<NewCivilState> {
  final TextEditingController _cont = TextEditingController();
  final _key = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return _buildNewGeneric('Nuevo Estado Civil', 'Estado Civil', _cont, _key,
        'estadosciviles', 'Estado Civil registrado con éxito');
  }
}

class NewNacionality extends StatefulWidget {
  const NewNacionality({super.key});
  @override
  State<NewNacionality> createState() => _NewNacionalityState();
}

class _NewNacionalityState extends State<NewNacionality> {
  final TextEditingController _cont = TextEditingController();
  final _key = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return _buildNewGeneric('Nueva Nacionalidad', 'Nacionalidad', _cont, _key,
        'nacionalidades', 'Nacionalidad registrada con éxito');
  }
}

class NewLabor extends StatefulWidget {
  const NewLabor({super.key});
  @override
  State<NewLabor> createState() => _NewLaborState();
}

class _NewLaborState extends State<NewLabor> {
  final TextEditingController _cont = TextEditingController();
  final _key = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return _buildNewGeneric('Nueva Labor', 'Cargo/Labor', _cont, _key,
        'labores', 'Labor registrada con éxito');
  }
}

Widget _buildNewGeneric(String title, String hint, TextEditingController cont,
    GlobalKey<FormState> key, String docId, String successMsg) {
  return SingleChildScrollView(
    child: Padding(
      padding: EdgeInsets.only(
          bottom: Get.context != null
              ? MediaQuery.of(Get.context!).viewInsets.bottom
              : 0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InputTextField(
                  textController: cont,
                  hint: hint,
                  onFieldSubmitted: (_) {
                    if (key.currentState!.validate()) {
                      db.collection('Otros').doc(docId).update({
                        'tipos': FieldValue.arrayUnion([cont.text.trim()])
                      });
                      Get.back();
                      AnimatedSnackBar.material(successMsg,
                              type: AnimatedSnackBarType.success)
                          .show(Get.context!);
                    }
                  },
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                        funcion: () => Get.back(),
                        texto: 'Cancelar',
                        cancelar: true,
                        icon: Icons.close_rounded,
                        width: double.infinity),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      funcion: () {
                        if (key.currentState!.validate()) {
                          db.collection('Otros').doc(docId).update({
                            'tipos': FieldValue.arrayUnion([cont.text.trim()])
                          });
                          Get.back();
                          AnimatedSnackBar.material(successMsg,
                                  type: AnimatedSnackBarType.success)
                              .show(Get.context!);
                        }
                      },
                      texto: 'Agregar',
                      cancelar: false,
                      icon: Icons.add_rounded,
                      width: double.infinity,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class EditGenericCategory extends StatefulWidget {
  final String docId;
  final String existingItem;
  final String title;

  const EditGenericCategory({
    super.key,
    required this.docId,
    required this.existingItem,
    required this.title,
  });

  @override
  State<EditGenericCategory> createState() => _EditGenericCategoryState();
}

class _EditGenericCategoryState extends State<EditGenericCategory> {
  late TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.existingItem);
  }

  void _save() async {
    try {
      await db.runTransaction((transaction) async {
        DocumentReference ref = db.collection('Otros').doc(widget.docId);
        DocumentSnapshot snap = await transaction.get(ref);
        if (snap.exists) {
          List<dynamic> items = List.from(snap['tipos']);
          int index = items.indexOf(widget.existingItem);
          if (index != -1) {
            items[index] = _controller.text.trim();
            transaction.update(ref, {'tipos': items});
          }
        }
      });
      if (!mounted) return;
      Get.back();
      AnimatedSnackBar.material('Cambios guardados',
              type: AnimatedSnackBarType.success)
          .show(context);
    } catch (e) {
      debugPrint("Error updating category: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InputTextField(
                  textController: _controller,
                  hint: 'Nombre',
                  onFieldSubmitted: (_) {
                    if (_formKey.currentState!.validate()) _save();
                  },
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                        funcion: () => Get.back(),
                        texto: 'Cancelar',
                        cancelar: true,
                        icon: Icons.close_rounded,
                        width: double.infinity),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                        funcion: () {
                          if (_formKey.currentState!.validate()) _save();
                        },
                        texto: 'Guardar',
                        cancelar: false,
                        icon: Icons.check_rounded,
                        width: double.infinity),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
