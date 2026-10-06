import '../../services/permission_service.dart';
import '../../widgets/routes.dart';
import '../setup/setup_screen.dart';
import 'shell_screen.dart';

class AppFlow {
  static Future<void> enter() async {
    final perms = await PermissionService.check();
    Nav.replaceAll(perms.all ? const ShellScreen() : const SetupScreen());
  }

  static void openShell() => Nav.replaceAll(const ShellScreen());
}
