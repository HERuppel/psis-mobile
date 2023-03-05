import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/modules/patients/patients_controller.dart';
import 'package:mobile/providers/auth/auth_provider.dart';
import 'package:mobile/shared/models/Patient/patient_model.dart';

import '../../service/index.dart';
import '../../shared/models/Error/error_response_model.dart';
import '../../shared/widgets/snackbar/snackbar_widget.dart';
import '../../shared/widgets/text_input/text_input.dart';

class PatientsPage extends ConsumerStatefulWidget {
  const PatientsPage({super.key});

  @override
  ConsumerState<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends ConsumerState<PatientsPage> {
  final patientsController = PatientsController();
  bool loading = true;
  ValueNotifier<List<PatientModel>> patients = ValueNotifier([]);

  Future<void> getPatients() async {
    try {
      setState(() {
        loading = true;
      });
      final hasUser = await ref.read(authProvider).getUserData();

      if (hasUser) {
        final accessToken = ref.read(authProvider).accessToken;
        dio.options.headers[HttpHeaders.authorizationHeader] =
            "bearer $accessToken";
      }

      final value = await patientsController.getPatients(0, 10, '');
      setState(() {
        patients.value = value.content.items;
      });
    } catch (e) {
      if (e is DioError) {
        ErrorResponseModel response =
            ErrorResponseModel.fromJson(e.response?.data);

        GlobalSnackBar.show(
            context,
            response.message != ""
                ? response.message
                : "Ocorreu um erro ao recuperar os pacientes.");
      } else {
        GlobalSnackBar.show(
            context, "Ocorreu um erro ao recuperar os pacientes.");
      }
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getPatients();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(children: [
        TextInputWidget(
            label: "Nome, CPF ou e-mail",
            onChanged: (value) {
              patientsController.onChange(composed: value);
            }),
        Expanded(
            child: ValueListenableBuilder<List<PatientModel>>(
          valueListenable: patients,
          builder: (context, value, _) {
            return ListView.builder(
              itemCount: value.length,
              itemBuilder: (context, index) {
                return Text(value[index].name);
              },
            );
          },
        )),
      ]),
    );
  }
}
