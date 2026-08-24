import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/excel_backup_service.dart';

final excelBackupServiceProvider = Provider<ExcelBackupService>((ref) => ExcelBackupService());
